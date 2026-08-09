from __future__ import annotations
from collections.abc import Sequence
import pandas as pd
from sqlalchemy import MetaData, Table, delete, text
from sqlalchemy.engine import Engine
from sqlalchemy.dialects.postgresql import insert
from cybersentinel_auth_ml.config import (
    DELETE_STALE_RESULTS,
    FEATURE_SCHEMA,
    FEATURE_TABLE,
    RESULT_SCHEMA,
    RESULT_TABLE,
)

# --> PostgreSQL result table column definitions
RESULT_COLUMNS: Sequence[str] = (
    "authentication_window_id",
    "machine_id",
    "hostname",
    "hostname_public",
    "username",
    "event_date",
    "hour",
    "window_start",
    "window_end",
    "is_anomaly",
    "detection_status",
    "ml_anomaly_score",
    "security_risk_score",
    "risk_level",
    "requires_investigation",
    "reason",
    "recommended_action",
    "model_name",
    "model_version",
    "model_run_id",
    "scored_at",
)

UPSERT_UPDATE_COLUMNS: Sequence[str] = tuple(
    column
    for column in RESULT_COLUMNS
    if column != "authentication_window_id"
)

INTEGER_COLUMNS: Sequence[str] = (
    "authentication_window_id",
    "hour",
    "is_anomaly",
    "requires_investigation",
)

FLOAT_COLUMNS: Sequence[str] = (
    "ml_anomaly_score",
    "security_risk_score",
)

DATETIME_COLUMNS: Sequence[str] = (
    "window_start",
    "window_end",
    "scored_at",
)

# --> Define preferred output columns for reporting
def _qualified_name(schema: str, table: str) -> str:
    
    safe_schema = schema.replace('"', '""')
    safe_table = table.replace('"', '""')
    return f'"{safe_schema}"."{safe_table}"'

# --> Define preferred output columns for reporting
def read_authentication_features(
    engine: Engine,
) -> pd.DataFrame:
    # --> Read the authentication features from the PostgreSQL database and return as a pandas DataFrame
    query = text(
        f"""
        SELECT *
        FROM {_qualified_name(FEATURE_SCHEMA, FEATURE_TABLE)}
        ORDER BY
            event_date,
            hour,
            machine_id,
            username,
            authentication_window_id
        """
    )

    return pd.read_sql_query(
        query,
        engine,
    )

# --> Define preferred output columns for reporting
def _validate_result_columns(
    df: pd.DataFrame,
) -> None:
    # --> Validate that the DataFrame contains all required result columns before performing a PostgreSQL upsert
    missing_columns = sorted(
        set(RESULT_COLUMNS).difference(df.columns)
    )
    if missing_columns:
        raise ValueError(
            "Missing result columns before PostgreSQL upsert: "
            f"{missing_columns}"
        )

# --> Define preferred output columns for reporting
def _normalize_records(
    df: pd.DataFrame,
) -> list[dict]:
    """
    Convert pandas values into SQLAlchemy-ready Python records.
    """
    _validate_result_columns(df)

    output = df.loc[:, RESULT_COLUMNS].copy()

    output["authentication_window_id"] = pd.to_numeric(
        output["authentication_window_id"],
        errors="raise",
    ).astype("int64")

    output["event_date"] = pd.to_datetime(
        output["event_date"],
        errors="raise",
    ).dt.date

    for column in DATETIME_COLUMNS:
        output[column] = pd.to_datetime(
            output[column],
            errors="raise",
            utc=True,
        )

    for column in INTEGER_COLUMNS:
        output[column] = pd.to_numeric(
            output[column],
            errors="raise",
        ).astype("int64")

    for column in FLOAT_COLUMNS:
        output[column] = pd.to_numeric(
            output[column],
            errors="raise",
        ).astype("float64")


    if output["authentication_window_id"].duplicated().any():
        duplicated_ids = (
            output.loc[
                output["authentication_window_id"].duplicated(
                    keep=False
                ),
                "authentication_window_id",
            ]
            .drop_duplicates()
            .tolist()
        )

        raise ValueError(
            "Duplicate authentication_window_id values detected "
            f"before PostgreSQL upsert: {duplicated_ids[:10]}"
        )

    if output["authentication_window_id"].isna().any():
        raise ValueError(
            "Null authentication_window_id values detected "
            "before PostgreSQL upsert."
        )

    output = output.astype(object).where(
        pd.notna(output),
        None,
    )

    return output.to_dict(
        orient="records",
    )


def _delete_stale_scores(
    connection,
    target_table: Table,
    current_window_ids: list[int],
) -> int:
    """
    Delete scores whose authentication windows no longer exist
    in the current dbt feature dataset.

    This behaviour is disabled unless
    AUTH_ML_DELETE_STALE_RESULTS=true.
    """
    if not current_window_ids:
        return 0

    statement = delete(target_table).where(
        target_table.c.authentication_window_id.not_in(
            current_window_ids
        )
    )

    result = connection.execute(statement)

    return result.rowcount or 0


def upsert_authentication_scores(
    engine: Engine,
    results: pd.DataFrame,
    *,
    batch_size: int = 1000,
) -> int:
    """
    Insert new anomaly scores and update existing authentication windows.
    """
    if results.empty:
        return 0

    if batch_size <= 0:
        raise ValueError(
            "PostgreSQL batch_size must be greater than zero."
        )

    records = _normalize_records(
        results
    )

    metadata = MetaData()

    target_table = Table(
        RESULT_TABLE,
        metadata,
        schema=RESULT_SCHEMA,
        autoload_with=engine,
    )

    required_database_columns = set(
        RESULT_COLUMNS
    ).union(
        {
            "authentication_window_id",
        }
    )

    missing_database_columns = sorted(
        required_database_columns.difference(
            target_table.columns.keys()
        )
    )

    if missing_database_columns:
        raise ValueError(
            "The PostgreSQL result table is missing columns: "
            f"{missing_database_columns}"
        )

    affected_rows = 0
    deleted_rows = 0

    current_window_ids = [
        int(record["authentication_window_id"])
        for record in records
    ]

    with engine.begin() as connection:
        if DELETE_STALE_RESULTS:
            deleted_rows = _delete_stale_scores(
                connection=connection,
                target_table=target_table,
                current_window_ids=current_window_ids,
            )

        for start_index in range(
            0,
            len(records),
            batch_size,
        ):
            batch = records[
                start_index : start_index + batch_size
            ]

            insert_statement = insert(
                target_table
            ).values(
                batch
            )

            upsert_statement = (
                insert_statement.on_conflict_do_update(
                    index_elements=[
                        "authentication_window_id"
                    ],
                    set_={
                        column: getattr(
                            insert_statement.excluded,
                            column,
                        )
                        for column in UPSERT_UPDATE_COLUMNS
                    }
                    | {
                        "updated_at": text("NOW()")
                    },
                )
            )

            execution_result = connection.execute(
                upsert_statement
            )

            affected_rows += (
                execution_result.rowcount or 0
            )

    if DELETE_STALE_RESULTS:
        print(
            "Stale authentication anomaly scores deleted: "
            f"{deleted_rows}"
        )

    return affected_rows