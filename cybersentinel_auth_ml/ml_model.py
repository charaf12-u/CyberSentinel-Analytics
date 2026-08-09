from __future__ import annotations
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import RobustScaler
from cybersentinel_auth_ml.config import (
    ANOMALY_SCORE_MIN,
    CONTAMINATION,
    MIN_TRAINING_ROWS,
    ML_FEATURE_COLUMNS,
    N_ESTIMATORS,
    NORMAL_SCORE_MAX,
    RANDOM_STATE,
)

# --> Validate model input
def validate_model_input(df: pd.DataFrame) -> None:
    # --> Validate the input DataFrame for training the Isolation Forest model
    if df.empty:
        raise ValueError(
            "The authentication ML dataset is empty."
        )
    # --> Validate the number of rows in the input DataFrame
    if len(df) < MIN_TRAINING_ROWS:
        raise ValueError(
            "Insufficient authentication rows for Isolation Forest. "
            f"Required at least {MIN_TRAINING_ROWS}, "
            f"received {len(df)}."
        )
    # --> Validate the presence of required ML feature columns
    missing_feature_columns = [
        column
        for column in ML_FEATURE_COLUMNS
        if column not in df.columns
    ]
    # --> Raise an error if any required ML feature columns are missing
    if missing_feature_columns:
        raise ValueError(
            "Missing ML feature columns: "
            f"{missing_feature_columns}"
        )
    # --> Validate the feature matrix for NaN or infinite values
    feature_matrix = df[
        ML_FEATURE_COLUMNS
    ].to_numpy(dtype="float64")
    # --> Raise an error if the feature matrix contains NaN or infinite values
    if not np.isfinite(feature_matrix).all():
        raise ValueError(
            "The ML feature matrix contains NaN "
            "or infinite values."
        )

# --> Normalize anomaly scores
def normalize_anomaly_scores(
    raw_scores: np.ndarray,
) -> np.ndarray:
    
    if raw_scores.size == 0:
        return np.array([], dtype=float)
    # --> Invert the raw scores to align with the desired scoring direction
    inverted_scores = -np.asarray(
        raw_scores,
        dtype="float64",
    )

    lower_bound = float(
        np.percentile(inverted_scores, 5)
    )

    upper_bound = float(
        np.percentile(inverted_scores, 95)
    )

    score_range = upper_bound - lower_bound

    if score_range <= 1e-9:
        return np.zeros(
            len(inverted_scores),
            dtype=float,
        )

    clipped_scores = np.clip(
        inverted_scores,
        lower_bound,
        upper_bound,
    )

    normalized_scores = (
        100.0
        * (
            clipped_scores - lower_bound
        )
        / score_range
    )

    return np.round(
        normalized_scores,
        2,
    )

# --> Align scores with predictions
def align_score_with_prediction(
    scores: pd.Series,
    is_anomaly: pd.Series,
) -> pd.Series:
    # --> Align the anomaly scores with the corresponding predictions
    aligned_scores = pd.to_numeric(
        scores,
        errors="coerce",
    ).fillna(0.0)
    # --> Clip the aligned scores to ensure they are within the valid range
    aligned_scores = aligned_scores.clip(
        lower=0.0,
        upper=100.0,
    )
    # --> Create masks for normal and anomaly predictions
    normal_mask = is_anomaly.eq(0)
    anomaly_mask = is_anomaly.eq(1)
    # --> Clip the aligned scores based on the prediction masks
    aligned_scores.loc[normal_mask] = (
        aligned_scores.loc[normal_mask]
        .clip(
            lower=0.0,
            upper=NORMAL_SCORE_MAX,
        )
    )
    # --> Clip the aligned scores for anomaly predictions
    aligned_scores.loc[anomaly_mask] = (
        aligned_scores.loc[anomaly_mask]
        .clip(
            lower=ANOMALY_SCORE_MIN,
            upper=100.0,
        )
    )

    return aligned_scores.round(2)

# --> Build feature matrix
def build_feature_matrix(
    df: pd.DataFrame,
) -> np.ndarray:
    # --> Build the feature matrix for training the Isolation Forest model
    feature_frame = (
        df[ML_FEATURE_COLUMNS]
        .astype("float64")
    )
    # --> Scale the feature matrix using RobustScaler to handle outliers
    scaler = RobustScaler()

    return scaler.fit_transform(
        feature_frame
    )

# --> Train anomaly model
def train_anomaly_model(
    df: pd.DataFrame,
) -> pd.DataFrame:

    # --> Validate the input DataFrame for training the Isolation Forest model
    validate_model_input(df)
    results = df.copy()
    feature_matrix = build_feature_matrix(
        results
    )

    # --> Train the Isolation Forest model for anomaly detection
    model = IsolationForest(
        n_estimators=N_ESTIMATORS,
        contamination=CONTAMINATION,
        max_samples="auto",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )
    # --> Fit the model and predict anomalies in the feature matrix
    predictions = model.fit_predict(
        feature_matrix
    )

    raw_scores = model.score_samples(
        feature_matrix
    )

    results["is_anomaly"] = (
        predictions == -1
    ).astype("int64")
    # --> Normalize the raw anomaly scores and align them with the predictions
    initial_scores = pd.Series(
        normalize_anomaly_scores(
            raw_scores
        ),
        index=results.index,
        dtype="float64",
    )
    # --> Align the normalized scores with the corresponding predictions
    results["ml_anomaly_score"] = (
        align_score_with_prediction(
            initial_scores,
            results["is_anomaly"],
        )
    )
    # --> Add detection status based on the anomaly predictions
    results["detection_status"] = np.where(
        results["is_anomaly"].eq(1),
        "Anomaly",
        "Normal",
    )

    return results