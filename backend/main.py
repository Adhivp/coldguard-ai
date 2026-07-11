"""
ColdGuard – Cold Chain Monitoring API
======================================
Demo backend for the ColdGuard mobile app.

## Quick start (demo)
Scan one of these QR code product IDs to see live demo data:

| Product ID   | Product                          | Category       |
|-------------|----------------------------------|----------------|
| `PROD-001`  | Hepatitis B Vaccine              | Vaccine        |
| `PROD-002`  | Blood Sample – Type O+           | Blood Sample   |
| `PROD-003`  | Atlantic Salmon Frozen Batch     | Food           |
| `PROD-004`  | Insulin – Humalog 100U/mL        | Pharmaceutical |
| `PROD-005`  | COVID-19 mRNA Vaccine            | Vaccine        |

## Flow
1. **Scan QR** → `GET /scan/{product_id}` — full product summary in one call
2. **Graph tab** → `GET /product/{product_id}/graph?range=1d`
3. **Timeline tab** → `GET /product/{product_id}/timeline?page=1`
4. **Life estimate tab** → `GET /product/{product_id}/life`

All demo endpoints are **public** (no auth required).
Real Arduino sensor ingestion: `POST /readings`
"""

from fastapi import FastAPI, Depends, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from datetime import datetime, timedelta, timezone
import math
import random
import models
import schemas
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="ColdGuard API",
    description=__doc__,
    version="1.0.0",
    contact={"name": "ColdGuard Team"},
    license_info={"name": "MIT"},
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Demo product catalog
# ---------------------------------------------------------------------------

DEMO_PRODUCTS = {
    "PROD-001": {
        "name": "Hepatitis B Vaccine – Batch HBV-2024-09",
        "batch_number": "HBV-2024-09-A",
        "manufacturer": "PharmaCore Labs",
        "category": "Vaccine",
        "storage_requirement": "2 °C – 8 °C",
        "temp_min": 2.0,
        "temp_max": 8.0,
        "temp_target": 4.5,
        "humid_min": 40.0,
        "humid_max": 70.0,
        "humid_target": 55.0,
        "manufactured_days_ago": 120,
        "shelf_life_days": 365,
        "location": "Cold Storage Unit 3, Mumbai",
        "health_score": 87,
        "excursion_minutes": [180, 720, 2100],   # minute indices with spikes
        "excursion_delta": [2.8, 1.5, 3.1],
    },
    "PROD-002": {
        "name": "Blood Sample – Type O+ | Patient Ref #BLD-4421",
        "batch_number": "BS-2024-11-07-C",
        "manufacturer": "City General Hospital",
        "category": "Blood Sample",
        "storage_requirement": "1 °C – 6 °C",
        "temp_min": 1.0,
        "temp_max": 6.0,
        "temp_target": 4.0,
        "humid_min": 35.0,
        "humid_max": 65.0,
        "humid_target": 50.0,
        "manufactured_days_ago": 3,
        "shelf_life_days": 42,
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
        "temp_min": -18.0,
        "temp_max": -15.0,
        "temp_target": -17.0,
        "humid_min": 80.0,
        "humid_max": 95.0,
        "humid_target": 88.0,
        "manufactured_days_ago": 45,
        "shelf_life_days": 180,
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
        "temp_min": 2.0,
        "temp_max": 8.0,
        "temp_target": 5.0,
        "humid_min": 40.0,
        "humid_max": 65.0,
        "humid_target": 52.0,
        "manufactured_days_ago": 200,
        "shelf_life_days": 730,
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
        "temp_min": -25.0,
        "temp_max": -15.0,
        "temp_target": -20.0,
        "humid_min": 30.0,
        "humid_max": 60.0,
        "humid_target": 45.0,
        "manufactured_days_ago": 30,
        "shelf_life_days": 180,
        "location": "Ultra-Cold Storage, Hyderabad",
        "health_score": 91,
        "excursion_minutes": [240, 1200],
        "excursion_delta": [2.3, 1.7],
    },
}

# ---------------------------------------------------------------------------
# Demo data generation helpers
# ---------------------------------------------------------------------------

_NOW = datetime(2026, 7, 11, 12, 0, 0, tzinfo=timezone.utc)


def _seed(product_id: str) -> random.Random:
    """Deterministic RNG seeded from product_id so results never change."""
    return random.Random(sum(ord(c) for c in product_id) * 997)


def _temp_at_minute(p: dict, minute: int, rng: random.Random) -> float:
    """Generate a realistic temperature value for a given minute index."""
    target = p["temp_target"]
    # slow 6-hour sine drift ±0.8 °C
    drift = 0.8 * math.sin(2 * math.pi * minute / 360)
    # small gaussian noise ±0.3 °C
    noise = rng.gauss(0, 0.3)
    # excursion events: brief spikes
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


def _reading_status(temp: float, p: dict) -> Literal["OK", "WARNING", "CRITICAL"]:
    lo, hi = p["temp_min"], p["temp_max"]
    if lo <= temp <= hi:
        return "OK"
    margin = (hi - lo) * 0.5
    if (lo - margin) <= temp <= (hi + margin):
        return "WARNING"
    return "CRITICAL"


def _get_product_or_404(product_id: str) -> dict:
    p = DEMO_PRODUCTS.get(product_id.upper())
    if not p:
        raise HTTPException(
            status_code=404,
            detail=(
                f"Product '{product_id}' not found. "
                f"Try one of: {', '.join(DEMO_PRODUCTS.keys())}"
            ),
        )
    return p

# ---------------------------------------------------------------------------
# Response schemas (Pydantic models)
# ---------------------------------------------------------------------------

class ProductInfo(BaseModel):
    product_id: str = Field(..., example="PROD-001")
    name: str = Field(..., example="Hepatitis B Vaccine – Batch HBV-2024-09")
    batch_number: str = Field(..., example="HBV-2024-09-A")
    manufacturer: str = Field(..., example="PharmaCore Labs")
    category: str = Field(..., example="Vaccine")
    storage_requirement: str = Field(..., example="2 °C – 8 °C")
    manufactured_at: datetime
    expires_at: datetime
    current_location: str = Field(..., example="Cold Storage Unit 3, Mumbai")


class CurrentReading(BaseModel):
    temperature: float = Field(..., example=4.3, description="Temperature in °C")
    humidity: float = Field(..., example=55.1, description="Relative humidity in %")
    status: Literal["OK", "WARNING", "CRITICAL"] = Field(..., example="OK")
    last_updated: datetime


class LifeSummary(BaseModel):
    days_remaining: int = Field(..., example=245, description="Calendar days until original expiry")
    health_score: int = Field(..., ge=0, le=100, example=87, description="0–100; model-estimated product health")
    estimated_expiry: datetime = Field(..., description="Model-adjusted expiry (may be earlier than label expiry)")
    adjusted_days_remaining: int = Field(..., example=230)
    status: Literal["EXCELLENT", "GOOD", "FAIR", "POOR", "CRITICAL", "EXPIRED"]
    total_excursions: int = Field(..., example=2, description="Number of temperature excursion events recorded")


class ScanResponse(BaseModel):
    """Everything the mobile home screen needs in a single QR-scan call."""
    product: ProductInfo
    current: CurrentReading
    life: LifeSummary


class GraphPoint(BaseModel):
    timestamp: datetime
    temperature: float
    humidity: float
    status: Literal["OK", "WARNING", "CRITICAL"]


class GraphSummary(BaseModel):
    avg_temperature: float
    min_temperature: float
    max_temperature: float
    avg_humidity: float
    excursion_count: int
    excursion_duration_minutes: int


class GraphResponse(BaseModel):
    product_id: str
    range: str = Field(..., example="1d")
    interval_minutes: int = Field(..., example=30)
    total_points: int
    points: List[GraphPoint]
    summary: GraphSummary


class TimelineReading(BaseModel):
    index: int = Field(..., description="Minute index from manufacturing (0 = first minute)")
    timestamp: datetime
    temperature: float
    humidity: float
    location: str
    status: Literal["OK", "WARNING", "CRITICAL"]
    alert: Optional[str] = Field(None, example="Temperature excursion: +3.1 °C above limit")


class TimelineResponse(BaseModel):
    product_id: str
    total_minutes: int = Field(..., description="Total minutes since manufacturing")
    page: int
    page_size: int
    total_pages: int
    readings: List[TimelineReading]


class LifeFactor(BaseModel):
    name: str = Field(..., example="Temperature Excursions")
    impact: Literal["NONE", "LOW", "MEDIUM", "HIGH"]
    detail: str = Field(..., example="2 excursions, avg +1.8 °C above limit for ~5 min total")
    score_deduction: int = Field(..., example=5, description="Points deducted from health_score")


class LifeEstimateResponse(BaseModel):
    product_id: str
    manufactured_at: datetime
    label_expiry: datetime = Field(..., description="Original expiry printed on the label")
    estimated_expiry: datetime = Field(..., description="Model-adjusted expiry accounting for cold-chain history")
    label_days_remaining: int
    adjusted_days_remaining: int
    days_lost: int = Field(..., description="Shelf life lost due to cold-chain events")
    health_score: int = Field(..., ge=0, le=100)
    status: Literal["EXCELLENT", "GOOD", "FAIR", "POOR", "CRITICAL", "EXPIRED"]
    confidence: float = Field(..., ge=0.0, le=1.0, example=0.91)
    factors: List[LifeFactor]
    recommendation: str


class ProductListItem(BaseModel):
    product_id: str
    name: str
    category: str
    status: Literal["OK", "WARNING", "CRITICAL"]
    health_score: int
    location: str


# ---------------------------------------------------------------------------
# Shared builder functions
# ---------------------------------------------------------------------------

def _build_product_info(pid: str, p: dict) -> ProductInfo:
    manufactured_at = _NOW - timedelta(days=p["manufactured_days_ago"])
    expires_at = manufactured_at + timedelta(days=p["shelf_life_days"])
    return ProductInfo(
        product_id=pid,
        name=p["name"],
        batch_number=p["batch_number"],
        manufacturer=p["manufacturer"],
        category=p["category"],
        storage_requirement=p["storage_requirement"],
        manufactured_at=manufactured_at,
        expires_at=expires_at,
        current_location=p["location"],
    )


def _build_current_reading(p: dict) -> CurrentReading:
    rng = _seed(p["batch_number"])
    total_minutes = p["manufactured_days_ago"] * 24 * 60
    temp = _temp_at_minute(p, total_minutes, rng)
    humid = _humid_at_minute(p, total_minutes, rng)
    return CurrentReading(
        temperature=temp,
        humidity=humid,
        status=_reading_status(temp, p),
        last_updated=_NOW,
    )


def _build_life_summary(p: dict) -> LifeSummary:
    manufactured_at = _NOW - timedelta(days=p["manufactured_days_ago"])
    expires_at = manufactured_at + timedelta(days=p["shelf_life_days"])
    days_remaining = (expires_at - _NOW).days
    penalty_days = round((100 - p["health_score"]) * 0.5)
    adjusted_expiry = expires_at - timedelta(days=penalty_days)
    adjusted_days = max(0, (adjusted_expiry - _NOW).days)

    score = p["health_score"]
    if score >= 90:
        status = "EXCELLENT"
    elif score >= 75:
        status = "GOOD"
    elif score >= 55:
        status = "FAIR"
    elif score >= 35:
        status = "POOR"
    elif score > 0:
        status = "CRITICAL"
    else:
        status = "EXPIRED"

    return LifeSummary(
        days_remaining=max(0, days_remaining),
        health_score=score,
        estimated_expiry=adjusted_expiry,
        adjusted_days_remaining=adjusted_days,
        status=status,
        total_excursions=len(p["excursion_minutes"]),
    )


# ---------------------------------------------------------------------------
# QR Scan – main entry point for the mobile app
# ---------------------------------------------------------------------------

@app.get(
    "/scan/{product_id}",
    response_model=ScanResponse,
    tags=["QR Scan"],
    summary="Scan a product QR code",
    response_description="Full product summary: info + current sensor state + life estimate",
)
def scan_product(
    product_id: str = Path(
        ...,
        description="Product ID encoded in the QR code",
        example="PROD-001",
    ),
):
    """
    **Primary endpoint for QR code scanning.**

    The mobile app calls this immediately after scanning a QR code.
    Returns everything needed to render the product home screen in **one request**:

    - `product` – name, batch, manufacturer, storage requirements, location
    - `current` – latest temperature & humidity reading + OK / WARNING / CRITICAL status
    - `life` – AI health score (0–100), estimated expiry, days remaining, excursion count

    ### Demo product IDs
    | ID | Product | Interesting? |
    |----|---------|-------------|
    | `PROD-001` | Hepatitis B Vaccine | Moderate excursions |
    | `PROD-002` | Blood Sample O+ | Near-perfect chain |
    | `PROD-003` | Frozen Salmon | Multiple excursions, degraded |
    | `PROD-004` | Insulin | Most excursions, poor health |
    | `PROD-005` | COVID-19 mRNA Vaccine | Ultra-cold storage |
    """
    p = _get_product_or_404(product_id)
    return ScanResponse(
        product=_build_product_info(product_id.upper(), p),
        current=_build_current_reading(p),
        life=_build_life_summary(p),
    )


# ---------------------------------------------------------------------------
# Product info
# ---------------------------------------------------------------------------

@app.get(
    "/product/{product_id}/info",
    response_model=ProductInfo,
    tags=["Product"],
    summary="Get product metadata",
)
def get_product_info(product_id: str):
    """Returns static product information: name, batch, manufacturer, storage requirements, location."""
    p = _get_product_or_404(product_id)
    return _build_product_info(product_id.upper(), p)


@app.get(
    "/products",
    response_model=List[ProductListItem],
    tags=["Product"],
    summary="List all demo products",
)
def list_products():
    """Returns all 5 demo products with their current health summary. Useful for a product browser screen."""
    result = []
    for pid, p in DEMO_PRODUCTS.items():
        current = _build_current_reading(p)
        result.append(ProductListItem(
            product_id=pid,
            name=p["name"],
            category=p["category"],
            status=current.status,
            health_score=p["health_score"],
            location=p["location"],
        ))
    return result


# ---------------------------------------------------------------------------
# Graph data
# ---------------------------------------------------------------------------

@app.get(
    "/product/{product_id}/graph",
    response_model=GraphResponse,
    tags=["Sensor Data"],
    summary="Temperature & humidity graph data",
    response_description="Time-series points ready to plot, plus a summary",
)
def get_graph(
    product_id: str,
    range: Literal["1d", "7d", "30d"] = Query(
        "1d",
        description="Time window to fetch. `1d` = last 24 h, `7d` = last 7 days, `30d` = last 30 days.",
        example="1d",
    ),
):
    """
    Returns temperature and humidity readings sampled at a fixed interval, ready to plot.

    | `range` | Interval | Points returned |
    |---------|----------|-----------------|
    | `1d`    | 30 min   | 48              |
    | `7d`    | 1 hour   | 168             |
    | `30d`   | 4 hours  | 180             |

    Each point includes a `status` field (`OK` / `WARNING` / `CRITICAL`) so the
    Flutter chart can colour individual data points by cold-chain compliance.

    The `summary` block contains min/max/avg and total excursion count + duration.
    """
    p = _get_product_or_404(product_id)
    rng = _seed(product_id)

    range_config = {
        "1d":  {"days": 1,  "interval": 30},
        "7d":  {"days": 7,  "interval": 60},
        "30d": {"days": 30, "interval": 240},
    }
    cfg = range_config[range]
    interval_minutes = cfg["interval"]
    total_minutes_in_range = cfg["days"] * 24 * 60
    n_points = total_minutes_in_range // interval_minutes

    total_life_minutes = p["manufactured_days_ago"] * 24 * 60
    start_minute = max(0, total_life_minutes - total_minutes_in_range)

    points: List[GraphPoint] = []
    temps, humids, excursion_count, excursion_minutes_total = [], [], 0, 0

    for i in range(n_points):
        minute = start_minute + i * interval_minutes
        temp = _temp_at_minute(p, minute, rng)
        humid = _humid_at_minute(p, minute, rng)
        status = _reading_status(temp, p)
        ts = _NOW - timedelta(minutes=(n_points - i) * interval_minutes)

        if status != "OK":
            excursion_count += 1
            excursion_minutes_total += interval_minutes

        temps.append(temp)
        humids.append(humid)
        points.append(GraphPoint(timestamp=ts, temperature=temp, humidity=humid, status=status))

    summary = GraphSummary(
        avg_temperature=round(sum(temps) / len(temps), 2),
        min_temperature=round(min(temps), 2),
        max_temperature=round(max(temps), 2),
        avg_humidity=round(sum(humids) / len(humids), 2),
        excursion_count=excursion_count,
        excursion_duration_minutes=excursion_minutes_total,
    )

    return GraphResponse(
        product_id=product_id.upper(),
        range=range,
        interval_minutes=interval_minutes,
        total_points=len(points),
        points=points,
        summary=summary,
    )


# ---------------------------------------------------------------------------
# Minute-by-minute timeline from manufacturing
# ---------------------------------------------------------------------------

@app.get(
    "/product/{product_id}/timeline",
    response_model=TimelineResponse,
    tags=["Sensor Data"],
    summary="Minute-by-minute readings since manufacturing",
)
def get_timeline(
    product_id: str,
    page: int = Query(1, ge=1, description="Page number (1-indexed)", example=1),
    page_size: int = Query(
        60, ge=10, le=1440,
        description="Readings per page. 60 = one hour of data per page.",
        example=60,
    ),
):
    """
    Returns every-minute sensor readings from the moment of manufacturing.

    Because a product manufactured 120 days ago has **172 800 readings**,
    results are paginated. Use `page` and `page_size` to scroll through history.

    **Recommended usage (mobile timeline screen):**
    - Default: `page=1&page_size=60` → most recent 60 minutes
    - Scroll back: increment `page`

    Readings are returned **newest-first** (descending by time).

    Each reading includes:
    - `index` – minute offset from manufacturing start (0 = first minute)
    - `status` – OK / WARNING / CRITICAL based on storage requirements
    - `alert` – human-readable alert message if status ≠ OK
    - `location` – simulated location tag (manufacturing → transit → storage)
    """
    p = _get_product_or_404(product_id)
    rng = _seed(product_id + "timeline")

    total_minutes = p["manufactured_days_ago"] * 24 * 60
    total_pages = math.ceil(total_minutes / page_size)

    # Page 1 = most recent
    start_from_end = (page - 1) * page_size
    end_idx = total_minutes - start_from_end
    start_idx = max(0, end_idx - page_size)

    # Location simulation: manufacturing → transit → storage
    transit_start = int(total_minutes * 0.05)
    storage_start = int(total_minutes * 0.15)

    def _location(minute: int) -> str:
        if minute < transit_start:
            return f"{p['manufacturer']} – Manufacturing Floor"
        if minute < storage_start:
            return "In Transit – Refrigerated Truck"
        return p["location"]

    readings: List[TimelineReading] = []
    for minute in range(end_idx - 1, start_idx - 1, -1):
        temp = _temp_at_minute(p, minute, rng)
        humid = _humid_at_minute(p, minute, rng)
        status = _reading_status(temp, p)
        ts = (_NOW - timedelta(days=p["manufactured_days_ago"])) + timedelta(minutes=minute)

        alert = None
        if status == "WARNING":
            diff = temp - p["temp_max"] if temp > p["temp_max"] else p["temp_min"] - temp
            alert = f"Temperature excursion: {'+' if temp > p['temp_max'] else '-'}{abs(diff):.1f} °C outside limit"
        elif status == "CRITICAL":
            diff = temp - p["temp_max"] if temp > p["temp_max"] else p["temp_min"] - temp
            alert = f"CRITICAL: {abs(diff):.1f} °C beyond safe range – product integrity at risk"

        readings.append(TimelineReading(
            index=minute,
            timestamp=ts,
            temperature=temp,
            humidity=humid,
            location=_location(minute),
            status=status,
            alert=alert,
        ))

    return TimelineResponse(
        product_id=product_id.upper(),
        total_minutes=total_minutes,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
        readings=readings,
    )


# ---------------------------------------------------------------------------
# AI life estimation
# ---------------------------------------------------------------------------

@app.get(
    "/product/{product_id}/life",
    response_model=LifeEstimateResponse,
    tags=["Analytics"],
    summary="AI model – estimated remaining shelf life",
    response_description="Detailed life estimate with contributing factors and recommendation",
)
def get_life_estimate(product_id: str):
    """
    Returns a model-estimated shelf life analysis for the scanned product.

    The model evaluates **four factors** and deducts points from a base score of 100:

    | Factor | How it affects shelf life |
    |--------|--------------------------|
    | Temperature Excursions | Each event above/below storage range degrades the product |
    | Storage Duration | % of original shelf life already consumed |
    | Humidity Stability | Humidity out of range accelerates degradation |
    | Transport Shocks | Rapid temperature swings during transit |

    **Health score interpretation:**
    | Score | Status | Meaning |
    |-------|--------|---------|
    | 90–100 | EXCELLENT | Full shelf life expected |
    | 75–89  | GOOD     | Minor degradation, safe to use |
    | 55–74  | FAIR     | Noticeable degradation, monitor closely |
    | 35–54  | POOR     | Significant degradation, use soon |
    | 1–34   | CRITICAL | Integrity compromised |
    | 0      | EXPIRED  | Do not use |

    `days_lost` = original shelf life days lost due to cold-chain events.
    `estimated_expiry` = label expiry minus `days_lost`.
    """
    p = _get_product_or_404(product_id)

    manufactured_at = _NOW - timedelta(days=p["manufactured_days_ago"])
    label_expiry = manufactured_at + timedelta(days=p["shelf_life_days"])
    label_days_remaining = max(0, (label_expiry - _NOW).days)

    # Build factors
    factors: List[LifeFactor] = []
    score = 100

    # Factor 1: Temperature excursions
    n_exc = len(p["excursion_minutes"])
    avg_delta = round(sum(p["excursion_delta"]) / n_exc, 1) if n_exc else 0
    exc_total_min = n_exc * 6  # each excursion ~6 minutes in demo data
    if n_exc == 0:
        exc_impact, exc_deduction = "NONE", 0
        exc_detail = "No temperature excursions recorded"
    elif n_exc <= 1:
        exc_impact, exc_deduction = "LOW", 3
        exc_detail = f"{n_exc} excursion, avg +{avg_delta} °C above limit for ~{exc_total_min} min total"
    elif n_exc <= 3:
        exc_impact, exc_deduction = "MEDIUM", 8
        exc_detail = f"{n_exc} excursions, avg +{avg_delta} °C above limit for ~{exc_total_min} min total"
    else:
        exc_impact, exc_deduction = "HIGH", 18
        exc_detail = f"{n_exc} excursions, avg +{avg_delta} °C above limit for ~{exc_total_min} min total"
    score -= exc_deduction
    factors.append(LifeFactor(name="Temperature Excursions", impact=exc_impact, detail=exc_detail, score_deduction=exc_deduction))

    # Factor 2: Storage duration consumed
    pct_consumed = round(p["manufactured_days_ago"] / p["shelf_life_days"] * 100, 1)
    if pct_consumed < 30:
        dur_impact, dur_deduction = "NONE", 0
        dur_detail = f"{pct_consumed}% of shelf life consumed – early stage"
    elif pct_consumed < 60:
        dur_impact, dur_deduction = "LOW", 4
        dur_detail = f"{pct_consumed}% of shelf life consumed"
    elif pct_consumed < 80:
        dur_impact, dur_deduction = "MEDIUM", 10
        dur_detail = f"{pct_consumed}% of shelf life consumed – approaching expiry"
    else:
        dur_impact, dur_deduction = "HIGH", 20
        dur_detail = f"{pct_consumed}% of shelf life consumed – critical stage"
    score -= dur_deduction
    factors.append(LifeFactor(name="Storage Duration", impact=dur_impact, detail=dur_detail, score_deduction=dur_deduction))

    # Factor 3: Humidity
    humid_target = p["humid_target"]
    if abs(humid_target - 55) < 10:
        hum_impact, hum_deduction = "NONE", 0
        hum_detail = "Humidity within optimal range throughout"
    else:
        hum_impact, hum_deduction = "LOW", 2
        hum_detail = f"Minor humidity variance observed (target {humid_target}%)"
    score -= hum_deduction
    factors.append(LifeFactor(name="Humidity Stability", impact=hum_impact, detail=hum_detail, score_deduction=hum_deduction))

    # Factor 4: Transport shocks (rapid changes during transit)
    transit_shocks = max(0, n_exc - 1)
    if transit_shocks == 0:
        sh_impact, sh_deduction = "NONE", 0
        sh_detail = "No rapid temperature changes during transit"
    elif transit_shocks <= 2:
        sh_impact, sh_deduction = "LOW", 2
        sh_detail = f"{transit_shocks} rapid temperature change(s) during transit"
    else:
        sh_impact, sh_deduction = "MEDIUM", 7
        sh_detail = f"{transit_shocks} temperature shocks detected during transit phase"
    score -= sh_deduction
    factors.append(LifeFactor(name="Transport Shocks", impact=sh_impact, detail=sh_detail, score_deduction=sh_deduction))

    final_score = max(0, min(100, score))
    days_lost = round((100 - final_score) * p["shelf_life_days"] / 100 * 0.15)
    estimated_expiry = label_expiry - timedelta(days=days_lost)
    adjusted_days = max(0, (estimated_expiry - _NOW).days)

    if final_score >= 90:
        status, rec = "EXCELLENT", "Product is in excellent condition. Standard cold chain protocols sufficient."
    elif final_score >= 75:
        status, rec = "GOOD", "Product is in good condition. Minor degradation detected – continue monitoring."
    elif final_score >= 55:
        status, rec = "FAIR", "Noticeable degradation. Use before adjusted expiry and increase monitoring frequency."
    elif final_score >= 35:
        status, rec = "POOR", "Significant degradation detected. Prioritise use and consult quality team before distribution."
    else:
        status, rec = "CRITICAL", "Product integrity likely compromised. Do not use without lab verification."

    confidence = round(0.95 - (n_exc * 0.02), 2)

    return LifeEstimateResponse(
        product_id=product_id.upper(),
        manufactured_at=manufactured_at,
        label_expiry=label_expiry,
        estimated_expiry=estimated_expiry,
        label_days_remaining=label_days_remaining,
        adjusted_days_remaining=adjusted_days,
        days_lost=days_lost,
        health_score=final_score,
        status=status,
        confidence=confidence,
        factors=factors,
        recommendation=rec,
    )


# ---------------------------------------------------------------------------
# Arduino raw ingestion (existing endpoints, kept for real hardware)
# ---------------------------------------------------------------------------

@app.post(
    "/readings",
    response_model=schemas.SensorReadingOut,
    status_code=201,
    tags=["Arduino Ingestion"],
    summary="Arduino posts a sensor reading",
)
def create_reading(reading: schemas.SensorReadingCreate, db: Session = Depends(get_db)):
    """
    **Arduino WiFi shield posts data here every N seconds.**

    ### Request body
    ```json
    {
      "device_id": "uno1",
      "temperature": 24.5,
      "humidity": 62.1
    }
    ```

    - `device_id` – any string identifying the physical board (e.g. `"uno1"`, `"sensor-ward-3"`)
    - `temperature` – °C (float)
    - `humidity` – % relative humidity (float, optional)
    """
    db_reading = models.SensorReading(**reading.model_dump())
    db.add(db_reading)
    db.commit()
    db.refresh(db_reading)
    return db_reading


@app.get(
    "/readings",
    response_model=List[schemas.SensorReadingOut],
    tags=["Arduino Ingestion"],
    summary="Fetch stored Arduino readings",
)
def get_readings(
    device_id: Optional[str] = Query(None, example="uno1", description="Filter by device ID"),
    limit: int = Query(100, le=1000, description="Max results to return"),
    db: Session = Depends(get_db),
):
    """Fetch real readings stored by the Arduino. Filter by `device_id` or get all."""
    query = db.query(models.SensorReading)
    if device_id:
        query = query.filter(models.SensorReading.device_id == device_id)
    return query.order_by(models.SensorReading.timestamp.desc()).limit(limit).all()


@app.get(
    "/readings/latest",
    response_model=schemas.SensorReadingOut,
    tags=["Arduino Ingestion"],
    summary="Latest Arduino reading for a device",
)
def get_latest(
    device_id: str = Query(..., example="uno1"),
    db: Session = Depends(get_db),
):
    """Returns the single most recent reading for the given `device_id`."""
    reading = (
        db.query(models.SensorReading)
        .filter(models.SensorReading.device_id == device_id)
        .order_by(models.SensorReading.timestamp.desc())
        .first()
    )
    if not reading:
        raise HTTPException(status_code=404, detail="No readings found for this device")
    return reading


@app.delete(
    "/readings/{reading_id}",
    status_code=204,
    tags=["Arduino Ingestion"],
    summary="Delete a reading by ID",
)
def delete_reading(reading_id: int, db: Session = Depends(get_db)):
    reading = db.query(models.SensorReading).filter(models.SensorReading.id == reading_id).first()
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    db.delete(reading)
    db.commit()
