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


def validate_model_input(df: pd.DataFrame) -> None:
    """
    Validate the dataset before training the Isolation Forest model.
    """
    if df.empty:
        raise ValueError(
            "The authentication ML dataset is empty."
        )

    if len(df) < MIN_TRAINING_ROWS:
        raise ValueError(
            "Insufficient authentication rows for Isolation Forest. "
            f"Required at least {MIN_TRAINING_ROWS}, "
            f"received {len(df)}."
        )

    missing_feature_columns = [
        column
        for column in ML_FEATURE_COLUMNS
        if column not in df.columns
    ]

    if missing_feature_columns:
        raise ValueError(
            "Missing ML feature columns: "
            f"{missing_feature_columns}"
        )

    feature_matrix = df[
        ML_FEATURE_COLUMNS
    ].to_numpy(dtype="float64")

    if not np.isfinite(feature_matrix).all():
        raise ValueError(
            "The ML feature matrix contains NaN "
            "or infinite values."
        )


def normalize_anomaly_scores(
    raw_scores: np.ndarray,
) -> np.ndarray:
    """
    Convert Isolation Forest decision scores to a 0-100 risk scale.

    Higher values represent more anomalous authentication behaviour.
    """
    if raw_scores.size == 0:
        return np.array([], dtype=float)

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


def align_score_with_prediction(
    scores: pd.Series,
    is_anomaly: pd.Series,
) -> pd.Series:
    """
    Keep displayed risk scores consistent with model predictions.

    Normal records remain below the configured anomaly threshold.
    Anomalous records start at the configured anomaly threshold.
    """
    aligned_scores = pd.to_numeric(
        scores,
        errors="coerce",
    ).fillna(0.0)

    aligned_scores = aligned_scores.clip(
        lower=0.0,
        upper=100.0,
    )

    normal_mask = is_anomaly.eq(0)
    anomaly_mask = is_anomaly.eq(1)

    aligned_scores.loc[normal_mask] = (
        aligned_scores.loc[normal_mask]
        .clip(
            lower=0.0,
            upper=NORMAL_SCORE_MAX,
        )
    )

    aligned_scores.loc[anomaly_mask] = (
        aligned_scores.loc[anomaly_mask]
        .clip(
            lower=ANOMALY_SCORE_MIN,
            upper=100.0,
        )
    )

    return aligned_scores.round(2)


def build_feature_matrix(
    df: pd.DataFrame,
) -> np.ndarray:
    """
    Build and scale the numerical feature matrix.
    """
    feature_frame = (
        df[ML_FEATURE_COLUMNS]
        .astype("float64")
    )

    scaler = RobustScaler()

    return scaler.fit_transform(
        feature_frame
    )


def train_anomaly_model(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Train Isolation Forest and append anomaly detection results.
    """
    validate_model_input(df)

    results = df.copy()

    feature_matrix = build_feature_matrix(
        results
    )

    model = IsolationForest(
        n_estimators=N_ESTIMATORS,
        contamination=CONTAMINATION,
        max_samples="auto",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    predictions = model.fit_predict(
        feature_matrix
    )

    raw_scores = model.score_samples(
        feature_matrix
    )

    results["is_anomaly"] = (
        predictions == -1
    ).astype("int64")

    initial_scores = pd.Series(
        normalize_anomaly_scores(
            raw_scores
        ),
        index=results.index,
        dtype="float64",
    )

    results["ml_anomaly_score"] = (
        align_score_with_prediction(
            initial_scores,
            results["is_anomaly"],
        )
    )

    results["detection_status"] = np.where(
        results["is_anomaly"].eq(1),
        "Anomaly",
        "Normal",
    )

    return results