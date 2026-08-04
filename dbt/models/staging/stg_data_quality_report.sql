{{ config(
    materialized='table',
    schema='silver'
) }}

with source_data as (

    select *
    from {{ source('bronze', 'data_quality_report') }}

)

select
    raw_id,

    {{ normalize_null('collection_id') }} as collection_id,
    upper({{ normalize_null('machine_id') }}) as machine_id,

    coalesce(
        {{ normalize_null('file_name') }},
        {{ normalize_null('source_file') }}
    ) as file_name,
    {{ normalize_null('source_name') }} as source_name,

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