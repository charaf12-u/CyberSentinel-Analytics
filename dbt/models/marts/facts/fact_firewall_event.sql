{{ config(
    materialized='table',
    schema='warehouse'
) }}

select
    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as firewall_event_key,

    {{ generate_surrogate_key([
        'event_uid'
    ]) }} as event_key,

    action,
    protocol,

    source_port,
    destination_port,

    packet_size,
    tcp_flags,

    icmp_type,
    icmp_code,

    direction,
    rule_name,
    profile,
    process_path,

    firewall_enabled,
    firewall_logging_enabled,

    allowed_logging_enabled,
    dropped_logging_enabled,

    firewall_log_exists,
    firewall_log_size_bytes,
    firewall_last_modified

from {{ ref('stg_firewall') }}