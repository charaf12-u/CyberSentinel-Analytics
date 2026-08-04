{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'network_inventory') }}

),

typed as (

    select
        raw_id,

        {{ normalize_null('collection_id') }} as collection_id,
        upper({{ normalize_null('machine_id') }}) as machine_id,

        {{ normalize_null('hostname') }} as hostname,
        {{ normalize_null('hostname_public') }} as hostname_public,

        {{ normalize_null('adapter') }} as adapter,
        {{ normalize_null('adapter_description') }} as adapter_description,

        {{ normalize_null('ipv4') }} as ipv4,
        {{ normalize_null('ipv6') }} as ipv6,
        upper({{ normalize_null('mac') }}) as mac_address,

        {{ normalize_null('gateway') }} as gateway,
        {{ normalize_null('dns') }} as dns,

        cast(
            {{ normalize_null('dhcp') }}
            as boolean
        ) as dhcp_enabled,

        cast(
            {{ normalize_null('speed') }}
            as bigint
        ) as speed,

        {{ normalize_null('status') }} as adapter_status,
        {{ normalize_null('collector_version') }} as collector_version,

        cast(
            {{ normalize_null('collected_at_utc') }}
            as timestamptz
        ) as collected_at_utc,

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
                coalesce(mac_address, adapter)
            order by
                collected_at_utc desc nulls last,
                ingestion_timestamp desc,
                raw_id desc
        ) as duplicate_rank

    from typed

)

select
    raw_id,
    collection_id,
    machine_id,
    hostname,
    hostname_public,
    adapter,
    adapter_description,
    ipv4,
    ipv6,
    mac_address,
    gateway,
    dns,
    dhcp_enabled,
    speed,
    adapter_status,
    collector_version,
    collected_at_utc,
    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from deduplicated

where duplicate_rank = 1
  and machine_id is not null