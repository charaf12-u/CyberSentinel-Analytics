{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'windows_system_logs') }}

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

        cast(
            {{ normalize_null('event_id') }}
            as integer
        ) as event_id,

        cast(
            {{ normalize_null('event_record_id') }}
            as bigint
        ) as event_record_id,

        {{ normalize_null('event_uid') }} as source_event_uid,
        {{ normalize_null('raw_event_hash') }} as raw_event_hash,

        upper({{ normalize_null('category') }}) as category,

        {{ normalize_null('channel') }} as channel,
        {{ normalize_null('provider') }} as provider,

        {{ normalize_severity('severity_normalized') }}
            as severity,

        {{ normalize_null('level_raw') }} as level_raw,
        {{ normalize_null('data_origin') }} as data_origin,

        cast(
            {{ normalize_null('process_id') }}
            as bigint
        ) as process_id,

        cast(
            {{ normalize_null('thread_id') }}
            as bigint
        ) as thread_id,

        {{ normalize_null('activity_id') }}
            as activity_id,

        cast(
            {{ normalize_null('execution_process_id') }}
            as bigint
        ) as execution_process_id,

        {{ normalize_null('task') }} as task,
        {{ normalize_null('opcode') }} as opcode,
        {{ normalize_null('keywords') }} as keywords,
        {{ normalize_null('user_sid') }} as user_sid,

        {{ normalize_null('system_classification') }}
            as system_classification,

        {{ normalize_null('process_sha256') }}
            as process_sha256,

        {{ normalize_null('process_md5') }}
            as process_md5,

        cast(
            {{ normalize_null('process_signed') }}
            as boolean
        ) as process_signed,

        {{ normalize_null('process_signature_status') }}
            as process_signature_status,

        {{ normalize_null('process_publisher') }}
            as process_publisher,

        {{ normalize_null('process_company') }}
            as process_company,

        {{ normalize_null('process_description') }}
            as process_description,

        {{ normalize_null('event_family') }}
            as event_family,

        {{ normalize_null('event_action') }}
            as event_action,

        {{ normalize_null('event_category_normalized') }}
            as event_category_normalized,

        {{ normalize_null('security_domain') }}
            as security_domain,

        {{ normalize_null('mitre_tactic') }}
            as mitre_tactic,

        {{ normalize_null('mitre_technique') }}
            as mitre_technique,

        {{ normalize_null('mitre_id') }}
            as mitre_id,

        cast(
            {{ normalize_null('risk_score') }}
            as numeric(7, 2)
        ) as risk_score,

        {{ normalize_null('risk_level') }}
            as risk_level,

        {{ normalize_null('message') }}
            as message,

        {{ normalize_null('message_status') }}
            as message_status,

        {{ normalize_null('raw_xml') }}
            as raw_xml,

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
    data_origin,

    process_id,
    thread_id,
    activity_id,
    execution_process_id,

    task,
    opcode,
    keywords,
    user_sid,

    system_classification,

    process_sha256,
    process_md5,
    process_signed,
    process_signature_status,
    process_publisher,
    process_company,
    process_description,

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
    raw_xml,

    extracted_at_utc,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from deduplicated

where duplicate_rank = 1
  and event_uid is not null
  and machine_id is not null
  and event_timestamp is not null