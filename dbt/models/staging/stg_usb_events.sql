{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'usb_event_logs') }}

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

        {{ normalize_severity('severity_normalized') }} as severity,
        {{ normalize_null('level_raw') }} as level_raw,

        {{ normalize_null('event_action') }} as event_action,

        {{ normalize_null('class_guid') }} as class_guid,
        {{ normalize_null('device_instance_id') }} as device_instance_id,
        {{ normalize_null('device_description') }} as device_description,

        {{ normalize_null('driver_name') }} as driver_name,
        {{ normalize_null('driver_version') }} as driver_version,
        {{ normalize_null('status_code') }} as status_code,

        {{ normalize_null('vendor_id') }} as vendor_id,
        {{ normalize_null('product_id') }} as product_id,

        {{ normalize_null('serial_number') }} as serial_number,
        {{ normalize_null('serial_number_hash') }} as serial_number_hash,

        {{ normalize_null('device_name') }} as device_name,
        {{ normalize_null('device_class') }} as device_class,
        {{ normalize_null('manufacturer') }} as manufacturer,
        {{ normalize_null('device_type') }} as device_type,

        cast(
            {{ normalize_null('usb_risk_score') }}
            as numeric(7, 2)
        ) as usb_risk_score,

        {{ normalize_null('usb_risk_level') }} as usb_risk_level,

        cast(
            {{ normalize_null('is_connected') }}
            as boolean
        ) as is_connected,

        cast(
            {{ normalize_null('is_removed') }}
            as boolean
        ) as is_removed,

        cast(
            {{ normalize_null('is_failed') }}
            as boolean
        ) as is_failed,

        cast(
            {{ normalize_null('is_blocked') }}
            as boolean
        ) as is_blocked,

        {{ normalize_null('event_family') }} as event_family,

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
        {{ normalize_null('raw_xml') }} as raw_xml,

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
    event_action,
    class_guid,
    device_instance_id,
    device_description,
    driver_name,
    driver_version,
    status_code,
    vendor_id,
    product_id,
    serial_number,
    serial_number_hash,
    device_name,
    device_class,
    manufacturer,
    device_type,
    usb_risk_score,
    usb_risk_level,
    is_connected,
    is_removed,
    is_failed,
    is_blocked,
    event_family,
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