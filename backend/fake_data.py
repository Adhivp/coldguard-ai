"""
ColdGuard – Fake Data Generator
=================================
Seeds sensor_readings with realistic synthetic data for each product in the
products table. Run this before training ML models.

Usage:
    python fake_data.py
    python fake_data.py --days 30 --device-id CG-UNO-0001
    python fake_data.py --product-id PROD-001 --days 7
"""

import argparse
import math
import random
import sys
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv

load_dotenv()

from database import supabase  # noqa: E402

BATCH_SIZE = 1000
INTERVAL_SECONDS = 60  # one reading per minute


def _generate_readings(
    product: dict,
    device_id: str,
    days: int,
    rng: random.Random,
) -> list[dict]:
    pid = product["product_id"]
    t_min = product.get("storage_req_min_c") or 2.0
    t_max = product.get("storage_req_max_c") or 8.0
    t_target = (t_min + t_max) / 2
    t_range = t_max - t_min
    max_minutes = product.get("max_minutes_above_limit") or 30

    total_minutes = days * 24 * 60
    start_ts = datetime.now(timezone.utc) - timedelta(minutes=total_minutes)

    # Inject excursion events: random spikes + slow drifts
    excursions = []
    n_excursions = rng.randint(2, max(3, days // 5))
    for _ in range(n_excursions):
        exc_minute = rng.randint(30, total_minutes - 30)
        exc_delta = rng.uniform(t_range * 0.5, t_range * 2.5)
        exc_duration = rng.randint(2, max_minutes + 10)
        exc_type = rng.choice(["spike", "drift"])
        excursions.append((exc_minute, exc_delta, exc_duration, exc_type))

    rows = []
    firmware = "1.0.0"
    minutes_above = 0.0
    prev_ts = None

    for i in range(total_minutes):
        ts = start_ts + timedelta(minutes=i)

        # Base temperature: sinusoidal + noise
        drift = (t_range * 0.3) * math.sin(2 * math.pi * i / (24 * 60))
        noise = rng.gauss(0, t_range * 0.05)
        temp = t_target + drift + noise

        # Apply excursion events
        for exc_min, exc_delta, exc_dur, exc_type in excursions:
            dist = i - exc_min
            if 0 <= dist < exc_dur:
                if exc_type == "spike":
                    peak = math.exp(-0.5 * ((dist - exc_dur / 2) / (exc_dur / 4)) ** 2)
                    temp += exc_delta * peak
                else:  # drift
                    temp += exc_delta * (dist / exc_dur)

        temp = round(temp, 2)

        # Humidity: similar sinusoidal pattern
        h_base = 55.0
        h_drift = 8.0 * math.sin(2 * math.pi * i / (12 * 60) + 1.2)
        h_noise = rng.gauss(0, 2.0)
        humidity = round(max(20.0, min(95.0, h_base + h_drift + h_noise)), 2)

        # Presence: True 95% of the time
        presence = rng.random() > 0.05

        # Gap and continuity
        gap_seconds = (ts - prev_ts).total_seconds() if prev_ts else None
        continuity_ok = True if gap_seconds is None else gap_seconds <= 70
        prev_ts = ts

        # Cumulative minutes above limit
        if temp < t_min or temp > t_max:
            minutes_above += INTERVAL_SECONDS / 60
        else:
            minutes_above = max(0.0, minutes_above - 0.1)  # slow recovery

        # Unique nonce per reading
        nonce = f"fake-{pid}-{i:07d}"

        rows.append({
            "device_id": device_id,
            "product_id": pid,
            "temperature_c": temp,
            "humidity_pct": humidity,
            "presence": presence,
            "firmware_version": firmware,
            "nonce": nonce,
            "reading_ts": ts.isoformat(),
            "gap_seconds": round(gap_seconds, 2) if gap_seconds else None,
            "continuity_ok": continuity_ok,
            "minutes_above_limit": round(minutes_above, 3),
            "anomaly_score": None,
            "breach_probability": None,
        })

    return rows


def _insert_rows(rows: list[dict]) -> None:
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i: i + BATCH_SIZE]
        supabase.table("sensor_readings").insert(batch).execute()
        print(f"  inserted rows {i + 1}–{min(i + BATCH_SIZE, len(rows))}")


def run(days: int = 30, device_id: str = "CG-UNO-0001", product_id: str | None = None) -> None:
    print(f"[fake_data] Fetching products from Supabase...")
    result = supabase.table("products").select("*").execute()
    products = result.data

    if not products:
        print("[fake_data] ERROR: No products found. Insert products first via supabase_schema.sql.")
        sys.exit(1)

    if product_id:
        products = [p for p in products if p["product_id"] == product_id]
        if not products:
            print(f"[fake_data] ERROR: Product '{product_id}' not found.")
            sys.exit(1)

    for product in products:
        pid = product["product_id"]
        rng = random.Random(sum(ord(c) for c in pid) * 1337)
        print(f"[fake_data] Generating {days} days × {24*60} readings for {pid}...")
        rows = _generate_readings(product, device_id, days, rng)
        print(f"[fake_data] Inserting {len(rows)} rows for {pid}...")
        _insert_rows(rows)
        print(f"[fake_data] Done: {pid}")

    print(f"[fake_data] Complete. Total rows: {len(products) * days * 24 * 60}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ColdGuard fake data generator")
    parser.add_argument("--days", type=int, default=30, help="Days of history to generate (default 30)")
    parser.add_argument("--device-id", type=str, default="CG-UNO-0001", help="Device ID to assign readings to")
    parser.add_argument("--product-id", type=str, default=None, help="Only generate for this product (default: all)")
    args = parser.parse_args()
    run(days=args.days, device_id=args.device_id, product_id=args.product_id)
