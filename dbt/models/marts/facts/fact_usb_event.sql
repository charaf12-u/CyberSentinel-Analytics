{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as usb_event_key,

    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as event_key,

    {{ generate_surrogate_key([
        "coalesce(device_instance_id, '')",
        "coalesce(serial_number_hash, '')",
        "coalesce(vendor_id, '')",
        "coalesce(product_id, '')"
    ]) }} as usb_device_key,

    event_action,

    class_guid,
    driver_name,
    driver_version,
    status_code,

    usb_risk_score,
    usb_risk_level,

    is_connected,
    is_removed,
    is_failed,
    is_blocked

from {{ ref('stg_usb_events') }}