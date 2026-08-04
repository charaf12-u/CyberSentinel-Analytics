from __future__ import annotations

from pathlib import Path

import pandas as pd


PREFERRED_COLUMNS = [
    "authentication_window_id",
    "machine_id",
    "hostname_public",
    "hostname",
    "username",
    "event_date",
    "hour",
    "window_start",
    "window_end",
    "failed_login_count",
    "successful_login_count",
    "authentication_event_count",
    "total_events",
    "unique_source_ips",
    "has_source_ip",
    "is_night_login",
    "failed_login_ratio",
    "events_per_minute",
    "window_minutes",
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
]


RISK_LEVEL_ORDER = [
    "Critical",
    "High",
    "Medium",
    "Low",
]


DETECTION_STATUS_ORDER = [
    "Anomaly",
    "Normal",
]


def reorder_output_columns(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Reorder authentication ML output columns for reporting and debugging.

    Preferred columns are placed first. Any additional columns are
    preserved and appended at the end.
    """
    if df.empty:
        return df.copy()

    existing_preferred_columns = [
        column
        for column in PREFERRED_COLUMNS
        if column in df.columns
    ]

    remaining_columns = [
        column
        for column in df.columns
        if column not in existing_preferred_columns
    ]

    return df.loc[
        :,
        existing_preferred_columns + remaining_columns,
    ].copy()


def export_results(
    df: pd.DataFrame,
    output_path: str | Path,
) -> None:
    """
    Export authentication ML results to a UTF-8 CSV file.
    """
    if df.empty:
        raise ValueError(
            "Cannot export an empty authentication ML result dataset."
        )

    path = Path(output_path).expanduser().resolve()

    if path.suffix.lower() != ".csv":
        raise ValueError(
            "The authentication ML debug output path "
            "must use the .csv extension."
        )

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    ordered_results = reorder_output_columns(
        df
    )

    ordered_results.to_csv(
        path,
        index=False,
        encoding="utf-8-sig",
        date_format="%Y-%m-%dT%H:%M:%S%z",
    )


def _safe_count(
    results: pd.DataFrame,
    column: str,
) -> int:
    """
    Safely count positive or true values from a result column.
    """
    if column not in results.columns:
        return 0

    values = results[column]

    if pd.api.types.is_bool_dtype(values.dtype):
        return int(
            values.fillna(False).sum()
        )

    numeric_values = pd.to_numeric(
        values,
        errors="coerce",
    ).fillna(0)

    return int(numeric_values.sum())


def _print_distribution(
    results: pd.DataFrame,
    *,
    column: str,
    order: list[str],
) -> None:
    """
    Print an ordered categorical distribution.
    """
    if column not in results.columns:
        print(
            f"Column unavailable: {column}"
        )
        return

    distribution = (
        results[column]
        .astype("string")
        .value_counts(dropna=False)
        .reindex(order, fill_value=0)
    )

    for label, count in distribution.items():
        percentage = (
            float(count) / len(results) * 100
            if len(results) > 0
            else 0.0
        )

        print(
            f"  {label:<10}: "
            f"{int(count):>6} "
            f"({percentage:6.2f}%)"
        )


def print_summary(
    results: pd.DataFrame,
) -> None:
    """
    Print a readable execution summary for Airflow and local debugging.
    """
    print(
        "\nCyberSentinel Authentication ML Summary"
    )
    print(
        "-" * 52
    )

    if results.empty:
        print(
            "No authentication windows were scored."
        )
        return

    scored_windows = len(results)

    anomaly_count = _safe_count(
        results,
        "is_anomaly",
    )

    investigation_count = _safe_count(
        results,
        "requires_investigation",
    )

    anomaly_rate = (
        anomaly_count / scored_windows * 100
    )

    investigation_rate = (
        investigation_count / scored_windows * 100
    )

    print(
        f"Scored windows          : {scored_windows}"
    )
    print(
        f"ML anomalies            : "
        f"{anomaly_count} ({anomaly_rate:.2f}%)"
    )
    print(
        f"Investigation required  : "
        f"{investigation_count} "
        f"({investigation_rate:.2f}%)"
    )

    if "ml_anomaly_score" in results.columns:
        anomaly_scores = pd.to_numeric(
            results["ml_anomaly_score"],
            errors="coerce",
        )

        if anomaly_scores.notna().any():
            print(
                f"Average ML score        : "
                f"{anomaly_scores.mean():.2f}"
            )
            print(
                f"Maximum ML score        : "
                f"{anomaly_scores.max():.2f}"
            )

    if "security_risk_score" in results.columns:
        security_scores = pd.to_numeric(
            results["security_risk_score"],
            errors="coerce",
        )

        if security_scores.notna().any():
            print(
                f"Average security risk   : "
                f"{security_scores.mean():.2f}"
            )
            print(
                f"Maximum security risk   : "
                f"{security_scores.max():.2f}"
            )

    print(
        "\nDetection distribution:"
    )

    _print_distribution(
        results,
        column="detection_status",
        order=DETECTION_STATUS_ORDER,
    )

    print(
        "\nRisk distribution:"
    )

    _print_distribution(
        results,
        column="risk_level",
        order=RISK_LEVEL_ORDER,
    )

    print(
        "-" * 52
    )