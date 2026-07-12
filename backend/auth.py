"""
Device authentication – HMAC-SHA256 per-device secret model.

Every Arduino Uno Q is provisioned with:
  - A globally unique Device ID  (e.g. "CG-UNO-0001")
  - A 256-bit secret (32 bytes, stored as 64-char hex) that NEVER leaves the device

Each request must include an X-CG-Signature header computed as:

    HMAC-SHA256(secret, "{device_id}:{product_id}:{timestamp_utc}:{nonce}:{firmware_version}:{temperature_c}:{humidity_pct}")

All fields joined with ":" in that exact order.
humidity_pct is the string "null" when not present.
"""

import hashlib
import hmac
import os
import secrets
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, Header
from database import supabase

TIMESTAMP_TOLERANCE = int(os.getenv("TIMESTAMP_TOLERANCE_SECONDS", "300"))


def _get_device_secret(device_id: str) -> str:
    """Fetch the device's 256-bit secret from Supabase. Raises 401 if unknown."""
    result = (
        supabase.table("devices")
        .select("secret_hex, is_active")
        .eq("device_id", device_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=401, detail="Unknown device")
    if not result.data["is_active"]:
        raise HTTPException(status_code=403, detail="Device is deactivated")
    return result.data["secret_hex"]


def _check_and_consume_nonce(device_id: str, nonce: str) -> None:
    """Reject replayed nonces. Raises 401 if already seen."""
    existing = (
        supabase.table("request_log")
        .select("nonce")
        .eq("device_id", device_id)
        .eq("nonce", nonce)
        .execute()
    )
    if existing.data:
        raise HTTPException(status_code=401, detail="Replayed nonce – request rejected")
    supabase.table("request_log").insert({"device_id": device_id, "nonce": nonce}).execute()


def _verify_timestamp(timestamp_utc: str) -> datetime:
    """Parse and validate the device timestamp is within tolerance of server time."""
    try:
        ts = datetime.fromisoformat(timestamp_utc.replace("Z", "+00:00"))
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid timestamp format – use ISO 8601 UTC")

    now = datetime.now(timezone.utc)
    delta = abs((now - ts).total_seconds())
    if delta > TIMESTAMP_TOLERANCE:
        raise HTTPException(
            status_code=400,
            detail=f"Timestamp out of tolerance ({delta:.1f}s > {TIMESTAMP_TOLERANCE}s). Sync device clock."
        )
    return ts


def _build_message(
    device_id: str,
    product_id: str,
    timestamp_utc: str,
    nonce: str,
    firmware_version: str,
    temperature_c: float,
    humidity_pct: float | None,
) -> str:
    humidity_str = f"{humidity_pct:.2f}" if humidity_pct is not None else "null"
    return f"{device_id}:{product_id}:{timestamp_utc}:{nonce}:{firmware_version}:{temperature_c:.2f}:{humidity_str}"


def verify_request(
    device_id: str,
    product_id: str,
    timestamp_utc: str,
    nonce: str,
    firmware_version: str,
    temperature_c: float,
    humidity_pct: float | None,
    signature: str,
) -> datetime:
    """
    Full auth pipeline:
      1. Validate timestamp within tolerance
      2. Reject replayed nonce
      3. Fetch per-device secret from Supabase
      4. Verify HMAC-SHA256 signature
    Returns the parsed UTC timestamp on success.
    """
    ts = _verify_timestamp(timestamp_utc)
    _check_and_consume_nonce(device_id, nonce)

    secret_hex = _get_device_secret(device_id)
    secret_bytes = bytes.fromhex(secret_hex)
    message = _build_message(device_id, product_id, timestamp_utc, nonce, firmware_version, temperature_c, humidity_pct)
    expected = hmac.new(secret_bytes, message.encode(), hashlib.sha256).hexdigest()

    if not hmac.compare_digest(expected, signature.lower()):
        raise HTTPException(status_code=401, detail="Invalid signature")

    return ts


def provision_new_device(device_id: str, firmware_version: str | None = None) -> str:
    """
    Generate a new 256-bit secret for a device and register it in Supabase.
    Returns the secret as a 64-char hex string – store it on the device, never again.
    """
    existing = supabase.table("devices").select("device_id").eq("device_id", device_id).execute()
    if existing.data:
        raise HTTPException(status_code=409, detail=f"Device '{device_id}' already provisioned")

    secret_hex = secrets.token_hex(32)  # 32 bytes = 256 bits
    supabase.table("devices").insert({
        "device_id": device_id,
        "secret_hex": secret_hex,
        "firmware_version": firmware_version,
    }).execute()
    return secret_hex
