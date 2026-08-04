{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'collection_id',
        'machine_id',
        'coalesce(device_instance_id, device_id)'
    ]) }} as usb_inventory_key,

    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    {{ generate_surrogate_key([
        "coalesce(device_instance_id, '')",
        "coalesce(serial_number_hash, '')",
        "coalesce(vendor_id, '')",
        "coalesce(product_id, '')"
    ]) }} as usb_device_key,

    to_char(
        snapshot_timestamp,
        'YYYYMMDD'
    )::integer as date_key,

    to_char(
        snapshot_timestamp,
        'HH24MISS'
    )::integer as time_key,

    is_present,
    status as device_status,
    error_code,

    usb_risk_score,
    usb_risk_level,

    free_space_bytes,
    capacity_bytes,

    snapshot_timestamp

from {{ ref('stg_usb_devices') }}

where snapshot_timestamp is not null