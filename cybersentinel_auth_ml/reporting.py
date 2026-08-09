from __future__ import annotations
from pathlib import Path
import pandas as pd

# --> Reporting configuration constants
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

# --> Import the enrich_security_results function from the risk_engine module
def reorder_output_columns(
    df: pd.DataFrame,
) -> pd.DataFrame:
    
    if df.empty:
        return df.copy()
    # --> Identify existing preferred columns in the DataFrame
    existing_preferred_columns = [
        column
        for column in PREFERRED_COLUMNS
        if column in df.columns
    ]
    # --> Identify remaining columns in the DataFrame that are not part of the preferred columns
    remaining_columns = [
        column
        for column in df.columns
        if column not in existing_preferred_columns
    ]
    # --> Reorder the DataFrame columns to have preferred columns first, followed by remaining columns
    return df.loc[
        :,
        existing_preferred_columns + remaining_columns,
    ].copy()

# --> Export authentication ML results to a UTF-8 CSV file
def export_results(
    df: pd.DataFrame,
    output_path: str | Path,
) -> None:
    
    if df.empty:
        raise ValueError(
            "Cannot export an empty authentication ML result dataset."
        )

    path = Path(output_path).expanduser().resolve()
    # --> Validate that the output path has a .csv extension
    if path.suffix.lower() != ".csv":
        raise ValueError(
            "The authentication ML debug output path "
            "must use the .csv extension."
        )
    # --> Create the parent directory for the output path if it does not exist
    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )
    # --> Reorder the DataFrame columns to have preferred columns first, followed by remaining columns
    ordered_results = reorder_output_columns(
        df
    )
    # --> Export the ordered DataFrame to a CSV file with UTF-8 encoding and ISO 8601 date format
    ordered_results.to_csv(
        path,
        index=False,
        encoding="utf-8-sig",
        date_format="%Y-%m-%dT%H:%M:%S%z",
    )

# --> Print a summary of the authentication ML results, including counts and distributions
def _safe_count(
    results: pd.DataFrame,
    column: str,
) -> int:
    
    if column not in results.columns:
        return 0

    values = results[column]
    # --> Handle boolean columns by counting True values, treating NaN as False
    if pd.api.types.is_bool_dtype(values.dtype):
        return int(
            values.fillna(False).sum()
        )
    # --> Handle numeric columns by converting to numeric, coercing errors to NaN, and filling NaN with 0 before summing
    numeric_values = pd.to_numeric(
        values,
        errors="coerce",
    ).fillna(0)

    return int(numeric_values.sum())

# --> Print an ordered categorical distribution for a specified column in the results DataFrame
def _print_distribution(
    results: pd.DataFrame,
    *,
    column: str,
    order: list[str],
) -> None:
    
    if column not in results.columns:
        print(
            f"Column unavailable: {column}"
        )
        return
    # --> Calculate the distribution of values in the specified column, including NaN values, and reindex to match the specified order, filling missing values with 0
    distribution = (
        results[column]
        .astype("string")
        .value_counts(dropna=False)
        .reindex(order, fill_value=0)
    )
    # --> Print the distribution of values in the specified column, including counts and percentages
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

# --> Print a summary of the authentication ML results, including counts and distributions
def print_summary(
    results: pd.DataFrame,
) -> None:
    
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
    # --> Print average and maximum ML anomaly scores if the column exists in the results DataFrame
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
    # --> Print average and maximum security risk scores if the column exists in the results DataFrame
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