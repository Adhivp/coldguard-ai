from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


# ── Arduino → Backend ────────────────────────────────────────────────────────

class TelemetryPayload(BaseModel):
    """
    Sent by the Arduino Uno Q every 60 seconds per product being monitored.

    ### HMAC-SHA256 signature

    The Arduino computes the signature as:

        HMAC-SHA256(device_secret,
            "{device_id}:{product_id}:{timestamp_utc}:{nonce}:{firmware_version}:{temperature_c}:{humidity_pct}")

    - `humidity_pct` is the literal string `"null"` when not present.
    - `timestamp_utc` must be ISO 8601 with UTC offset, e.g. `2026-07-11T10:30:00+00:00`
    - `nonce` must be unique per request (recommended: UUID4 or 16-byte hex)
    - The secret is **never** included in the request

    The signature is passed in the `X-CG-Signature` HTTP header.

    ### presence
    Optional boolean sent once per minute. `true` = product detected by RFID/IR sensor,
    `false` = product absent. Omit if the device has no presence sensor.
    """
    device_id: str = Field(..., example="CG-UNO-0001", description="Globally unique device ID")
    product_id: str = Field(..., example="PROD-001", description="Product being monitored (one device → many products)")
    timestamp_utc: str = Field(..., example="2026-07-11T10:30:00+00:00", description="ISO 8601 UTC timestamp from device RTC")
    nonce: str = Field(..., example="a3f8c1d2e4b56789", description="Unique per-request random value (replay protection)")
    firmware_version: str = Field(..., example="1.2.0", description="Firmware version running on the device")
    temperature_c: float = Field(..., example=4.3, description="Temperature in Celsius")
    humidity_pct: Optional[float] = Field(None, example=58.2, description="Relative humidity %, omit if sensor absent")
    presence: Optional[bool] = Field(None, example=True, description="Product presence (true=present, false=absent). Sent once per minute, omit if no presence sensor.")


# ── Backend → Arduino/App ─────────────────────────────────────────────────────

class TelemetryAccepted(BaseModel):
    status: str = Field("accepted", example="accepted")
    reading_id: int
    device_id: str
    product_id: str
    reading_ts: datetime
    gap_seconds: Optional[float]
    continuity_ok: bool


class TelemetryCooloff(BaseModel):
    status: str = Field("cooloff", example="cooloff")
    message: str
    cooloff_remaining_seconds: float
    last_reading: "ReadingOut"


class ReadingOut(BaseModel):
    id: int
    device_id: str
    product_id: str
    temperature_c: float
    humidity_pct: Optional[float]
    presence: Optional[bool]
    firmware_version: str
    reading_ts: datetime
    received_at: datetime
    gap_seconds: Optional[float]
    continuity_ok: bool

    class Config:
        from_attributes = True


TelemetryCooloff.model_rebuild()


# ── Device provisioning ───────────────────────────────────────────────────────

class ProvisionRequest(BaseModel):
    device_id: str = Field(..., example="CG-UNO-0001")
    firmware_version: Optional[str] = Field(None, example="1.2.0")


class ProvisionResponse(BaseModel):
    device_id: str
    secret_hex: str = Field(..., description="256-bit HMAC secret – store on device, never transmit again")
    message: str = Field("Provision this secret onto the device immediately. It will not be shown again.")
