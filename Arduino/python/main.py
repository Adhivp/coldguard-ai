import hashlib
import hmac
import json
import os
import secrets
import threading
import time
import urllib.error
import urllib.request
from collections import deque
from datetime import datetime, timezone
from pathlib import Path

from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI

_ui_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui")
ui = WebUI(assets_dir_path=_ui_dir)

# ── Config ────────────────────────────────────────────────────────────────────
BACKEND_URL      = "https://coldguard-ai.onrender.com/telemetry"
MODEL_BASE_URL   = "https://coldguard-ai.onrender.com"
DEVICE_ID        = "CG-UNO-0001"
PRODUCT_ID       = "PROD-001"
FIRMWARE_VERSION = "1.0.0"
SECRET_HEX       = "16a4fc06c7bbacd3fb82f3ab972d2b9acd4ea1ee0e508d04ad43aae16fc37d14"

# Product safe range — kept in sync with products table
PRODUCT_TEMP_MIN          = 2.0    # storage_req_min_c for PROD-001
PRODUCT_TEMP_MAX          = 8.0    # storage_req_max_c for PROD-001
MAX_MINUTES_ABOVE_LIMIT   = 30.0   # max_minutes_above_limit for PROD-001

POLL_INTERVAL_SECONDS     = 1.0
BATCH_SIZE                = 60
MODEL_CHECK_INTERVAL_SEC  = 86400  # re-check model every 24 h
ANOMALY_THRESHOLD         = 0.80
BREACH_THRESHOLD          = 0.75

MODEL_DIR = Path.home() / ".coldguard" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)

# ── State ─────────────────────────────────────────────────────────────────────
_batch: list          = []
_batch_lock           = threading.Lock()
_latest_reading: dict = {}
_reading_lock         = threading.Lock()

# Rolling buffer for inference (last 60 readings)
_inference_buffer: deque = deque(maxlen=60)
_buffer_lock             = threading.Lock()

# Cumulative minutes above safe range
_minutes_above_limit: float = 0.0
_last_reading_ts: datetime | None = None

# TFLite interpreters (loaded after model download)
_anomaly_interpreter = None
_breach_interpreter  = None
_model_version: str  = ""
_model_lock          = threading.Lock()


# ── HMAC-SHA256 auth ──────────────────────────────────────────────────────────

def _build_signature(timestamp_utc: str, nonce: str, temp_c: float, humid_pct) -> str:
    humid_str = "null" if humid_pct is None else f"{humid_pct:.2f}"
    message   = f"{DEVICE_ID}:{PRODUCT_ID}:{timestamp_utc}:{nonce}:{FIRMWARE_VERSION}:{temp_c:.2f}:{humid_str}"
    key       = bytes.fromhex(SECRET_HEX)
    return hmac.new(key, message.encode(), hashlib.sha256).hexdigest()


# ── Model management ──────────────────────────────────────────────────────────

def _fetch_json(url: str) -> dict | None:
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return json.loads(r.read())
    except Exception as exc:
        print(f"[model] fetch error {url}: {exc}")
        return None


def _download_file(url: str, dest: Path) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            dest.write_bytes(r.read())
        return True
    except Exception as exc:
        print(f"[model] download error {url}: {exc}")
        return False


def _load_interpreter(path: Path):
    try:
        import tflite_runtime.interpreter as tflite
        interp = tflite.Interpreter(model_path=str(path))
        interp.allocate_tensors()
        return interp
    except ImportError:
        try:
            import tensorflow as tf
            interp = tf.lite.Interpreter(model_path=str(path))
            interp.allocate_tensors()
            return interp
        except Exception as exc:
            print(f"[model] Could not load interpreter: {exc}")
            return None


def _check_and_update_models() -> None:
    global _anomaly_interpreter, _breach_interpreter, _model_version
    meta = _fetch_json(f"{MODEL_BASE_URL}/model/version")
    if not meta:
        return
    new_version = meta.get("version", "")
    if new_version == _model_version:
        print(f"[model] Already on latest version: {_model_version}")
        return

    print(f"[model] New version available: {new_version}. Downloading...")
    anomaly_ok = _download_file(meta["anomaly_url"], MODEL_DIR / "anomaly.tflite")
    breach_ok  = _download_file(meta["breach_url"],  MODEL_DIR / "breach.tflite")

    if anomaly_ok and breach_ok:
        with _model_lock:
            _anomaly_interpreter = _load_interpreter(MODEL_DIR / "anomaly.tflite")
            _breach_interpreter  = _load_interpreter(MODEL_DIR / "breach.tflite")
            _model_version = new_version
        print(f"[model] Loaded version {_model_version}")
    else:
        print("[model] Download failed — keeping previous model")


def _model_watcher() -> None:
    # Also try loading cached models from disk immediately
    global _anomaly_interpreter, _breach_interpreter
    a_path = MODEL_DIR / "anomaly.tflite"
    b_path = MODEL_DIR / "breach.tflite"
    if a_path.exists() and b_path.exists():
        with _model_lock:
            _anomaly_interpreter = _load_interpreter(a_path)
            _breach_interpreter  = _load_interpreter(b_path)
        print("[model] Loaded cached models from disk")

    _check_and_update_models()
    while True:
        time.sleep(MODEL_CHECK_INTERVAL_SEC)
        _check_and_update_models()


# ── ML inference ──────────────────────────────────────────────────────────────

def _normalise(temp: float, humid: float, gap: float) -> list[float]:
    t_range = max(PRODUCT_TEMP_MAX - PRODUCT_TEMP_MIN, 1.0)
    return [
        (temp - PRODUCT_TEMP_MIN) / t_range,
        (humid or 55.0) / 100.0,
        min((gap or 60.0) / 120.0, 1.0),
    ]


def _run_inference(buffer: list[dict]) -> tuple[float, float]:
    """Returns (anomaly_score, breach_probability). Both 0.0 if models not loaded."""
    import numpy as np

    anomaly_score      = 0.0
    breach_probability = 0.0

    with _model_lock:
        a_interp = _anomaly_interpreter
        b_interp = _breach_interpreter

    if len(buffer) < 60 or a_interp is None:
        return anomaly_score, breach_probability

    try:
        features = [_normalise(r["temperature_c"], r.get("humidity_pct"), r.get("gap_seconds")) for r in buffer[-60:]]
        X_a = np.array([features], dtype=np.float32)
        inp = a_interp.get_input_details()[0]
        out = a_interp.get_output_details()[0]
        # INT8 quantisation: scale + zero_point
        scale, zp = inp["quantization"]
        if scale != 0:
            X_a = (X_a / scale + zp).astype(np.int8)
        a_interp.set_tensor(inp["index"], X_a)
        a_interp.invoke()
        raw = a_interp.get_tensor(out["index"])
        o_scale, o_zp = out["quantization"]
        anomaly_score = float((raw[0][0] - o_zp) * o_scale) if o_scale != 0 else float(raw[0][0])
    except Exception as exc:
        print(f"[inference] anomaly error: {exc}")

    if len(buffer) >= 10 and b_interp is not None:
        try:
            features10 = [_normalise(r["temperature_c"], r.get("humidity_pct"), r.get("gap_seconds")) for r in buffer[-10:]]
            X_b = np.array([features10], dtype=np.float32)
            inp = b_interp.get_input_details()[0]
            out = b_interp.get_output_details()[0]
            scale, zp = inp["quantization"]
            if scale != 0:
                X_b = (X_b / scale + zp).astype(np.int8)
            b_interp.set_tensor(inp["index"], X_b)
            b_interp.invoke()
            raw = b_interp.get_tensor(out["index"])
            o_scale, o_zp = out["quantization"]
            breach_probability = float((raw[0][0] - o_zp) * o_scale) if o_scale != 0 else float(raw[0][0])
        except Exception as exc:
            print(f"[inference] breach error: {exc}")

    return round(anomaly_score, 4), round(breach_probability, 4)


# ── Alarm control via Bridge ──────────────────────────────────────────────────

def _set_alarm(level: str) -> None:
    try:
        Bridge.call("set_alarm", level)
    except Exception as exc:
        print(f"[alarm] Bridge.call error: {exc}")


# ── Backend sender ────────────────────────────────────────────────────────────

def _send_reading(temp_c: float, humid_pct, timestamp_utc: str,
                  minutes_above: float, anomaly_score: float, breach_prob: float) -> None:
    nonce     = secrets.token_hex(16)
    signature = _build_signature(timestamp_utc, nonce, temp_c, humid_pct)

    payload = {
        "device_id":          DEVICE_ID,
        "product_id":         PRODUCT_ID,
        "timestamp_utc":      timestamp_utc,
        "nonce":              nonce,
        "firmware_version":   FIRMWARE_VERSION,
        "temperature_c":      round(temp_c, 2),
        "minutes_above_limit": round(minutes_above, 3),
    }
    if humid_pct is not None:
        payload["humidity_pct"] = round(humid_pct, 2)
    if anomaly_score > 0.0:
        payload["anomaly_score"] = anomaly_score
    if breach_prob > 0.0:
        payload["breach_probability"] = breach_prob

    body = json.dumps(payload).encode("utf-8")
    req  = urllib.request.Request(
        BACKEND_URL,
        data=body,
        headers={"Content-Type": "application/json", "X-CG-Signature": signature},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read())
            print(f"[backend] {result.get('status','?')} | T={temp_c:.2f}°C "
                  f"A={anomaly_score:.2f} B={breach_prob:.2f} ts={timestamp_utc}")
    except urllib.error.HTTPError as exc:
        print(f"[backend] HTTP {exc.code}: {exc.read().decode()}")
    except urllib.error.URLError as exc:
        print(f"[backend] Network error: {exc}")


def _flush_batch(batch: list) -> None:
    print(f"[batch] Flushing {len(batch)} readings to backend...")
    for entry in batch:
        _send_reading(
            entry["temperature_c"], entry["humidity_pct"], entry["timestamp_utc"],
            entry["minutes_above_limit"], entry["anomaly_score"], entry["breach_probability"],
        )


# ── Bridge helpers ────────────────────────────────────────────────────────────

def _call_mcu(method, *args):
    try:
        return json.loads(Bridge.call(method, *args))
    except Exception as exc:
        print(f"[bridge] {method} error: {exc}")
        return None


def _send_ui(event, data, client=None):
    if client:
        ui.send_message(event, data, client)
    else:
        ui.send_message(event, data)


# ── Poll loop ─────────────────────────────────────────────────────────────────

def _poll_loop() -> None:
    global _minutes_above_limit, _last_reading_ts

    while True:
        data = _call_mcu("get_temperature")
        if data is None:
            _send_ui("temperature_error", {"message": "Could not read sensor"})
            time.sleep(POLL_INTERVAL_SECONDS)
            continue

        temp_c       = data.get("temperature_c")
        humid_pct    = data.get("humidity")
        rfid_present = data.get("rfid_present", True)
        timestamp_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")
        now_ts = datetime.now(timezone.utc)

        # ── Cumulative minutes above safe range ───────────────────────────────
        if _last_reading_ts is not None:
            elapsed_min = (now_ts - _last_reading_ts).total_seconds() / 60
            if temp_c < PRODUCT_TEMP_MIN or temp_c > PRODUCT_TEMP_MAX:
                _minutes_above_limit += elapsed_min
            else:
                _minutes_above_limit = max(0.0, _minutes_above_limit - 0.05)
        _last_reading_ts = now_ts

        # ── Update inference buffer ───────────────────────────────────────────
        gap = (_last_reading_ts - _last_reading_ts).total_seconds() if _last_reading_ts else 60.0
        with _buffer_lock:
            _inference_buffer.append({
                "temperature_c": temp_c,
                "humidity_pct": humid_pct,
                "gap_seconds": POLL_INTERVAL_SECONDS,
            })
            buf_snapshot = list(_inference_buffer)

        # ── Run ML inference ──────────────────────────────────────────────────
        anomaly_score, breach_prob = _run_inference(buf_snapshot)

        # ── Drive buzzer via Bridge based on ML scores ────────────────────────
        if anomaly_score > ANOMALY_THRESHOLD:
            _set_alarm("anomaly")
        elif breach_prob > BREACH_THRESHOLD:
            _set_alarm("warning")
        else:
            _set_alarm("off")

        # ── Update UI cache + broadcast ───────────────────────────────────────
        ui_data = {
            **data,
            "anomaly_score": anomaly_score,
            "breach_probability": breach_prob,
            "minutes_above_limit": round(_minutes_above_limit, 2),
        }
        with _reading_lock:
            _latest_reading.update(ui_data)
        _send_ui("temperature_update", ui_data)

        print(f"[poll] T={temp_c:.2f}°C H={humid_pct:.1f}% "
              f"RFID={'YES' if rfid_present else 'NO'} "
              f"A={anomaly_score:.2f} B={breach_prob:.2f} "
              f"min_above={_minutes_above_limit:.1f}")

        # ── Buffer for batch send ─────────────────────────────────────────────
        batch_to_flush = None
        with _batch_lock:
            _batch.append({
                "temperature_c":      round(temp_c, 2),
                "humidity_pct":       round(humid_pct, 2) if humid_pct is not None else None,
                "timestamp_utc":      timestamp_utc,
                "minutes_above_limit": round(_minutes_above_limit, 3),
                "anomaly_score":      anomaly_score,
                "breach_probability": breach_prob,
            })
            if len(_batch) >= BATCH_SIZE:
                batch_to_flush = list(_batch)
                _batch.clear()

        if batch_to_flush:
            threading.Thread(target=_flush_batch, args=(batch_to_flush,), daemon=True).start()

        time.sleep(POLL_INTERVAL_SECONDS)


# ── On-demand UI request ──────────────────────────────────────────────────────

def on_request_temperature(client, data=None):
    with _reading_lock:
        cached = dict(_latest_reading)
    if cached:
        _send_ui("temperature_update", cached, client)
    else:
        fresh = _call_mcu("get_temperature")
        if fresh:
            _send_ui("temperature_update", fresh, client)
        else:
            _send_ui("temperature_error", {"message": "Could not read sensor"}, client)


ui.on_message("request_temperature", on_request_temperature)

threading.Thread(target=_model_watcher, daemon=True).start()
threading.Thread(target=_poll_loop, daemon=True).start()

App.run()
