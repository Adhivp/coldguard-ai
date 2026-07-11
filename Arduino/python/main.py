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
SECRET_HEX       = "replace_with_64_char_hex_from_provision_endpoint"

POLL_INTERVAL_SECONDS  = 1.0   # UI refresh rate
SEND_INTERVAL_SECONDS  = 60.0  # backend send rate (1 per minute)

# ── State ─────────────────────────────────────────────────────────────────────
_last_send_time = 0.0
_latest_reading = {}
_reading_lock   = threading.Lock()


# ── HMAC-SHA256 auth ──────────────────────────────────────────────────────────

def _build_signature(timestamp_utc: str, nonce: str, temp_c: float, humid_pct) -> str:
    """
    Matches backend auth.py _build_message():
      HMAC-SHA256(secret, "device_id:product_id:timestamp_utc:nonce:firmware_version:temperature_c:humidity_pct")
    humidity_pct is the string "null" when absent.
    """
    humid_str = "null" if humid_pct is None else f"{humid_pct:.2f}"
    message   = f"{DEVICE_ID}:{PRODUCT_ID}:{timestamp_utc}:{nonce}:{FIRMWARE_VERSION}:{temp_c:.2f}:{humid_str}"
    key       = bytes.fromhex(SECRET_HEX)
    return hmac.new(key, message.encode(), hashlib.sha256).hexdigest()


# ── Backend sender ────────────────────────────────────────────────────────────

def _send_to_backend(temp_c: float, humid_pct):
    timestamp_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")
    nonce         = secrets.token_hex(16)
    signature     = _build_signature(timestamp_utc, nonce, temp_c, humid_pct)

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
        headers={
            "Content-Type":   "application/json",
            "X-CG-Signature": signature,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read())
            status = result.get("status", "?")
            print(f"[backend] {status} | T={temp_c:.2f}°C H={humid_pct}%")
    except urllib.error.HTTPError as exc:
        print(f"[backend] HTTP {exc.code}: {exc.read().decode()}")
    except urllib.error.URLError as exc:
        print(f"[backend] Network error: {exc}")


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
    global _last_send_time
    while True:
        data = _call_mcu("get_temperature")
        if data is None:
            _send_ui("temperature_error", {"message": "Could not read sensor"})
            time.sleep(POLL_INTERVAL_SECONDS)
            continue

        temp_c    = data.get("temperature_c")
        humid_pct = data.get("humidity")

        # Update shared latest reading for on-demand requests
        with _reading_lock:
            _latest_reading.update(data)

        # Push to UI every second
        _send_ui("temperature_update", data)

        # Send to backend every 60 seconds on a separate thread
        now = time.monotonic()
        if now - _last_send_time >= SEND_INTERVAL_SECONDS:
            _last_send_time = now
            threading.Thread(
                target=_send_to_backend,
                args=(temp_c, humid_pct),
                daemon=True,
            ).start()

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
