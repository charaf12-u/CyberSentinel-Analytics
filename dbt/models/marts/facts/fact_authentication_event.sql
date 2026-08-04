{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as authentication_event_key,

    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as event_key,

    username,
    target_username,
    subject_username,

    workstation,

    source_port,
    destination_port,

    logon_type,
    logon_process,
    authentication_package,

    failure_reason,
    status_code,
    sub_status_code,

    is_success,
    is_failure,
    is_remote_logon,
    is_privileged_logon,

    logon_session_id,

    process_id,
    thread_id,
    activity_id,
    execution_process_id

from {{ ref('stg_authentication') }}