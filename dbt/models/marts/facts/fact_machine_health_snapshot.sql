{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'collection_id',
        'machine_id',
        'collected_at_utc'
    ]) }} as machine_health_key,

    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    to_char(
        collected_at_utc,
        'YYYYMMDD'
    )::integer as date_key,

    to_char(
        collected_at_utc,
        'HH24MISS'
    )::integer as time_key,

    cpu_usage,
    memory_usage,
    disk_usage,

    collected_at_utc as snapshot_timestamp

from {{ ref('stg_machine_inventory') }}

where collected_at_utc is not null