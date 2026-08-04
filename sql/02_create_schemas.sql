-- =========================================================
-- CYBERSENTINEL ANALYTICS
-- DATABASE SCHEMAS
-- =========================================================

BEGIN;

-- Raw collector data loaded from local files.
CREATE SCHEMA IF NOT EXISTS bronze;

-- Cleaned, typed, validated and deduplicated dbt models.
CREATE SCHEMA IF NOT EXISTS silver;

-- Intermediate dbt transformations and correlation models.
CREATE SCHEMA IF NOT EXISTS intermediate;

-- Gold dimensional model used by Power BI.
CREATE SCHEMA IF NOT EXISTS warehouse;

-- Pipeline execution, loading and data-quality monitoring.
CREATE SCHEMA IF NOT EXISTS audit;


COMMENT ON SCHEMA bronze IS
'Raw source-shaped data loaded from local CyberSentinel collector files.';

COMMENT ON SCHEMA silver IS
'Cleaned, typed, standardized, validated and deduplicated security datasets produced by dbt.';

COMMENT ON SCHEMA intermediate IS
'Intermediate dbt models used for unions, enrichments, correlations and business rules.';

COMMENT ON SCHEMA warehouse IS
'CyberSentinel Gold dimensional model containing dimensions, facts and Power BI-ready marts.';

COMMENT ON SCHEMA audit IS
'Pipeline runs, source extraction status, file loading history and data-quality results.';


COMMIT;