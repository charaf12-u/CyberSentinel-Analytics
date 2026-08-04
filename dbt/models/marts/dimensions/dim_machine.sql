{{ config(
    materialized='table',
    schema='warehouse'
) }}

with event_activity as (

    select
        machine_id,
        min(event_timestamp) as first_seen_at,
        max(event_timestamp) as last_seen_at

    from {{ ref('int_security_events_unioned') }}

    where machine_id is not null

    group by machine_id

)

select
    {{ generate_surrogate_key([
        "coalesce(inventory.machine_id, activity.machine_id)"
    ]) }} as machine_key,

    coalesce(
        inventory.machine_id,
        activity.machine_id
    ) as machine_id,

    inventory.hostname,
    inventory.hostname_raw,
    inventory.hostname_public,

    inventory.manufacturer,
    inventory.model,
    inventory.serial_number,
    inventory.bios_version,

    inventory.cpu,
    inventory.ram_gb,
    inventory.architecture,

    inventory.windows_version,
    inventory.windows_build,
    inventory.domain_name,

    inventory.collector_version,

    coalesce(
        activity.first_seen_at,
        inventory.collected_at_utc
    ) as first_seen_at,

    coalesce(
        activity.last_seen_at,
        inventory.collected_at_utc
    ) as last_seen_at,

    true as is_active

from {{ ref('stg_machine_inventory') }} as inventory

full outer join event_activity as activity
    on inventory.machine_id = activity.machine_id