{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as defender_event_key,

    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as event_key,

    case
        when threat_id is null
         and threat_name is null
        then null

        else {{ generate_surrogate_key([
            "coalesce(threat_id, '')",
            "coalesce(threat_name, '')"
        ]) }}
    end as threat_key,

    resource_path,

    action_name,
    action_status,

    error_code,
    error_description,

    engine_version,
    security_intelligence_version

from {{ ref('stg_antivirus') }}