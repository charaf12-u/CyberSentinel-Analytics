from __future__ import annotations
import numpy as np
import pandas as pd
from cybersentinel_auth_ml.config import (
    MIN_TRAINING_ROWS,
    ML_FEATURE_COLUMNS,
    REQUIRED_INPUT_COLUMNS,
)
from cybersentinel_auth_ml.database import create_postgres_engine
from cybersentinel_auth_ml.repository import read_authentication_features


# --> Define text columns
TEXT_COLUMNS = [
    "machine_id",
    "hostname",
    "hostname_public",
    "username",
]
DATETIME_COLUMNS = [
    "window_start",
    "window_end",
]
NON_NEGATIVE_INTEGER_COLUMNS = [
    "failed_login_count",
    "successful_login_count",
    "total_events",
    "unique_source_ips",
]

# --> Validate required columns
def validate_required_columns(df: pd.DataFrame) -> None:
    # --> 
    missing_columns = sorted(set(REQUIRED_INPUT_COLUMNS).difference(df.columns))
    if missing_columns:
        raise ValueError(
            "Missing required authentication ML input columns: "
            f"{missing_columns}"
        )

# --> Data cleaning and transformation functions
def clean_text_columns(df: pd.DataFrame) -> pd.DataFrame:

    result = df.copy()
    for column in TEXT_COLUMNS:
        result[column] = (
            result[column]
            .astype("string")
            .str.strip()
        )
        result.loc[
            result[column].isin(["", "none", "null", "nan"]),
            column,
        ] = pd.NA

    return result

# --> Data type conversion functions
def convert_identifier_columns(df: pd.DataFrame) -> pd.DataFrame:
    
    result = df.copy()
    result["authentication_window_id"] = pd.to_numeric(
        result["authentication_window_id"],
        errors="coerce",
    ).astype("Int64")
    return result

# --> Data type conversion functions
def convert_datetime_columns(df: pd.DataFrame) -> pd.DataFrame:

    result = df.copy()
    for column in DATETIME_COLUMNS:
        result[column] = pd.to_datetime(
            result[column],
            errors="coerce",
            utc=True,
        )
    event_dates = pd.to_datetime(
        result["event_date"],
        errors="coerce",
        utc=True,
    )
    result["event_date"] = event_dates.dt.date
    return result

# --> Data type conversion functions
def convert_feature_columns(df: pd.DataFrame) -> pd.DataFrame:
    
    result = df.copy()
    for column in ML_FEATURE_COLUMNS:
        result[column] = pd.to_numeric(
            result[column],
            errors="coerce",
        )
    result[ML_FEATURE_COLUMNS] = (
        result[ML_FEATURE_COLUMNS]
        .replace([np.inf, -np.inf], np.nan)
        .fillna(0)
    )
    return result

# --> Data validation and cleaning functions
def enforce_feature_boundaries(df: pd.DataFrame) -> pd.DataFrame:
    
    result = df.copy()
    result["hour"] = (
        result["hour"]
        .clip(lower=0, upper=23)
        .round()
        .astype("int64")
    )
    result["is_night_login"] = (
        result["is_night_login"]
        .clip(lower=0, upper=1)
        .round()
        .astype("int64")
    )
    for column in NON_NEGATIVE_INTEGER_COLUMNS:
        result[column] = (
            result[column]
            .clip(lower=0)
            .round()
            .astype("int64")
        )
    result["failed_login_ratio"] = (
        result["failed_login_ratio"]
        .clip(lower=0.0, upper=1.0)
        .astype("float64")
    )
    result["events_per_minute"] = (
        result["events_per_minute"]
        .clip(lower=0.0)
        .astype("float64")
    )
    return result

# --> Data validation and cleaning functions
def remove_invalid_rows(df: pd.DataFrame) -> pd.DataFrame:
    
    result = df.copy()
    required_identifier_columns = [
        "authentication_window_id",
        "machine_id",
        "username",
        "event_date",
        "window_start",
        "window_end",
    ]
    result = result.dropna(
        subset=required_identifier_columns
    )
    result = result[
        result["authentication_window_id"] > 0
    ]
    result = result[
        result["window_end"] >= result["window_start"]
    ]
    result = result[
        result["total_events"]
        >= (
            result["failed_login_count"]
            + result["successful_login_count"]
        )
    ]
    return result

# --> Data validation and cleaning functions
def remove_duplicate_windows(df: pd.DataFrame) -> pd.DataFrame:
    
    result = df.copy()
    result = result.sort_values(
        by=[
            "authentication_window_id",
            "window_end",
        ],
        ascending=[
            True,
            True,
        ],
    )
    result = result.drop_duplicates(
        subset=["authentication_window_id"],
        keep="last",
    )
    return result

# --> Data validation and cleaning functions
def validate_training_dataset(df: pd.DataFrame) -> None:
    
    if df.empty:
        raise ValueError(
            "No valid authentication feature rows remain "
            "after validation."
        )
    if len(df) < MIN_TRAINING_ROWS:
        raise ValueError(
            "Insufficient authentication feature rows for "
            "Isolation Forest training. "
            f"Required at least {MIN_TRAINING_ROWS}, "
            f"received {len(df)}."
        )
    duplicated_ids = df[
        "authentication_window_id"
    ].duplicated()
    if duplicated_ids.any():
        raise ValueError(
            "Duplicate authentication_window_id values remain "
            "after deduplication."
        )
    invalid_feature_values = (
        ~np.isfinite(
            df[ML_FEATURE_COLUMNS].to_numpy(
                dtype="float64"
            )
        )
    ).any()
    if invalid_feature_values:
        raise ValueError(
            "The authentication ML feature matrix contains "
            "non-finite numeric values."
        )

# --> Data preparation function
def prepare_authentication_features( df: pd.DataFrame ) -> pd.DataFrame:
   
    if df.empty:
        raise ValueError(
            "The authentication ML feature table is empty."
        )
    validate_required_columns(df)
    result = df.copy()
    result = clean_text_columns(result)
    result = convert_identifier_columns(result)
    result = convert_datetime_columns(result)
    result = convert_feature_columns(result)
    result = enforce_feature_boundaries(result)
    result = remove_invalid_rows(result)
    result = remove_duplicate_windows(result)
    result = result.reset_index(drop=True)
    validate_training_dataset(result)

    return result

# --> Data loading function
def load_data() -> pd.DataFrame:
    
    engine = create_postgres_engine()
    try:
        raw_features = read_authentication_features(
            engine
        )
        return prepare_authentication_features(
            raw_features
        )
    finally:
        engine.dispose()