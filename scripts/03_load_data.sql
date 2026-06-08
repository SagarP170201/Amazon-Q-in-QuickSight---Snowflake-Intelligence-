-- XpressBees Profitability - Load Data from Parquet Files
-- Run after 02_create_tables.sql
-- ============================================================
-- BEFORE running this script:
-- 1. Upload all parquet files to @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE
--    - Revenue files: Revenue October.parquet, Revenue November.parquet, etc.
--    - AWB files: AWB Created or Picked in oct.parquet, etc.
--    - FM/LM/MM Journey files: FM Journey October.parquet, etc.
--    - Daily Load files: Daily_Load_October.parquet, etc.
--    - Weighted Utilization files: Use the CLEANED parquets from scripts/07_prepare_wu_files.py
--    - Dimension files: Hub-city_mapping.parquet, Hub_to_zone_mapping.parquet (one-time)
-- 2. For WU files: Run scripts/07_prepare_wu_files.py first to clean headers
-- ============================================================

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

-- B2B Revenue (all months)
COPY INTO B2B_REVENUE
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Rr]evenue.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- AWB File (all months - includes PDD files)
COPY INTO AWB_FILE
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*(AWB|PDD|awb|pdd).*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- FM Journey (all months)
COPY INTO FM_JOURNEY
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Ff][Mm].*[Jj]ourney.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- LM Journey (all months)
COPY INTO LM_JOURNEY
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Ll][Mm].*[Jj]ourney.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- MM Journey (all months)
COPY INTO MM_JOURNEY
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Mm][Mm].*[Jj]ourney.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Daily Load (all months)
COPY INTO DAILY_LOAD
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Dd]aily.*[Ll]oad.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Weighted Utilization (use cleaned files from 07_prepare_wu_files.py)
COPY INTO WEIGHTED_UTILIZATION
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Ww]eighted.*_clean\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Dimension tables (load once)
COPY INTO DIM_HUB_CITY
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Hh]ub.*[Cc]ity.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

COPY INTO DIM_HUB_TO_ZONE
FROM @DATA_STAGE
FILE_FORMAT = (TYPE = 'PARQUET')
PATTERN = '.*[Hh]ub.*[Zz]one.*\.parquet'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Verify row counts
SELECT 'B2B_REVENUE' AS table_name, COUNT(*) AS row_count FROM B2B_REVENUE
UNION ALL SELECT 'AWB_FILE', COUNT(*) FROM AWB_FILE
UNION ALL SELECT 'FM_JOURNEY', COUNT(*) FROM FM_JOURNEY
UNION ALL SELECT 'LM_JOURNEY', COUNT(*) FROM LM_JOURNEY
UNION ALL SELECT 'MM_JOURNEY', COUNT(*) FROM MM_JOURNEY
UNION ALL SELECT 'DAILY_LOAD', COUNT(*) FROM DAILY_LOAD
UNION ALL SELECT 'WEIGHTED_UTILIZATION', COUNT(*) FROM WEIGHTED_UTILIZATION
UNION ALL SELECT 'DIM_HUB_CITY', COUNT(*) FROM DIM_HUB_CITY
UNION ALL SELECT 'DIM_HUB_TO_ZONE', COUNT(*) FROM DIM_HUB_TO_ZONE;
