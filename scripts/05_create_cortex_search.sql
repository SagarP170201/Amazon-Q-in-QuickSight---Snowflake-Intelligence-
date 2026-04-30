-- XpressBees Profitability - Create Cortex Search Service
-- ============================================================
-- This script chunks the XB Guide and XB Prompt documents and creates
-- a Cortex Search Service for the agent's knowledge base.
--
-- BEFORE running:
-- 1. Open "XB Guide FINAL.docx" — Select All, Copy the full text
-- 2. Open "XB Prompt FINAL.docx" — Select All, Copy the full text
-- 3. Paste each into the INSERT statements below (replace the placeholders)
-- ============================================================

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

-- Step 1: Create a staging table for raw document text
CREATE OR REPLACE TEMPORARY TABLE RAW_DOCS (
    DOC_NAME VARCHAR,
    DOC_TEXT VARCHAR
);

-- Step 2: Insert the full document text
-- IMPORTANT: Replace <PASTE_XB_GUIDE_TEXT_HERE> with the full text from XB Guide FINAL.docx
-- IMPORTANT: Replace <PASTE_XB_PROMPT_TEXT_HERE> with the full text from XB Prompt FINAL.docx
-- TIP: If the text contains single quotes ('), replace them with two single quotes ('')

INSERT INTO RAW_DOCS VALUES ('XB_Guide', '<PASTE_XB_GUIDE_TEXT_HERE>');
INSERT INTO RAW_DOCS VALUES ('XB_Prompt', '<PASTE_XB_PROMPT_TEXT_HERE>');

-- Step 3: Chunk the documents (1500 chars per chunk, 200 char overlap)
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

-- Step 4: Create Cortex Search Service
CREATE OR REPLACE CORTEX SEARCH SERVICE XB_DOCS_SEARCH
  ON CHUNK_TEXT
  ATTRIBUTES DOC_NAME
  WAREHOUSE = SNOW_INTELLIGENCE_DEMO_WH
  TARGET_LAG = '1 hour'
  AS (SELECT CHUNK_TEXT, DOC_NAME FROM DOC_CHUNKS);

-- Verify
SHOW CORTEX SEARCH SERVICES IN SCHEMA RAW;
