from __future__ import annotations

import pandas as pd

from cybersentinel_auth_ml.config import (
    DATABASE_BATCH_SIZE,
    DEBUG_OUTPUT_PATH,
    EXPORT_DEBUG_CSV,
)
from cybersentinel_auth_ml.data_loader import load_data
from cybersentinel_auth_ml.database import create_postgres_engine
from cybersentinel_auth_ml.metadata import add_model_metadata
from cybersentinel_auth_ml.ml_model import train_anomaly_model
from cybersentinel_auth_ml.reporting import (
    export_results,
    print_summary,
    reorder_output_columns,
)
from cybersentinel_auth_ml.repository import (
    upsert_authentication_scores,
)
from cybersentinel_auth_ml.risk_engine import (
    enrich_security_results,
)


def validate_pipeline_output(df: pd.DataFrame) -> None:
    """
    Validate the final authentication anomaly results
    before writing them to PostgreSQL.
    """
    if df.empty:
        raise ValueError(
            "The authentication ML pipeline produced no results."
        )

    required_output_columns = [
        "authentication_window_id",
        "machine_id",
        "username",
        "event_date",
        "window_start",
        "window_end",
        "is_anomaly",
        "ml_anomaly_score",
        "detection_status",
        "model_name",
        "model_version",
        "model_run_id",
        "scored_at",
    ]

    missing_columns = [
        column
        for column in required_output_columns
        if column not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            "The authentication ML pipeline output is missing "
            f"required columns: {missing_columns}"
        )

    if df["authentication_window_id"].isna().any():
        raise ValueError(
            "The pipeline output contains null "
            "authentication_window_id values."
        )

    if df["authentication_window_id"].duplicated().any():
        raise ValueError(
            "The pipeline output contains duplicate "
            "authentication_window_id values."
        )

    invalid_predictions = ~df["is_anomaly"].isin([0, 1])

    if invalid_predictions.any():
        raise ValueError(
            "The pipeline output contains invalid "
            "is_anomaly values."
        )

    invalid_scores = (
        df["ml_anomaly_score"].isna()
        | df["ml_anomaly_score"].lt(0)
        | df["ml_anomaly_score"].gt(100)
    )

    if invalid_scores.any():
        raise ValueError(
            "The pipeline output contains invalid anomaly "
            "scores. Scores must be between 0 and 100."
        )


def persist_results(df: pd.DataFrame) -> int:
    """
    Persist authentication anomaly scores to PostgreSQL.
    """
    engine = create_postgres_engine()

    try:
        return upsert_authentication_scores(
            engine,
            df,
            batch_size=DATABASE_BATCH_SIZE,
        )
    finally:
        engine.dispose()


def run_pipeline() -> pd.DataFrame:
    """
    Execute the complete authentication anomaly detection pipeline.

    Steps:
        1. Load dbt authentication features from PostgreSQL.
        2. Train and run Isolation Forest.
        3. Add cybersecurity risk interpretation.
        4. Add traceable model metadata.
        5. Validate and persist results.
        6. Optionally export a debug CSV.
    """
    print(
        "Loading authentication ML features from PostgreSQL..."
    )
    features = load_data()

    print(
        f"Authentication feature rows loaded: {len(features)}"
    )

    print(
        "Training Isolation Forest and scoring authentication windows..."
    )
    scored_results = train_anomaly_model(
        features
    )

    print(
        "Applying cybersecurity risk enrichment..."
    )
    scored_results = enrich_security_results(
        scored_results
    )

    print(
        "Adding model execution metadata..."
    )
    scored_results = add_model_metadata(
        scored_results
    )

    scored_results = reorder_output_columns(
        scored_results
    )

    validate_pipeline_output(
        scored_results
    )

    print(
        "Writing authentication anomaly scores to PostgreSQL..."
    )
    affected_rows = persist_results(
        scored_results
    )

    if EXPORT_DEBUG_CSV:
        export_results(
            scored_results,
            DEBUG_OUTPUT_PATH,
        )

        print(
            "Debug CSV exported to: "
            f"{DEBUG_OUTPUT_PATH}"
        )

    print_summary(
        scored_results
    )

    print(
        "PostgreSQL rows inserted or updated: "
        f"{affected_rows}"
    )

    return scored_results