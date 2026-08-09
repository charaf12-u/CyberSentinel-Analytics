from __future__ import annotations
import pandas as pd
from cybersentinel_auth_ml.data_loader import prepare_authentication_features

# --> Feature engineering function
def build_features(df: pd.DataFrame) -> pd.DataFrame:
    return prepare_authentication_features(df)
