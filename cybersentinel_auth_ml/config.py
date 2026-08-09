from __future__ import annotations
import os
from pathlib import Path
from dotenv import load_dotenv

# --> Load environment variables from .env file
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

#--> Define project directories
def _int(name: str, default: int) -> int:
    raw_value = os.getenv(name)
    if raw_value is None or not raw_value.strip():
        return default

    try:
        return int(raw_value)
    except ValueError as exc:
        raise ValueError( f"{name} must be a valid integer. Received: {raw_value!r}" ) from exc

# --> Define project directories
def _float(name: str, default: float) -> float:
    raw_value = os.getenv(name)
    if raw_value is None or not raw_value.strip():
        return default

    try:
        return float(raw_value)
    except ValueError as exc:
        raise ValueError( f"{name} must be a valid number. Received: {raw_value!r}" ) from exc

# --> Define project directories
def _bool(name: str, default: bool = False) -> bool:
    raw_value = os.getenv(name)
    if raw_value is None:
        return default

    normalized_value = raw_value.strip().lower()
    true_values = {"1", "true", "yes", "y", "on"}
    false_values = {"0", "false", "no", "n", "off"}

    if normalized_value in true_values:
        return True
    if normalized_value in false_values:
        return False

    raise ValueError(f"{name} must be a boolean value. Received: {raw_value!r}")


# --> PostgreSQL
POSTGRES_HOST = os.getenv(
    "POSTGRES_HOST",
    "postgres",
)
POSTGRES_PORT = _int(
    "POSTGRES_PORT",
    5432,
)
POSTGRES_DB = os.getenv(
    "POSTGRES_DB",
    "cybersentinel_dw",
)
POSTGRES_USER = os.getenv(
    "POSTGRES_USER",
    "cybersentinel_admin",
)
POSTGRES_PASSWORD = os.getenv(
    "POSTGRES_PASSWORD",
    "CyberSentinel_DB_2026",
)
POSTGRES_CONNECT_TIMEOUT = _int(
    "POSTGRES_CONNECT_TIMEOUT",
    15,
)


# --> Feature and result tables
FEATURE_SCHEMA = os.getenv(
    "AUTH_ML_FEATURE_SCHEMA",
    "warehouse",
)
FEATURE_TABLE = os.getenv(
    "AUTH_ML_FEATURE_TABLE",
    "ml_authentication_features",
)
RESULT_SCHEMA = os.getenv(
    "AUTH_ML_RESULT_SCHEMA",
    "ml",
)
RESULT_TABLE = os.getenv(
    "AUTH_ML_RESULT_TABLE",
    "authentication_anomaly_scores",
)


# --> Isolation Forest
MODEL_NAME = os.getenv(
    "AUTH_ML_MODEL_NAME",
    "IsolationForest",
)
MODEL_VERSION = os.getenv(
    "AUTH_ML_MODEL_VERSION",
    "auth_isolation_forest_v1",
)
RANDOM_STATE = _int(
    "AUTH_ML_RANDOM_STATE",
    42,
)
N_ESTIMATORS = _int(
    "AUTH_ML_N_ESTIMATORS",
    300,
)
CONTAMINATION = _float(
    "AUTH_ML_CONTAMINATION",
    0.03,
)
MIN_TRAINING_ROWS = _int(
    "AUTH_ML_MIN_TRAINING_ROWS",
    20,
)


# --> Risk score thresholds
NORMAL_SCORE_MAX = _float(
    "AUTH_ML_NORMAL_SCORE_MAX",
    69.99,
)
ANOMALY_SCORE_MIN = _float(
    "AUTH_ML_ANOMALY_SCORE_MIN",
    70.0,
)


# --> Database persistence
DATABASE_BATCH_SIZE = _int(
    "AUTH_ML_DATABASE_BATCH_SIZE",
    1000,
)
DELETE_STALE_RESULTS = _bool(
    "AUTH_ML_DELETE_STALE_RESULTS",
    False,
)


# --> Debug export
EXPORT_DEBUG_CSV = _bool(
    "AUTH_ML_EXPORT_DEBUG_CSV",
    False,
)
DEBUG_OUTPUT_PATH = Path(
    os.getenv(
        "AUTH_ML_DEBUG_OUTPUT_PATH",
        str(
            PROJECT_ROOT
            / "data"
            / "reports"
            / "authentication_anomalies_debug.csv"
        ),
    )
)


# --> Data model
ML_FEATURE_COLUMNS = [
    "hour",
    "failed_login_count",
    "successful_login_count",
    "total_events",
    "unique_source_ips",
    "failed_login_ratio",
    "is_night_login",
    "events_per_minute",
]
IDENTIFIER_COLUMNS = [
    "authentication_window_id",
    "machine_id",
    "hostname",
    "hostname_public",
    "username",
    "event_date",
    "window_start",
    "window_end",
]
REQUIRED_INPUT_COLUMNS = list(
    dict.fromkeys(IDENTIFIER_COLUMNS + ML_FEATURE_COLUMNS)
)


# --> Configuration validation
if not POSTGRES_HOST.strip():
    raise ValueError("POSTGRES_HOST cannot be empty.")

if not POSTGRES_DB.strip():
    raise ValueError("POSTGRES_DB cannot be empty.")

if not POSTGRES_USER.strip():
    raise ValueError("POSTGRES_USER cannot be empty.")

if POSTGRES_PORT <= 0 or POSTGRES_PORT > 65535:
    raise ValueError( "POSTGRES_PORT must be between 1 and 65535.")

if POSTGRES_CONNECT_TIMEOUT <= 0:
    raise ValueError("POSTGRES_CONNECT_TIMEOUT must be greater than zero.")

if not FEATURE_SCHEMA.strip() or not FEATURE_TABLE.strip():
    raise ValueError("Authentication ML feature schema and table cannot be empty.")

if not RESULT_SCHEMA.strip() or not RESULT_TABLE.strip():
    raise ValueError("Authentication ML result schema and table cannot be empty.")

if N_ESTIMATORS < 10:
    raise ValueError("AUTH_ML_N_ESTIMATORS must be at least 10.")

if not 0.0 < CONTAMINATION <= 0.5:
    raise ValueError(
        "AUTH_ML_CONTAMINATION must be greater than 0 "
        "and lower than or equal to 0.5."
    )

if MIN_TRAINING_ROWS < 2:
    raise ValueError("AUTH_ML_MIN_TRAINING_ROWS must be at least 2.")

if DATABASE_BATCH_SIZE <= 0:
    raise ValueError("AUTH_ML_DATABASE_BATCH_SIZE must be greater than zero.")

if not 0.0 <= NORMAL_SCORE_MAX <= 100.0:
    raise ValueError("AUTH_ML_NORMAL_SCORE_MAX must be between 0 and 100.")

if not 0.0 <= ANOMALY_SCORE_MIN <= 100.0:
    raise ValueError("AUTH_ML_ANOMALY_SCORE_MIN must be between 0 and 100.")

if NORMAL_SCORE_MAX >= ANOMALY_SCORE_MIN:
    raise ValueError(
        "AUTH_ML_NORMAL_SCORE_MAX must be lower than "
        "AUTH_ML_ANOMALY_SCORE_MIN."
    )