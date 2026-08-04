{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'machine_inventory') }}

),

typed as (

    select
        raw_id,

        {{ normalize_null('collection_id') }} as collection_id,
        upper({{ normalize_null('machine_id') }}) as machine_id,

        {{ normalize_null('hostname') }} as hostname,
        {{ normalize_null('hostname_raw') }} as hostname_raw,
        {{ normalize_null('hostname_public') }} as hostname_public,

        {{ normalize_null('manufacturer') }} as manufacturer,
        {{ normalize_null('model') }} as model,
        {{ normalize_null('bios_version') }} as bios_version,
        {{ normalize_null('serial_number') }} as serial_number,

        {{ normalize_null('cpu') }} as cpu,

        cast(
            {{ normalize_null('ram_gb') }}
            as numeric(10, 2)
        ) as ram_gb,

        {{ normalize_null('architecture') }} as architecture,
        {{ normalize_null('windows_version') }} as windows_version,
        {{ normalize_null('windows_build') }} as windows_build,
        {{ normalize_null('domain_name') }} as domain_name,

        {{ normalize_null('ipv4') }} as ipv4,
        {{ normalize_null('mac_address') }} as mac_address,

        {{ normalize_null('collector_version') }} as collector_version,

        cast(
            {{ normalize_null('cpu_usage') }}
            as numeric(6, 2)
        ) as cpu_usage,

        cast(
            {{ normalize_null('memory_usage') }}
            as numeric(6, 2)
        ) as memory_usage,

        cast(
            {{ normalize_null('disk_usage') }}
            as numeric(6, 2)
        ) as disk_usage,

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
            partition by machine_id
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
    hostname_raw,
    hostname_public,
    manufacturer,
    model,
    bios_version,
    serial_number,
    cpu,
    ram_gb,
    architecture,
    windows_version,
    windows_build,
    domain_name,
    ipv4,
    mac_address,
    collector_version,
    cpu_usage,
    memory_usage,
    disk_usage,
    collected_at_utc,
    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from deduplicated

where duplicate_rank = 1
  and machine_id is not null