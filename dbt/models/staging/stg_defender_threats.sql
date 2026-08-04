{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'defender_threats') }}

),

typed as (

    select
        raw_id,

        {{ normalize_null('collection_id') }} as collection_id,
        upper({{ normalize_null('machine_id') }}) as machine_id,

        {{ normalize_null('hostname') }} as hostname,
        {{ normalize_null('hostname_public') }} as hostname_public,

        cast(
            {{ normalize_null('timestamp_utc') }}
            as timestamptz
        ) as event_timestamp,

        {{ normalize_null('event_id') }} as event_id,

        {{ normalize_null('event_record_id') }} as event_record_id,

        {{ normalize_null('event_uid') }} as source_event_uid,
        {{ normalize_null('raw_event_hash') }} as raw_event_hash,

        upper({{ normalize_null('category') }}) as category,
        {{ normalize_null('channel') }} as channel,
        {{ normalize_null('provider') }} as provider,

        {{ normalize_severity('severity_normalized') }} as severity,
        {{ normalize_null('level_raw') }} as level_raw,

        {{ normalize_null('threat_id') }} as threat_id,
        {{ normalize_null('threat_status_id') }} as threat_status_id,

        cast(
            {{ normalize_null('initial_detection_time') }}
            as timestamptz
        ) as initial_detection_time,

        cast(
            {{ normalize_null('last_status_change_time') }}
            as timestamptz
        ) as last_status_change_time,

        cast(
            {{ normalize_null('remediation_time') }}
            as timestamptz
        ) as remediation_time,

        cast(
            {{ normalize_null('action_success') }}
            as boolean
        ) as action_success,

        {{ normalize_null('execution_status_id') }}
            as execution_status_id,

        lower({{ normalize_null('username') }}) as username,
        {{ normalize_null('process_name') }} as process_name,
        {{ normalize_null('resource_path') }} as resource_path,
        {{ normalize_null('action_status') }} as action_status,

        {{ normalize_null('engine_version') }} as engine_version,

        {{ normalize_null('security_intelligence_version') }}
            as security_intelligence_version,

        {{ normalize_null('event_family') }} as event_family,
        {{ normalize_null('event_action') }} as event_action,

        {{ normalize_null('event_category_normalized') }}
            as event_category_normalized,

        {{ normalize_null('security_domain') }} as security_domain,

        {{ normalize_null('mitre_tactic') }} as mitre_tactic,
        {{ normalize_null('mitre_technique') }} as mitre_technique,
        {{ normalize_null('mitre_id') }} as mitre_id,

        cast(
            {{ normalize_null('risk_score') }}
            as numeric(7, 2)
        ) as risk_score,

        {{ normalize_null('risk_level') }} as risk_level,

        {{ normalize_null('message') }} as message,
        {{ normalize_null('message_status') }} as message_status,

        cast(
            {{ normalize_null('extracted_at_utc') }}
            as timestamptz
        ) as extracted_at_utc,

        source_file,
        source_path,
        source_sha256,
        ingestion_timestamp

    from source_data

),

with_event_uid as (

    select
        *,

        coalesce(
            source_event_uid,

            {{ generate_event_uid(
                'machine_id',
                'category',
                'event_record_id',
                'event_timestamp'
            ) }}
        ) as event_uid

    from typed

),

deduplicated as (

    select
        *,

        row_number() over (
            partition by event_uid
            order by ingestion_timestamp desc, raw_id desc
        ) as duplicate_rank

    from with_event_uid

)

select
    event_uid,
    raw_event_hash,
    raw_id,
    collection_id,
    machine_id,
    hostname,
    hostname_public,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,
    level_raw,
    threat_id,
    threat_status_id,
    initial_detection_time,
    last_status_change_time,
    remediation_time,
    action_success,
    execution_status_id,
    username,
    process_name,
    resource_path,
    action_status,
    engine_version,
    security_intelligence_version,
    event_family,
    event_action,
    event_category_normalized,
    security_domain,
    mitre_tactic,
    mitre_technique,
    mitre_id,
    risk_score,
    risk_level,
    message,
    message_status,
    extracted_at_utc,
    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from deduplicated

where duplicate_rank = 1
  and event_uid is not null
  and machine_id is not null