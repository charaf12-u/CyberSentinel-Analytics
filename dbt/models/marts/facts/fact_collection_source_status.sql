{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'collection_id',
        'machine_id',
        'source_name'
    ]) }} as collection_source_status_key,

    {{ generate_surrogate_key([
        'collection_id'
    ]) }} as collection_key,

    {{ generate_surrogate_key([
        'machine_id'
    ]) }} as machine_key,

    source_name,

    source_enabled,
    logging_enabled,

    permission_status,
    source_status,

    rows_extracted,
    rows_rejected,
    parse_errors,

    limit_reached,

    oldest_event_timestamp,
    newest_event_timestamp,

    duration_seconds,
    error_message,

    quality_score,
    missing_percentage,
    duplicate_percentage,

    validation_status,
    quality_rule_version

from {{ ref('stg_extraction_report') }}