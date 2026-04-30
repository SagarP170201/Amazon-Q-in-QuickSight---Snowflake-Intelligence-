-- XpressBees Profitability - Deploy Semantic View
-- ============================================================
-- BEFORE running this script:
-- 1. Go to Snowsight → Data → Databases → XPRESSBEES_PROFITABILITY → SEMANTIC_MODELS
-- 2. Click on SEMANTIC_STAGE → Upload
-- 3. Upload the file: semantic_model/xpressbees_profitability_semantic_model.yaml
-- 4. Then come back here and run this script
-- ============================================================

USE DATABASE XPRESSBEES_PROFITABILITY;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

CREATE OR REPLACE TEMPORARY FILE FORMAT RAW.RAW_TEXT
  TYPE = 'CSV'
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = NONE
  ESCAPE_UNENCLOSED_FIELD = NONE;

-- Verify the YAML file is on stage
LIST @SEMANTIC_MODELS.SEMANTIC_STAGE;

-- Deploy the semantic view by reading YAML directly from stage
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS',
  (SELECT $1 FROM @SEMANTIC_MODELS.SEMANTIC_STAGE/xpressbees_profitability_semantic_model.yaml
   (FILE_FORMAT => 'RAW.RAW_TEXT')),
  FALSE
);

-- Verify
SHOW SEMANTIC VIEWS IN SCHEMA SEMANTIC_MODELS;
