-- XpressBees Profitability AI Agent - Data Loading
-- ============================================================
-- IMPORTANT: Replace <month> with actual folder name (e.g., "February 2026")
-- IMPORTANT: PUT commands CANNOT run in Snowsight. Use SnowSQL or Python.
-- Data is APPENDED — safe to run multiple times for different months.
-- ============================================================

-- Step 1: Upload files to stage
-- Run these from SnowSQL CLI (NOT Snowsight — PUT is not supported in Snowsight):
--
--   snowsql -c <your_connection>
--
-- Then run:
--   PUT file:///path/to/<month>/B2B_Revenue.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/AWB_File.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/FM_Journey.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/LM_Journey.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/MM_Journey.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/Daily_Load.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/<month>/Weighted_Utilization.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--
-- Alternatively, upload files via Snowsight UI: Data → Databases → RAW → DATA_STAGE → Upload

-- Step 2: Load data into tables (run in Snowsight or SnowSQL)
-- Replace <month> below with the actual folder name you used in PUT above

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

COPY INTO B2B_REVENUE
FROM @DATA_STAGE/<month>/B2B_Revenue.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO AWB_FILE
FROM @DATA_STAGE/<month>/AWB_File.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO FM_JOURNEY
FROM @DATA_STAGE/<month>/FM_Journey.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO LM_JOURNEY
FROM @DATA_STAGE/<month>/LM_Journey.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO MM_JOURNEY
FROM @DATA_STAGE/<month>/MM_Journey.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO DAILY_LOAD
FROM @DATA_STAGE/<month>/Daily_Load.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO WEIGHTED_UTILIZATION
FROM @DATA_STAGE/<month>/Weighted_Utilization.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Dimension tables (load ONCE — not per month)
-- Upload via SnowSQL:
--   PUT file:///path/to/Hub-city_mapping.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/Hub_to_zone_mapping.csv @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

COPY INTO DIM_HUB_CITY
FROM @DATA_STAGE/Hub-city_mapping.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO DIM_HUB_TO_ZONE
FROM @DATA_STAGE/Hub_to_zone_mapping.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Step 3: Verify row counts
SELECT 'B2B_REVENUE' AS tbl, COUNT(*) AS rows FROM B2B_REVENUE
UNION ALL SELECT 'AWB_FILE', COUNT(*) FROM AWB_FILE
UNION ALL SELECT 'FM_JOURNEY', COUNT(*) FROM FM_JOURNEY
UNION ALL SELECT 'LM_JOURNEY', COUNT(*) FROM LM_JOURNEY
UNION ALL SELECT 'MM_JOURNEY', COUNT(*) FROM MM_JOURNEY
UNION ALL SELECT 'DAILY_LOAD', COUNT(*) FROM DAILY_LOAD
UNION ALL SELECT 'WEIGHTED_UTILIZATION', COUNT(*) FROM WEIGHTED_UTILIZATION
UNION ALL SELECT 'DIM_HUB_CITY', COUNT(*) FROM DIM_HUB_CITY
UNION ALL SELECT 'DIM_HUB_TO_ZONE', COUNT(*) FROM DIM_HUB_TO_ZONE;
