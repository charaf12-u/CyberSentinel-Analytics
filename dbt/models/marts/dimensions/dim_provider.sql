{{ config(
    materialized='table',
    schema='warehouse'
) }}

select distinct
    {{ generate_surrogate_key([
        "coalesce(provider, '')",
        "coalesce(channel, '')"
    ]) }} as provider_key,

    provider as provider_name,
    channel as channel_name,
    category as source_system

from {{ ref('int_security_events_unioned') }}

where provider is not null
   or channel is not null