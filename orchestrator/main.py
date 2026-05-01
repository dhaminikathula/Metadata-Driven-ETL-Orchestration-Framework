"""
orchestrator/main.py
--------------------
Entry point for the orchestrator service.
Reads DATABASE_URL from the environment, waits for the DB to be ready,
then runs the orchestration cycle.

RUN_ONCE=true  → execute one cycle and exit  (good for CI / Docker healthcheck)
RUN_ONCE=false → loop forever with ORCHESTRATOR_INTERVAL seconds between runs
"""

from __future__ import annotations

import logging
import os
import time

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

from orchestrator import run_orchestration

# ── Logging setup ────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)-8s] %(name)s – %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("main")

# ── Load environment ─────────────────────────────────────────────────────────
load_dotenv()

DATABASE_URL:          str = os.environ["DATABASE_URL"]
ORCHESTRATOR_INTERVAL: int = int(os.environ.get("ORCHESTRATOR_INTERVAL", "60"))
RUN_ONCE:              bool = os.environ.get("RUN_ONCE", "false").lower() == "true"


# ── Wait-for-DB ──────────────────────────────────────────────────────────────
def wait_for_db(engine, retries: int = 30, delay: int = 3) -> None:
    """Block until PostgreSQL is reachable or retries are exhausted."""
    for attempt in range(1, retries + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("Database is reachable.")
            return
        except OperationalError as exc:
            logger.warning(
                "DB not ready (attempt %d/%d): %s – retrying in %ds …",
                attempt, retries, exc.__class__.__name__, delay,
            )
            time.sleep(delay)
    raise RuntimeError("Database did not become available within the allowed time.")


# ── Main ─────────────────────────────────────────────────────────────────────
def main() -> None:
    logger.info("Orchestrator starting …")
    logger.info("DATABASE_URL : %s", DATABASE_URL.replace(DATABASE_URL.split("@")[0].split("//")[1], "***:***"))
    logger.info("RUN_ONCE     : %s", RUN_ONCE)
    logger.info("INTERVAL     : %d s", ORCHESTRATOR_INTERVAL)

    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    wait_for_db(engine)

    if RUN_ONCE:
        run_orchestration(engine)
        logger.info("RUN_ONCE=true – orchestrator exiting.")
    else:
        while True:
            try:
                run_orchestration(engine)
            except Exception as exc:  # noqa: BLE001
                logger.error("Unhandled exception in orchestration cycle: %s", exc, exc_info=True)
            logger.info("Sleeping %d seconds before next cycle …", ORCHESTRATOR_INTERVAL)
            time.sleep(ORCHESTRATOR_INTERVAL)


if __name__ == "__main__":
    main()
