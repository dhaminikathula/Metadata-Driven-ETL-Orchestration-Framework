"""
mock_api/app.py
---------------
FastAPI service that simulates a real-world REST API data source.
Supports full fetch and incremental fetch via ?since=<ISO timestamp>.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse

app = FastAPI(title="Mock ETL Data API", version="1.0.0")

# ---------------------------------------------------------------------------
# Static in-memory dataset  (15 records with staggered last_modified times)
# ---------------------------------------------------------------------------
BASE_DT = datetime(2024, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

EVENTS: List[dict] = [
    {
        "event_id": i,
        "event_type": etype,
        "user_id": 1000 + i,
        "amount": round(10.0 + i * 7.5, 2),
        "region": region,
        "last_modified": (
            datetime(2024, 1, i, 10, 0, 0, tzinfo=timezone.utc).isoformat()
        ),
    }
    for i, (etype, region) in enumerate(
        [
            ("purchase",   "US-East"),
            ("refund",     "US-West"),
            ("purchase",   "EU-Central"),
            ("view",       "APAC"),
            ("purchase",   "US-East"),
            ("signup",     "LATAM"),
            ("purchase",   "US-West"),
            ("refund",     "EU-Central"),
            ("view",       "APAC"),
            ("purchase",   "US-East"),
            ("signup",     "US-West"),
            ("purchase",   "EU-Central"),
            ("view",       "US-East"),
            ("purchase",   "APAC"),
            ("refund",     "LATAM"),
        ],
        start=1,
    )
]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health")
def health() -> dict:
    """Health-check endpoint used by Docker Compose."""
    return {"status": "ok"}


@app.get("/data")
def get_data(
    since: Optional[str] = Query(
        default=None,
        description="ISO-8601 timestamp. Only records with last_modified > since are returned.",
    )
) -> JSONResponse:
    """
    Return event records.
    - GET /data          → all 15 records
    - GET /data?since=X  → only records newer than X (incremental support)
    """
    records = EVENTS

    if since:
        try:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            records = [
                r for r in records
                if datetime.fromisoformat(r["last_modified"]) > since_dt
            ]
        except ValueError:
            return JSONResponse(
                status_code=400,
                content={"error": f"Invalid 'since' timestamp format: {since}"},
            )

    return JSONResponse(content=records)


@app.get("/data/add-new")
def add_new_records() -> dict:
    """
    Helper endpoint: appends 3 new records with current timestamps.
    Used to simulate 'new data arrived' in integration tests.
    """
    global EVENTS
    next_id = max(r["event_id"] for r in EVENTS) + 1
    now_iso = datetime.now(tz=timezone.utc).isoformat()
    new_records = [
        {
            "event_id":    next_id + j,
            "event_type":  "purchase",
            "user_id":     9000 + j,
            "amount":      round(999.99 + j, 2),
            "region":      "NEW-REGION",
            "last_modified": now_iso,
        }
        for j in range(3)
    ]
    EVENTS.extend(new_records)
    return {"added": 3, "total": len(EVENTS)}


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("MOCK_API_PORT", 8080))
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=False)
