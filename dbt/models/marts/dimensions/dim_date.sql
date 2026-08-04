{{ config(
    materialized='table',
    schema='warehouse'
) }}

with bounds as (

    select
        coalesce(
            min(event_timestamp::date),
            current_date
        ) as min_date,

        coalesce(
            max(event_timestamp::date),
            current_date
        ) as max_date

    from {{ ref('int_security_events_unioned') }}

),

dates as (

    select
        generate_series(
            min_date,
            max_date,
            interval '1 day'
        )::date as full_date

    from bounds

)

select
    to_char(full_date, 'YYYYMMDD')::integer as date_key,
    full_date,

    extract(day from full_date)::smallint as day_number,
    extract(isodow from full_date)::smallint as day_of_week,
    trim(to_char(full_date, 'Day')) as day_name,

    extract(week from full_date)::smallint as week_number,

    extract(month from full_date)::smallint as month_number,
    trim(to_char(full_date, 'Month')) as month_name,

    extract(quarter from full_date)::smallint as quarter_number,
    extract(year from full_date)::smallint as year_number,

    extract(isodow from full_date) in (6, 7) as is_weekend

from dates