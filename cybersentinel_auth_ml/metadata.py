from __future__ import annotations
from datetime import datetime, timezone
from uuid import uuid4
import pandas as pd
from cybersentinel_auth_ml.config import (
    MODEL_NAME,
    MODEL_VERSION,
)

# --> Add model metadata to scored rows
def add_model_metadata(df: pd.DataFrame) -> pd.DataFrame:

    results = df.copy()
    model_run_id = str(uuid4())
    scored_at = datetime.now(timezone.utc)
    results["model_name"] = MODEL_NAME
    results["model_version"] = MODEL_VERSION
    results["model_run_id"] = model_run_id
    results["scored_at"] = scored_at

    return results