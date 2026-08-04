{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as event_key,

    event_uid,
    raw_event_hash,

    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    to_char(
        event_timestamp,
        'YYYYMMDD'
    )::integer as date_key,

    to_char(
        event_timestamp,
        'HH24MISS'
    )::integer as time_key,

    {{ generate_surrogate_key([
        "coalesce(provider, '')",
        "coalesce(channel, '')"
    ]) }} as provider_key,

    {{ generate_surrogate_key([
        "coalesce(event_id::text, '')",
        "coalesce(event_category_normalized, '')",
        "coalesce(event_action, '')"
    ]) }} as event_type_key,

    case severity
        when 'Low' then 1
        when 'Medium' then 2
        when 'High' then 3
        when 'Critical' then 4
        else 0
    end::smallint as severity_key,

    case
        when mitre_id is null
         and mitre_tactic is null
         and mitre_technique is null
        then null

        else {{ generate_surrogate_key([
            "coalesce(mitre_id, '')",
            "coalesce(mitre_tactic, '')",
            "coalesce(mitre_technique, '')"
        ]) }}
    end as mitre_key,

    case
        when username is null
         and user_sid is null
        then null

        else {{ generate_surrogate_key([
            "coalesce(user_sid, '')",
            "coalesce(username, '')"
        ]) }}
    end as target_user_key,

    case
        when source_ip is null
         and source_ip_hash is null
        then null

        else {{ generate_surrogate_key([
            "coalesce(source_ip, source_ip_hash)"
        ]) }}
    end as source_ip_key,

    case
        when destination_ip is null
         and destination_ip_hash is null
        then null

        else {{ generate_surrogate_key([
            "coalesce(destination_ip, destination_ip_hash)"
        ]) }}
    end as destination_ip_key,

    event_timestamp as event_timestamp_utc,

    event_record_id,
    event_id as native_event_id,

    category,
    message,

    risk_score,
    risk_level,

    source_file,
    source_path,
    ingestion_timestamp

from {{ ref('int_security_events_unioned') }}