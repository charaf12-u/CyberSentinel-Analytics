{{ config(
    materialized='table',
    schema='warehouse',
    indexes=[
        {'columns': ['authentication_window_id'], 'unique': true},
        {'columns': ['machine_id', 'event_date']},
        {'columns': ['risk_level']},
        {'columns': ['requires_investigation']}
    ]
) }}

with features as (

    select *
    from {{ ref('ml_authentication_features') }}

),

scores as (

    select *
    from {{ source('ml', 'authentication_anomaly_scores') }}

)

select
    features.authentication_window_id,

    features.machine_id,
    features.hostname,
    features.hostname_public,
    features.username,
    features.event_date,
    features.hour,
    features.window_start,
    features.window_end,

    features.failed_login_count,
    features.successful_login_count,
    features.authentication_event_count,
    features.total_events,
    features.unique_source_ips,
    features.has_source_ip,
    features.is_night_login,
    features.failed_login_ratio,
    features.window_minutes,
    features.events_per_minute,

    coalesce(scores.is_anomaly, 0)::smallint as is_anomaly,

    coalesce(
        scores.detection_status,
        'Not Scored'
    ) as detection_status,

    scores.ml_anomaly_score,
    scores.security_risk_score,

    coalesce(
        scores.risk_level,
        'Not Scored'
    ) as risk_level,

    coalesce(
        scores.requires_investigation,
        0
    )::smallint as requires_investigation,

    coalesce(
        scores.reason,
        'Authentication window has not been scored yet'
    ) as reason,

    coalesce(
        scores.recommended_action,
        'Run the authentication ML scoring pipeline'
    ) as recommended_action,

    scores.model_name,
    scores.model_version,
    scores.model_run_id,
    scores.scored_at,

    features.features_built_at,

    case
        when scores.authentication_window_id is null then 0
        else 1
    end::smallint as has_ml_score

from features

left join scores
    on features.authentication_window_id
       = scores.authentication_window_id
