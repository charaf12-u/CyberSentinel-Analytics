--> MACHINE LEARNING SCHEMA
-- =========================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS ml;

COMMENT ON SCHEMA ml IS
'Machine-learning scores, model metadata and explainable security recommendations.';

COMMIT;
