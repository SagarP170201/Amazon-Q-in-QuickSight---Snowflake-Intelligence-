import snowflake.connector, os

conn = snowflake.connector.connect(connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME"))
cur = conn.cursor()
cur.execute("USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH")

yaml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'semantic_model', 'xpressbees_profitability_semantic_model.yaml')
yaml_path = os.path.abspath(yaml_path)

print(f"Uploading YAML from: {yaml_path}")
cur.execute(f"PUT file://{yaml_path} @XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS.SEMANTIC_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE")
print("Stage upload:", cur.fetchone())

with open(yaml_path, 'r') as f:
    yaml_content = f.read()

escaped = yaml_content.replace("'", "''")
sql = f"CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('XPRESSBEES_PROFITABILITY.SEMANTIC_MODELS', '{escaped}', FALSE)"

try:
    cur.execute(sql)
    print("Deploy:", cur.fetchone())
except Exception as e:
    print("ERROR:", str(e)[:500])

cur.close()
conn.close()
