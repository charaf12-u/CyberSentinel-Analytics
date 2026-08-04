{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'authentication_logs') }}

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

        ({{ normalize_null('event_id') }}::numeric)::integer as event_id,

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

        lower({{ normalize_null('username') }})
            as username,

        lower({{ normalize_null('target_username') }})
            as target_username,

        lower({{ normalize_null('subject_username') }})
            as subject_username,

        {{ normalize_null('user_sid') }} as user_sid,

        lower({{ normalize_null('domain') }})
            as domain,

        {{ normalize_null('workstation') }}
            as workstation,

        {{ normalize_null('source_ip') }}
            as source_ip,

        {{ normalize_null('destination_ip') }}
            as destination_ip,

        {{ normalize_null('source_ip_hash') }}
            as source_ip_hash,

        {{ normalize_null('destination_ip_hash') }}
            as destination_ip_hash,

        cast(
            {{ normalize_null('source_ip_is_private') }}
            as boolean
        ) as source_ip_is_private,

        cast(
            {{ normalize_null('destination_ip_is_private') }}
            as boolean
        ) as destination_ip_is_private,

        {{ normalize_null('source_ip_class') }}
            as source_ip_class,

        {{ normalize_null('destination_ip_class') }}
            as destination_ip_class,

        {{ normalize_null('source_ip_subnet') }}
            as source_ip_subnet,

        {{ normalize_null('destination_ip_subnet') }}
            as destination_ip_subnet,

        cast(
            cast(
                {{ normalize_null('source_port') }}
                as numeric
            )
            as integer
        ) as source_port,

        cast(
            cast(
                {{ normalize_null('destination_port') }}
                as numeric
            )
            as integer
        ) as destination_port,

        cast(
            cast(
                {{ normalize_null('logon_type') }}
                as numeric
            )
            as integer
        ) as logon_type,

        {{ normalize_null('logon_process') }}
            as logon_process,

        {{ normalize_null('authentication_package') }}
            as authentication_package,

        {{ normalize_null('process_name') }}
            as process_name,

        {{ normalize_null('event_status') }}
            as event_status,

        {{ normalize_null('failure_reason') }}
            as failure_reason,

        {{ normalize_null('status_code') }}
            as status_code,

        {{ normalize_null('sub_status_code') }}
            as sub_status_code,

        cast(
            {{ normalize_null('is_success') }}
            as boolean
        ) as is_success,

        cast(
            {{ normalize_null('is_failure') }}
            as boolean
        ) as is_failure,

        cast(
            {{ normalize_null('is_remote_logon') }}
            as boolean
        ) as is_remote_logon,

        cast(
            {{ normalize_null('is_privileged_logon') }}
            as boolean
        ) as is_privileged_logon,

        {{ normalize_null('logon_session_id') }}
            as logon_session_id,

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

    username,
    target_username,
    subject_username,
    user_sid,
    domain,
    workstation,

    source_ip,
    destination_ip,
    source_ip_hash,
    destination_ip_hash,
    source_ip_is_private,
    destination_ip_is_private,
    source_ip_class,
    destination_ip_class,
    source_ip_subnet,
    destination_ip_subnet,
    source_port,
    destination_port,

    logon_type,
    logon_process,
    authentication_package,
    process_name,

    event_status,
    failure_reason,
    status_code,
    sub_status_code,

    is_success,
    is_failure,
    is_remote_logon,
    is_privileged_logon,
    logon_session_id,

    process_id,
    thread_id,
    activity_id,
    execution_process_id,

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