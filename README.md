# Amazon Q in QuickSight → Snowflake Intelligence

Migration of **XpressBees B2B Profitability AI Agent** from Amazon Q/QuickSight to Snowflake Intelligence.

**Everything runs in Snowsight UI — no Python, CLI, or local tools required.**

---

## Quick Start

> **Prerequisites**: Snowflake account with `ACCOUNTADMIN` role, monthly data CSVs, XB Guide FINAL.docx, XB Prompt FINAL.docx.

| Step | What | How | Time |
|------|------|-----|------|
| **1** | Create database, schemas, warehouse | Open Snowsight → SQL Worksheet → paste & run `scripts/01_setup_database.sql` | 1 min |
| **2** | Create tables | SQL Worksheet → paste & run `scripts/02_create_tables.sql` | 1 min |
| **3** | Upload & load data | Upload CSVs to `DATA_STAGE` via Snowsight UI, then run COPY INTO from SQL Worksheet (see Step 3 below). Files stay on stage for re-loading/debugging. | 10-30 min |
| **4** | Deploy Semantic View | Upload YAML to stage via Snowsight UI, then run `scripts/04_deploy_semantic_view.sql`. **To edit later**: use the Semantic View editor in Snowsight (AI & ML → Semantic Views) to add/modify dimensions, metrics, and VQRs directly in the UI. | 1 min |
| **5** | Load knowledge docs | Extract text from .docx files → SQL Worksheet → paste & run `scripts/05_create_cortex_search.sql` (insert doc text where marked) | 5 min |
| **6** | Create Cortex Agent | SQL Worksheet → paste & run `scripts/06_create_agent.sql` | 1 min |
| **7** | Register in Intelligence | Go to `ai.snowflake.com` → Intelligence → Create → Select `XPRESSBEES_PROFITABILITY_AGENT` | 1 min |
| **8** | Test | Ask: *"What is my overall business this month?"* | Done! |

### Step 3 — Loading Data (Stage First, Then COPY INTO)

Upload CSVs to **internal stage first**, then COPY INTO tables. Files are retained on stage for re-loading, debugging, or deletion.

**Step 3a: Upload CSVs to Stage**
1. Go to **Snowsight** → **Data** → **Databases** → `XPRESSBEES_PROFITABILITY` → `RAW` → **Stages** → `DATA_STAGE`
2. Click **+ Files** (top right)
3. Create a folder for each month (e.g., `october_2025`, `november_2025`, etc.)
4. Upload all 7 CSV files for that month into the folder
5. Repeat for each month

**Step 3b: COPY INTO tables from stage**

Run in a SQL Worksheet — replace `<month>` with the folder name (e.g., `october_2025`):

```sql
USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

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

COPY INTO WEIGHTED_UTILIZATION FROM @DATA_STAGE/<month>/Weighted_Utilization.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';
```

**Dimension tables (upload once to stage root, load once):**

```sql
COPY INTO DIM_HUB_CITY FROM @DATA_STAGE/Hub-city_mapping.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';

COPY INTO DIM_HUB_TO_ZONE FROM @DATA_STAGE/Hub_to_zone_mapping.csv
  FILE_FORMAT = CSV_FORMAT MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = 'CONTINUE';
```

**Verify:**
```sql
SELECT 'B2B_REVENUE' AS tbl, COUNT(*) AS rows FROM B2B_REVENUE
UNION ALL SELECT 'AWB_FILE', COUNT(*) FROM AWB_FILE
UNION ALL SELECT 'FM_JOURNEY', COUNT(*) FROM FM_JOURNEY
UNION ALL SELECT 'LM_JOURNEY', COUNT(*) FROM LM_JOURNEY
UNION ALL SELECT 'MM_JOURNEY', COUNT(*) FROM MM_JOURNEY
UNION ALL SELECT 'DAILY_LOAD', COUNT(*) FROM DAILY_LOAD
UNION ALL SELECT 'WEIGHTED_UTILIZATION', COUNT(*) FROM WEIGHTED_UTILIZATION
UNION ALL SELECT 'DIM_HUB_CITY', COUNT(*) FROM DIM_HUB_CITY
UNION ALL SELECT 'DIM_HUB_TO_ZONE', COUNT(*) FROM DIM_HUB_TO_ZONE;
```

> **Why stage first?** Files are retained — you can re-load, debug, or delete and re-ingest anytime. `LIST @DATA_STAGE` shows all uploaded files. COPY INTO tracks loaded files and won't double-load.

**For each month (Oct'25 → Mar'26), load these 7 files:**

| CSV File | Target Table |
|----------|-------------|
| B2B_Revenue.csv | B2B_REVENUE |
| AWB_File.csv | AWB_FILE |
| FM_Journey.csv | FM_JOURNEY |
| LM_Journey.csv | LM_JOURNEY |
| MM_Journey.csv | MM_JOURNEY |
| Daily_Load.csv | DAILY_LOAD |
| Weighted_Utilization.csv | WEIGHTED_UTILIZATION |

**Dimension tables (load once, not per month):**

| CSV File | Target Table |
|----------|-------------|
| Hub-city_mapping.csv | DIM_HUB_CITY |
| Hub_to_zone_mapping.csv | DIM_HUB_TO_ZONE |

### Step 5 — Loading Knowledge Docs (Detailed)

1. Open `XB Guide FINAL.docx` and `XB Prompt FINAL.docx`
2. Select All → Copy the full text from each document
3. Open `scripts/05_create_cortex_search.sql` in a SQL Worksheet
4. Replace the `<PASTE_XB_GUIDE_TEXT_HERE>` and `<PASTE_XB_PROMPT_TEXT_HERE>` placeholders with the copied text
5. Run the script — it will chunk the text, load into DOC_CHUNKS, and create the Cortex Search Service

---

## Architecture

| Capability | AWS (Before) | Snowflake (After) |
|---|---|---|
| Data Warehouse | Amazon Redshift | Snowflake Tables |
| BI Dashboard | Amazon QuickSight | Snowflake Intelligence (ai.snowflake.com) |
| AI/NL Query Engine | Amazon Q in QuickSight | Cortex Analyst (Semantic View + VQRs) |
| AI Agent / Orchestration | Amazon Q Business | Cortex Agent |
| Knowledge Base / RAG | Amazon Kendra / Bedrock KB | Cortex Search Service |
| Semantic Data Layer | QuickSight Topics | Semantic View YAML |
| Document Storage | Amazon S3 | Snowflake Stages + Tables |
| LLM Backend | Amazon Bedrock | Snowflake Cortex LLM (built-in) |
| Access Control | IAM + QuickSight Permissions | Snowflake RBAC |
| Prompt Engineering | Q Business Guardrails | Agent Instructions + Cortex Search |

**Key advantage**: Everything in one platform — no cross-service orchestration, no IAM-to-QuickSight permission mapping, no S3-to-Redshift data pipelines.

## Components

```
┌─────────────────────────────────────────────────────────┐
│                 Snowflake Intelligence UI                │
│              (ai.snowflake.com / Chat Interface)         │
└──────────────────────┬──────────────────────────────────┘
                       │
              ┌────────▼────────┐
              │  Cortex Agent   │
              │  (Orchestrator) │
              └───┬─────────┬───┘
                  │         │
     ┌────────────▼──┐  ┌──▼──────────────┐
     │profitability   │  │ xb_knowledge    │
     │_data           │  │ (Cortex Search) │
     │(Cortex Analyst)│  │                 │
     └───────┬────────┘  └────────┬────────┘
             │                    │
    ┌────────▼────────┐  ┌───────▼─────────┐
    │ Semantic View   │  │ DOC_CHUNKS      │
    │ (16 VQRs,       │  │ (76 chunks)     │
    │  18 dims,       │  │ XB Guide +      │
    │  22 facts,      │  │ XB Prompt       │
    │  15 metrics)    │  │                 │
    └────────┬────────┘  └─────────────────┘
             │
    ┌────────▼────────┐
    │ 9 Data Tables   │
    │ (B2B_REVENUE,   │
    │  AWB_FILE, etc) │
    └─────────────────┘
```

### Agent Tools

| Tool | Type | Purpose |
|------|------|---------|
| `profitability_data` | Cortex Analyst (Semantic View) | Converts natural language → SQL → runs queries on profitability data |
| `xb_knowledge` | Cortex Search Service | Searches XB Guide (operational playbook) + XB Prompt (agent behavior rules) |

## Data Model

### Tables (in `XPRESSBEES_PROFITABILITY.RAW`)

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `B2B_REVENUE` | Primary fact table — AWB-level revenue, cost, margin | AWB No, Client Name, Net Charges, Total Cost, Margin, TOT_CHRGWT |
| `AWB_FILE` | AWB to Promised Delivery Date mapping | parentawbno, pdd |
| `FM_JOURNEY` | First mile journey details | AWB, FM_TRIPID, ORIGINHUB, PICKUPDATE |
| `LM_JOURNEY` | Last mile journey details | AWB, LM_TRIPID, DESTHUB, DELIVERYDATETIME |
| `MM_JOURNEY` | Mid-mile journey details | AWB, MM_TRIPID |
| `DAILY_LOAD` | Daily load utilization | (not in semantic view — for future use) |
| `WEIGHTED_UTILIZATION` | Weighted utilization metrics | (not in semantic view — for future use) |
| `DIM_HUB_CITY` | Hub to city/territory mapping | HubName, HubCity, Territory |
| `DIM_HUB_TO_ZONE` | Hub to zone mapping | hubname, hubzonename |
| `DOC_CHUNKS` | Chunked XB Guide + XB Prompt docs | CHUNK_TEXT, DOC_NAME, CHUNK_ID |

### Key Metrics

| Metric | Formula |
|--------|---------|
| Revenue | `SUM(TRY_TO_NUMBER("Net Charges", 18, 2))` |
| Margin | `SUM(TRY_TO_NUMBER("Margin", 18, 2))` |
| Margin % | `SUM(Margin) / NULLIF(SUM(Net Charges), 0) * 100` |
| CPK (Cost Per Kg) | `SUM(Total Cost) / NULLIF(SUM(TOT_CHRGWT), 0)` |
| Yield / RPK | `SUM(Net Charges) / NULLIF(SUM(TOT_CHRGWT), 0)` |
| Volume | `SUM(TOT_CHRGWT)` (billed weight in kg) |

### Important Data Notes

- **All numeric columns are stored as VARCHAR** — always use `TRY_TO_NUMBER()` for aggregations
- **National vs Regional**: `Origin_Terr != Dest_Terr` = National, same territory = Regional. Do NOT use Route column (it's "Surface" for all rows)
- **10 lakhs = 1,000,000 INR**, **1 crore = 10,000,000 INR**

## Handover Checklist

### Done (POC — Feb 2026 data)
- [x] Database, schemas, warehouse, stages created
- [x] 9 tables created and loaded with Feb 2026 data
- [x] Semantic View deployed with 16 VQRs, 18 dimensions, 22 facts, 15 metrics
- [x] Cortex Search Service created (XB Guide + XB Prompt — 76 chunks)
- [x] Cortex Agent created with 2 tools (profitability_data + xb_knowledge)
- [x] Agent registered in Snowflake Intelligence
- [x] 19 of 38 questions answerable and tested

### Remaining (Customer)
- [ ] Load Oct'25 → Mar'26 data (6 months) via Snowsight UI (Step 3 above)
- [ ] Add 19 multi-month VQRs — use the Semantic View editor in Snowsight (AI & ML → Semantic Views → edit) to add VQRs directly in the UI, or edit the YAML and re-run `scripts/04_deploy_semantic_view.sql`
- [ ] Re-deploy semantic view after adding VQRs (re-run `scripts/04_deploy_semantic_view.sql`)
- [ ] Test all 38 questions end-to-end (see `docs/test_questions.md`)
- [ ] Set up RBAC roles and grants (see below)
- [ ] Establish monthly data refresh process

### RBAC Setup (run in SQL Worksheet)

```sql
CREATE ROLE IF NOT EXISTS XB_PROFITABILITY_VIEWER;
GRANT USAGE ON DATABASE XPRESSBEES_PROFITABILITY TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.RAW TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.AGENTS TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON AGENT XPRESSBEES_PROFITABILITY.AGENTS.XPRESSBEES_PROFITABILITY_AGENT TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH TO ROLE XB_PROFITABILITY_VIEWER;
GRANT ROLE XB_PROFITABILITY_VIEWER TO USER <username>;
```

## File Structure

```
├── README.md                          # This file
├── semantic_model/
│   └── xpressbees_profitability_semantic_model.yaml  # Semantic view YAML (16 VQRs)
├── scripts/
│   ├── 01_setup_database.sql          # Database, schema, warehouse setup
│   ├── 02_create_tables.sql           # Table DDL for all 9 tables
│   ├── 04_deploy_semantic_view.sql    # Deploy semantic view from YAML
│   ├── 05_create_cortex_search.sql    # Chunk docs + create search service
│   └── 06_create_agent.sql            # Create cortex agent with 2 tools
└── docs/
    └── test_questions.md              # All 38 test questions across 3 tabs
```

> **Note**: No Step 03 script — data loading is done via Snowsight UI drag-drop (see Step 3 above).

## VQR Validation Guide

The 35 Verified Queries (VQRs) in the semantic view are **syntactically valid SQL templates**, but they have NOT been validated against ground truth. Your domain team must verify them before considering them production-ready.

### Why Manual Validation is Required

- VQRs were built from sample data (few months), not the full dataset
- "Verified" in Snowflake means **human-approved** — the system does not auto-validate correctness
- Only your team knows what the "right answer" should be (compare against existing QuickSight/Amazon Q reports)

### How to Validate (Two Approaches)

#### Approach A: SQL Worksheet (Recommended for Bulk Validation)

1. Open a **Snowsight SQL Worksheet**
2. Copy a VQR's SQL from the YAML file (under each `verified_queries:` → `sql:` field)
3. Paste and run in the worksheet
4. Compare the output against your source-of-truth report (QuickSight, Excel, etc.)
5. If results match → VQR is validated ✅
6. If results don't match → fix the SQL in the YAML or remove the VQR

#### Approach B: Snowflake Intelligence Chat (Tests Full AI Pipeline)

1. Open **Snowflake Intelligence** → Select the agent
2. Ask the natural language question (the `question:` field from the VQR)
3. Check if the AI-generated answer matches your expectations
4. This tests both the VQR matching AND the AI interpretation

#### Approach C: UI Semantic View Editor (Guided Experience)

1. Go to **Snowsight** → **AI & ML** → **Semantic Views**
2. Open `XPRESSBEES_PROFITABILITY`
3. Navigate to **Verified Queries** tab
4. Add/edit VQRs interactively with built-in validation flow
5. You can copy SQL from our YAML into the UI editor for guided validation

### Validation Checklist

| # | Action | Status |
|---|--------|--------|
| 1 | Load ALL months of data into tables | ☐ |
| 2 | Run 3-4 VQRs in worksheet, compare to QuickSight reports | ☐ |
| 3 | If results match, proceed to bulk validate remaining VQRs | ☐ |
| 4 | Remove or fix any VQR that returns incorrect results | ☐ |
| 5 | Test via Snowflake Intelligence chat for natural language accuracy | ☐ |

### Header/Column Validation (Before Loading New Months)

If loading data for months you haven't tested before, verify CSV headers match table columns:

```sql
-- Check table columns
SELECT COLUMN_NAME FROM XPRESSBEES_PROFITABILITY.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME = '<TABLE_NAME>'
ORDER BY ORDINAL_POSITION;

-- If COPY INTO fails with column mismatch, compare CSV headers vs table DDL
-- Fix with: ALTER TABLE ... RENAME COLUMN "old_name" TO "new_name";
```

### Important Notes

- VQRs using relative dates (`DATEADD(MONTH, -3, CURRENT_DATE())`) will return different results depending on when you run them — this is expected
- If a VQR returns 0 rows, it likely means that month's data hasn't been loaded yet
- `TRY_TO_NUMBER()` will return NULL for non-numeric values — check for unexpected NULLs in aggregations

---

## Trial → Production Migration (Git Integration)

Use Snowflake's native Git Integration to sync this repo directly into your production account. This eliminates manual file uploads — any future YAML or script updates are available instantly via stage refresh.

### One-Time Setup (5 min)

**Step 1: Create API Integration (ACCOUNTADMIN)**
```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/SagarP170201')
  ENABLED = TRUE;
```

**Step 2: Create Git Repository**
```sql
CREATE OR REPLACE GIT REPOSITORY XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO
  API_INTEGRATION = git_api_integration
  ORIGIN = 'https://github.com/SagarP170201/Amazon-Q-in-QuickSight---Snowflake-Intelligence-.git';
```

**Step 3: Fetch Latest**
```sql
ALTER GIT REPOSITORY XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO FETCH;
```

**Step 4: Verify Files**
```sql
SHOW GIT BRANCHES IN XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO;

LS @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO/branches/main/;
```

### Deploy from Git Repo

**Run setup scripts directly from the repo stage:**
```sql
-- Run any script from the repo
EXECUTE IMMEDIATE FROM @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO/branches/main/scripts/01_setup_database.sql;
EXECUTE IMMEDIATE FROM @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO/branches/main/scripts/02_create_tables.sql;
```

**Deploy Semantic View from Git repo:**
```sql
CREATE OR REPLACE SEMANTIC VIEW XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XPRESSBEES_PROFITABILITY
  FROM @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO/branches/main/semantic_model/xpressbees_profitability_semantic_model.yaml;
```

### Ongoing Updates

Whenever a fix is pushed to GitHub (e.g., date format fix, new VQRs):
```sql
-- Pull latest changes
ALTER GIT REPOSITORY XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO FETCH;

-- Re-deploy semantic view
CREATE OR REPLACE SEMANTIC VIEW XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XPRESSBEES_PROFITABILITY
  FROM @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XB_REPO/branches/main/semantic_model/xpressbees_profitability_semantic_model.yaml;
```

> **Note**: Data (CSVs) still needs to be loaded separately via `DATA_STAGE` — Git Integration handles scripts and YAML only, not data files.

---

## Key Technical Learnings

| Issue | Fix |
|-------|-----|
| Semantic View YAML `verified_query:` field | Use `sql:` (not `verified_query:`) |
| Missing `data_type` in dimensions | Add `data_type: TEXT` to all dims, `NUMBER` to facts |
| `primary_key` format error | Must be `primary_key: {columns: ["col"]}` (object, not string) |
| `one_to_many` relationship type | Only `many_to_one` and `one_to_one` supported — swap left/right tables |
| Agent instruction size limit (48K) | Put full docs in Cortex Search, keep agent instructions concise |
| Route column = "Surface" for all rows | Use `Origin_Terr != Dest_Terr` for National vs Regional |
| VARCHAR numeric columns | Always wrap in `TRY_TO_NUMBER()` for aggregations |
