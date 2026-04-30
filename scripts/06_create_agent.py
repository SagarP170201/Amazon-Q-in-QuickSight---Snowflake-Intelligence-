import snowflake.connector, os, json

conn = snowflake.connector.connect(connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME"))
cur = conn.cursor()

agent_spec = {
    "models": {"orchestration": "auto"},
    "orchestration": {"budget": {"seconds": 900, "tokens": 400000}},
    "instructions": {
        "response": (
            "Format responses in a professional, third-person, research-report style "
            "with clear headings and tables. For business summary: Summary, Unit Economics, "
            "Comparison/Trend, Business Interpretation. For ranking: Ranking Table, Unit Economics "
            "Snapshot, Short Interpretation. For RCA/investigation: Summary, Unit Economics, "
            "RCA Explanation, Benchmark Comparison, Operational Recommendations, Business Decision "
            "Statement. Round monetary values to 2 decimal places. Percentages to 1 decimal place. "
            "Do not expose internal reasoning. Output must read like a professional research report."
        ),
        "orchestration": (
            "You are the XpressBees B2B Profitability AI Agent - a senior cross-functional "
            "business investigator. Every answer must connect: commercial truth, operational cause, "
            "benchmark context, business interpretation, and action recommendation.\n"
            "TOOLS: 1. profitability_data - Query structured profitability data (revenue, cost, "
            "margin, volume, yield, CPK, customer/lane/territory analysis). Use for ANY question "
            "needing numbers. 2. xb_knowledge - Search XpressBees Guide (operational context, "
            "dashboard navigation, benchmarks) AND XpressBees System Prompt (RCA methodology, "
            "response format rules, execution logic, priority framework). ALWAYS search xb_knowledge "
            "FIRST before answering RCA, investigation, or complex analysis questions to retrieve "
            "the correct methodology and response structure.\n"
            "KEY RULES: - Before answering, classify: ranking query vs non-ranking query. "
            "This determines output format. - For RCA: search xb_knowledge for priority-based "
            "RCA framework, then query profitability_data. - Revenue = Net Charges. "
            "Margin = pre-calculated Margin column. Volume = TOT_CHRGWT (billed weight kg). "
            "- CPK = Total Cost / Billed Weight. Yield/RPK = Net Charges / Billed Weight. "
            "- All numeric columns are VARCHAR - always use TRY_TO_NUMBER() in SQL. "
            "- Cost breakdown: Pickup + Delivery + Linehaul + Midmile + Handling + Common + Other "
            "= Total Cost. - National vs Regional: Origin_Terr != Dest_Terr = National, "
            "same territory = Regional. Do NOT use Route column. "
            "- Lane/OD pair = Origin_City || '-' || Dest_City. "
            "- 10 lakhs = 1,000,000 INR. 1 crore = 10,000,000 INR. "
            "- For top N customers, always include revenue, margin, and volume. "
            "- Search xb_knowledge (filter DOC_NAME='XB_Prompt') to retrieve full response "
            "format rules and execution precedence logic."
        ),
        "sample_questions": "\n".join([
            "What is my overall business this month?",
            "Who are my top 10 customers by revenue?",
            "What is my overall yield this month?",
            "Which cost is driving the loss for the client?",
            "What is the national vs regional volume comparison?",
            "Top 10 negative margin customers with revenue more than 10 lacs?",
            "Top 10 negative margin lanes in National Linehaul?",
            "What is the cost breakdown?",
            "Which customer gives me maximum load on DEL-BLR lane?",
            "Top 5 OD pairs with the most negative margin?",
        ])
    },
    "tools": [
        {
            "tool_spec": {
                "type": "cortex_analyst_text_to_sql",
                "name": "profitability_data",
                "description": (
                    "Query XpressBees B2B logistics profitability data. Use for: revenue "
                    "(Net Charges), cost breakdowns (Pickup, Delivery, Linehaul, Midmile, "
                    "Handling, Common, Other costs), margin, volume (billed weight), yield/RPK, "
                    "CPK, customer rankings, lane/OD pair analysis, territory/zone analysis, "
                    "national vs regional comparisons, cost root cause analysis, and any question "
                    "requiring numerical data from the B2B_REVENUE table."
                )
            }
        },
        {
            "tool_spec": {
                "type": "cortex_search",
                "name": "xb_knowledge",
                "description": (
                    "Search XpressBees knowledge base containing two documents: "
                    "(1) XB_Guide - operational guide with RCA methodology, dashboard navigation "
                    "logic, benchmark comparison rules, operational context, and investigation "
                    "frameworks. (2) XB_Prompt - system prompt with response format standards, "
                    "execution precedence rules, priority-based RCA framework, completeness rules, "
                    "and analytical sequence requirements. Use DOC_NAME attribute to filter: "
                    "'XB_Guide' for operational knowledge, 'XB_Prompt' for behavior rules."
                )
            }
        }
    ],
    "tool_resources": {
        "profitability_data": {
            "execution_environment": {
                "query_timeout": 299,
                "type": "warehouse",
                "warehouse": "SNOW_INTELLIGENCE_DEMO_WH"
            },
            "semantic_view": "XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.XPRESSBEES_PROFITABILITY"
        },
        "xb_knowledge": {
            "execution_environment": {
                "query_timeout": 299,
                "type": "warehouse",
                "warehouse": "SNOW_INTELLIGENCE_DEMO_WH"
            },
            "search_service": "XPRESSBEES_PROFITABILITY.RAW.XB_DOCS_SEARCH"
        }
    }
}

spec_json = json.dumps(agent_spec, ensure_ascii=False)
escaped = spec_json.replace("'", "''")

comment = (
    "XpressBees B2B Profitability AI Agent - Analyzes revenue, cost, margin, yield, "
    "CPK across customers, lanes, and territories. Powered by Cortex Analyst "
    "(structured data) and Cortex Search (XB Guide + XB Prompt knowledge base)."
)

sql = f"""CREATE OR REPLACE AGENT XPRESSBEES_PROFITABILITY.AGENTS.XPRESSBEES_PROFITABILITY_AGENT
COMMENT = '{comment.replace("'", "''")}'
FROM SPECIFICATION '{escaped}'"""

try:
    cur.execute(sql)
    print("Agent created:", cur.fetchone())
except Exception as e:
    print("ERROR:", str(e)[:500])

cur.close()
conn.close()
print("Done! Register the agent in Snowflake Intelligence at ai.snowflake.com")
