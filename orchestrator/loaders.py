"""
orchestrator/loaders.py
------------------------
Destination loaders that write a pandas DataFrame into a PostgreSQL table.

load_type = 'full'        → TRUNCATE then INSERT
load_type = 'incremental' → INSERT (append)
"""

from __future__ import annotations

import logging

import pandas as pd
from sqlalchemy import engine as sa_engine, text

logger = logging.getLogger(__name__)


def load(
    df: pd.DataFrame,
    destination_table: str,
    load_type: str,
    engine: sa_engine.Engine,
) -> int:
    """
    Write *df* to *destination_table* using the specified *load_type*.

    Returns
    -------
    int
        Number of rows written.
    """
    if df.empty:
        logger.warning("Loader: DataFrame is empty – nothing to write to '%s'", destination_table)
        return 0

    rows = len(df)

    with engine.begin() as conn:
        if load_type == "full":
            logger.info("Loader [full]: TRUNCATE '%s'", destination_table)
            conn.execute(text(f"TRUNCATE TABLE {destination_table}"))

        logger.info(
            "Loader [%s]: inserting %d rows into '%s'",
            load_type, rows, destination_table,
        )
        # Pass the SQLAlchemy connection directly (compatible with pandas 2.x + SQLAlchemy 2.x)
        df.to_sql(
            destination_table,
            con=conn,
            if_exists="append",   # table already exists; truncation handled above
            index=False,
            method="multi",       # batch inserts for performance
            chunksize=500,
        )

    logger.info("Loader: successfully wrote %d rows", rows)
    return rows
