-- =============================================================================
-- 01_schema.sql  –  DDL for all control + destination tables
-- Executed automatically by postgres docker-entrypoint-initdb.d
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CONTROL TABLE  –  one row per pipeline definition
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS etl_control (
    pipeline_id       SERIAL PRIMARY KEY,
    pipeline_name     VARCHAR(255) NOT NULL UNIQUE,
    source_type       VARCHAR(50)  NOT NULL CHECK (source_type IN ('csv','api','db')),
    source_options    JSONB        NOT NULL DEFAULT '{}',
    destination_table VARCHAR(255) NOT NULL,
    load_type         VARCHAR(50)  NOT NULL CHECK (load_type IN ('full','incremental')),
    incremental_key   VARCHAR(255),
    dependencies      TEXT[]       DEFAULT '{}',
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------------
-- AUDIT LOG  –  one row per pipeline execution attempt
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS etl_audit_log (
    run_id          SERIAL PRIMARY KEY,
    pipeline_name   VARCHAR(255) NOT NULL,
    start_time      TIMESTAMPTZ  NOT NULL,
    end_time        TIMESTAMPTZ,
    duration_ms     INTEGER,
    status          VARCHAR(20)  NOT NULL DEFAULT 'RUNNING',
    rows_read       INTEGER,
    rows_written    INTEGER,
    error_message   TEXT
);

-- ---------------------------------------------------------------------------
-- WATERMARKS  –  remembers the last high-water-mark for incremental loads
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS etl_watermarks (
    pipeline_name   VARCHAR(255) PRIMARY KEY,
    watermark_value VARCHAR(255) NOT NULL
);

-- ---------------------------------------------------------------------------
-- SOURCE TABLES  –  sample data tables used by db-type pipelines
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS source_products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(255) NOT NULL,
    category      VARCHAR(100),
    price         NUMERIC(10,2),
    stock         INTEGER,
    last_modified TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- DESTINATION TABLES  –  pre-created so loaders can truncate / insert freely
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dest_csv_customers (
    id            INTEGER,
    name          VARCHAR(255),
    email         VARCHAR(255),
    city          VARCHAR(100),
    signup_date   DATE,
    total_orders  INTEGER,
    total_spent   NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS dest_products (
    product_id    INTEGER,
    product_name  VARCHAR(255),
    category      VARCHAR(100),
    price         NUMERIC(10,2),
    stock         INTEGER,
    last_modified TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS dest_api_events (
    event_id      INTEGER,
    event_type    VARCHAR(100),
    user_id       INTEGER,
    amount        NUMERIC(10,2),
    region        VARCHAR(100),
    last_modified TIMESTAMPTZ
);

-- Table deliberately left missing dest columns so "pipeline-fail" will error
-- (the pipeline points to a non-existent CSV path)
