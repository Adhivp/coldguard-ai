import hashlib
import hmac
import json
import os
import secrets
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI

_ui_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui")
ui = WebUI(assets_dir_path=_ui_dir)

# ── Config ────────────────────────────────────────────────────────────────────
BACKEND_URL      = "https://coldguard-ai.onrender.com/telemetry"
DEVICE_ID        = "CG-UNO-0001"
PRODUCT_ID       = "PROD-001"
FIRMWARE_VERSION = "1.0.0"
# 64-char hex secret from POST /admin/provision – never share or commit this
SECRET_HEX       = "16a4fc06c7bbacd3fb82f3ab972d2b9acd4ea1ee0e508d04ad43aae16fc37d14"

POLL_INTERVAL_SECONDS  = 1.0   # UI refresh rate + per-second buffer
BATCH_SIZE             = 60    # flush every 60 readings (1 minute)

# ── State ─────────────────────────────────────────────────────────────────────
_batch: list         = []
_batch_lock          = threading.Lock()
_latest_reading: dict = {}
_reading_lock        = threading.Lock()


# ── HMAC-SHA256 auth ──────────────────────────────────────────────────────────

def _build_signature(timestamp_utc: str, nonce: str, temp_c: float, humid_pct) -> str:
    humid_str = "null" if humid_pct is None else f"{humid_pct:.2f}"
    message   = f"{DEVICE_ID}:{PRODUCT_ID}:{timestamp_utc}:{nonce}:{FIRMWARE_VERSION}:{temp_c:.2f}:{humid_str}"
    key       = bytes.fromhex(SECRET_HEX)
    return hmac.new(key, message.encode(), hashlib.sha256).hexdigest()


# ── Backend sender – posts one reading from the batch ─────────────────────────

def _send_reading(temp_c: float, humid_pct, timestamp_utc: str):
    nonce     = secrets.token_hex(16)
    signature = _build_signature(timestamp_utc, nonce, temp_c, humid_pct)

    payload = {
        "device_id":        DEVICE_ID,
        "product_id":       PRODUCT_ID,
        "timestamp_utc":    timestamp_utc,
        "nonce":            nonce,
        "firmware_version": FIRMWARE_VERSION,
        "temperature_c":    round(temp_c, 2),
    }
    if humid_pct is not None:
        payload["humidity_pct"] = round(humid_pct, 2)

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
            print(f"[backend] {result.get('status','?')} | T={temp_c:.2f}°C ts={timestamp_utc}")
    except urllib.error.HTTPError as exc:
        print(f"[backend] HTTP {exc.code}: {exc.read().decode()}")
    except urllib.error.URLError as exc:
        print(f"[backend] Network error: {exc}")


def _flush_batch(batch: list):
    """Send all 60 buffered readings to the backend one by one on a background thread."""
    print(f"[batch] Flushing {len(batch)} readings to backend...")
    for entry in batch:
        _send_reading(entry["temperature_c"], entry["humidity_pct"], entry["timestamp_utc"])


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


# ── Poll loop (every 1 second) ────────────────────────────────────────────────

def _poll_loop():
    while True:
        data = _call_mcu("get_temperature")
        if data is None:
            _send_ui("temperature_error", {"message": "Could not read sensor"})
            time.sleep(POLL_INTERVAL_SECONDS)
            continue

        temp_c    = data.get("temperature_c")
        humid_pct = data.get("humidity")
        timestamp_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")

        # Update cache for on-demand UI requests
        with _reading_lock:
            _latest_reading.update(data)

        # Push live to browser UI every second
        _send_ui("temperature_update", data)

        # Buffer this second's reading
        batch_to_flush = None
        with _batch_lock:
            _batch.append({
                "temperature_c":  round(temp_c, 2),
                "humidity_pct":   round(humid_pct, 2) if humid_pct is not None else None,
                "timestamp_utc":  timestamp_utc,
            })
            if len(_batch) >= BATCH_SIZE:
                batch_to_flush = list(_batch)
                _batch.clear()

        # Once 60 readings collected, flush to backend on a separate thread
        if batch_to_flush:
            threading.Thread(target=_flush_batch, args=(batch_to_flush,), daemon=True).start()

        time.sleep(POLL_INTERVAL_SECONDS)


# ── On-demand UI request ──────────────────────────────────────────────────────

def on_request_temperature(client, data=None):
    """Browser asked for an immediate reading (e.g. on page load)."""
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

threading.Thread(target=_poll_loop, daemon=True).start()

App.run()
