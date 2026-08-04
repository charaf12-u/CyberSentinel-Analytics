{{ config(
    materialized='table',
    schema='warehouse'
) }}

select distinct
    {{ generate_surrogate_key([
        "coalesce(device_instance_id, '')",
        "coalesce(serial_number_hash, '')",
        "coalesce(vendor_id, '')",
        "coalesce(product_id, '')"
    ]) }} as usb_device_key,

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

    device_type,

    is_usb,
    is_storage,
    is_removable,
    is_external,

    usb_is_trusted as is_trusted,

    drive_letter,
    volume_label,
    filesystem,

    capacity_bytes,
    free_space_bytes,

    bitlocker_status,
    encryption_status,

    usb_first_seen as first_seen_at,
    usb_last_seen as last_seen_at

from {{ ref('stg_usb_devices') }}