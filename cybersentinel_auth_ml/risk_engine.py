from __future__ import annotations

from typing import Any

import numpy as np
import pandas as pd


REQUIRED_RISK_COLUMNS = [
    "failed_login_count",
    "successful_login_count",
    "unique_source_ips",
    "failed_login_ratio",
    "total_events",
    "events_per_minute",
    "ml_anomaly_score",
    "is_anomaly",
    "is_night_login",
]


def _safe_int(
    value: Any,
    *,
    default: int = 0,
    minimum: int | None = None,
) -> int:
    """
    Convert a value to an integer without allowing invalid numeric values.
    """
    try:
        numeric_value = float(value)

        if not np.isfinite(numeric_value):
            return default

        result = int(round(numeric_value))
    except (TypeError, ValueError):
        return default

    if minimum is not None:
        result = max(result, minimum)

    return result


def _safe_float(
    value: Any,
    *,
    default: float = 0.0,
    minimum: float | None = None,
    maximum: float | None = None,
) -> float:
    """
    Convert a value to a finite float and apply optional boundaries.
    """
    try:
        result = float(value)

        if not np.isfinite(result):
            return default
    except (TypeError, ValueError):
        return default

    if minimum is not None:
        result = max(result, minimum)

    if maximum is not None:
        result = min(result, maximum)

    return result


def validate_risk_input(df: pd.DataFrame) -> None:
    """
    Validate columns required by the cybersecurity risk engine.
    """
    if df.empty:
        raise ValueError(
            "The authentication risk engine received an empty dataset."
        )

    missing_columns = sorted(
        set(REQUIRED_RISK_COLUMNS).difference(df.columns)
    )

    if missing_columns:
        raise ValueError(
            "Missing columns required by the security risk engine: "
            f"{missing_columns}"
        )


def calculate_security_risk(
    row: pd.Series,
) -> tuple[int, list[str]]:
    """
    Calculate an explainable security risk score.

    The score represents operational security severity and is evaluated
    independently from behavioural rarity detected by Isolation Forest.
    """
    score = 0
    reasons: list[str] = []

    failed_count = _safe_int(
        row.get("failed_login_count"),
        minimum=0,
    )

    success_count = _safe_int(
        row.get("successful_login_count"),
        minimum=0,
    )

    unique_ips = _safe_int(
        row.get("unique_source_ips"),
        minimum=0,
    )

    failed_ratio = _safe_float(
        row.get("failed_login_ratio"),
        minimum=0.0,
        maximum=1.0,
    )

    total_events = _safe_int(
        row.get("total_events"),
        minimum=0,
    )

    events_per_minute = _safe_float(
        row.get("events_per_minute"),
        minimum=0.0,
    )

    ml_score = _safe_float(
        row.get("ml_anomaly_score"),
        minimum=0.0,
        maximum=100.0,
    )

    is_anomaly = _safe_int(
        row.get("is_anomaly"),
        minimum=0,
    )

    is_night = _safe_int(
        row.get("is_night_login"),
        minimum=0,
    )

    window_minutes = _safe_float(
        row.get("window_minutes", 1.0),
        default=1.0,
        minimum=0.0,
    )

    # ------------------------------------------------------------------
    # Failed authentication volume
    # ------------------------------------------------------------------

    if failed_count >= 20:
        score += 55
        reasons.append(
            f"Very high failed login volume ({failed_count})"
        )
    elif failed_count >= 10:
        score += 45
        reasons.append(
            f"High failed login volume ({failed_count})"
        )
    elif failed_count >= 5:
        score += 30
        reasons.append(
            f"Multiple failed login attempts ({failed_count})"
        )
    elif failed_count >= 3:
        score += 18
        reasons.append(
            f"Repeated failed login attempts ({failed_count})"
        )
    elif failed_count >= 1:
        score += 5
        reasons.append(
            f"Limited failed login activity ({failed_count})"
        )

    # ------------------------------------------------------------------
    # Authentication failure ratio
    # ------------------------------------------------------------------

    authentication_count = failed_count + success_count

    if authentication_count >= 5:
        if failed_ratio >= 0.90:
            score += 20
            reasons.append(
                "Almost all authentication attempts failed"
            )
        elif failed_ratio >= 0.70:
            score += 15
            reasons.append(
                "High failed authentication ratio"
            )
        elif failed_ratio >= 0.40:
            score += 8
            reasons.append(
                "Elevated failed authentication ratio"
            )

    # ------------------------------------------------------------------
    # Source-IP diversity
    # ------------------------------------------------------------------

    if unique_ips >= 10:
        score += 25
        reasons.append(
            f"Authentication activity from {unique_ips} source IPs"
        )
    elif unique_ips >= 5:
        score += 18
        reasons.append(
            f"Multiple source IPs detected ({unique_ips})"
        )
    elif unique_ips >= 3:
        score += 10
        reasons.append(
            f"Several source IPs detected ({unique_ips})"
        )

    # ------------------------------------------------------------------
    # Night authentication activity
    # ------------------------------------------------------------------

    if is_night == 1:
        if failed_count >= 3:
            score += 15
            reasons.append(
                "Failed authentication activity during night hours"
            )
        elif is_anomaly == 1:
            score += 8
            reasons.append(
                "Unusual activity during night hours"
            )
        else:
            score += 2
            reasons.append(
                "Authentication activity during night hours"
            )

    # ------------------------------------------------------------------
    # Successful-login volume
    # ------------------------------------------------------------------

    if success_count >= 300:
        score += 25
        reasons.append(
            f"Extremely high successful login volume ({success_count})"
        )
    elif success_count >= 150:
        score += 18
        reasons.append(
            f"Very high successful login volume ({success_count})"
        )
    elif success_count >= 75:
        score += 10
        reasons.append(
            f"High successful login volume ({success_count})"
        )

    # ------------------------------------------------------------------
    # Event volume and sustained bursts
    # ------------------------------------------------------------------

    if total_events >= 500:
        score += 15
        reasons.append(
            "Extreme authentication event volume"
        )
    elif total_events >= 250:
        score += 10
        reasons.append(
            "High authentication event volume"
        )
    elif window_minutes >= 2 and events_per_minute >= 100:
        score += 15
        reasons.append(
            "Extreme sustained authentication event burst"
        )
    elif window_minutes >= 2 and events_per_minute >= 50:
        score += 10
        reasons.append(
            "High sustained authentication event burst"
        )

    # ------------------------------------------------------------------
    # Behavioural anomaly detected by Isolation Forest
    # ------------------------------------------------------------------

    if is_anomaly == 1:
        if ml_score >= 90:
            score += 20
            reasons.append(
                "Strong behavioural anomaly detected by ML"
            )
        elif ml_score >= 70:
            score += 15
            reasons.append(
                "Behavioural anomaly detected by ML"
            )
        else:
            score += 8
            reasons.append(
                "Moderate behavioural anomaly detected by ML"
            )

    return min(max(score, 0), 100), reasons


def assign_risk_level(
    score: int,
) -> str:
    """
    Convert the numerical security score to a risk classification.
    """
    if score >= 80:
        return "Critical"

    if score >= 60:
        return "High"

    if score >= 30:
        return "Medium"

    return "Low"


def format_reason(
    row: pd.Series,
    reasons: list[str],
) -> str:
    """
    Build a human-readable explanation for Power BI and analysts.
    """
    if reasons:
        return " | ".join(reasons)

    if _safe_int(row.get("is_anomaly")) == 1:
        return (
            "Behaviour differs from the normal authentication baseline"
        )

    return "Normal authentication behaviour"


def generate_recommended_action(
    risk_level: str,
    row: pd.Series,
) -> str:
    """
    Generate a recommended SOC response from the final risk level.
    """
    if risk_level == "Critical":
        return (
            "Investigate immediately; validate the account, source IPs "
            "and related Windows events"
        )

    if risk_level == "High":
        return (
            "Prioritize investigation and correlate with endpoint, "
            "firewall and Microsoft Defender logs"
        )

    if risk_level == "Medium":
        return (
            "Review the activity and monitor the account for repetition"
        )

    if _safe_int(row.get("is_anomaly")) == 1:
        return (
            "Monitor the unusual behaviour and compare it with the "
            "user baseline"
        )

    return "No immediate action required"


def enrich_security_results(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Append risk scores, explanations and response recommendations.
    """
    validate_risk_input(df)

    results = df.copy()

    risk_results = results.apply(
        calculate_security_risk,
        axis=1,
    )

    results["security_risk_score"] = pd.Series(
        [score for score, _ in risk_results],
        index=results.index,
        dtype="int64",
    )

    reason_lists = [
        reasons
        for _, reasons in risk_results
    ]

    results["risk_level"] = (
        results["security_risk_score"]
        .apply(assign_risk_level)
        .astype("string")
    )

    results["reason"] = [
        format_reason(row, row_reasons)
        for (_, row), row_reasons in zip(
            results.iterrows(),
            reason_lists,
        )
    ]

    results["recommended_action"] = results.apply(
        lambda row: generate_recommended_action(
            risk_level=str(row["risk_level"]),
            row=row,
        ),
        axis=1,
    )

    results["requires_investigation"] = (
        results["risk_level"].isin(
            ["High", "Critical"]
        )
        | (
            results["is_anomaly"].eq(1)
            & results["security_risk_score"].ge(30)
        )
    ).astype("int64")

    return results