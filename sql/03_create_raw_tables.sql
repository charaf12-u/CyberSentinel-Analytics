-- =========================================================
-- CYBERSENTINEL ANALYTICS
-- BRONZE TABLES
--
-- Source:
-- Local CyberSentinel Collector 2.1.0 files
--
-- Principle:
-- Bronze preserves source-shaped data.
-- Cleaning, casting and deduplication are performed by dbt
-- inside the Silver layer.
-- =========================================================

BEGIN;


-- =========================================================
-- AUDIT — FILE LOAD HISTORY
-- =========================================================

CREATE TABLE IF NOT EXISTS audit.file_loads (
    file_load_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,

    source_path TEXT NOT NULL,
    source_file VARCHAR(500) NOT NULL,
    source_machine VARCHAR(255),

    source_sha256 CHAR(64) NOT NULL,
    file_size_bytes BIGINT,

    rows_discovered BIGINT NOT NULL DEFAULT 0,
    rows_loaded BIGINT NOT NULL DEFAULT 0,
    rows_rejected BIGINT NOT NULL DEFAULT 0,

    load_status VARCHAR(30) NOT NULL,
    error_message TEXT,

    started_at TIMESTAMPTZ,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_file_load_status CHECK (
        load_status IN (
            'PENDING',
            'RUNNING',
            'SUCCESS',
            'PARTIAL_SUCCESS',
            'EMPTY',
            'SKIPPED',
            'FAILED'
        )
    ),

    CONSTRAINT uq_file_load_version UNIQUE (
        source_path,
        source_sha256
    )
);


-- =========================================================
-- COMMON NOTE
--
-- Source values remain mostly TEXT in Bronze.
-- dbt Silver will perform:
-- - timestamp casts
-- - integer casts
-- - boolean casts
-- - null normalization
-- - deduplication using event_uid
-- =========================================================


-- =========================================================
-- WINDOWS SYSTEM EVENTS
-- Feeds:
-- fact_security_event
-- dim_machine
-- dim_provider
-- dim_event_type
-- dim_process
-- dim_user
-- dim_mitre
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.windows_system_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Collection and machine
    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    -- Event identity
    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    -- Event description
    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Windows technical fields
    process_id TEXT,
    thread_id TEXT,
    activity_id TEXT,
    execution_process_id TEXT,

    task TEXT,
    opcode TEXT,
    keywords TEXT,
    user_sid TEXT,

    system_classification TEXT,
    raw_xml TEXT,

    -- Event classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    -- MITRE
    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    -- Process enrichment
    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,
    process_enrichment_status TEXT,

    -- Risk
    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    -- Enrichment
    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,
    enrichment_error TEXT,

    geoip_status TEXT,
    dns_status TEXT,
    threat_intel_status TEXT,

    -- Quality
    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    -- Loader metadata
    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- WINDOWS APPLICATION EVENTS
-- Feeds:
-- fact_security_event
-- dim_process
-- dim_provider
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.windows_application_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Application crash details
    application_name TEXT,
    faulting_application TEXT,
    faulting_module TEXT,
    exception_code TEXT,

    process_id TEXT,
    thread_id TEXT,
    activity_id TEXT,

    service_name TEXT,
    error_bucket TEXT,
    user_sid TEXT,

    raw_xml TEXT,

    -- Classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    -- Process enrichment
    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,
    process_enrichment_status TEXT,

    -- Risk
    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    -- Enrichment
    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,
    enrichment_error TEXT,

    geoip_status TEXT,
    dns_status TEXT,
    threat_intel_status TEXT,

    -- Quality
    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- AUTHENTICATION EVENTS
-- Feeds:
-- fact_security_event
-- fact_authentication_event
-- dim_user
-- dim_ip
-- dim_process
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.authentication_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Users
    username TEXT,
    target_username TEXT,
    subject_username TEXT,
    user_sid TEXT,
    domain TEXT,
    workstation TEXT,

    -- IP and network
    source_ip TEXT,
    destination_ip TEXT,

    source_ip_hash TEXT,
    destination_ip_hash TEXT,

    source_ip_is_private TEXT,
    destination_ip_is_private TEXT,

    source_ip_class TEXT,
    destination_ip_class TEXT,

    source_ip_subnet TEXT,
    destination_ip_subnet TEXT,

    source_ip_version TEXT,
    destination_ip_version TEXT,
    ip_version TEXT,

    source_port TEXT,
    destination_port TEXT,

    -- GeoIP / DNS / reputation
    source_country TEXT,
    destination_country TEXT,

    source_city TEXT,
    destination_city TEXT,

    source_asn TEXT,
    destination_asn TEXT,

    source_organization TEXT,
    destination_organization TEXT,

    source_latitude TEXT,
    destination_latitude TEXT,

    source_longitude TEXT,
    destination_longitude TEXT,

    source_hostname TEXT,
    destination_hostname TEXT,

    source_ip_reputation TEXT,
    destination_ip_reputation TEXT,

    source_ip_risk TEXT,
    destination_ip_risk TEXT,

    source_ip_malicious TEXT,
    destination_ip_malicious TEXT,

    source_threat_feed TEXT,
    destination_threat_feed TEXT,

    source_threat_category TEXT,
    destination_threat_category TEXT,

    source_geoip_status TEXT,
    destination_geoip_status TEXT,

    source_dns_status TEXT,
    destination_dns_status TEXT,

    source_threat_intel_status TEXT,
    destination_threat_intel_status TEXT,

    -- Authentication
    logon_type TEXT,
    logon_process TEXT,
    authentication_package TEXT,
    process_name TEXT,

    event_status TEXT,
    failure_reason TEXT,
    status_code TEXT,
    sub_status_code TEXT,

    is_success TEXT,
    is_failure TEXT,
    is_remote_logon TEXT,
    is_privileged_logon TEXT,

    logon_session_id TEXT,

    -- Process metadata
    process_id TEXT,
    thread_id TEXT,
    activity_id TEXT,
    execution_process_id TEXT,

    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,

    raw_xml TEXT,

    -- Classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    -- Risk
    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    -- Enrichment
    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,

    geoip_status TEXT,
    dns_status TEXT,
    threat_intel_status TEXT,
    process_enrichment_status TEXT,

    enrichment_error TEXT,

    -- Quality
    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- MICROSOFT DEFENDER EVENTS
-- Feeds:
-- fact_security_event
-- fact_defender_event
-- dim_threat
-- dim_process
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.antivirus_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Threat
    threat_id TEXT,
    threat_name TEXT,
    threat_category TEXT,
    threat_severity TEXT,

    resource_path TEXT,
    process_name TEXT,
    username TEXT,

    action_name TEXT,
    action_status TEXT,

    detection_source TEXT,
    detection_origin TEXT,
    detection_type TEXT,

    error_code TEXT,
    error_description TEXT,

    engine_version TEXT,
    security_intelligence_version TEXT,

    -- Windows technical information
    process_id TEXT,
    thread_id TEXT,
    activity_id TEXT,
    execution_process_id TEXT,

    keywords TEXT,
    opcode TEXT,
    task TEXT,
    user_sid TEXT,

    raw_xml TEXT,

    -- Process enrichment
    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,
    process_enrichment_status TEXT,

    -- Classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    -- Risk
    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    -- Enrichment
    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,

    geoip_status TEXT,
    dns_status TEXT,
    threat_intel_status TEXT,

    enrichment_error TEXT,

    -- Quality
    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- DEFENDER THREAT HISTORY
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.defender_threats (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    threat_id TEXT,
    threat_status_id TEXT,

    initial_detection_time TEXT,
    last_status_change_time TEXT,
    remediation_time TEXT,

    action_success TEXT,
    execution_status_id TEXT,

    username TEXT,
    process_name TEXT,
    resource_path TEXT,
    action_status TEXT,

    engine_version TEXT,
    security_intelligence_version TEXT,

    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,

    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,
    enrichment_error TEXT,

    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- FIREWALL EVENTS
-- Feeds:
-- fact_security_event
-- fact_firewall_event
-- dim_ip
-- dim_process
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.firewall_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Firewall event
    action TEXT,
    protocol TEXT,

    source_ip TEXT,
    destination_ip TEXT,

    source_ip_hash TEXT,
    destination_ip_hash TEXT,

    source_ip_is_private TEXT,
    destination_ip_is_private TEXT,

    source_ip_class TEXT,
    destination_ip_class TEXT,

    source_ip_subnet TEXT,
    destination_ip_subnet TEXT,

    source_ip_version TEXT,
    destination_ip_version TEXT,
    ip_version TEXT,

    source_port TEXT,
    destination_port TEXT,

    packet_size TEXT,
    tcp_flags TEXT,
    icmp_type TEXT,
    icmp_code TEXT,

    direction TEXT,
    process_path TEXT,
    rule_name TEXT,
    profile TEXT,

    -- Firewall configuration
    firewall_enabled TEXT,
    firewall_logging_enabled TEXT,
    allowed_logging_enabled TEXT,
    dropped_logging_enabled TEXT,

    firewall_log_path TEXT,
    firewall_log_exists TEXT,
    firewall_log_size_bytes TEXT,
    firewall_last_modified TEXT,

    -- GeoIP / DNS / Threat intelligence
    source_country TEXT,
    destination_country TEXT,

    source_city TEXT,
    destination_city TEXT,

    source_asn TEXT,
    destination_asn TEXT,

    source_organization TEXT,
    destination_organization TEXT,

    source_latitude TEXT,
    destination_latitude TEXT,

    source_longitude TEXT,
    destination_longitude TEXT,

    source_hostname TEXT,
    destination_hostname TEXT,

    source_ip_reputation TEXT,
    destination_ip_reputation TEXT,

    source_ip_risk TEXT,
    destination_ip_risk TEXT,

    source_ip_malicious TEXT,
    destination_ip_malicious TEXT,

    source_threat_feed TEXT,
    destination_threat_feed TEXT,

    source_threat_category TEXT,
    destination_threat_category TEXT,

    source_geoip_status TEXT,
    destination_geoip_status TEXT,

    source_dns_status TEXT,
    destination_dns_status TEXT,

    source_threat_intel_status TEXT,
    destination_threat_intel_status TEXT,

    threat_feed TEXT,
    threat_category TEXT,

    -- Process enrichment
    process_sha256 TEXT,
    process_md5 TEXT,
    process_signed TEXT,
    process_signature_status TEXT,
    process_publisher TEXT,
    process_company TEXT,
    process_description TEXT,
    process_enrichment_status TEXT,

    raw_xml TEXT,

    -- Classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    -- Risk
    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    -- Enrichment
    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,

    geoip_status TEXT,
    dns_status TEXT,
    threat_intel_status TEXT,

    enrichment_error TEXT,

    -- Quality
    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- USB DEVICES INVENTORY
-- Feeds:
-- dim_usb_device
-- fact_usb_inventory_snapshot
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.usb_devices (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- Device identity
    device_id TEXT,
    device_instance_id TEXT,

    device_name TEXT,
    device_description TEXT,
    device_class TEXT,

    manufacturer TEXT,
    serial_number TEXT,
    serial_number_hash TEXT,

    vendor_id TEXT,
    product_id TEXT,
    pnp_device_id TEXT,

    service TEXT,
    status TEXT,
    error_code TEXT,

    -- Device classification
    is_present TEXT,
    is_usb TEXT,
    is_storage TEXT,
    is_removable TEXT,
    is_external TEXT,

    device_type TEXT,

    -- Storage information
    drive_letter TEXT,
    volume_label TEXT,
    filesystem TEXT,

    capacity_bytes TEXT,
    free_space_bytes TEXT,

    bitlocker_status TEXT,
    encryption_status TEXT,

    -- USB-specific risk
    usb_risk_score TEXT,
    usb_risk_level TEXT,

    usb_is_mass_storage TEXT,
    usb_is_removable TEXT,
    usb_is_trusted TEXT,

    usb_serial TEXT,
    usb_first_seen TEXT,
    usb_last_seen TEXT,

    -- General event classification
    event_family TEXT,
    event_action TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,
    enrichment_error TEXT,

    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- USB HISTORICAL EVENTS
-- Feeds:
-- fact_security_event
-- fact_usb_event
-- dim_usb_device
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.usb_event_logs (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,
    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    timestamp_utc TEXT,
    event_id TEXT,
    event_record_id TEXT,
    event_uid TEXT,
    raw_event_hash TEXT,

    category TEXT,
    channel TEXT,
    provider TEXT,

    level TEXT,
    level_raw TEXT,
    severity_normalized TEXT,

    message TEXT,
    message_status TEXT,

    data_origin TEXT,
    collector_version TEXT,
    extracted_at_utc TEXT,
    source_file TEXT,

    -- USB event
    event_action TEXT,

    class_guid TEXT,
    device_instance_id TEXT,
    device_description TEXT,

    driver_name TEXT,
    driver_version TEXT,

    status_code TEXT,

    vendor_id TEXT,
    product_id TEXT,
    serial_number TEXT,
    serial_number_hash TEXT,

    device_name TEXT,
    device_class TEXT,
    manufacturer TEXT,
    device_type TEXT,

    usb_risk_score TEXT,
    usb_risk_level TEXT,

    is_connected TEXT,
    is_removed TEXT,
    is_failed TEXT,
    is_blocked TEXT,

    raw_xml TEXT,

    -- Classification
    event_family TEXT,
    event_category_normalized TEXT,
    security_domain TEXT,

    mitre_tactic TEXT,
    mitre_technique TEXT,
    mitre_id TEXT,
    mitre_confidence TEXT,

    classification_rule_id TEXT,
    classification_version TEXT,
    requires_correlation TEXT,

    risk_score TEXT,
    risk_level TEXT,
    risk_reasons TEXT,
    risk_components JSONB,
    risk_rule_version TEXT,
    risk_confidence TEXT,

    enrichment_status TEXT,
    enrichment_provider TEXT,
    enrichment_version TEXT,
    enriched_at_utc TEXT,
    enrichment_error TEXT,

    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- MACHINE INVENTORY
-- Feeds:
-- dim_machine
-- fact_machine_health_snapshot
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.machine_inventory (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,

    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    manufacturer TEXT,
    model TEXT,
    bios_version TEXT,
    serial_number TEXT,

    cpu TEXT,
    ram_gb TEXT,
    architecture TEXT,

    windows_version TEXT,
    windows_build TEXT,
    domain_name TEXT,

    ipv4 TEXT,
    mac_address TEXT,

    collector_version TEXT,

    cpu_usage TEXT,
    memory_usage TEXT,
    disk_usage TEXT,

    collected_at_utc TEXT,

    source_file TEXT,
    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,

    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- NETWORK INVENTORY
-- Feeds:
-- dim_network_adapter
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.network_inventory (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,

    hostname TEXT,
    hostname_raw TEXT,
    hostname_public TEXT,

    adapter TEXT,
    adapter_description TEXT,

    ipv4 TEXT,
    ipv6 TEXT,
    mac TEXT,

    gateway TEXT,
    dns TEXT,

    dhcp TEXT,
    speed TEXT,
    status TEXT,

    collector_version TEXT,
    collected_at_utc TEXT,

    source_file TEXT,
    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,

    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- EXTRACTION REPORT
-- Feeds:
-- fact_collection_source_status
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.extraction_report (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,

    source_name TEXT,
    source_enabled TEXT,
    logging_enabled TEXT,
    permission_status TEXT,
    source_status TEXT,

    rows_extracted TEXT,
    rows_rejected TEXT,
    parse_errors TEXT,
    limit_reached TEXT,

    oldest_event_timestamp TEXT,
    newest_event_timestamp TEXT,
    duration_seconds TEXT,

    error_message TEXT,

    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,
    validation_status TEXT,
    quality_rule_version TEXT,

    source_file TEXT,
    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,

    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- DATA QUALITY REPORT
-- Feeds:
-- fact_file_quality
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.data_quality_report (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    collection_id TEXT,
    machine_id TEXT,

    file_name TEXT,
    source_name TEXT,

    rows_extracted TEXT,
    rows_rejected TEXT,
    parse_errors TEXT,

    quality_score TEXT,
    missing_percentage TEXT,
    duplicate_percentage TEXT,
    parsing_errors TEXT,

    validation_status TEXT,
    quality_rule_version TEXT,

    source_file TEXT,
    source_path TEXT NOT NULL,
    source_sha256 CHAR(64) NOT NULL,

    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    ingestion_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);


COMMIT;