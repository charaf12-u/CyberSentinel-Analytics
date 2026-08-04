{{ config(
    materialized='table',
    schema='warehouse'
) }}

with raw_ip_addresses as (

    select
        source_ip as ip_address,
        source_ip_hash as ip_hash,
        source_ip_is_private as is_private,
        source_ip_class as ip_class,
        source_ip_subnet as ip_subnet
    from {{ ref('stg_authentication') }}
    where source_ip is not null or source_ip_hash is not null

    union all

    select
        destination_ip as ip_address,
        destination_ip_hash as ip_hash,
        destination_ip_is_private as is_private,
        destination_ip_class as ip_class,
        destination_ip_subnet as ip_subnet
    from {{ ref('stg_authentication') }}
    where destination_ip is not null or destination_ip_hash is not null

    union all

    select
        source_ip as ip_address,
        source_ip_hash as ip_hash,
        source_ip_is_private as is_private,
        source_ip_class as ip_class,
        source_ip_subnet as ip_subnet
    from {{ ref('stg_firewall') }}
    where source_ip is not null or source_ip_hash is not null

    union all

    select
        destination_ip as ip_address,
        destination_ip_hash as ip_hash,
        destination_ip_is_private as is_private,
        destination_ip_class as ip_class,
        destination_ip_subnet as ip_subnet
    from {{ ref('stg_firewall') }}
    where destination_ip is not null or destination_ip_hash is not null

),

deduplicated as (

    select
        coalesce(ip_address, ip_hash) as ip_identifier,
        max(ip_address) as ip_address,
        max(ip_hash) as ip_hash,
        bool_or(is_private) as is_private,
        max(ip_class) as ip_class,
        max(ip_subnet) as ip_subnet
    from raw_ip_addresses
    group by 1

)

select
    {{ generate_surrogate_key([
        "ip_identifier"
    ]) }} as ip_key,

    ip_address,
    ip_hash,

    case
        when ip_address like '%:%' then 6
        when ip_address is not null then 4
        else null
    end::smallint as ip_version,

    ip_class,
    ip_subnet,
    is_private

from deduplicated