import os
import urllib.parse
import psycopg2


_TABLES_SQL = """
CREATE TABLE IF NOT EXISTS devices (
    device_id        TEXT PRIMARY KEY,
    secret_hex       TEXT        NOT NULL,
    firmware_version TEXT,
    provisioned_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at     TIMESTAMPTZ,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS products (
    product_id        TEXT PRIMARY KEY,
    rfid_tag          TEXT UNIQUE,
    name              TEXT,
    category          TEXT,
    manufacturer      TEXT,
    batch_number      TEXT,
    storage_req_min_c FLOAT,
    storage_req_max_c FLOAT,
    manufactured_at   TIMESTAMPTZ,
    expires_at        TIMESTAMPTZ,
    location          TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    id               BIGSERIAL   PRIMARY KEY,
    device_id        TEXT        NOT NULL REFERENCES devices(device_id),
    product_id       TEXT        NOT NULL,
    temperature_c    FLOAT       NOT NULL,
    humidity_pct     FLOAT,
    presence         BOOLEAN,
    firmware_version TEXT        NOT NULL,
    nonce            TEXT        NOT NULL,
    reading_ts       TIMESTAMPTZ NOT NULL,
    received_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    gap_seconds      FLOAT,
    continuity_ok    BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS request_log (
    nonce      TEXT        NOT NULL,
    device_id  TEXT        NOT NULL,
    used_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (nonce, device_id)
);

CREATE INDEX IF NOT EXISTS idx_readings_device_product
    ON sensor_readings (device_id, product_id, reading_ts DESC);

CREATE INDEX IF NOT EXISTS idx_products_rfid
    ON products (rfid_tag);

CREATE INDEX IF NOT EXISTS idx_nonces_used_at
    ON request_log (used_at);

CREATE INDEX IF NOT EXISTS idx_nonces_device_id
    ON request_log (device_id);

-- Add presence column to existing sensor_readings if upgrading
ALTER TABLE sensor_readings ADD COLUMN IF NOT EXISTS presence BOOLEAN;
"""


def create_tables():
    p = urllib.parse.urlparse(os.environ["DATABASE_URL"])
    try:
        conn = psycopg2.connect(
            host=p.hostname,
            port=p.port or 5432,
            dbname=p.path.lstrip("/"),
            user=p.username,
            password=urllib.parse.unquote(p.password),
            connect_timeout=10,
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute(_TABLES_SQL)
        cur.close()
        conn.close()
        print("[models] Tables ready")
    except Exception as exc:
        print(f"[models] WARNING: could not connect to DB at startup ({exc}). "
              f"Tables must already exist or run supabase_schema.sql manually.")
