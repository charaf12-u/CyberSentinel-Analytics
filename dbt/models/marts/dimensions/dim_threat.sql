{{ config(
    materialized='table',
    schema='warehouse'
) }}

select distinct
    {{ generate_surrogate_key([
        "coalesce(threat_id, '')",
        "coalesce(threat_name, '')"
    ]) }} as threat_key,

    threat_id,
    threat_name,
    threat_category,
    threat_severity,

    detection_source,
    detection_origin,
    detection_type

from {{ ref('stg_antivirus') }}

where threat_id is not null
   or threat_name is not null