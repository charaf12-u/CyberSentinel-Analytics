--> BRONZE AND AUDIT INDEXES
-- =========================================================

BEGIN;


--> AUDIT.FILE_LOADS
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_file_loads_status_loaded_at
ON audit.file_loads (
    load_status,
    loaded_at DESC
);

CREATE INDEX IF NOT EXISTS idx_file_loads_collection
ON audit.file_loads (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_file_loads_machine
ON audit.file_loads (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_file_loads_source_file
ON audit.file_loads (
    source_file
);

CREATE INDEX IF NOT EXISTS idx_file_loads_sha256
ON audit.file_loads (
    source_sha256
);


--> WINDOWS SYSTEM
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_system_machine
ON bronze.windows_system_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_system_collection
ON bronze.windows_system_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_system_event_id
ON bronze.windows_system_logs (
    event_id
);

CREATE INDEX IF NOT EXISTS idx_system_event_uid
ON bronze.windows_system_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_system_timestamp
ON bronze.windows_system_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_system_provider
ON bronze.windows_system_logs (
    provider
);

CREATE INDEX IF NOT EXISTS idx_system_severity
ON bronze.windows_system_logs (
    severity_normalized
);

CREATE INDEX IF NOT EXISTS idx_system_machine_timestamp
ON bronze.windows_system_logs (
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_system_collection_event_uid
ON bronze.windows_system_logs (
    collection_id,
    event_uid
);


--> WINDOWS APPLICATION
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_application_machine
ON bronze.windows_application_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_application_collection
ON bronze.windows_application_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_application_event_id
ON bronze.windows_application_logs (
    event_id
);

CREATE INDEX IF NOT EXISTS idx_application_event_uid
ON bronze.windows_application_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_application_timestamp
ON bronze.windows_application_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_application_provider
ON bronze.windows_application_logs (
    provider
);

CREATE INDEX IF NOT EXISTS idx_application_severity
ON bronze.windows_application_logs (
    severity_normalized
);

CREATE INDEX IF NOT EXISTS idx_application_machine_timestamp
ON bronze.windows_application_logs (
    machine_id,
    timestamp_utc
);


--> AUTHENTICATION
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_auth_machine
ON bronze.authentication_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_auth_collection
ON bronze.authentication_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_auth_event_id
ON bronze.authentication_logs (
    event_id
);

CREATE INDEX IF NOT EXISTS idx_auth_event_uid
ON bronze.authentication_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_auth_timestamp
ON bronze.authentication_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_auth_username
ON bronze.authentication_logs (
    username
);

CREATE INDEX IF NOT EXISTS idx_auth_target_username
ON bronze.authentication_logs (
    target_username
);

CREATE INDEX IF NOT EXISTS idx_auth_user_sid
ON bronze.authentication_logs (
    user_sid
);

CREATE INDEX IF NOT EXISTS idx_auth_source_ip
ON bronze.authentication_logs (
    source_ip
);

CREATE INDEX IF NOT EXISTS idx_auth_source_ip_hash
ON bronze.authentication_logs (
    source_ip_hash
);

CREATE INDEX IF NOT EXISTS idx_auth_event_status
ON bronze.authentication_logs (
    event_status
);

CREATE INDEX IF NOT EXISTS idx_auth_machine_timestamp
ON bronze.authentication_logs (
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_auth_failure_analysis
ON bronze.authentication_logs (
    is_failure,
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_auth_remote_analysis
ON bronze.authentication_logs (
    is_remote_logon,
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_auth_privileged_analysis
ON bronze.authentication_logs (
    is_privileged_logon,
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_auth_logon_session
ON bronze.authentication_logs (
    logon_session_id
);


--> MICROSOFT DEFENDER EVENTS
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_antivirus_machine
ON bronze.antivirus_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_antivirus_collection
ON bronze.antivirus_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_antivirus_event_id
ON bronze.antivirus_logs (
    event_id
);

CREATE INDEX IF NOT EXISTS idx_antivirus_event_uid
ON bronze.antivirus_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_antivirus_timestamp
ON bronze.antivirus_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_antivirus_threat_id
ON bronze.antivirus_logs (
    threat_id
);

CREATE INDEX IF NOT EXISTS idx_antivirus_threat_name
ON bronze.antivirus_logs (
    threat_name
);

CREATE INDEX IF NOT EXISTS idx_antivirus_action
ON bronze.antivirus_logs (
    action_name
);

CREATE INDEX IF NOT EXISTS idx_antivirus_severity
ON bronze.antivirus_logs (
    severity_normalized
);

CREATE INDEX IF NOT EXISTS idx_antivirus_machine_timestamp
ON bronze.antivirus_logs (
    machine_id,
    timestamp_utc
);


--> DEFENDER THREAT HISTORY
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_defender_threats_machine
ON bronze.defender_threats (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_defender_threats_collection
ON bronze.defender_threats (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_defender_threats_event_uid
ON bronze.defender_threats (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_defender_threats_threat_id
ON bronze.defender_threats (
    threat_id
);

CREATE INDEX IF NOT EXISTS idx_defender_threats_timestamp
ON bronze.defender_threats (
    timestamp_utc
);


--> FIREWALL
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_firewall_machine
ON bronze.firewall_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_firewall_collection
ON bronze.firewall_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_firewall_event_uid
ON bronze.firewall_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_firewall_timestamp
ON bronze.firewall_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_firewall_action
ON bronze.firewall_logs (
    action
);

CREATE INDEX IF NOT EXISTS idx_firewall_protocol
ON bronze.firewall_logs (
    protocol
);

CREATE INDEX IF NOT EXISTS idx_firewall_source_ip
ON bronze.firewall_logs (
    source_ip
);

CREATE INDEX IF NOT EXISTS idx_firewall_destination_ip
ON bronze.firewall_logs (
    destination_ip
);

CREATE INDEX IF NOT EXISTS idx_firewall_source_ip_hash
ON bronze.firewall_logs (
    source_ip_hash
);

CREATE INDEX IF NOT EXISTS idx_firewall_destination_ip_hash
ON bronze.firewall_logs (
    destination_ip_hash
);

CREATE INDEX IF NOT EXISTS idx_firewall_destination_port
ON bronze.firewall_logs (
    destination_port
);

CREATE INDEX IF NOT EXISTS idx_firewall_direction
ON bronze.firewall_logs (
    direction
);

CREATE INDEX IF NOT EXISTS idx_firewall_machine_timestamp
ON bronze.firewall_logs (
    machine_id,
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_firewall_action_protocol_timestamp
ON bronze.firewall_logs (
    action,
    protocol,
    timestamp_utc
);


--> USB DEVICES INVENTORY
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_usb_devices_machine
ON bronze.usb_devices (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_collection
ON bronze.usb_devices (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_event_uid
ON bronze.usb_devices (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_device_id
ON bronze.usb_devices (
    device_id
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_instance_id
ON bronze.usb_devices (
    device_instance_id
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_serial_hash
ON bronze.usb_devices (
    serial_number_hash
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_vendor_product
ON bronze.usb_devices (
    vendor_id,
    product_id
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_type
ON bronze.usb_devices (
    device_type
);

CREATE INDEX IF NOT EXISTS idx_usb_devices_risk
ON bronze.usb_devices (
    usb_risk_score
);


--> USB HISTORICAL EVENTS
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_usb_events_machine
ON bronze.usb_event_logs (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_usb_events_collection
ON bronze.usb_event_logs (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_usb_events_event_id
ON bronze.usb_event_logs (
    event_id
);

CREATE INDEX IF NOT EXISTS idx_usb_events_event_uid
ON bronze.usb_event_logs (
    event_uid
);

CREATE INDEX IF NOT EXISTS idx_usb_events_timestamp
ON bronze.usb_event_logs (
    timestamp_utc
);

CREATE INDEX IF NOT EXISTS idx_usb_events_device_instance
ON bronze.usb_event_logs (
    device_instance_id
);

CREATE INDEX IF NOT EXISTS idx_usb_events_serial_hash
ON bronze.usb_event_logs (
    serial_number_hash
);

CREATE INDEX IF NOT EXISTS idx_usb_events_action
ON bronze.usb_event_logs (
    event_action
);

CREATE INDEX IF NOT EXISTS idx_usb_events_machine_timestamp
ON bronze.usb_event_logs (
    machine_id,
    timestamp_utc
);


--> MACHINE INVENTORY
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_machine_inventory_machine
ON bronze.machine_inventory (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_machine_inventory_collection
ON bronze.machine_inventory (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_machine_inventory_hostname_public
ON bronze.machine_inventory (
    hostname_public
);

CREATE INDEX IF NOT EXISTS idx_machine_inventory_collected_at
ON bronze.machine_inventory (
    collected_at_utc
);


--> NETWORK INVENTORY
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_network_inventory_machine
ON bronze.network_inventory (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_network_inventory_collection
ON bronze.network_inventory (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_network_inventory_mac
ON bronze.network_inventory (
    mac
);

CREATE INDEX IF NOT EXISTS idx_network_inventory_ipv4
ON bronze.network_inventory (
    ipv4
);

CREATE INDEX IF NOT EXISTS idx_network_inventory_status
ON bronze.network_inventory (
    status
);


--> EXTRACTION REPORT
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_extraction_report_collection
ON bronze.extraction_report (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_extraction_report_machine
ON bronze.extraction_report (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_extraction_report_source
ON bronze.extraction_report (
    source_name
);

CREATE INDEX IF NOT EXISTS idx_extraction_report_status
ON bronze.extraction_report (
    source_status
);

CREATE INDEX IF NOT EXISTS idx_extraction_report_limit
ON bronze.extraction_report (
    limit_reached
);

CREATE INDEX IF NOT EXISTS idx_extraction_report_collection_source
ON bronze.extraction_report (
    collection_id,
    source_name
);


--> DATA QUALITY REPORT
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_quality_report_collection
ON bronze.data_quality_report (
    collection_id
);

CREATE INDEX IF NOT EXISTS idx_quality_report_machine
ON bronze.data_quality_report (
    machine_id
);

CREATE INDEX IF NOT EXISTS idx_quality_report_file
ON bronze.data_quality_report (
    file_name
);

CREATE INDEX IF NOT EXISTS idx_quality_report_validation
ON bronze.data_quality_report (
    validation_status
);

CREATE INDEX IF NOT EXISTS idx_quality_report_score
ON bronze.data_quality_report (
    quality_score
);

CREATE INDEX IF NOT EXISTS idx_quality_report_collection_file
ON bronze.data_quality_report (
    collection_id,
    file_name
);


COMMIT;