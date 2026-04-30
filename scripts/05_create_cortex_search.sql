-- XpressBees Profitability - Create Cortex Search Service
-- ============================================================
-- This script loads knowledge documents and creates a Cortex Search Service.
--
-- TWO OPTIONS for loading document text:
--
-- OPTION A (Recommended): Upload text files to stage via Snowsight UI
--   1. Open each .docx file, Select All, Copy, paste into a plain .txt file
--   2. Save as "XB_Guide.txt" and "XB_Prompt.txt"
--   3. In Snowsight: Data → XPRESSBEES_PROFITABILITY → RAW → DATA_STAGE
--   4. Upload both .txt files to DATA_STAGE/docs/
--   5. Run this script starting from "OPTION A" section below
--
-- OPTION B: Paste text directly into SQL
--   1. Open each .docx, Select All, Copy
--   2. Paste into the INSERT statements in "OPTION B" section below
--   3. IMPORTANT: Replace all single quotes (') with two single quotes ('')
--   4. Run the script
-- ============================================================

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

-- Create temp file format for reading raw text
CREATE OR REPLACE TEMPORARY FILE FORMAT RAW_TEXT
  TYPE = 'CSV'
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = NONE
  ESCAPE_UNENCLOSED_FIELD = NONE;

-- Create staging table for raw document text
CREATE OR REPLACE TEMPORARY TABLE RAW_DOCS (
    DOC_NAME VARCHAR,
    DOC_TEXT VARCHAR
);

-- ============================================================
-- OPTION A: Load from staged text files (recommended)
-- Upload XB_Guide.txt and XB_Prompt.txt to @DATA_STAGE/docs/ first
-- ============================================================

INSERT INTO RAW_DOCS
SELECT 'XB_Guide', $1
FROM @DATA_STAGE/docs/XB_Guide.txt (FILE_FORMAT => 'RAW_TEXT');

INSERT INTO RAW_DOCS
SELECT 'XB_Prompt', $1
FROM @DATA_STAGE/docs/XB_Prompt.txt (FILE_FORMAT => 'RAW_TEXT');

-- ============================================================
-- OPTION B: Paste text directly (alternative)
-- Uncomment and use these instead of Option A if you prefer
-- IMPORTANT: Escape all single quotes as '' (two single quotes)
-- ============================================================

-- INSERT INTO RAW_DOCS SELECT 'XB_Guide', '<PASTE_XB_GUIDE_TEXT_HERE>';
-- INSERT INTO RAW_DOCS SELECT 'XB_Prompt', '<PASTE_XB_PROMPT_TEXT_HERE>';

-- ============================================================
-- Verify documents loaded
-- ============================================================
SELECT DOC_NAME, LENGTH(DOC_TEXT) AS char_count FROM RAW_DOCS;

-- ============================================================
-- Chunk documents (1500 chars per chunk, 200 char overlap)
-- ============================================================
TRUNCATE TABLE IF EXISTS DOC_CHUNKS;

INSERT INTO DOC_CHUNKS (DOC_NAME, CHUNK_ID, CHUNK_TEXT)
WITH chunks AS (
    SELECT
        DOC_NAME,
        ROW_NUMBER() OVER (PARTITION BY DOC_NAME ORDER BY start_pos) - 1 AS CHUNK_ID,
        SUBSTR(DOC_TEXT, start_pos, 1500) AS CHUNK_TEXT
    FROM RAW_DOCS,
    LATERAL (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) * 1300 - 1299 AS start_pos
        FROM TABLE(GENERATOR(ROWCOUNT => 100))
    ) g
    WHERE start_pos <= LENGTH(DOC_TEXT)
)
SELECT DOC_NAME, CHUNK_ID, CHUNK_TEXT FROM chunks
WHERE LENGTH(CHUNK_TEXT) > 0;

-- Verify chunks
SELECT DOC_NAME, COUNT(*) AS chunk_count, SUM(LENGTH(CHUNK_TEXT)) AS total_chars
FROM DOC_CHUNKS GROUP BY DOC_NAME;

-- ============================================================
-- Create Cortex Search Service
-- ============================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE XB_DOCS_SEARCH
  ON CHUNK_TEXT
  ATTRIBUTES DOC_NAME
  WAREHOUSE = SNOW_INTELLIGENCE_DEMO_WH
  TARGET_LAG = '1 hour'
  AS (SELECT CHUNK_TEXT, DOC_NAME FROM DOC_CHUNKS);

-- Verify
SHOW CORTEX SEARCH SERVICES IN SCHEMA RAW;
