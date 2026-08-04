{{ config(
    materialized='table',
    schema='intermediate'
) }}

-->  WINDOWS SYSTEM
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    cast(null as text) as username,
    user_sid,

    cast(null as text) as source_ip,
    cast(null as text) as source_ip_hash,

    cast(null as text) as destination_ip,
    cast(null as text) as destination_ip_hash,

    cast(null as text) as process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_windows_system') }}


union all


-->  WINDOWS APPLICATION
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    cast(null as text) as username,
    user_sid,

    cast(null as text) as source_ip,
    cast(null as text) as source_ip_hash,

    cast(null as text) as destination_ip,
    cast(null as text) as destination_ip_hash,

    coalesce(
        faulting_application,
        application_name
    ) as process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_windows_application') }}


union all


-->  AUTHENTICATION
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    username,
    user_sid,

    source_ip,
    source_ip_hash,

    destination_ip,
    destination_ip_hash,

    process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_authentication') }}


union all


-->  MICROSOFT DEFENDER
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    username,
    cast(null as text) as user_sid,

    cast(null as text) as source_ip,
    cast(null as text) as source_ip_hash,

    cast(null as text) as destination_ip,
    cast(null as text) as destination_ip_hash,

    process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_antivirus') }}


union all


-->  WINDOWS FIREWALL
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    cast(null as text) as username,
    cast(null as text) as user_sid,

    source_ip,
    source_ip_hash,

    destination_ip,
    destination_ip_hash,

    process_path as process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_firewall') }}


union all


-->  USB EVENTS
---  =========================================================

select
    event_uid,
    raw_event_hash,
    collection_id,
    machine_id,
    event_timestamp,
    event_id,
    event_record_id,
    category,
    channel,
    provider,
    severity,

    event_family,
    event_action,
    event_category_normalized,
    security_domain,

    mitre_tactic,
    mitre_technique,
    mitre_id,

    risk_score,
    risk_level,
    message,

    cast(null as text) as username,
    cast(null as text) as user_sid,

    cast(null as text) as source_ip,
    cast(null as text) as source_ip_hash,

    cast(null as text) as destination_ip,
    cast(null as text) as destination_ip_hash,

    cast(null as text) as process_name,

    source_file,
    source_path,
    source_sha256,
    ingestion_timestamp

from {{ ref('stg_usb_events') }}