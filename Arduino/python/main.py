import json
import os
import threading
import time
import urllib.error
import urllib.request

from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI

_ui_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui")
ui = WebUI(assets_dir_path=_ui_dir)

POLL_INTERVAL_SECONDS = 1.0

# ── 1-minute batching ───────────────────────────────────────
BATCH_SIZE = 60  # 60 readings @ 1/sec = 1 minute
SAMPLE_ENDPOINT_URL = "https://example.com/api/sample"  # TODO: replace with your real endpoint

_batch_buffer = []
_batch_lock = threading.Lock()


def _call_mcu(method, *args):
    try:
        return json.loads(Bridge.call(method, *args))
    except Exception as exc:
        print(f"[bridge] {method} error: {exc}")
        return None


def _send(event, data, client=None):
    """Push a WebSocket event to one client, or broadcast to all if client is None."""
    if client:
        ui.send_message(event, data, client)
    else:
        ui.send_message(event, data)


def _send_batch_to_backend(batch):
    """POST one minute's worth of readings to the sample endpoint."""
    payload = json.dumps({"readings": batch}).encode("utf-8")
    req = urllib.request.Request(
        SAMPLE_ENDPOINT_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"[backend] Sent {len(batch)} readings, status={resp.status}")
    except urllib.error.URLError as exc:
        print(f"[backend] Failed to send batch of {len(batch)} readings: {exc}")


def _buffer_reading(data):
    """Add one second's reading to the buffer; flush + clear once 60 are collected."""
    reading = {
        "temperature_c": data.get("temperature_c"),
        "humidity": data.get("humidity"),
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime()),
    }

    batch_to_send = None
    with _batch_lock:
        _batch_buffer.append(reading)
        if len(_batch_buffer) >= BATCH_SIZE:
            batch_to_send = list(_batch_buffer)
            _batch_buffer.clear()  # remove the data once it's queued to send

    if batch_to_send:
        # Send on a separate thread so a slow/stuck network call never
        # delays the next second's temperature reading or UI update.
        threading.Thread(target=_send_batch_to_backend, args=(batch_to_send,), daemon=True).start()


def _read_and_broadcast(client=None, buffer=False):
    """Fetch a reading from the sketch and push it to the browser(s).

    buffer=True is used only by the automatic 1-second poll loop, so it adds
    the reading to the 1-minute batch. On-demand requests from the browser
    (buffer=False) are not buffered, so they can't skew the 60-per-minute cadence.
    """
    data = _call_mcu("get_temperature")
    if data is None:
        _send("temperature_error", {"message": "Could not read sensor"}, client)
        return
    _send("temperature_update", data, client)

    if buffer:
        _buffer_reading(data)


def _poll_loop():
    """Background thread: keeps every connected client updated automatically."""
    while True:
        _read_and_broadcast(buffer=True)
        time.sleep(POLL_INTERVAL_SECONDS)


def on_request_temperature(client, data=None):
    """Lets the browser ask for an immediate reading (e.g. on page load)."""
    _read_and_broadcast(client)


ui.on_message("request_temperature", on_request_temperature)

threading.Thread(target=_poll_loop, daemon=True).start()

App.run()