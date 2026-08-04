{{ config(
    materialized='table',
    schema='warehouse'
) }}

select distinct
    {{ generate_surrogate_key([
        "coalesce(mitre_id, '')",
        "coalesce(mitre_tactic, '')",
        "coalesce(mitre_technique, '')"
    ]) }} as mitre_key,

    mitre_id,
    mitre_tactic as tactic_name,
    mitre_technique as technique_name

from {{ ref('int_security_events_unioned') }}

where mitre_id is not null
   or mitre_tactic is not null
   or mitre_technique is not null