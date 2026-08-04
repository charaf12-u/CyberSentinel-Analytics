{{ config(
    materialized='table',
    schema='warehouse',
    indexes=[
        {'columns': ['authentication_window_id'], 'unique': true},
        {'columns': ['machine_id', 'event_date']},
        {'columns': ['username', 'event_date']}
    ]
) }}

with authentication_events as (

    select
        machine_id,
        hostname,
        hostname_public,

        coalesce(
            nullif(username, ''),
            nullif(target_username, ''),
            nullif(subject_username, '')
        ) as username,

        event_timestamp,
        event_id,
        source_ip,
        source_ip_hash,
        is_success,
        is_failure

    from {{ ref('stg_authentication') }}

    where machine_id is not null
      and event_timestamp is not null
      and coalesce(
            nullif(username, ''),
            nullif(target_username, ''),
            nullif(subject_username, '')
          ) is not null

),

prepared as (

    select
        machine_id,
        hostname,
        hostname_public,
        username,

        event_timestamp,
        event_timestamp::date as event_date,
        extract(hour from event_timestamp)::smallint as hour,

        case
            when event_id = 4625 or coalesce(is_failure, false)
                then 1
            else 0
        end as is_failed_login,

        case
            when event_id = 4624 or coalesce(is_success, false)
                then 1
            else 0
        end as is_successful_login,

        case
            when extract(hour from event_timestamp) between 0 and 5
                then 1
            else 0
        end as is_night_login,

        coalesce(
            nullif(source_ip, ''),
            nullif(source_ip_hash, '')
        ) as source_identity

    from authentication_events

),

aggregated as (

    select
        machine_id,
        max(hostname) as hostname,
        max(hostname_public) as hostname_public,
        username,
        event_date,
        hour,

        min(event_timestamp) as window_start,
        max(event_timestamp) as window_end,

        sum(is_failed_login)::integer as failed_login_count,
        sum(is_successful_login)::integer as successful_login_count,
        count(*)::integer as total_events,
        count(distinct source_identity)::integer as unique_source_ips,
        max(is_night_login)::smallint as is_night_login

    from prepared

    group by
        machine_id,
        username,
        event_date,
        hour

),

features as (

    select
        {{ generate_surrogate_key([
            'machine_id',
            'username',
            'event_date',
            'hour'
        ]) }} as authentication_window_id,

        machine_id,
        hostname,
        hostname_public,
        username,
        event_date,
        hour,
        window_start,
        window_end,

        failed_login_count,
        successful_login_count,

        (
            failed_login_count
            + successful_login_count
        )::integer as authentication_event_count,

        total_events,
        unique_source_ips,

        case
            when unique_source_ips > 0 then 1
            else 0
        end::smallint as has_source_ip,

        is_night_login,

        case
            when failed_login_count + successful_login_count > 0
                then round(
                    failed_login_count::numeric
                    / (failed_login_count + successful_login_count),
                    6
                )
            else 0::numeric
        end as failed_login_ratio,

        greatest(
            extract(epoch from (window_end - window_start)) / 60.0,
            1.0
        )::numeric(12, 6) as window_minutes

    from aggregated

)

select
    authentication_window_id,
    machine_id,
    hostname,
    hostname_public,
    username,
    event_date,
    hour,
    window_start,
    window_end,

    failed_login_count,
    successful_login_count,
    authentication_event_count,
    total_events,
    unique_source_ips,
    has_source_ip,
    is_night_login,
    failed_login_ratio,
    window_minutes,

    round(
        total_events::numeric / nullif(window_minutes, 0),
        6
    ) as events_per_minute,

    current_timestamp as features_built_at

from features
