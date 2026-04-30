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
| **3** | Upload & load data | Snowsight → Data → Add Data → Load Files into Table (drag-drop CSVs per table, per month) | 10-30 min |
| **4** | Deploy Semantic View | Upload YAML to stage via Snowsight UI, then run `scripts/04_deploy_semantic_view.sql`. **To edit later**: use the Semantic View editor in Snowsight (AI & ML → Semantic Views) to add/modify dimensions, metrics, and VQRs directly in the UI. | 1 min |
| **5** | Load knowledge docs | Extract text from .docx files → SQL Worksheet → paste & run `scripts/05_create_cortex_search.sql` (insert doc text where marked) | 5 min |
| **6** | Create Cortex Agent | SQL Worksheet → paste & run `scripts/06_create_agent.sql` | 1 min |
| **7** | Register in Intelligence | Go to `ai.snowflake.com` → Intelligence → Create → Select `XPRESSBEES_PROFITABILITY_AGENT` | 1 min |
| **8** | Test | Ask: *"What is my overall business this month?"* | Done! |

### Step 3 — Loading Data via Snowsight UI (Detailed)

Since there are no PUT commands or Python scripts, load data entirely through the Snowsight UI:

1. Go to **Snowsight** → **Data** → **Databases** → `XPRESSBEES_PROFITABILITY` → `RAW`
2. Click on a table (e.g., `B2B_REVENUE`)
3. Click **Load Data** (top right)
4. Select warehouse: `SNOW_INTELLIGENCE_DEMO_WH`
5. Drag-drop or browse to the CSV file for that table
6. Select file format: `CSV_FORMAT` (already created in Step 1 — uses `PARSE_HEADER = TRUE`)
7. Set **Match by column name**: `CASE_INSENSITIVE` (this ensures column order in CSV doesn't matter)
8. Click **Load**
8. Repeat for each table, for each month

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
