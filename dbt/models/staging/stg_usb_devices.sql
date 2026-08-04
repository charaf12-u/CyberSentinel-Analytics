{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'usb_devices') }}

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
        ) as snapshot_timestamp,

        {{ normalize_null('event_uid') }} as event_uid,
        {{ normalize_null('raw_event_hash') }} as raw_event_hash,

        {{ normalize_null('device_id') }} as device_id,
        {{ normalize_null('device_instance_id') }} as device_instance_id,

        {{ normalize_null('device_name') }} as device_name,
        {{ normalize_null('device_description') }} as device_description,
        {{ normalize_null('device_class') }} as device_class,

        {{ normalize_null('manufacturer') }} as manufacturer,
        {{ normalize_null('serial_number') }} as serial_number,
        {{ normalize_null('serial_number_hash') }} as serial_number_hash,

        {{ normalize_null('vendor_id') }} as vendor_id,
        {{ normalize_null('product_id') }} as product_id,
        {{ normalize_null('pnp_device_id') }} as pnp_device_id,

        {{ normalize_null('service') }} as service,
        {{ normalize_null('status') }} as status,
        {{ normalize_null('error_code') }} as error_code,

        cast(
            {{ normalize_null('is_present') }}
            as boolean
        ) as is_present,

        cast(
            {{ normalize_null('is_usb') }}
            as boolean
        ) as is_usb,

        cast(
            {{ normalize_null('is_storage') }}
            as boolean
        ) as is_storage,

        cast(
            {{ normalize_null('is_removable') }}
            as boolean
        ) as is_removable,

        cast(
            {{ normalize_null('is_external') }}
            as boolean
        ) as is_external,

        {{ normalize_null('device_type') }} as device_type,

        {{ normalize_null('drive_letter') }} as drive_letter,
        {{ normalize_null('volume_label') }} as volume_label,
        {{ normalize_null('filesystem') }} as filesystem,

        cast(
            {{ normalize_null('capacity_bytes') }}
            as bigint
        ) as capacity_bytes,

        cast(
            {{ normalize_null('free_space_bytes') }}
            as bigint
        ) as free_space_bytes,

        {{ normalize_null('bitlocker_status') }} as bitlocker_status,
        {{ normalize_null('encryption_status') }} as encryption_status,

        cast(
            {{ normalize_null('usb_risk_score') }}
            as numeric(7, 2)
        ) as usb_risk_score,

        {{ normalize_null('usb_risk_level') }} as usb_risk_level,

        cast(
            {{ normalize_null('usb_is_mass_storage') }}
            as boolean
        ) as usb_is_mass_storage,

        cast(
            {{ normalize_null('usb_is_removable') }}
            as boolean
        ) as usb_is_removable,

        cast(
            {{ normalize_null('usb_is_trusted') }}
            as boolean
        ) as usb_is_trusted,

        cast(
            {{ normalize_null('usb_first_seen') }}
            as timestamptz
        ) as usb_first_seen,

        cast(
            {{ normalize_null('usb_last_seen') }}
            as timestamptz
        ) as usb_last_seen,

        source_file,
        source_path,
        source_sha256,
        ingestion_timestamp

    from source_data

),

deduplicated as (

    select
        *,

        row_number() over (
            partition by
                machine_id,
                coalesce(
                    device_instance_id,
                    serial_number_hash,
                    device_id
                )
            order by ingestion_timestamp desc, raw_id desc
        ) as duplicate_rank

    from typed

)

select
    raw_id,
    collection_id,
    machine_id,
    hostname,
    hostname_public,
    snapshot_timestamp,
    event_uid,
    raw_event_hash,
    device_id,
    device_instance_id,
    device_name,
    device_description,
    device_class,
    manufacturer,
    serial_number,
    serial_number_hash,
    vendor_id,
    product_id,
    pnp_device_id,
    service,
    status,
    error_code,
    is_present,
    is_usb,
    is_storage,
    is_removable,
    is_external,
    device_type,
    drive_letter,
    volume_label,
    filesystem,
    capacity_bytes,
    free_space_bytes,
    bitlocker_status,
    encryption_status,
    usb_risk_score,
    usb_risk_level,
    usb_is_mass_storage,
    usb_is_removable,
    usb_is_trusted,
    usb_first_seen,
    usb_last_seen,
    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from deduplicated

where duplicate_rank = 1
  and machine_id is not null