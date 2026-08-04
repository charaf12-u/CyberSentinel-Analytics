{{ config(
    materialized='table',
    schema='warehouse'
) }}

select distinct
    {{ generate_surrogate_key([
        "coalesce(event_id::text, '')",
        "coalesce(event_category_normalized, '')",
        "coalesce(event_action, '')"
    ]) }} as event_type_key,

    event_id as native_event_id,
    event_family,
    event_action,

    category as event_category,
    event_category_normalized,
    security_domain

from {{ ref('int_security_events_unioned') }}