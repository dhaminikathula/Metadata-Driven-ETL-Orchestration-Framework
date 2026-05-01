"""
orchestrator/connectors.py
--------------------------
Source connectors for CSV, REST API, and PostgreSQL DB sources.
Each connector exposes a single `extract(options, watermark=None)` method
that returns a pandas DataFrame.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

import pandas as pd
import requests
from sqlalchemy import engine as sa_engine, text

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# CSV Connector
# ─────────────────────────────────────────────────────────────────────────────

class CSVConnector:
    """Reads a CSV file and returns its contents as a DataFrame."""

    def extract(
        self,
        options: Dict[str, Any],
        watermark: Optional[str] = None,
    ) -> pd.DataFrame:
        path: str = options.get("path", "")
        if not path:
            raise ValueError("CSVConnector: 'path' is required in source_options")

        logger.info("CSVConnector: reading file '%s'", path)
        df = pd.read_csv(path)
        logger.info("CSVConnector: extracted %d rows", len(df))
        return df


# ─────────────────────────────────────────────────────────────────────────────
# API Connector
# ─────────────────────────────────────────────────────────────────────────────

class APIConnector:
    """
    Fetches JSON records from a REST API endpoint.
    Supports incremental fetching via a configurable query parameter.
    """

    def extract(
        self,
        options: Dict[str, Any],
        watermark: Optional[str] = None,
    ) -> pd.DataFrame:
        url: str = options.get("url", "")
        if not url:
            raise ValueError("APIConnector: 'url' is required in source_options")

        since_param: str = options.get("since_param", "since")
        params: Dict[str, str] = {}

        if watermark:
            params[since_param] = watermark
            logger.info(
                "APIConnector: incremental fetch from '%s' with %s=%s",
                url, since_param, watermark,
            )
        else:
            logger.info("APIConnector: full fetch from '%s'", url)

        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()

        records = response.json()
        if not isinstance(records, list):
            raise ValueError(
                f"APIConnector: expected a JSON array, got {type(records).__name__}"
            )

        df = pd.DataFrame(records) if records else pd.DataFrame()
        logger.info("APIConnector: extracted %d rows", len(df))
        return df


# ─────────────────────────────────────────────────────────────────────────────
# DB Connector
# ─────────────────────────────────────────────────────────────────────────────

class DBConnector:
    """
    Reads a full table (or filtered rows) from PostgreSQL.
    Uses direct SQLAlchemy execute + DataFrame construction for
    maximum compatibility with SQLAlchemy 2.x + pandas 2.x.
    """

    def __init__(self, engine: sa_engine.Engine) -> None:
        self.engine = engine

    def extract(
        self,
        options: Dict[str, Any],
        watermark: Optional[str] = None,
    ) -> pd.DataFrame:
        table: str = options.get("table", "")
        if not table:
            raise ValueError("DBConnector: 'table' is required in source_options")

        incremental_key: Optional[str] = options.get("incremental_key")

        with self.engine.connect() as conn:
            if watermark and incremental_key:
                stmt = text(
                    f"SELECT * FROM {table} WHERE {incremental_key} > :wm"  # noqa: S608
                )
                logger.info(
                    "DBConnector: incremental read from '%s' where %s > %s",
                    table, incremental_key, watermark,
                )
                result = conn.execute(stmt, {"wm": watermark})
            else:
                stmt = text(f"SELECT * FROM {table}")  # noqa: S608
                logger.info("DBConnector: full read from '%s'", table)
                result = conn.execute(stmt)

            rows: List = result.fetchall()
            columns: List[str] = list(result.keys())

        df = pd.DataFrame(rows, columns=columns)
        logger.info("DBConnector: extracted %d rows", len(df))
        return df


# ─────────────────────────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────────────────────────

def get_connector(source_type: str, engine: sa_engine.Engine):
    """Return the appropriate connector instance for the given source_type."""
    if source_type == "csv":
        return CSVConnector()
    if source_type == "api":
        return APIConnector()
    if source_type == "db":
        return DBConnector(engine)
    raise ValueError(f"Unknown source_type: '{source_type}'")
