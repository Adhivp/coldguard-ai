-- ─────────────────────────────────────────────────────────────────────────────
-- ColdGuard – Supabase schema
-- Run this once in the Supabase SQL editor (Dashboard → SQL Editor → New query)
-- ─────────────────────────────────────────────────────────────────────────────

-- Registered Arduino devices
-- The `secret` column stores the 256-bit (64-char hex) HMAC key.
-- Row-Level Security: only the service-role key can read secrets.
CREATE TABLE IF NOT EXISTS devices (
    device_id       TEXT PRIMARY KEY,
    secret_hex      TEXT        NOT NULL,          -- 64-char hex, 256-bit HMAC secret
    firmware_version TEXT,
    provisioned_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Per-device, per-product telemetry readings
CREATE TABLE IF NOT EXISTS sensor_readings (
    id              BIGSERIAL   PRIMARY KEY,
    device_id       TEXT        NOT NULL REFERENCES devices(device_id),
    product_id      TEXT        NOT NULL,          -- one device → many products
    temperature_c   FLOAT       NOT NULL,
    humidity_pct    FLOAT,
    firmware_version TEXT       NOT NULL,
    nonce           TEXT        NOT NULL,
    reading_ts      TIMESTAMPTZ NOT NULL,          -- UTC timestamp from the device
    received_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    gap_seconds     FLOAT,                         -- gap from previous reading (NULL = first)
    continuity_ok   BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Used nonces – prevents replay attacks (TTL-cleaned by cron or Supabase function)
CREATE TABLE IF NOT EXISTS used_nonces (
    nonce           TEXT        NOT NULL,
    device_id       TEXT        NOT NULL,
    used_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (nonce, device_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_readings_device_product ON sensor_readings (device_id, product_id, reading_ts DESC);
CREATE INDEX IF NOT EXISTS idx_nonces_used_at ON used_nonces (used_at);

-- Auto-clean nonces older than 10 minutes (run as a Supabase scheduled function or pg_cron)
-- DELETE FROM used_nonces WHERE used_at < now() - interval '10 minutes';
