-- XpressBees Profitability - Load Data from Stage into Tables
-- ============================================================
-- BEFORE running this script:
-- 1. Upload CSVs to @DATA_STAGE via Snowsight UI:
--    Data → Databases → XPRESSBEES_PROFITABILITY → RAW → Stages → DATA_STAGE → + Files
-- 2. Create a folder per month (e.g., october_2025, november_2025, etc.)
-- 3. Upload all 7 CSV files for that month into the folder
-- 4. Then run this script — replace <month> with folder name
--
-- NOTE: Data is APPENDED — safe to run multiple times for different months.
-- NOTE: For WEIGHTED_UTILIZATION CSVs, strip the junk first row before uploading.
-- ============================================================

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

-- ============================================================
-- Replace <month> below with your folder name (e.g., october_2025)
-- Run this block once per month
-- ============================================================

COPY INTO B2B_REVENUE FROM @DATA_STAGE/<month>/B2B_Revenue.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO AWB_FILE FROM @DATA_STAGE/<month>/AWB_File.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO FM_JOURNEY FROM @DATA_STAGE/<month>/FM_Journey.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO LM_JOURNEY FROM @DATA_STAGE/<month>/LM_Journey.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO MM_JOURNEY FROM @DATA_STAGE/<month>/MM_Journey.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO DAILY_LOAD FROM @DATA_STAGE/<month>/Daily_Load.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

-- WEIGHTED_UTILIZATION: Use SKIP_HEADER = 1 (not PARSE_HEADER) because
-- these CSVs have a junk row 1 that must be stripped before upload,
-- and the real headers are in the first row of the cleaned file.
COPY INTO WEIGHTED_UTILIZATION FROM @DATA_STAGE/weighted_utilization/
  FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1 NULL_IF=('','NULL','null','#N/A','NA') FIELD_DELIMITER=',' ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE)
  ON_ERROR = 'CONTINUE';

-- ============================================================
-- Dimension tables (load ONCE — not per month)
-- ============================================================

COPY INTO DIM_HUB_CITY FROM @DATA_STAGE/Hub-city_mapping.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO DIM_HUB_TO_ZONE FROM @DATA_STAGE/Hub_to_zone_mapping.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

-- ============================================================
-- Verify row counts
-- ============================================================

SELECT 'B2B_REVENUE' AS tbl, COUNT(*) AS rows FROM B2B_REVENUE
UNION ALL SELECT 'AWB_FILE', COUNT(*) FROM AWB_FILE
UNION ALL SELECT 'FM_JOURNEY', COUNT(*) FROM FM_JOURNEY
UNION ALL SELECT 'LM_JOURNEY', COUNT(*) FROM LM_JOURNEY
UNION ALL SELECT 'MM_JOURNEY', COUNT(*) FROM MM_JOURNEY
UNION ALL SELECT 'DAILY_LOAD', COUNT(*) FROM DAILY_LOAD
UNION ALL SELECT 'WEIGHTED_UTILIZATION', COUNT(*) FROM WEIGHTED_UTILIZATION
UNION ALL SELECT 'DIM_HUB_CITY', COUNT(*) FROM DIM_HUB_CITY
UNION ALL SELECT 'DIM_HUB_TO_ZONE', COUNT(*) FROM DIM_HUB_TO_ZONE;
