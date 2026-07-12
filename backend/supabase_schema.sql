-- ─────────────────────────────────────────────────────────────────────────────
-- ColdGuard – Supabase schema
-- Run this once in the Supabase SQL editor (Dashboard → SQL Editor → New query)
-- ─────────────────────────────────────────────────────────────────────────────

-- Registered Arduino devices
CREATE TABLE IF NOT EXISTS devices (
    device_id        TEXT PRIMARY KEY,
    secret_hex       TEXT        NOT NULL,
    firmware_version TEXT,
    provisioned_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at     TIMESTAMPTZ,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Products – registered products with RFID tag
CREATE TABLE IF NOT EXISTS products (
    product_id             TEXT PRIMARY KEY,
    rfid_tag               TEXT UNIQUE,
    name                   TEXT,
    category               TEXT,
    manufacturer           TEXT,
    batch_number           TEXT,
    storage_req_min_c      FLOAT,
    storage_req_max_c      FLOAT,
    max_minutes_above_limit INT DEFAULT 30,  -- spoilage threshold in minutes outside safe range
    manufactured_at        TIMESTAMPTZ,
    expires_at             TIMESTAMPTZ,
    location               TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Per-device, per-product telemetry readings
CREATE TABLE IF NOT EXISTS sensor_readings (
    id                   BIGSERIAL   PRIMARY KEY,
    device_id            TEXT        NOT NULL REFERENCES devices(device_id),
    product_id           TEXT        NOT NULL,
    temperature_c        FLOAT       NOT NULL,
    humidity_pct         FLOAT,
    presence             BOOLEAN     DEFAULT TRUE,
    firmware_version     TEXT        NOT NULL,
    nonce                TEXT        NOT NULL,
    reading_ts           TIMESTAMPTZ NOT NULL,
    received_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    gap_seconds          FLOAT,
    continuity_ok        BOOLEAN     NOT NULL DEFAULT TRUE,
    minutes_above_limit  FLOAT,        -- cumulative minutes outside safe range at this reading
    anomaly_score        FLOAT,        -- 0.0–1.0 from ML anomaly detector
    breach_probability   FLOAT         -- 0.0–1.0 from ML breach predictor
);

-- Replay attack prevention
CREATE TABLE IF NOT EXISTS request_log (
    nonce     TEXT        NOT NULL,
    device_id TEXT        NOT NULL,
    used_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (nonce, device_id)
);

-- ML model version registry
CREATE TABLE IF NOT EXISTS model_versions (
    id          SERIAL PRIMARY KEY,
    version     TEXT        NOT NULL,
    trained_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    anomaly_url TEXT        NOT NULL,
    breach_url  TEXT        NOT NULL,
    rows_used   INT,
    notes       TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_readings_device_product  ON sensor_readings (device_id, product_id, reading_ts DESC);
CREATE INDEX IF NOT EXISTS idx_request_log_used_at      ON request_log (used_at);
CREATE INDEX IF NOT EXISTS idx_request_log_device_id    ON request_log (device_id);
CREATE INDEX IF NOT EXISTS idx_products_rfid            ON products (rfid_tag);

-- ── Upgrade commands (run if tables already exist) ───────────────────────────
ALTER TABLE products         ADD COLUMN IF NOT EXISTS max_minutes_above_limit INT DEFAULT 30;
ALTER TABLE sensor_readings  ADD COLUMN IF NOT EXISTS minutes_above_limit  FLOAT;
ALTER TABLE sensor_readings  ADD COLUMN IF NOT EXISTS anomaly_score         FLOAT;
ALTER TABLE sensor_readings  ADD COLUMN IF NOT EXISTS breach_probability    FLOAT;
ALTER TABLE sensor_readings  ALTER COLUMN presence SET DEFAULT TRUE;

-- Backfill NULLs for presence (treat old rows as present)
UPDATE sensor_readings SET presence = TRUE WHERE presence IS NULL;

-- Update product spoilage limits
UPDATE products SET max_minutes_above_limit = 30  WHERE product_id = 'PROD-001';  -- Hepatitis B Vaccine
UPDATE products SET max_minutes_above_limit = 10  WHERE product_id = 'PROD-002';  -- Blood Sample
UPDATE products SET max_minutes_above_limit = 2   WHERE product_id = 'PROD-003';  -- Frozen Salmon
UPDATE products SET max_minutes_above_limit = 20  WHERE product_id = 'PROD-004';  -- Insulin
UPDATE products SET max_minutes_above_limit = 5   WHERE product_id = 'PROD-005';  -- COVID mRNA Vaccine
