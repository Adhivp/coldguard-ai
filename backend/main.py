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
"""

import os
from datetime import datetime, timezone
from typing import List, Literal, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Path, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import auth
import schemas
from database import supabase
from models import create_tables

load_dotenv()

COOLOFF_WINDOW = int(os.getenv("COOLOFF_WINDOW_SECONDS", "300"))
MAX_GAP = int(os.getenv("MAX_GAP_SECONDS", "70"))

app = FastAPI(
    title="ColdGuard API",
    description=__doc__,
    version="3.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    create_tables()


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
        version="3.0.0",
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
)
def ingest_telemetry(
    payload: schemas.TelemetryPayload,
    x_cg_signature: str = Header(
        ...,
        alias="X-CG-Signature",
        description="HMAC-SHA256 hex digest",
        example="3d4f...a8b1",
    ),
):
    """
    **Primary endpoint for the Arduino Uno Q.**

    ### Request flow
    1. Timestamp validated within ±`TIMESTAMP_TOLERANCE_SECONDS` of UTC now
    2. Nonce checked against `request_log` table (replay attack prevention)
    3. Device secret fetched from `devices` table
    4. HMAC-SHA256 signature verified
    5. Cool-off check: if a reading for this `(device_id, product_id)` pair was
       accepted within the last `COOLOFF_WINDOW_SECONDS`, returns cached reading
    6. Continuity check: gap > `MAX_GAP_SECONDS` sets `continuity_ok = false`
    7. Reading persisted to `sensor_readings`
    """
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
                message=f"Cool-off active. Next reading accepted in {remaining:.0f}s.",
                cooloff_remaining_seconds=round(remaining, 1),
                last_reading=schemas.ReadingOut(**last_row),
            )

    gap_seconds: Optional[float] = None
    continuity_ok = True
    if last_row:
        last_ts = datetime.fromisoformat(last_row["reading_ts"])
        if last_ts.tzinfo is None:
            last_ts = last_ts.replace(tzinfo=timezone.utc)
        gap_seconds = round((reading_ts - last_ts).total_seconds(), 2)
        if gap_seconds > MAX_GAP:
            continuity_ok = False

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
    product_id: Optional[str] = Query(None, example="PROD-001"),
    limit: int = Query(100, le=1000),
):
    """Fetch real readings stored by the device. Optionally filter by `product_id`."""
    q = supabase.table("sensor_readings").select("*").eq("device_id", device_id)
    if product_id:
        q = q.eq("product_id", product_id)
    result = q.order("reading_ts", desc=True).limit(limit).execute()
    return result.data


# ─────────────────────────────────────────────────────────────────────────────
# Device provisioning
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
    and returns it **once**. Flash this secret onto the Arduino.

    > **The secret is shown exactly once – it cannot be retrieved again.**
    """
    secret_hex = auth.provision_new_device(req.device_id, req.firmware_version)
    return schemas.ProvisionResponse(
        device_id=req.device_id,
        secret_hex=secret_hex,
        message="Provision this secret onto the device immediately. It will not be shown again.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# QR Scan – product summary from real data
# ─────────────────────────────────────────────────────────────────────────────

class CurrentReading(BaseModel):
    temperature_c: float
    humidity_pct: Optional[float]
    reading_ts: datetime
    continuity_ok: bool
    gap_seconds: Optional[float]


class ProductSummary(BaseModel):
    product_id: str
    device_id: str
    total_readings: int
    first_reading_ts: Optional[datetime]
    last_reading_ts: Optional[datetime]
    current: Optional[CurrentReading]
    avg_temperature_c: Optional[float]
    min_temperature_c: Optional[float]
    max_temperature_c: Optional[float]
    avg_humidity_pct: Optional[float]
    excursion_count: int = Field(..., description="Readings where continuity_ok = false")


@app.get(
    "/scan/{product_id}",
    response_model=ProductSummary,
    tags=["QR Scan"],
    summary="Scan a QR code – returns real product summary from sensor data",
)
def scan_product(
    product_id: str = Path(..., example="PROD-001"),
    device_id: Optional[str] = Query(None, example="CG-UNO-0001", description="Filter by device if multiple devices monitor this product"),
):
    """
    **Primary endpoint for the mobile QR scan screen.**

    Queries real sensor readings stored in Supabase for the given `product_id`
    and returns a summary including current reading, stats, and excursion count.

    Pass `device_id` to filter to a specific Arduino if multiple devices
    are monitoring the same product.
    """
    q = supabase.table("sensor_readings").select("*").eq("product_id", product_id)
    if device_id:
        q = q.eq("device_id", device_id)

    all_rows = q.order("reading_ts", desc=False).execute().data

    if not all_rows:
        raise HTTPException(
            status_code=404,
            detail=f"No readings found for product '{product_id}'. Has the Arduino started sending data?"
        )

    temps = [r["temperature_c"] for r in all_rows]
    humids = [r["humidity_pct"] for r in all_rows if r.get("humidity_pct") is not None]
    excursions = sum(1 for r in all_rows if not r.get("continuity_ok", True))
    latest = all_rows[-1]

    return ProductSummary(
        product_id=product_id.upper(),
        device_id=latest["device_id"],
        total_readings=len(all_rows),
        first_reading_ts=all_rows[0]["reading_ts"],
        last_reading_ts=latest["reading_ts"],
        current=CurrentReading(
            temperature_c=latest["temperature_c"],
            humidity_pct=latest.get("humidity_pct"),
            reading_ts=latest["reading_ts"],
            continuity_ok=latest.get("continuity_ok", True),
            gap_seconds=latest.get("gap_seconds"),
        ),
        avg_temperature_c=round(sum(temps) / len(temps), 2),
        min_temperature_c=round(min(temps), 2),
        max_temperature_c=round(max(temps), 2),
        avg_humidity_pct=round(sum(humids) / len(humids), 2) if humids else None,
        excursion_count=excursions,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Zoom-level graph  (day → hour → minute → second)
# ─────────────────────────────────────────────────────────────────────────────

class GraphPoint(BaseModel):
    timestamp: datetime
    temperature_c: float
    humidity_pct: Optional[float]
    continuity_ok: bool


class GraphMeta(BaseModel):
    zoom: str = Field(..., description="Current zoom level: day | hour | minute | second")
    page: int
    page_size: int
    total_pages: int
    total_points: int
    period_start: Optional[datetime]
    period_end: Optional[datetime]
    avg_temperature_c: Optional[float]
    min_temperature_c: Optional[float]
    max_temperature_c: Optional[float]
    excursion_count: int


class GraphResponse(BaseModel):
    product_id: str
    device_id: Optional[str]
    meta: GraphMeta
    points: List[GraphPoint]


@app.get(
    "/product/{product_id}/graph",
    response_model=GraphResponse,
    tags=["Graph"],
    summary="Zoom-level paginated graph data (day → hour → minute → second)",
)
def get_graph(
    product_id: str = Path(..., example="PROD-001"),
    zoom: Literal["day", "hour", "minute", "second"] = Query(
        "day",
        description=(
            "Zoom level controls aggregation and what `page` means:\n\n"
            "| zoom | 1 page = | points per page | drill-in by |\n"
            "|------|----------|-----------------|-------------|\n"
            "| `day` | all data grouped by day | 1 point per day | pick a day → zoom=hour&date=YYYY-MM-DD |\n"
            "| `hour` | one day, grouped by hour | 24 points | pick an hour → zoom=minute&date=...&hour=HH |\n"
            "| `minute` | one hour, grouped by minute | 60 points | pick a minute → zoom=second&date=...&hour=HH&minute=MM |\n"
            "| `second` | one minute, raw every-second rows | up to 60 points | raw data |\n"
        ),
    ),
    date: Optional[str] = Query(
        None,
        description="UTC date string `YYYY-MM-DD`. Required for zoom=hour/minute/second.",
        example="2026-07-12",
    ),
    hour: Optional[int] = Query(
        None,
        ge=0, le=23,
        description="UTC hour (0–23). Required for zoom=minute/second.",
        example=14,
    ),
    minute: Optional[int] = Query(
        None,
        ge=0, le=59,
        description="UTC minute (0–59). Required for zoom=second.",
        example=30,
    ),
    device_id: Optional[str] = Query(None, example="CG-UNO-0001"),
    page: int = Query(1, ge=1, description="Page number. Only applies to zoom=day (multiple days)."),
    page_size: int = Query(30, ge=1, le=365, description="Days per page. Only used for zoom=day."),
):
    """
    **Zoom-level paginated graph endpoint.**

    Drill from overview down to every individual second reading:

    ```
    zoom=day                         → one point per day (paginated)
      └─ zoom=hour&date=2026-07-12   → 24 hourly points for that day
           └─ zoom=minute&date=2026-07-12&hour=14   → 60 minute points
                └─ zoom=second&date=2026-07-12&hour=14&minute=30  → raw rows
    ```

    All data comes directly from the real `sensor_readings` table in Supabase.
    """
    q_base = supabase.table("sensor_readings").select("*").eq("product_id", product_id)
    if device_id:
        q_base = q_base.eq("device_id", device_id)

    # ── Build time window filter based on zoom level ──────────────────────────
    if zoom == "day":
        rows = q_base.order("reading_ts", desc=False).execute().data

    elif zoom == "hour":
        if not date:
            raise HTTPException(status_code=422, detail="zoom=hour requires ?date=YYYY-MM-DD")
        day_start = f"{date}T00:00:00+00:00"
        day_end   = f"{date}T23:59:59+00:00"
        rows = (
            q_base
            .gte("reading_ts", day_start)
            .lte("reading_ts", day_end)
            .order("reading_ts", desc=False)
            .execute().data
        )

    elif zoom == "minute":
        if not date or hour is None:
            raise HTTPException(status_code=422, detail="zoom=minute requires ?date=YYYY-MM-DD&hour=HH")
        h = str(hour).zfill(2)
        hour_start = f"{date}T{h}:00:00+00:00"
        hour_end   = f"{date}T{h}:59:59+00:00"
        rows = (
            q_base
            .gte("reading_ts", hour_start)
            .lte("reading_ts", hour_end)
            .order("reading_ts", desc=False)
            .execute().data
        )

    elif zoom == "second":
        if not date or hour is None or minute is None:
            raise HTTPException(status_code=422, detail="zoom=second requires ?date=YYYY-MM-DD&hour=HH&minute=MM")
        h = str(hour).zfill(2)
        m = str(minute).zfill(2)
        min_start = f"{date}T{h}:{m}:00+00:00"
        min_end   = f"{date}T{h}:{m}:59+00:00"
        rows = (
            q_base
            .gte("reading_ts", min_start)
            .lte("reading_ts", min_end)
            .order("reading_ts", desc=False)
            .execute().data
        )

    if not rows:
        raise HTTPException(
            status_code=404,
            detail=f"No readings found for product '{product_id}' at this zoom level / time window."
        )

    used_device_id = rows[0]["device_id"] if rows else device_id

    # ── Aggregate rows into graph points based on zoom level ──────────────────

    def _parse_ts(r) -> datetime:
        ts = datetime.fromisoformat(r["reading_ts"])
        return ts if ts.tzinfo else ts.replace(tzinfo=timezone.utc)

    def _bucket_key(r, z: str) -> str:
        ts = _parse_ts(r)
        if z == "day":    return ts.strftime("%Y-%m-%d")
        if z == "hour":   return ts.strftime("%Y-%m-%dT%H")
        if z == "minute": return ts.strftime("%Y-%m-%dT%H:%M")
        return ts.strftime("%Y-%m-%dT%H:%M:%S")

    # Group rows by bucket
    from collections import defaultdict
    buckets: dict = defaultdict(list)
    for r in rows:
        buckets[_bucket_key(r, zoom)].append(r)

    sorted_keys = sorted(buckets.keys())

    # Paginate at day zoom; other zooms return all points (they're already bounded)
    if zoom == "day":
        total_pages = max(1, -(-len(sorted_keys) // page_size))  # ceil division
        start = (page - 1) * page_size
        paged_keys = sorted_keys[start: start + page_size]
    else:
        total_pages = 1
        paged_keys = sorted_keys

    # Build graph points: average within each bucket
    points: List[GraphPoint] = []
    for key in paged_keys:
        bucket = buckets[key]
        avg_temp = round(sum(r["temperature_c"] for r in bucket) / len(bucket), 2)
        humids_b = [r["humidity_pct"] for r in bucket if r.get("humidity_pct") is not None]
        avg_humid = round(sum(humids_b) / len(humids_b), 2) if humids_b else None
        cont_ok = all(r.get("continuity_ok", True) for r in bucket)
        # Use the first timestamp of the bucket as the point's time
        ts = _parse_ts(bucket[0])
        points.append(GraphPoint(
            timestamp=ts,
            temperature_c=avg_temp,
            humidity_pct=avg_humid,
            continuity_ok=cont_ok,
        ))

    # Summary stats over returned points
    all_temps = [p.temperature_c for p in points]
    all_humids = [p.humidity_pct for p in points if p.humidity_pct is not None]
    exc_count = sum(1 for p in points if not p.continuity_ok)

    return GraphResponse(
        product_id=product_id.upper(),
        device_id=used_device_id,
        meta=GraphMeta(
            zoom=zoom,
            page=page,
            page_size=page_size if zoom == "day" else len(points),
            total_pages=total_pages,
            total_points=len(points),
            period_start=points[0].timestamp if points else None,
            period_end=points[-1].timestamp if points else None,
            avg_temperature_c=round(sum(all_temps) / len(all_temps), 2) if all_temps else None,
            min_temperature_c=round(min(all_temps), 2) if all_temps else None,
            max_temperature_c=round(max(all_temps), 2) if all_temps else None,
            excursion_count=exc_count,
        ),
        points=points,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Products list – from real device data
# ─────────────────────────────────────────────────────────────────────────────

class ProductListItem(BaseModel):
    product_id: str
    device_id: str
    total_readings: int
    latest_temperature_c: Optional[float]
    latest_reading_ts: Optional[datetime]


@app.get(
    "/products",
    response_model=List[ProductListItem],
    tags=["Product"],
    summary="List all products seen in sensor data",
)
def list_products():
    """
    Returns every distinct `product_id` that has sent at least one reading,
    with the latest temperature and timestamp.
    """
    result = supabase.table("sensor_readings").select("product_id, device_id, temperature_c, reading_ts").order("reading_ts", desc=True).execute()

    seen: dict = {}
    for r in result.data:
        pid = r["product_id"]
        if pid not in seen:
            seen[pid] = r

    counts = supabase.table("sensor_readings").select("product_id", count="exact").execute()

    items = []
    for pid, latest in seen.items():
        items.append(ProductListItem(
            product_id=pid,
            device_id=latest["device_id"],
            total_readings=sum(1 for r in result.data if r["product_id"] == pid),
            latest_temperature_c=latest["temperature_c"],
            latest_reading_ts=latest["reading_ts"],
        ))
    return items
