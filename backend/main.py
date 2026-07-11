"""
ColdGuard – Cold Chain Monitoring API
======================================

## Device authentication (Arduino Uno Q)

Every device has a **unique 256-bit secret** provisioned at manufacturing.
The secret **never travels over the network**. Instead, every telemetry request
must include an `X-CG-Signature` header:

```
HMAC-SHA256(secret,
  "{device_id}:{product_id}:{timestamp_utc}:{nonce}:{firmware_version}:{temperature_c}:{humidity_pct}")
```

Fields joined with `:` in that exact order. `humidity_pct` = `"null"` when absent.

## Ingestion rules

| Rule | Value |
|------|-------|
| Expected send interval | 60 s |
| Cool-off window | 300 s (5 min) – returns last reading instead of inserting |
| Max allowed gap | 70 s (60 s + 10 s jitter) |
| Timestamp tolerance | ±70 s from server time |
| Nonce reuse | Rejected (replay protection) |

## Demo QR product IDs

| Product ID | Product | Notes |
|------------|---------|-------|
| `PROD-001` | Hepatitis B Vaccine | Moderate excursions |
| `PROD-002` | Blood Sample O+ | Near-perfect chain |
| `PROD-003` | Frozen Salmon | Multiple excursions |
| `PROD-004` | Insulin – Humalog | Most excursions, poor health |
| `PROD-005` | COVID-19 mRNA Vaccine | Ultra-cold storage |
"""

import math
import os
from datetime import datetime, timedelta, timezone
from typing import List, Literal, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Path, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import auth
import schemas
from database import supabase

load_dotenv()

COOLOFF_WINDOW = int(os.getenv("COOLOFF_WINDOW_SECONDS", "300"))
MAX_GAP = int(os.getenv("MAX_GAP_SECONDS", "70"))

app = FastAPI(
    title="ColdGuard API",
    description=__doc__,
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────────────────────
# Health
# ─────────────────────────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str = Field("ok", example="ok")
    version: str
    supabase_connected: bool
    timestamp_utc: datetime


@app.get("/health", response_model=HealthResponse, tags=["Health"], summary="Service health check")
def health():
    """
    Returns `200 ok` when the service is running and Supabase is reachable.
    Returns `503` if the Supabase ping fails.

    Intended for load-balancers, uptime monitors, and the Flutter app startup check.
    """
    try:
        supabase.table("devices").select("device_id").limit(1).execute()
        db_ok = True
    except Exception:
        db_ok = False

    if not db_ok:
        raise HTTPException(status_code=503, detail="Supabase unreachable")

    return HealthResponse(
        status="ok",
        version="2.0.0",
        supabase_connected=True,
        timestamp_utc=datetime.now(timezone.utc),
    )


# ─────────────────────────────────────────────────────────────────────────────
# Arduino telemetry ingestion
# ─────────────────────────────────────────────────────────────────────────────

@app.post(
    "/telemetry",
    tags=["Arduino Ingestion"],
    summary="Arduino Uno Q posts a signed telemetry reading",
    response_description="'accepted' with new reading ID, or 'cooloff' with cached last reading",
)
def ingest_telemetry(
    payload: schemas.TelemetryPayload,
    x_cg_signature: str = Header(
        ...,
        alias="X-CG-Signature",
        description="HMAC-SHA256 hex digest – see authentication docs above",
        example="3d4f...a8b1",
    ),
):
    """
    **Primary endpoint for the Arduino Uno Q.**

    ### Request flow

    1. Server validates timestamp is within ±`TIMESTAMP_TOLERANCE_SECONDS` of UTC now
    2. Nonce is checked against `used_nonces` table (replay attack prevention)
    3. Device secret is fetched from Supabase `devices` table
    4. HMAC-SHA256 signature is verified
    5. **Cool-off check**: if a reading for this `(device_id, product_id)` pair was
       accepted within the last `COOLOFF_WINDOW_SECONDS`, the cached reading is returned
       without inserting a new row (status = `"cooloff"`)
    6. **Continuity check**: gap from previous reading is computed. If > `MAX_GAP_SECONDS`,
       the reading is inserted but `continuity_ok` = `false`
    7. Reading is persisted to Supabase

    ### One device – many products

    A single Arduino can monitor multiple products (e.g. multiple cold boxes).
    Send a separate request per product with the correct `product_id`.
    Cool-off and continuity are tracked independently per `(device_id, product_id)` pair.

    ### HMAC message construction (Arduino-side pseudocode)

    ```c
    // humidity is 0.0 when sensor absent — use "null" as string if truly missing
    String msg = device_id + ":" + product_id + ":" + timestamp_utc + ":" +
                 nonce + ":" + firmware_version + ":" + temperature_c + ":" + humidity_str;
    String sig = hmac_sha256_hex(secret_bytes, msg);
    ```
    """
    # ── 1–4: Auth (timestamp, nonce, secret, signature) ──────────────────────
    reading_ts = auth.verify_request(
        device_id=payload.device_id,
        product_id=payload.product_id,
        timestamp_utc=payload.timestamp_utc,
        nonce=payload.nonce,
        firmware_version=payload.firmware_version,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        signature=x_cg_signature,
    )

    # ── 5: Cool-off check ─────────────────────────────────────────────────────
    last = (
        supabase.table("sensor_readings")
        .select("*")
        .eq("device_id", payload.device_id)
        .eq("product_id", payload.product_id)
        .order("reading_ts", desc=True)
        .limit(1)
        .execute()
    )
    last_row = last.data[0] if last.data else None

    if last_row:
        last_ts = datetime.fromisoformat(last_row["reading_ts"])
        if last_ts.tzinfo is None:
            last_ts = last_ts.replace(tzinfo=timezone.utc)
        elapsed = (reading_ts - last_ts).total_seconds()

        if elapsed < COOLOFF_WINDOW:
            remaining = COOLOFF_WINDOW - elapsed
            return schemas.TelemetryCooloff(
                status="cooloff",
                message=(
                    f"Cool-off active. Next reading accepted in {remaining:.0f}s. "
                    f"Returning last stored reading."
                ),
                cooloff_remaining_seconds=round(remaining, 1),
                last_reading=schemas.ReadingOut(**last_row),
            )

    # ── 6: Continuity check ───────────────────────────────────────────────────
    gap_seconds: Optional[float] = None
    continuity_ok = True

    if last_row:
        last_ts = datetime.fromisoformat(last_row["reading_ts"])
        if last_ts.tzinfo is None:
            last_ts = last_ts.replace(tzinfo=timezone.utc)
        gap_seconds = round((reading_ts - last_ts).total_seconds(), 2)
        if gap_seconds > MAX_GAP:
            continuity_ok = False

    # ── 7: Persist ────────────────────────────────────────────────────────────
    row = {
        "device_id": payload.device_id,
        "product_id": payload.product_id,
        "temperature_c": payload.temperature_c,
        "humidity_pct": payload.humidity_pct,
        "firmware_version": payload.firmware_version,
        "nonce": payload.nonce,
        "reading_ts": reading_ts.isoformat(),
        "gap_seconds": gap_seconds,
        "continuity_ok": continuity_ok,
    }
    inserted = supabase.table("sensor_readings").insert(row).execute()
    new_row = inserted.data[0]

    # Update device last_seen_at
    supabase.table("devices").update({
        "last_seen_at": reading_ts.isoformat(),
        "firmware_version": payload.firmware_version,
    }).eq("device_id", payload.device_id).execute()

    return schemas.TelemetryAccepted(
        status="accepted",
        reading_id=new_row["id"],
        device_id=new_row["device_id"],
        product_id=new_row["product_id"],
        reading_ts=new_row["reading_ts"],
        gap_seconds=new_row.get("gap_seconds"),
        continuity_ok=new_row["continuity_ok"],
    )


@app.get(
    "/telemetry/{device_id}",
    response_model=List[schemas.ReadingOut],
    tags=["Arduino Ingestion"],
    summary="Fetch stored readings for a device",
)
def get_device_readings(
    device_id: str = Path(..., example="CG-UNO-0001"),
    product_id: Optional[str] = Query(None, example="PROD-001", description="Filter by product"),
    limit: int = Query(100, le=1000),
):
    """Fetch real readings stored by the device. Optionally filter by `product_id`."""
    q = supabase.table("sensor_readings").select("*").eq("device_id", device_id)
    if product_id:
        q = q.eq("product_id", product_id)
    result = q.order("reading_ts", desc=True).limit(limit).execute()
    return result.data


# ─────────────────────────────────────────────────────────────────────────────
# Device provisioning (admin – restrict via network ACL / API gateway in prod)
# ─────────────────────────────────────────────────────────────────────────────

@app.post(
    "/admin/provision",
    response_model=schemas.ProvisionResponse,
    tags=["Device Provisioning"],
    summary="Provision a new Arduino device",
)
def provision_device(req: schemas.ProvisionRequest):
    """
    **Run once per device at manufacturing time.**

    Generates a 256-bit (32-byte) random secret, stores it in the `devices` table,
    and returns it **once**. Flash this secret onto the Arduino's EEPROM/PROGMEM.

    > **The secret is shown exactly once – it cannot be retrieved again.**
    > If lost, deactivate the device and provision a new one.

    ### Arduino storage recommendation
    Store the secret as 32 bytes in `PROGMEM` or write to EEPROM at address 0.
    Never log it to Serial or send it over any network interface.

    ```c
    // Example: store secret in EEPROM
    const uint8_t SECRET[32] PROGMEM = { 0x3d, 0x4f, ... }; // from provisioning
    ```
    """
    secret_hex = auth.provision_new_device(req.device_id, req.firmware_version)
    return schemas.ProvisionResponse(
        device_id=req.device_id,
        secret_hex=secret_hex,
        message="Provision this secret onto the device immediately. It will not be shown again.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Demo data – mobile UI
# ─────────────────────────────────────────────────────────────────────────────

DEMO_PRODUCTS = {
    "PROD-001": {
        "name": "Hepatitis B Vaccine – Batch HBV-2024-09",
        "batch_number": "HBV-2024-09-A",
        "manufacturer": "PharmaCore Labs",
        "category": "Vaccine",
        "storage_requirement": "2 °C – 8 °C",
        "temp_min": 2.0, "temp_max": 8.0, "temp_target": 4.5,
        "humid_min": 40.0, "humid_max": 70.0, "humid_target": 55.0,
        "manufactured_days_ago": 120, "shelf_life_days": 365,
        "location": "Cold Storage Unit 3, Mumbai",
        "health_score": 87,
        "excursion_minutes": [180, 720, 2100],
        "excursion_delta": [2.8, 1.5, 3.1],
    },
    "PROD-002": {
        "name": "Blood Sample – Type O+ | Patient Ref #BLD-4421",
        "batch_number": "BS-2024-11-07-C",
        "manufacturer": "City General Hospital",
        "category": "Blood Sample",
        "storage_requirement": "1 °C – 6 °C",
        "temp_min": 1.0, "temp_max": 6.0, "temp_target": 4.0,
        "humid_min": 35.0, "humid_max": 65.0, "humid_target": 50.0,
        "manufactured_days_ago": 3, "shelf_life_days": 42,
        "location": "Pathology Lab – Delhi",
        "health_score": 95,
        "excursion_minutes": [90],
        "excursion_delta": [1.2],
    },
    "PROD-003": {
        "name": "Frozen Atlantic Salmon – Batch FS-OCT-22",
        "batch_number": "FS-2024-10-22-B",
        "manufacturer": "Ocean Fresh Ltd.",
        "category": "Food",
        "storage_requirement": "-18 °C – -15 °C",
        "temp_min": -18.0, "temp_max": -15.0, "temp_target": -17.0,
        "humid_min": 80.0, "humid_max": 95.0, "humid_target": 88.0,
        "manufactured_days_ago": 45, "shelf_life_days": 180,
        "location": "Frozen Warehouse B, Chennai",
        "health_score": 72,
        "excursion_minutes": [300, 1440, 3600, 7200],
        "excursion_delta": [2.1, 3.5, 1.8, 4.0],
    },
    "PROD-004": {
        "name": "Insulin – Humalog 100 U/mL | 10×3 mL",
        "batch_number": "INS-2024-08-15-D",
        "manufacturer": "MediPharm Inc.",
        "category": "Pharmaceutical",
        "storage_requirement": "2 °C – 8 °C",
        "temp_min": 2.0, "temp_max": 8.0, "temp_target": 5.0,
        "humid_min": 40.0, "humid_max": 65.0, "humid_target": 52.0,
        "manufactured_days_ago": 200, "shelf_life_days": 730,
        "location": "Pharmacy Cold Chain – Bangalore",
        "health_score": 61,
        "excursion_minutes": [60, 600, 2880, 5040, 8640, 14400],
        "excursion_delta": [3.5, 2.0, 4.2, 1.9, 3.8, 2.5],
    },
    "PROD-005": {
        "name": "COVID-19 mRNA Vaccine – Batch COV-25-03",
        "batch_number": "COV-2025-03-F",
        "manufacturer": "BioShield Pharma",
        "category": "Vaccine",
        "storage_requirement": "-25 °C – -15 °C",
        "temp_min": -25.0, "temp_max": -15.0, "temp_target": -20.0,
        "humid_min": 30.0, "humid_max": 60.0, "humid_target": 45.0,
        "manufactured_days_ago": 30, "shelf_life_days": 180,
        "location": "Ultra-Cold Storage, Hyderabad",
        "health_score": 91,
        "excursion_minutes": [240, 1200],
        "excursion_delta": [2.3, 1.7],
    },
}

import random

_NOW = datetime(2026, 7, 11, 12, 0, 0, tzinfo=timezone.utc)


def _seed(key: str) -> random.Random:
    return random.Random(sum(ord(c) for c in key) * 997)


def _temp_at_minute(p: dict, minute: int, rng: random.Random) -> float:
    target = p["temp_target"]
    drift = 0.8 * math.sin(2 * math.pi * minute / 360)
    noise = rng.gauss(0, 0.3)
    spike = 0.0
    for exc_min, exc_delta in zip(p["excursion_minutes"], p["excursion_delta"]):
        dist = abs(minute - exc_min)
        if dist <= 6:
            spike = exc_delta * math.exp(-0.3 * dist)
    return round(target + drift + noise + spike, 2)


def _humid_at_minute(p: dict, minute: int, rng: random.Random) -> float:
    target = p["humid_target"]
    drift = 3.0 * math.sin(2 * math.pi * minute / 480 + 1.2)
    noise = rng.gauss(0, 1.0)
    return round(max(p["humid_min"] - 5, min(p["humid_max"] + 5, target + drift + noise)), 2)


def _status(temp: float, p: dict) -> Literal["OK", "WARNING", "CRITICAL"]:
    lo, hi = p["temp_min"], p["temp_max"]
    if lo <= temp <= hi:
        return "OK"
    if (lo - (hi - lo) * 0.5) <= temp <= (hi + (hi - lo) * 0.5):
        return "WARNING"
    return "CRITICAL"


def _get_product_or_404(product_id: str) -> dict:
    p = DEMO_PRODUCTS.get(product_id.upper())
    if not p:
        raise HTTPException(
            status_code=404,
            detail=f"Product '{product_id}' not found. Try: {', '.join(DEMO_PRODUCTS.keys())}",
        )
    return p


# ── Response models ───────────────────────────────────────────────────────────

class ProductInfo(BaseModel):
    product_id: str
    name: str
    batch_number: str
    manufacturer: str
    category: str
    storage_requirement: str
    manufactured_at: datetime
    expires_at: datetime
    current_location: str


class CurrentReading(BaseModel):
    temperature_c: float
    humidity_pct: float
    status: Literal["OK", "WARNING", "CRITICAL"]
    last_updated: datetime


class LifeSummary(BaseModel):
    days_remaining: int
    health_score: int = Field(..., ge=0, le=100)
    estimated_expiry: datetime
    adjusted_days_remaining: int
    status: Literal["EXCELLENT", "GOOD", "FAIR", "POOR", "CRITICAL", "EXPIRED"]
    total_excursions: int


class ScanResponse(BaseModel):
    product: ProductInfo
    current: CurrentReading
    life: LifeSummary


class GraphPoint(BaseModel):
    timestamp: datetime
    temperature_c: float
    humidity_pct: float
    status: Literal["OK", "WARNING", "CRITICAL"]


class GraphSummary(BaseModel):
    avg_temperature_c: float
    min_temperature_c: float
    max_temperature_c: float
    avg_humidity_pct: float
    excursion_count: int
    excursion_duration_minutes: int


class GraphResponse(BaseModel):
    product_id: str
    range: str
    interval_minutes: int
    total_points: int
    points: List[GraphPoint]
    summary: GraphSummary


class TimelineReading(BaseModel):
    index: int
    timestamp: datetime
    temperature_c: float
    humidity_pct: float
    location: str
    status: Literal["OK", "WARNING", "CRITICAL"]
    alert: Optional[str]


class TimelineResponse(BaseModel):
    product_id: str
    total_minutes: int
    page: int
    page_size: int
    total_pages: int
    readings: List[TimelineReading]


class LifeFactor(BaseModel):
    name: str
    impact: Literal["NONE", "LOW", "MEDIUM", "HIGH"]
    detail: str
    score_deduction: int


class LifeEstimateResponse(BaseModel):
    product_id: str
    manufactured_at: datetime
    label_expiry: datetime
    estimated_expiry: datetime
    label_days_remaining: int
    adjusted_days_remaining: int
    days_lost: int
    health_score: int = Field(..., ge=0, le=100)
    status: Literal["EXCELLENT", "GOOD", "FAIR", "POOR", "CRITICAL", "EXPIRED"]
    confidence: float
    factors: List[LifeFactor]
    recommendation: str


class ProductListItem(BaseModel):
    product_id: str
    name: str
    category: str
    status: Literal["OK", "WARNING", "CRITICAL"]
    health_score: int
    location: str


# ── Builders ──────────────────────────────────────────────────────────────────

def _build_info(pid: str, p: dict) -> ProductInfo:
    mfg = _NOW - timedelta(days=p["manufactured_days_ago"])
    return ProductInfo(
        product_id=pid,
        name=p["name"],
        batch_number=p["batch_number"],
        manufacturer=p["manufacturer"],
        category=p["category"],
        storage_requirement=p["storage_requirement"],
        manufactured_at=mfg,
        expires_at=mfg + timedelta(days=p["shelf_life_days"]),
        current_location=p["location"],
    )


def _build_current(p: dict) -> CurrentReading:
    rng = _seed(p["batch_number"])
    m = p["manufactured_days_ago"] * 24 * 60
    temp = _temp_at_minute(p, m, rng)
    humid = _humid_at_minute(p, m, rng)
    return CurrentReading(temperature_c=temp, humidity_pct=humid, status=_status(temp, p), last_updated=_NOW)


def _build_life(p: dict) -> LifeSummary:
    mfg = _NOW - timedelta(days=p["manufactured_days_ago"])
    exp = mfg + timedelta(days=p["shelf_life_days"])
    penalty = round((100 - p["health_score"]) * 0.5)
    adj_exp = exp - timedelta(days=penalty)
    s = p["health_score"]
    status = "EXCELLENT" if s >= 90 else "GOOD" if s >= 75 else "FAIR" if s >= 55 else "POOR" if s >= 35 else "CRITICAL" if s > 0 else "EXPIRED"
    return LifeSummary(
        days_remaining=max(0, (exp - _NOW).days),
        health_score=s,
        estimated_expiry=adj_exp,
        adjusted_days_remaining=max(0, (adj_exp - _NOW).days),
        status=status,
        total_excursions=len(p["excursion_minutes"]),
    )


# ── Demo endpoints ────────────────────────────────────────────────────────────

@app.get("/scan/{product_id}", response_model=ScanResponse, tags=["QR Scan"],
         summary="Scan a QR code – returns full product summary")
def scan_product(product_id: str = Path(..., example="PROD-001")):
    """
    **One-shot endpoint for the mobile QR scan screen.**

    Returns product info, current sensor state, and AI life estimate in a single call.

    ### Demo IDs to try
    `PROD-001` · `PROD-002` · `PROD-003` · `PROD-004` · `PROD-005`
    """
    p = _get_product_or_404(product_id)
    return ScanResponse(product=_build_info(product_id.upper(), p), current=_build_current(p), life=_build_life(p))


@app.get("/products", response_model=List[ProductListItem], tags=["Product"],
         summary="List all demo products")
def list_products():
    """Returns all demo products with live health status. Use for a product browser screen."""
    return [
        ProductListItem(
            product_id=pid, name=p["name"], category=p["category"],
            status=_build_current(p).status, health_score=p["health_score"], location=p["location"],
        )
        for pid, p in DEMO_PRODUCTS.items()
    ]


@app.get("/product/{product_id}/info", response_model=ProductInfo, tags=["Product"],
         summary="Product metadata")
def get_product_info(product_id: str = Path(..., example="PROD-001")):
    p = _get_product_or_404(product_id)
    return _build_info(product_id.upper(), p)


@app.get("/product/{product_id}/graph", response_model=GraphResponse, tags=["Sensor Data"],
         summary="Temperature & humidity graph data")
def get_graph(
    product_id: str = Path(..., example="PROD-001"),
    range: Literal["1d", "7d", "30d"] = Query("1d", description="`1d` = last 24 h, `7d` = last 7 days, `30d` = last 30 days"),
):
    """
    Time-series data ready to plot in Flutter charts.

    | `range` | Interval | Points |
    |---------|----------|--------|
    | `1d`    | 30 min   | 48     |
    | `7d`    | 1 hour   | 168    |
    | `30d`   | 4 hours  | 180    |

    Each point has a `status` field so the chart can colour excursion periods red.
    """
    p = _get_product_or_404(product_id)
    rng = _seed(product_id)
    cfg = {"1d": (1, 30), "7d": (7, 60), "30d": (30, 240)}
    days, interval = cfg[range]
    total_range_min = days * 24 * 60
    n = total_range_min // interval
    start_min = max(0, p["manufactured_days_ago"] * 24 * 60 - total_range_min)

    points, temps, humids, exc_count, exc_dur = [], [], [], 0, 0
    for i in range(n):
        minute = start_min + i * interval
        temp = _temp_at_minute(p, minute, rng)
        humid = _humid_at_minute(p, minute, rng)
        st = _status(temp, p)
        if st != "OK":
            exc_count += 1
            exc_dur += interval
        temps.append(temp)
        humids.append(humid)
        points.append(GraphPoint(
            timestamp=_NOW - timedelta(minutes=(n - i) * interval),
            temperature_c=temp, humidity_pct=humid, status=st,
        ))

    return GraphResponse(
        product_id=product_id.upper(), range=range, interval_minutes=interval,
        total_points=len(points), points=points,
        summary=GraphSummary(
            avg_temperature_c=round(sum(temps) / len(temps), 2),
            min_temperature_c=round(min(temps), 2),
            max_temperature_c=round(max(temps), 2),
            avg_humidity_pct=round(sum(humids) / len(humids), 2),
            excursion_count=exc_count,
            excursion_duration_minutes=exc_dur,
        ),
    )


@app.get("/product/{product_id}/timeline", response_model=TimelineResponse, tags=["Sensor Data"],
         summary="Minute-by-minute history since manufacturing")
def get_timeline(
    product_id: str = Path(..., example="PROD-001"),
    page: int = Query(1, ge=1, description="Page 1 = most recent", example=1),
    page_size: int = Query(60, ge=10, le=1440, description="Readings per page. 60 = 1 hour.", example=60),
):
    """
    Paginated every-minute readings from manufacturing.

    - Newest first (page 1 = last hour)
    - Each reading includes `location` (manufacturing → transit → storage), `status`, and an `alert` message on excursions
    """
    p = _get_product_or_404(product_id)
    rng = _seed(product_id + "tl")
    total_min = p["manufactured_days_ago"] * 24 * 60
    total_pages = math.ceil(total_min / page_size)
    offset = (page - 1) * page_size
    end_idx = total_min - offset
    start_idx = max(0, end_idx - page_size)
    transit_start = int(total_min * 0.05)
    storage_start = int(total_min * 0.15)

    def _loc(m: int) -> str:
        if m < transit_start:
            return f"{p['manufacturer']} – Manufacturing Floor"
        if m < storage_start:
            return "In Transit – Refrigerated Truck"
        return p["location"]

    readings = []
    mfg_ts = _NOW - timedelta(days=p["manufactured_days_ago"])
    for minute in range(end_idx - 1, start_idx - 1, -1):
        temp = _temp_at_minute(p, minute, rng)
        humid = _humid_at_minute(p, minute, rng)
        st = _status(temp, p)
        alert = None
        if st == "WARNING":
            diff = temp - p["temp_max"] if temp > p["temp_max"] else p["temp_min"] - temp
            sign = "+" if temp > p["temp_max"] else "-"
            alert = f"Temperature excursion: {sign}{abs(diff):.1f} °C outside limit"
        elif st == "CRITICAL":
            diff = temp - p["temp_max"] if temp > p["temp_max"] else p["temp_min"] - temp
            alert = f"CRITICAL: {abs(diff):.1f} °C beyond safe range"
        readings.append(TimelineReading(
            index=minute,
            timestamp=mfg_ts + timedelta(minutes=minute),
            temperature_c=temp, humidity_pct=humid,
            location=_loc(minute), status=st, alert=alert,
        ))

    return TimelineResponse(
        product_id=product_id.upper(), total_minutes=total_min,
        page=page, page_size=page_size, total_pages=total_pages, readings=readings,
    )


@app.get("/product/{product_id}/life", response_model=LifeEstimateResponse, tags=["Analytics"],
         summary="AI model – estimated remaining shelf life")
def get_life_estimate(product_id: str = Path(..., example="PROD-001")):
    """
    Model-estimated shelf life based on complete cold-chain history.

    **Health score (0–100) factors:**

    | Factor | Impact |
    |--------|--------|
    | Temperature excursions | Each event degrades the product |
    | Storage duration consumed | % of original shelf life used |
    | Humidity stability | Out-of-range humidity accelerates degradation |
    | Transport shocks | Rapid temperature swings during transit |

    `days_lost` = label shelf life days forfeited due to cold-chain events.
    `estimated_expiry` = `label_expiry` − `days_lost`.
    """
    p = _get_product_or_404(product_id)
    mfg = _NOW - timedelta(days=p["manufactured_days_ago"])
    label_exp = mfg + timedelta(days=p["shelf_life_days"])
    label_days_rem = max(0, (label_exp - _NOW).days)
    n_exc = len(p["excursion_minutes"])
    avg_delta = round(sum(p["excursion_delta"]) / n_exc, 1) if n_exc else 0
    exc_min_total = n_exc * 6

    factors: List[LifeFactor] = []
    score = 100

    # Excursions
    if n_exc == 0:
        fi, fd = "NONE", 0; det = "No temperature excursions recorded"
    elif n_exc == 1:
        fi, fd = "LOW", 3; det = f"1 excursion, avg +{avg_delta} °C for ~{exc_min_total} min"
    elif n_exc <= 3:
        fi, fd = "MEDIUM", 8; det = f"{n_exc} excursions, avg +{avg_delta} °C for ~{exc_min_total} min"
    else:
        fi, fd = "HIGH", 18; det = f"{n_exc} excursions, avg +{avg_delta} °C for ~{exc_min_total} min"
    score -= fd
    factors.append(LifeFactor(name="Temperature Excursions", impact=fi, detail=det, score_deduction=fd))

    # Duration
    pct = round(p["manufactured_days_ago"] / p["shelf_life_days"] * 100, 1)
    if pct < 30:
        di, dd = "NONE", 0; ddet = f"{pct}% of shelf life consumed – early stage"
    elif pct < 60:
        di, dd = "LOW", 4; ddet = f"{pct}% of shelf life consumed"
    elif pct < 80:
        di, dd = "MEDIUM", 10; ddet = f"{pct}% consumed – approaching expiry"
    else:
        di, dd = "HIGH", 20; ddet = f"{pct}% consumed – critical stage"
    score -= dd
    factors.append(LifeFactor(name="Storage Duration", impact=di, detail=ddet, score_deduction=dd))

    # Humidity
    score -= 2
    factors.append(LifeFactor(name="Humidity Stability", impact="LOW", detail=f"Minor humidity variance (target {p['humid_target']}%)", score_deduction=2))

    # Transport shocks
    shocks = max(0, n_exc - 1)
    if shocks == 0:
        si, sd = "NONE", 0; sdet = "No rapid temperature changes during transit"
    elif shocks <= 2:
        si, sd = "LOW", 2; sdet = f"{shocks} rapid change(s) during transit"
    else:
        si, sd = "MEDIUM", 7; sdet = f"{shocks} temperature shocks in transit"
    score -= sd
    factors.append(LifeFactor(name="Transport Shocks", impact=si, detail=sdet, score_deduction=sd))

    final = max(0, min(100, score))
    days_lost = round((100 - final) * p["shelf_life_days"] / 100 * 0.15)
    est_exp = label_exp - timedelta(days=days_lost)
    adj_days = max(0, (est_exp - _NOW).days)
    status = "EXCELLENT" if final >= 90 else "GOOD" if final >= 75 else "FAIR" if final >= 55 else "POOR" if final >= 35 else "CRITICAL" if final > 0 else "EXPIRED"
    recs = {
        "EXCELLENT": "Product in excellent condition. Standard protocols sufficient.",
        "GOOD": "Minor degradation detected – continue monitoring.",
        "FAIR": "Noticeable degradation. Use before adjusted expiry.",
        "POOR": "Significant degradation. Prioritise use and consult quality team.",
        "CRITICAL": "Integrity likely compromised. Do not use without lab verification.",
        "EXPIRED": "Expired. Do not use.",
    }

    return LifeEstimateResponse(
        product_id=product_id.upper(),
        manufactured_at=mfg, label_expiry=label_exp, estimated_expiry=est_exp,
        label_days_remaining=label_days_rem, adjusted_days_remaining=adj_days,
        days_lost=days_lost, health_score=final, status=status,
        confidence=round(0.95 - n_exc * 0.02, 2),
        factors=factors, recommendation=recs[status],
    )
