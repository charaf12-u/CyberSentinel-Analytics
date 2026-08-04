{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    collection_id,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    machine_id,

    min(event_timestamp) as collection_start_utc,
    max(event_timestamp) as collection_end_utc,

    count(*) as events_collected

from {{ ref('int_security_events_unioned') }}

where collection_id is not null

group by
    collection_id,
    machine_id