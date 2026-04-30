# Amazon Q in QuickSight → Snowflake Intelligence

Migration of **XpressBees B2B Profitability AI Agent** from Amazon Q/QuickSight to Snowflake Intelligence.

---

## Quick Start (Start Here)

> **Prerequisites**: Snowflake account with `ACCOUNTADMIN` role, Python 3.8+, monthly data CSVs, XB Guide FINAL.docx, XB Prompt FINAL.docx.
>
> ```bash
> pip install -r requirements.txt   # installs snowflake-connector-python, python-docx
> ```

| Step | What | How | Time |
|------|------|-----|------|
| **1** | Create database, schemas, warehouse | Run `scripts/01_setup_database.sql` in Snowsight | 1 min |
| **2** | Create all 9 tables | Run `scripts/02_create_tables.sql` in Snowsight | 1 min |
| **3** | Upload & load data | Upload CSVs via SnowSQL (`PUT`) or Snowsight UI, then run `scripts/03_load_data.sql` per month (replace `<month>` with folder name). **Note: PUT commands cannot run in Snowsight — use SnowSQL CLI or upload via Snowsight UI.** | 10-30 min |
| **4** | Deploy Semantic View | `SNOWFLAKE_CONNECTION_NAME=<conn> python3 scripts/04_deploy_semantic_view.py` | 1 min |
| **5** | Create Cortex Search | Place both .docx files in current dir, run `SNOWFLAKE_CONNECTION_NAME=<conn> python3 scripts/05_create_cortex_search.py` | 2 min |
| **6** | Create Cortex Agent | `SNOWFLAKE_CONNECTION_NAME=<conn> python3 scripts/06_create_agent.py` | 1 min |
| **7** | Register in Snowflake Intelligence | Go to `ai.snowflake.com` → Intelligence → Create → Select `XPRESSBEES_PROFITABILITY_AGENT` | 1 min |
| **8** | Test | Ask: *"What is my overall business this month?"* | Done! |

> **Note**: Replace `<conn>` with your Snowflake connection name. To find available connections, run `snow connection list` in your terminal.

> **Data Loading**: For Oct'25–Mar'26, repeat Step 3 for each month. CSVs should match the column structure in `02_create_tables.sql`. Data is appended — do NOT truncate tables between months.

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
| `DOC_CHUNKS` | Chunked XB Guide + XB Prompt docs | CHUNK_TEXT, DOC_NAME, CHUNK_INDEX |

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

## Setup Instructions

### Prerequisites

- Snowflake account with `ACCOUNTADMIN` role
- Python 3.8+ with `snowflake-connector-python`
- Source data files (monthly CSVs for each table)
- XB Guide FINAL.docx and XB Prompt FINAL.docx

### Step 1: Database and Schema Setup

```sql
-- Run scripts/01_setup_database.sql
CREATE DATABASE IF NOT EXISTS XPRESSBEES_PROFITABILITY;
CREATE SCHEMA IF NOT EXISTS XPRESSBEES_PROFITABILITY.RAW;
CREATE SCHEMA IF NOT EXISTS XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS;
CREATE SCHEMA IF NOT EXISTS XPRESSBEES_PROFITABILITY.AGENTS;

CREATE WAREHOUSE IF NOT EXISTS SNOW_INTELLIGENCE_DEMO_WH
  WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 300 AUTO_RESUME = TRUE;

-- Enable cross-region Cortex (required for ap-southeast region)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';
```

### Step 2: Create Tables and Load Data

```sql
-- Run scripts/02_create_tables.sql
-- Then load data using scripts/03_load_data.sql
-- See scripts/ directory for complete SQL
```

### Step 3: Deploy Semantic View

```bash
# Run the deployment script
SNOWFLAKE_CONNECTION_NAME=<your_connection> python3 scripts/04_deploy_semantic_view.py
```

### Step 4: Create Cortex Search Service

```bash
# Chunk the XB Guide and XB Prompt documents, then create search service
SNOWFLAKE_CONNECTION_NAME=<your_connection> python3 scripts/05_create_cortex_search.py
```

### Step 5: Create Cortex Agent

```bash
# Create the agent with both tools
SNOWFLAKE_CONNECTION_NAME=<your_connection> python3 scripts/06_create_agent.py
```

### Step 6: Register in Snowflake Intelligence

1. Go to `ai.snowflake.com`
2. Navigate to Intelligence → Create
3. Select `XPRESSBEES_PROFITABILITY_AGENT`
4. Test with: "What is my overall business this month?"

## Scaling to Production (All 12 Months)

### Phase 1: Load All Monthly Data

For each month (Apr'25 → Mar'26):

```sql
-- Upload files to stage
PUT file:///path/to/<month>/B2B_Revenue.csv @RAW.DATA_STAGE/<month>/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- Repeat for AWB_File, FM_Journey, LM_Journey, MM_Journey, Daily_Load, Weighted_Utilization

-- Load into tables (APPEND — do NOT truncate)
COPY INTO RAW.B2B_REVENUE FROM @RAW.DATA_STAGE/<month>/B2B_Revenue.csv
  FILE_FORMAT = RAW.CSV_FORMAT ON_ERROR = 'CONTINUE';
-- Repeat for each table
```

### Phase 2: Add Multi-Month VQRs

The following 19 questions require multi-month data. Add VQRs to the semantic model YAML:

| # | Question | Months Needed |
|---|----------|---------------|
| 1 | What was my business last month? | 2 |
| 2 | What was my business in the last 3 months? | 3 |
| 3 | What was my business this quarter? | 3 |
| 4 | What is my YTD business? | 12 |
| 5 | Top 20 uptrading customers (by revenue) Jan vs Dec | 2 |
| 6 | Top 20 downtrading customers (by revenue) Jan vs Dec | 2 |
| 7 | New customers added this month vs last month | 2 |
| 8 | Which customers have potential for growth? | metadata |
| 9 | Which customers' yield dropped last month vs prior month? | 2 |
| 10 | Top 10 customers (>10L) whose yield dropped Jan vs Apr'25 | 10 |
| 11 | Uptrading/downtrading status yesterday | daily |
| 12 | Uptrading/downtrading last 7 days | daily |
| 13 | YoY growth for top clients | 12+ |
| 14 | Revenue/RPK/Yield/Volume trend Apr'25 to Jan'26 | 10 |
| 15 | Trend of National vs Regional for top 10 customers | 10 |
| 16 | Customers who went from negative to positive margin | 2+ |
| 17 | Customers who went from positive to negative margin | 2+ |
| 18 | How can I improve margin for a specific customer? | RCA |
| 19 | What operational changes needed for margin improvement? | RCA |

After adding VQRs, re-deploy:

```bash
SNOWFLAKE_CONNECTION_NAME=<your_connection> python3 scripts/04_deploy_semantic_view.py
```

### Phase 3: Test & Validate

Test all 35 questions from the three tabs (Questions, Uday sir, Mayank sir). See `docs/test_questions.md` for the complete list.

### Phase 4: Access & Governance

```sql
-- Create roles
CREATE ROLE IF NOT EXISTS XB_PROFITABILITY_VIEWER;
CREATE ROLE IF NOT EXISTS XB_PROFITABILITY_ANALYST;

-- Grant database access
GRANT USAGE ON DATABASE XPRESSBEES_PROFITABILITY TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.RAW TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS TO ROLE XB_PROFITABILITY_VIEWER;
GRANT USAGE ON SCHEMA XPRESSBEES_PROFITABILITY.AGENTS TO ROLE XB_PROFITABILITY_VIEWER;

-- Grant agent access
GRANT USAGE ON AGENT XPRESSBEES_PROFITABILITY.AGENTS.XPRESSBEES_PROFITABILITY_AGENT TO ROLE XB_PROFITABILITY_VIEWER;

-- Grant warehouse
GRANT USAGE ON WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH TO ROLE XB_PROFITABILITY_VIEWER;

-- Assign to users
GRANT ROLE XB_PROFITABILITY_VIEWER TO USER <username>;
```

## Handover Checklist (What's Done vs What's Remaining)

### Done (POC — Feb 2026 data)
- [x] Database, schemas, warehouse, stages created
- [x] 9 tables created and loaded with Feb 2026 data
- [x] Semantic View deployed with 16 VQRs, 18 dimensions, 22 facts, 15 metrics
- [x] Cortex Search Service created (XB Guide + XB Prompt — 76 chunks)
- [x] Cortex Agent created with 2 tools (profitability_data + xb_knowledge)
- [x] Agent registered in Snowflake Intelligence
- [x] 19 of 38 questions answerable and tested

### Remaining (Customer)
- [ ] Load Oct'25 → Mar'26 data (6 months) using Step 3 above
- [ ] Add 19 multi-month VQRs to `semantic_model/xpressbees_profitability_semantic_model.yaml` (see Phase 2 above)
- [ ] Re-deploy semantic view after adding VQRs (`python3 scripts/04_deploy_semantic_view.py`)
- [ ] Test all 38 questions end-to-end (see `docs/test_questions.md`)
- [ ] Set up RBAC roles and grants (see Phase 4 above)
- [ ] Establish monthly data refresh process

## File Structure

```
├── README.md                          # This file
├── semantic_model/
│   └── xpressbees_profitability_semantic_model.yaml  # Semantic view YAML (16 VQRs)
├── scripts/
│   ├── 01_setup_database.sql          # Database, schema, warehouse setup
│   ├── 02_create_tables.sql           # Table DDL for all 9 tables
│   ├── 03_load_data.sql               # COPY INTO statements for data loading
│   ├── 04_deploy_semantic_view.py     # Deploy/re-deploy semantic view
│   ├── 05_create_cortex_search.py     # Chunk docs + create search service
│   └── 06_create_agent.py             # Create cortex agent with 2 tools
└── docs/
    └── test_questions.md              # All 35 test questions across 3 tabs
```

## Key Technical Learnings

| Issue | Fix |
|-------|-----|
| Semantic View YAML `verified_query:` field | Use `sql:` (not `verified_query:`) |
| Missing `data_type` in dimensions | Add `data_type: TEXT` to all dims, `NUMBER` to facts |
| `primary_key` format error | Must be `primary_key: {columns: ["col"]}` (object, not string) |
| `one_to_many` relationship type | Only `many_to_one` and `one_to_one` supported — swap left/right tables |
| `$$` delimiter breaks YAML deploy | Use single-quoted escaped YAML via Python connector |
| Agent instruction size limit (48K) | Put full docs in Cortex Search, keep agent instructions concise |
| Route column = "Surface" for all rows | Use `Origin_Terr != Dest_Terr` for National vs Regional |
| VARCHAR numeric columns | Always wrap in `TRY_TO_NUMBER()` for aggregations |
