-- =========================================================
-- CYBERSENTINEL ANALYTICS
-- AUTHENTICATION MACHINE LEARNING RESULTS
-- =========================================================

BEGIN;

CREATE TABLE IF NOT EXISTS ml.authentication_anomaly_scores (
    authentication_window_id BIGINT PRIMARY KEY,

    machine_id TEXT NOT NULL,
    hostname TEXT,
    hostname_public TEXT,
    username TEXT NOT NULL,
    event_date DATE NOT NULL,
    hour SMALLINT NOT NULL CHECK (hour BETWEEN 0 AND 23),

    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,

    is_anomaly SMALLINT NOT NULL CHECK (is_anomaly IN (0, 1)),
    detection_status TEXT NOT NULL
        CHECK (detection_status IN ('Normal', 'Anomaly')),
    ml_anomaly_score NUMERIC(6, 2) NOT NULL
        CHECK (ml_anomaly_score BETWEEN 0 AND 100),

    security_risk_score SMALLINT NOT NULL
        CHECK (security_risk_score BETWEEN 0 AND 100),
    risk_level TEXT NOT NULL
        CHECK (risk_level IN ('Low', 'Medium', 'High', 'Critical')),
    requires_investigation SMALLINT NOT NULL
        CHECK (requires_investigation IN (0, 1)),

    reason TEXT NOT NULL,
    recommended_action TEXT NOT NULL,

    model_name TEXT NOT NULL,
    model_version TEXT NOT NULL,
    model_run_id UUID NOT NULL,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_authentication_ml_window
        UNIQUE (machine_id, username, event_date, hour)
);

CREATE INDEX IF NOT EXISTS idx_auth_ml_machine_date
    ON ml.authentication_anomaly_scores (machine_id, event_date DESC);

CREATE INDEX IF NOT EXISTS idx_auth_ml_username_date
    ON ml.authentication_anomaly_scores (username, event_date DESC);

CREATE INDEX IF NOT EXISTS idx_auth_ml_risk_level
    ON ml.authentication_anomaly_scores (risk_level);

CREATE INDEX IF NOT EXISTS idx_auth_ml_is_anomaly
    ON ml.authentication_anomaly_scores (is_anomaly);

CREATE INDEX IF NOT EXISTS idx_auth_ml_requires_investigation
    ON ml.authentication_anomaly_scores (requires_investigation)
    WHERE requires_investigation = 1;

CREATE INDEX IF NOT EXISTS idx_auth_ml_scored_at
    ON ml.authentication_anomaly_scores (scored_at DESC);

COMMENT ON TABLE ml.authentication_anomaly_scores IS
'Latest Isolation Forest and explainable security-risk result for each hourly machine-user authentication window.';

COMMENT ON COLUMN ml.authentication_anomaly_scores.authentication_window_id IS
'Deterministic dbt surrogate key generated from machine_id, username, event_date and hour.';

COMMENT ON COLUMN ml.authentication_anomaly_scores.ml_anomaly_score IS
'Behavioural rarity score from 0 to 100. Normal rows remain below 70 and anomaly rows start at 70.';

COMMENT ON COLUMN ml.authentication_anomaly_scores.security_risk_score IS
'Explainable cybersecurity risk score independent from behavioural rarity.';

COMMIT;
