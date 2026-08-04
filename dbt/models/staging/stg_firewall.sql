{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'firewall_logs') }}

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

        case
            when {{ normalize_null('event_id') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('event_id') }}
                    as numeric
                 ) between 0 and 2147483647
            then cast(
                cast(
                    {{ normalize_null('event_id') }}
                    as numeric
                )
                as integer
            )
            else null
        end as event_id,

        case
            when {{ normalize_null('event_record_id') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('event_record_id') }}
                    as numeric
                 ) between 0 and 9223372036854775807
            then cast(
                cast(
                    {{ normalize_null('event_record_id') }}
                    as numeric
                )
                as bigint
            )
            else null
        end as event_record_id,

        {{ normalize_null('event_uid') }} as source_event_uid,
        {{ normalize_null('raw_event_hash') }} as raw_event_hash,

        upper({{ normalize_null('category') }}) as category,
        {{ normalize_null('channel') }} as channel,
        {{ normalize_null('provider') }} as provider,

        {{ normalize_severity('severity_normalized') }} as severity,
        {{ normalize_null('level_raw') }} as level_raw,

        upper({{ normalize_null('action') }}) as action,
        upper({{ normalize_null('protocol') }}) as protocol,

        {{ normalize_null('source_ip') }} as source_ip,
        {{ normalize_null('destination_ip') }} as destination_ip,

        {{ normalize_null('source_ip_hash') }} as source_ip_hash,
        {{ normalize_null('destination_ip_hash') }} as destination_ip_hash,

        cast(
            {{ normalize_null('source_ip_is_private') }}
            as boolean
        ) as source_ip_is_private,

        cast(
            {{ normalize_null('destination_ip_is_private') }}
            as boolean
        ) as destination_ip_is_private,

        {{ normalize_null('source_ip_class') }} as source_ip_class,
        {{ normalize_null('destination_ip_class') }} as destination_ip_class,

        {{ normalize_null('source_ip_subnet') }} as source_ip_subnet,
        {{ normalize_null('destination_ip_subnet') }}
            as destination_ip_subnet,

        case
            when {{ normalize_null('source_port') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('source_port') }}
                    as numeric
                 ) between 0 and 65535
            then cast(
                cast(
                    {{ normalize_null('source_port') }}
                    as numeric
                )
                as integer
            )
            else null
        end as source_port,

        case
            when {{ normalize_null('destination_port') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('destination_port') }}
                    as numeric
                 ) between 0 and 65535
            then cast(
                cast(
                    {{ normalize_null('destination_port') }}
                    as numeric
                )
                as integer
            )
            else null
        end as destination_port,

        case
            when {{ normalize_null('packet_size') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('packet_size') }}
                    as numeric
                 ) between 0 and 9223372036854775807
            then cast(
                cast(
                    {{ normalize_null('packet_size') }}
                    as numeric
                )
                as bigint
            )
            else null
        end as packet_size,

        {{ normalize_null('tcp_flags') }} as tcp_flags,

        case
            when {{ normalize_null('icmp_type') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('icmp_type') }}
                    as numeric
                 ) between 0 and 255
            then cast(
                cast(
                    {{ normalize_null('icmp_type') }}
                    as numeric
                )
                as integer
            )
            else null
        end as icmp_type,

        case
            when {{ normalize_null('icmp_code') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('icmp_code') }}
                    as numeric
                 ) between 0 and 255
            then cast(
                cast(
                    {{ normalize_null('icmp_code') }}
                    as numeric
                )
                as integer
            )
            else null
        end as icmp_code,

        upper({{ normalize_null('direction') }}) as direction,

        {{ normalize_null('process_path') }} as process_path,
        {{ normalize_null('rule_name') }} as rule_name,
        {{ normalize_null('profile') }} as profile,

        cast(
            {{ normalize_null('firewall_enabled') }}
            as boolean
        ) as firewall_enabled,

        cast(
            {{ normalize_null('firewall_logging_enabled') }}
            as boolean
        ) as firewall_logging_enabled,

        cast(
            {{ normalize_null('allowed_logging_enabled') }}
            as boolean
        ) as allowed_logging_enabled,

        cast(
            {{ normalize_null('dropped_logging_enabled') }}
            as boolean
        ) as dropped_logging_enabled,

        cast(
            {{ normalize_null('firewall_log_exists') }}
            as boolean
        ) as firewall_log_exists,

        case
            when {{ normalize_null('firewall_log_size_bytes') }} ~ '^[0-9]+$'
             and cast(
                    {{ normalize_null('firewall_log_size_bytes') }}
                    as numeric
                 ) between 0 and 9223372036854775807
            then cast(
                cast(
                    {{ normalize_null('firewall_log_size_bytes') }}
                    as numeric
                )
                as bigint
            )
            else null
        end as firewall_log_size_bytes,

        cast(
            {{ normalize_null('firewall_last_modified') }}
            as timestamptz
        ) as firewall_last_modified,

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
    action,
    protocol,
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
    packet_size,
    tcp_flags,
    icmp_type,
    icmp_code,
    direction,
    process_path,
    rule_name,
    profile,
    firewall_enabled,
    firewall_logging_enabled,
    allowed_logging_enabled,
    dropped_logging_enabled,
    firewall_log_exists,
    firewall_log_size_bytes,
    firewall_last_modified,
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
  and event_timestamp is not null