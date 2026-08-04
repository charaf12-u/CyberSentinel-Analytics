{{ config(
    materialized='table',
    schema='warehouse'
) }}

select *

from (
    values
        (
            0::smallint,
            'Unknown'::text,
            0::smallint,
            0::numeric
        ),
        (
            1::smallint,
            'Low'::text,
            1::smallint,
            10::numeric
        ),
        (
            2::smallint,
            'Medium'::text,
            2::smallint,
            35::numeric
        ),
        (
            3::smallint,
            'High'::text,
            3::smallint,
            70::numeric
        ),
        (
            4::smallint,
            'Critical'::text,
            4::smallint,
            100::numeric
        )
) as severity_values (
    severity_key,
    severity_name,
    severity_rank,
    default_risk_weight
)