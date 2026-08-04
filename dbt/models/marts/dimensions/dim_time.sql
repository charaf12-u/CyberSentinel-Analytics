{{ config(
    materialized='table',
    schema='warehouse'
) }}

with seconds as (

    select generate_series(0, 86399) as second_of_day

)

select
    to_char(
        time '00:00:00'
        + second_of_day * interval '1 second',
        'HH24MISS'
    )::integer as time_key,

    (
        time '00:00:00'
        + second_of_day * interval '1 second'
    )::time as full_time,

    (second_of_day / 3600)::smallint as hour_number,

    (
        (second_of_day % 3600) / 60
    )::smallint as minute_number,

    (second_of_day % 60)::smallint as second_number,

    case
        when second_of_day < 21600 then 'Night'
        when second_of_day < 43200 then 'Morning'
        when second_of_day < 64800 then 'Afternoon'
        else 'Evening'
    end as period_of_day

from seconds