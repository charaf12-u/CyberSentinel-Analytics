--> DATABASE SCHEMAS
-- =========================================================

BEGIN;

-- schema bronze : row data
CREATE SCHEMA IF NOT EXISTS bronze;

-- schema silver : cleaned and standardized data
CREATE SCHEMA IF NOT EXISTS silver;

-- schema intermediate : intermediate dbt models used for unions, enrichments, correlations and business rules
CREATE SCHEMA IF NOT EXISTS intermediate;

-- schema warehouse : dimensional model containing dimensions, facts and Power BI-ready marts
CREATE SCHEMA IF NOT EXISTS warehouse;

-- schema audit : pipeline runs, source extraction status, file loading history and data-quality results
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