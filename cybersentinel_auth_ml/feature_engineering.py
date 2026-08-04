from __future__ import annotations

import pandas as pd

from cybersentinel_auth_ml.data_loader import prepare_authentication_features


def build_features(df: pd.DataFrame) -> pd.DataFrame:
    """Compatibility wrapper: dbt already builds the authentication features."""
    return prepare_authentication_features(df)
