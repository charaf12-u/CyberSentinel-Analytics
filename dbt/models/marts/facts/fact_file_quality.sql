{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'collection_id',
        'machine_id',
        'file_name'
    ]) }} as file_quality_key,

    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    file_name,
    source_name,

    rows_extracted,
    rows_rejected,
    parse_errors,

    quality_score,
    missing_percentage,
    duplicate_percentage,

    validation_status,
    quality_rule_version,

    ingestion_timestamp

from {{ ref('stg_data_quality_report') }}