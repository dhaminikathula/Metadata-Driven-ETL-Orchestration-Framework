<div align="center">

# 🔄 Metadata-Driven ETL Orchestration Framework

<img src="https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/PostgreSQL-15-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
<img src="https://img.shields.io/badge/FastAPI-0.110-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
<img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
<img src="https://img.shields.io/badge/Pandas-2.x-150458?style=for-the-badge&logo=pandas&logoColor=white"/>
<img src="https://img.shields.io/badge/NetworkX-DAG-orange?style=for-the-badge"/>

<br/>
<br/>

> **A production-inspired, fully containerised metadata-driven ETL orchestration engine** built with Python, PostgreSQL, FastAPI, Docker Compose, and Pandas — modelled after Azure Data Factory patterns.

<br/>

[🚀 Quick Start](#-quick-start) · [🏗️ Architecture](#️-architecture) · [📋 Pipelines](#-pipeline-definitions) · [🔍 Features](#-key-features) · [⚙️ Configuration](#️-environment-variables) · [🧪 Testing](#-testing-scenarios)

</div>

---

## 📖 Overview

Traditional ETL systems hardcode pipeline logic — making them brittle, hard to scale, and painful to maintain. This project solves that with a **metadata-driven approach**: pipeline definitions live in a database control table, not in code.

The orchestrator reads from this table at runtime, dynamically builds a dependency graph, detects circular dependencies, topologically sorts the execution order, and runs each pipeline — logging every result to an audit table.

**Adding a new pipeline = one SQL `INSERT`. Zero code changes.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Docker Compose Network                         │
│                                                                         │
│  ┌──────────────────┐    ┌─────────────────┐    ┌───────────────────┐  │
│  │    PostgreSQL     │    │   Mock REST API  │    │   Orchestrator    │  │
│  │      (db)         │◄───│   (FastAPI)      │◄───│   (Python)        │  │
│  │                   │    │   :8080/data     │    │                   │  │
│  │  ┌─────────────┐  │    └─────────────────┘    │  ① Fetch meta     │  │
│  │  │ etl_control │  │◄──────────────────────────│  ② Build DAG      │  │
│  │  │ etl_audit   │  │                            │  ③ Cycle detect   │  │
│  │  │ etl_watermarks│ │                            │  ④ Topo sort      │  │
│  │  │ source_*    │  │                            │  ⑤ ETL Execute    │  │
│  │  │ dest_*      │  │                            │  ⑥ Audit log      │  │
│  │  └─────────────┘  │                            └───────────────────┘  │
│  └──────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Service Startup Order

```
db (PostgreSQL)  ──health✓──►  mock-api (FastAPI)  ──health✓──►  orchestrator (Python)
     seeds SQL                    /health endpoint                  run_orchestration()
```

---

## 📁 Project Structure

```
Metadata-Driven-ETL-Orchestration-Framework/
│
├── 📄 docker-compose.yml          # Multi-service orchestration (db + mock-api + orchestrator)
├── 📄 .env                        # Runtime config (credentials, intervals)
├── 📄 .env.example                # Template — copy to .env to get started
├── 📄 .gitignore
├── 📄 run_etl.ps1                 # One-click PowerShell demo script
│
├── 📂 seeds/                      # Auto-executed by PostgreSQL on first start
│   ├── 📄 01_schema.sql           # DDL: etl_control, etl_audit_log, etl_watermarks,
│   │                              #      source_products, dest_* tables
│   └── 📄 02_seed_data.sql        # Seed: 10 source products + 6 pipeline definitions
│
├── 📂 data/
│   └── 📄 source_data.csv         # 10 rows of customer data (CSV source)
│
├── 📂 mock_api/                   # FastAPI mock REST API service
│   ├── 📄 Dockerfile
│   ├── 📄 requirements.txt
│   └── 📄 app.py                  # GET /data · GET /data?since=<ISO> · GET /data/add-new
│
└── 📂 orchestrator/               # Core ETL orchestration engine
    ├── 📄 Dockerfile
    ├── 📄 requirements.txt
    ├── 📄 main.py                 # Entry point · wait-for-DB loop · interval scheduling
    ├── 📄 orchestrator.py         # DAG building · cycle detection · topo sort · execution
    ├── 📄 connectors.py           # CSV / API / DB source connectors
    └── 📄 loaders.py              # Full (truncate+insert) · Incremental (append) loaders
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Docker Desktop | Latest | Must be running |
| Docker Compose | v2+ | Included with Docker Desktop |
| PowerShell | v5+ | For the helper script |

### 1️⃣ Clone the repository

```bash
git clone https://github.com/dhaminikathula/Metadata-Driven-ETL-Orchestration-Framework.git
cd Metadata-Driven-ETL-Orchestration-Framework
```

### 2️⃣ Configure environment

```bash
# .env is already committed with defaults — no changes needed for local demo
# To customise, copy the example:
copy .env.example .env
```

### 3️⃣ Start all services

```powershell
docker compose up --build --detach
```

This starts three containers in dependency order:
- **`etl_db`** — PostgreSQL starts, seeds schema + data automatically
- **`etl_mock_api`** — FastAPI starts, exposes `http://localhost:8080/data`
- **`etl_orchestrator`** — waits for both health checks, then runs ETL cycles

### 4️⃣ Watch it run

```powershell
docker compose logs orchestrator --follow
```

### 5️⃣ Verify results

```powershell
# Connect to the database
docker exec -it etl_db psql -U etl_user -d etl_db

-- Pipeline audit log
SELECT pipeline_name, status, rows_read, rows_written, duration_ms
FROM etl_audit_log ORDER BY run_id;

-- Watermarks (set after incremental runs)
SELECT * FROM etl_watermarks;

-- Destination table counts
SELECT 'dest_csv_customers' tbl, COUNT(*) FROM dest_csv_customers
UNION ALL SELECT 'dest_products',  COUNT(*) FROM dest_products
UNION ALL SELECT 'dest_api_events', COUNT(*) FROM dest_api_events;
```

### 6️⃣ One-click demo (optional)

```powershell
.\run_etl.ps1
```

Automates: down → build → up → wait → logs → DB verification.

---

## 📋 Pipeline Definitions

All pipelines are defined as rows in the `etl_control` table:

| Pipeline | Source Type | Source | Destination | Load Type | Dependencies | Purpose |
|----------|------------|--------|-------------|-----------|--------------|---------|
| `pipeline-A` | CSV | `source_data.csv` | `dest_csv_customers` | Full | — | Loads customer CSV → destination |
| `pipeline-B` | DB | `source_products` | `dest_products` | Full | pipeline-A | Loads product table after A completes |
| `pipeline-api` | API | `GET /data` | `dest_api_events` | Incremental | pipeline-A | Fetches only new events using watermark |
| `pipeline-fail` | CSV | `nonexistent_file.csv` | `dest_csv_customers` | Full | — | Tests FAILED audit logging |
| `cycle-A` | CSV | `source_data.csv` | `dest_csv_customers` | Full | cycle-B | Tests cycle detection |
| `cycle-B` | CSV | `source_data.csv` | `dest_csv_customers` | Full | cycle-A | Tests cycle detection (mutual) |

> **Note:** `pipeline-fail`, `cycle-A`, and `cycle-B` are intentional test fixtures. They demonstrate error handling and cycle detection capabilities.

---

## 🔍 Key Features

### 1. Metadata-Driven Pipeline Definitions

Pipelines are defined as **data**, not as code. The `etl_control` table holds every pipeline's source, destination, load type, dependencies, and active flag. Adding a new pipeline requires zero code changes — just one `INSERT` statement.

```sql
INSERT INTO etl_control (pipeline_name, source_type, source_options, destination_table, load_type, dependencies, is_active)
VALUES ('pipeline-new', 'csv', '{"path": "/data/new_file.csv"}', 'dest_new', 'full', '{}', TRUE);
```

---

### 2. DAG-Based Dependency Management

The orchestrator builds a **Directed Acyclic Graph** (DAG) using [NetworkX](https://networkx.org/). Each pipeline is a node; each dependency is a directed edge. Execution order is determined via **topological sort**, guaranteeing upstream pipelines always finish before downstream ones.

```
pipeline-A  ──────────────►  pipeline-B
     │
     └──────────────────────►  pipeline-api
```

---

### 3. Cycle Detection with Graceful Degradation

`cycle-A` and `cycle-B` form a circular dependency. The orchestrator uses `networkx.find_cycle()` to detect this, removes the offending nodes from the graph, and logs:

```
ERROR: Cycle detected in dependency graph! Involved nodes: ['cycle-A', 'cycle-B']
WARNING: Excluded 2 pipeline(s) due to circular dependencies. All remaining pipelines will still execute.
```

✅ **All valid pipelines continue to run** — the system degrades gracefully, not catastrophically.

---

### 4. Three Source Connectors

| Connector | Class | Incremental Support |
|-----------|-------|---------------------|
| CSV | `CSVConnector` | ❌ (always full read) |
| REST API | `APIConnector` | ✅ via `?since=<watermark>` |
| PostgreSQL | `DBConnector` | ✅ via `WHERE key > watermark` |

All connectors return a `pandas.DataFrame`, making the Transform and Load steps source-agnostic.

---

### 5. Full Load vs Incremental Load

**Full Load** (`load_type=full`):
```
TRUNCATE dest_table → INSERT all rows
```
Idempotent — running it N times always results in exactly the source row count.

**Incremental Load** (`load_type=incremental`):
```
Read watermark → Fetch only new rows → APPEND to dest_table → Update watermark
```
Efficient — avoids re-processing data that has already been loaded.

---

### 6. Watermark Management

After each successful incremental run, the maximum value of `incremental_key` is stored in `etl_watermarks`. On the next run:

```
GET /data?since=2024-01-15T10:00:00+00:00  →  only newer records returned
```

```sql
SELECT * FROM etl_watermarks;
-- pipeline-api | 2024-01-15T10:00:00+00:00
```

---

### 7. Comprehensive Audit Logging

Every pipeline execution — successful or failed — writes a row to `etl_audit_log`:

| Column | Description |
|--------|-------------|
| `run_id` | Auto-incremented execution ID |
| `pipeline_name` | Which pipeline ran |
| `start_time` | UTC timestamp of start |
| `end_time` | UTC timestamp of completion |
| `duration_ms` | Wall-clock duration in milliseconds |
| `status` | `RUNNING` → `SUCCESS` or `FAILED` |
| `rows_read` | Rows extracted from source |
| `rows_written` | Rows written to destination |
| `error_message` | Full traceback on failure |

---

### 8. Health-Check Driven Startup

Docker Compose `depends_on` with `condition: service_healthy` ensures:
- Orchestrator only starts **after** PostgreSQL passes `pg_isready`
- Orchestrator only starts **after** mock-api passes `GET /health`

No race conditions. No manual sleep hacks.

---

## 🧪 Testing Scenarios

### Full Load Idempotency

```powershell
docker compose up --build --detach     # Run 1 → 10 rows in dest_csv_customers
docker compose restart orchestrator    # Run 2 → still exactly 10 rows (TRUNCATE on full)
```

```sql
SELECT COUNT(*) FROM dest_csv_customers;  -- always 10
```

### Incremental Load — New Data Detection

```powershell
# After first run (15 API events loaded, watermark = 2024-01-15):
curl http://localhost:8080/data/add-new    # Adds 3 records with current timestamp

docker compose restart orchestrator
# Next cycle: pipeline-api fetches only the 3 new records
```

```sql
SELECT COUNT(*) FROM dest_api_events;  -- now 18 (15 + 3 new)
```

### Cycle Detection Verification

```sql
-- Check that cycle-A and cycle-B never appear in the audit log
SELECT pipeline_name, status FROM etl_audit_log
WHERE pipeline_name IN ('cycle-A', 'cycle-B');
-- (0 rows) — correctly excluded
```

### Error Handling — FAILED Pipeline Doesn't Stop Others

```sql
SELECT pipeline_name, status FROM etl_audit_log ORDER BY run_id;
-- pipeline-A    | SUCCESS
-- pipeline-fail | FAILED   ← file not found, but others still ran
-- pipeline-B    | SUCCESS
-- pipeline-api  | SUCCESS
```

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `etl_user` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `etl_password` | PostgreSQL password |
| `POSTGRES_DB` | `etl_db` | Database name |
| `DATABASE_URL` | `postgresql://etl_user:etl_password@db:5432/etl_db` | SQLAlchemy connection string |
| `MOCK_API_URL` | `http://mock-api:8080` | Base URL of the mock REST API |
| `ORCHESTRATOR_INTERVAL` | `60` | Seconds between orchestration cycles |
| `RUN_ONCE` | `false` | Set `true` to run one cycle and exit (useful for CI) |

---

## 🌐 API Endpoints

The mock API runs at `http://localhost:8080`:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Docker health check — returns `{"status": "ok"}` |
| `GET` | `/data` | Returns all 15 event records |
| `GET` | `/data?since=<ISO>` | Returns only records with `last_modified > since` |
| `GET` | `/data/add-new` | Appends 3 new records (for incremental testing) |

```powershell
# Full fetch
curl http://localhost:8080/data

# Incremental fetch
curl "http://localhost:8080/data?since=2024-01-10T00:00:00+00:00"

# Add new records to test incremental load
curl http://localhost:8080/data/add-new
```

---

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Container Orchestration | Docker Compose v2 | Multi-service lifecycle management |
| Control & Destination DB | PostgreSQL 15 Alpine | Metadata store + data warehouse |
| Mock REST API | FastAPI + Uvicorn | Simulates a real-world API data source |
| Orchestration Engine | Python 3.11 | Core ETL pipeline runner |
| DAG & Graph Logic | NetworkX | Dependency graph, cycle detection, topo sort |
| Data Processing | Pandas 2.x | DataFrame extraction, transformation, loading |
| DB Connectivity | SQLAlchemy 2.x + psycopg2 | Database ORM and connection pooling |
| HTTP Client | Requests | REST API data source connector |
| Environment Config | python-dotenv | 12-factor app config via `.env` |

---

## 📊 Expected Output

After a clean first run, the audit log shows:

```
 pipeline_name | status  | rows_read | rows_written | duration_ms
---------------+---------+-----------+--------------+-------------
 pipeline-A    | SUCCESS |        10 |           10 |          45
 pipeline-fail | FAILED  |         0 |            0 |          12
 pipeline-B    | SUCCESS |        10 |           10 |          67
 pipeline-api  | SUCCESS |        15 |           15 |          89
```

Destination table counts:

```
       tbl         | count
-------------------+-------
 dest_csv_customers |    10
 dest_products      |    10
 dest_api_events    |    15
```

---

## 🔧 Useful Commands

```powershell
# Start everything (clean)
docker compose down -v && docker compose up --build --detach

# Stream orchestrator logs
docker compose logs orchestrator --follow

# Check container status
docker compose ps

# Connect to PostgreSQL
docker exec -it etl_db psql -U etl_user -d etl_db

# Restart only the orchestrator (trigger new cycle)
docker compose restart orchestrator

# Add new API records (incremental test)
curl http://localhost:8080/data/add-new

# Stop and remove all containers + volumes
docker compose down -v
```

---

## 🤝 Contributing

Contributions are welcome! To add a new source connector:

1. Create a new class in `orchestrator/connectors.py` with an `extract(options, watermark)` method
2. Register it in the `get_connector()` factory function
3. Add `CHECK (source_type IN (...))` to the schema
4. Insert a test pipeline into `etl_control`

---

## 📄 License

This project is for educational and portfolio purposes.

---

<div align="center">

**Built with ❤️ using Python · PostgreSQL · FastAPI · Docker**

⭐ Star this repo if you found it useful!

</div>
