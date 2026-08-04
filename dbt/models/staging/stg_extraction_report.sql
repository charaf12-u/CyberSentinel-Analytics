{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'extraction_report') }}

)

select
    raw_id,

    {{ normalize_null('collection_id') }} as collection_id,
    upper({{ normalize_null('machine_id') }}) as machine_id,

    {{ normalize_null('source_name') }} as source_name,

    cast(
        {{ normalize_null('source_enabled') }}
        as boolean
    ) as source_enabled,

    cast(
        {{ normalize_null('logging_enabled') }}
        as boolean
    ) as logging_enabled,

    {{ normalize_null('permission_status') }} as permission_status,
    {{ normalize_null('source_status') }} as source_status,

    cast(
        {{ normalize_null('rows_extracted') }}
        as bigint
    ) as rows_extracted,

    cast(
        {{ normalize_null('rows_rejected') }}
        as bigint
    ) as rows_rejected,

    cast(
        {{ normalize_null('parse_errors') }}
        as bigint
    ) as parse_errors,

    cast(
        {{ normalize_null('limit_reached') }}
        as boolean
    ) as limit_reached,

    cast(
        {{ normalize_null('oldest_event_timestamp') }}
        as timestamptz
    ) as oldest_event_timestamp,

    cast(
        {{ normalize_null('newest_event_timestamp') }}
        as timestamptz
    ) as newest_event_timestamp,

    cast(
        {{ normalize_null('duration_seconds') }}
        as numeric(12, 3)
    ) as duration_seconds,

    {{ normalize_null('error_message') }} as error_message,

    cast(
        {{ normalize_null('quality_score') }}
        as numeric(6, 2)
    ) as quality_score,

    cast(
        {{ normalize_null('missing_percentage') }}
        as numeric(7, 3)
    ) as missing_percentage,

    cast(
        {{ normalize_null('duplicate_percentage') }}
        as numeric(7, 3)
    ) as duplicate_percentage,

    {{ normalize_null('validation_status') }} as validation_status,
    {{ normalize_null('quality_rule_version') }} as quality_rule_version,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from source_data