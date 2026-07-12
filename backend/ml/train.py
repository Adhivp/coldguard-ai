"""
ColdGuard ML Training Script (sklearn — no TensorFlow required)
================================================================
Trains Anomaly Detector and Breach Predictor using scikit-learn,
serialises both with joblib, and registers the version in Supabase.

Usage:
    python ml/train.py
    python ml/train.py --days 60
"""

import argparse
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import joblib
import numpy as np
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, str(Path(__file__).parent.parent))
from database import supabase  # noqa: E402

ANOMALY_WINDOW = 60   # seconds of history for anomaly model
BREACH_WINDOW  = 10   # seconds of history for breach model
BREACH_HORIZON = 60   # predict breach within next N seconds

MODEL_DIR = Path(__file__).parent.parent / "models"
MODEL_DIR.mkdir(exist_ok=True)


def _load_data(days: int):
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    # Paginate through all rows — Supabase default limit is 1000 per request
    readings = []
    page_size = 1000
    offset = 0
    while True:
        batch = (
            supabase.table("sensor_readings")
            .select("product_id, temperature_c, humidity_pct, gap_seconds, reading_ts, minutes_above_limit")
            .gte("reading_ts", since)
            .order("reading_ts")
            .range(offset, offset + page_size - 1)
            .execute().data
        )
        readings.extend(batch)
        print(f"[train] Fetched {len(readings)} rows...", end="\r")
        if len(batch) < page_size:
            break
        offset += page_size
    print()

    products = (
        supabase.table("products")
        .select("product_id, storage_req_min_c, storage_req_max_c, max_minutes_above_limit")
        .execute().data
    )
    return readings, {p["product_id"]: p for p in products}


def _features(row: dict, p: dict) -> list:
    t_min  = p.get("storage_req_min_c") or 0.0
    t_max  = p.get("storage_req_max_c") or 40.0
    t_range = max(t_max - t_min, 1.0)
    return [
        (row["temperature_c"] - t_min) / t_range,
        (row.get("humidity_pct") or 55.0) / 100.0,
        min((row.get("gap_seconds") or 60.0) / 120.0, 1.0),
        (row.get("minutes_above_limit") or 0.0) / max(p.get("max_minutes_above_limit") or 30, 1),
    ]


def _build_anomaly_data(rows, pmap):
    X, y = [], []
    for i in range(ANOMALY_WINDOW, len(rows)):
        window = rows[i - ANOMALY_WINDOW: i]
        p = pmap.get(window[0]["product_id"])
        if not p or len({r["product_id"] for r in window}) > 1:
            continue
        # Flatten window features: 60 readings × 4 features = 240 floats
        flat = [v for r in window for v in _features(r, p)]
        X.append(flat)
        t_min = p.get("storage_req_min_c") or 0.0
        t_max = p.get("storage_req_max_c") or 40.0
        max_min = p.get("max_minutes_above_limit") or 30
        last = rows[i]
        outside = last["temperature_c"] < t_min or last["temperature_c"] > t_max
        over_limit = (last.get("minutes_above_limit") or 0) >= max_min
        y.append(1 if (outside and over_limit) else 0)
    return np.array(X), np.array(y)


def _build_breach_data(rows, pmap):
    X, y = [], []
    for i in range(BREACH_WINDOW, len(rows) - BREACH_HORIZON):
        window = rows[i - BREACH_WINDOW: i]
        future = rows[i: i + BREACH_HORIZON]
        p = pmap.get(window[0]["product_id"])
        if not p or len({r["product_id"] for r in window + future}) > 1:
            continue
        flat = [v for r in window for v in _features(r, p)]
        X.append(flat)
        t_min = p.get("storage_req_min_c") or 0.0
        t_max = p.get("storage_req_max_c") or 40.0
        max_min = p.get("max_minutes_above_limit") or 30
        will_breach = any(
            (r["temperature_c"] < t_min or r["temperature_c"] > t_max)
            and (r.get("minutes_above_limit") or 0) >= max_min
            for r in future
        )
        y.append(1 if will_breach else 0)
    return np.array(X), np.array(y)


def run(days: int = 30, version: str | None = None) -> None:
    print(f"[train] Loading {days} days of data...")
    rows, pmap = _load_data(days)

    if len(rows) < ANOMALY_WINDOW + 10:
        print(f"[train] Not enough data ({len(rows)} rows). Run fake_data.py first.")
        sys.exit(1)

    print(f"[train] {len(rows)} readings. Building windows...")
    X_a, y_a = _build_anomaly_data(rows, pmap)
    X_b, y_b = _build_breach_data(rows, pmap)
    print(f"[train] Anomaly: {len(X_a)} samples (pos={y_a.sum():.0f})")
    print(f"[train] Breach:  {len(X_b)} samples (pos={y_b.sum():.0f})")

    # ── Anomaly detector ──────────────────────────────────────────────────
    print("[train] Training anomaly detector...")
    anomaly_pipe = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", MLPClassifier(hidden_layer_sizes=(64, 32), max_iter=200,
                              random_state=42, early_stopping=True, verbose=False)),
    ])
    anomaly_pipe.fit(X_a, y_a)
    print(classification_report(y_a, anomaly_pipe.predict(X_a), target_names=["normal", "anomaly"]))

    # ── Breach predictor ──────────────────────────────────────────────────
    print("[train] Training breach predictor...")
    breach_pipe = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=200,
                              random_state=42, early_stopping=True, verbose=False)),
    ])
    breach_pipe.fit(X_b, y_b)
    print(classification_report(y_b, breach_pipe.predict(X_b), target_names=["safe", "breach"]))

    # ── Save ──────────────────────────────────────────────────────────────
    joblib.dump(anomaly_pipe, MODEL_DIR / "anomaly.joblib")
    joblib.dump(breach_pipe,  MODEL_DIR / "breach.joblib")
    a_kb = (MODEL_DIR / "anomaly.joblib").stat().st_size / 1024
    b_kb = (MODEL_DIR / "breach.joblib").stat().st_size / 1024
    print(f"[train] Saved anomaly.joblib ({a_kb:.1f} KB), breach.joblib ({b_kb:.1f} KB)")

    # ── Compute metrics ───────────────────────────────────────────────────
    from sklearn.metrics import accuracy_score, f1_score, recall_score

    a_preds  = anomaly_pipe.predict(X_a)
    b_preds  = breach_pipe.predict(X_b)
    a_acc    = accuracy_score(y_a, a_preds)
    a_f1     = f1_score(y_a, a_preds, zero_division=0)
    b_acc    = accuracy_score(y_b, b_preds)
    b_f1     = f1_score(y_b, b_preds, zero_division=0)
    b_recall = recall_score(y_b, b_preds, zero_division=0)

    # ── Write training history to file ────────────────────────────────────
    ver = version or datetime.now(timezone.utc).strftime("v%Y%m%d")
    history_path = MODEL_DIR / "training_history.txt"
    with open(history_path, "a") as f:
        f.write(f"\n{'='*60}\n")
        f.write(f"Version      : {ver}\n")
        f.write(f"Trained at   : {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}\n")
        f.write(f"Training days: {days}\n")
        f.write(f"Rows used    : {len(rows)}\n")
        f.write(f"\n-- Anomaly Detector --\n")
        f.write(f"  Accuracy   : {a_acc:.4f}\n")
        f.write(f"  F1 Score   : {a_f1:.4f}\n")
        f.write(f"  Samples    : {len(X_a)}  (anomalies: {int(y_a.sum())})\n")
        f.write(f"  Model size : {a_kb:.1f} KB\n")
        f.write(f"\n-- Breach Predictor --\n")
        f.write(f"  Accuracy   : {b_acc:.4f}\n")
        f.write(f"  F1 Score   : {b_f1:.4f}\n")
        f.write(f"  Recall     : {b_recall:.4f}\n")
        f.write(f"  Samples    : {len(X_b)}  (breaches: {int(y_b.sum())})\n")
        f.write(f"  Model size : {b_kb:.1f} KB\n")
        f.write(f"{'='*60}\n")
    print(f"[train] Training history saved → {history_path}")

    # ── Register version in Supabase ──────────────────────────────────────
    base = "http://localhost:8000"
    supabase.table("model_versions").insert({
        "version": ver,
        "anomaly_url": f"{base}/model/anomaly.joblib",
        "breach_url":  f"{base}/model/breach.joblib",
        "rows_used": len(rows),
        "notes": f"anomaly_acc={a_acc:.3f} breach_acc={b_acc:.3f} breach_recall={b_recall:.3f}",
    }).execute()
    print(f"[train] Done. Version: {ver}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--days",    type=int, default=30)
    parser.add_argument("--version", type=str, default=None)
    args = parser.parse_args()
    run(days=args.days, version=args.version)
