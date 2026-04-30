import os, sys, csv, tempfile

guide_path = os.environ.get("XB_GUIDE_PATH", "XB Guide FINAL.docx")
prompt_path = os.environ.get("XB_PROMPT_PATH", "XB Prompt FINAL.docx")

if not os.path.exists(guide_path) or not os.path.exists(prompt_path):
    print("ERROR: Place 'XB Guide FINAL.docx' and 'XB Prompt FINAL.docx' in current directory")
    print("Or set XB_GUIDE_PATH and XB_PROMPT_PATH environment variables")
    sys.exit(1)

try:
    from docx import Document
except ImportError:
    print("ERROR: python-docx not installed. Run: pip install python-docx")
    sys.exit(1)

def extract_text_from_docx(path):
    doc = Document(path)
    return "\n".join([p.text for p in doc.paragraphs if p.text.strip()])

def chunk_text(text, chunk_size=1500, overlap=200):
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start = end - overlap
    return chunks

print("Extracting text from documents...")
guide_text = extract_text_from_docx(guide_path)
prompt_text = extract_text_from_docx(prompt_path)
print(f"  XB Guide: {len(guide_text)} chars")
print(f"  XB Prompt: {len(prompt_text)} chars")

print("Chunking documents...")
guide_chunks = chunk_text(guide_text)
prompt_chunks = chunk_text(prompt_text)
print(f"  XB Guide: {len(guide_chunks)} chunks")
print(f"  XB Prompt: {len(prompt_chunks)} chunks")

csv_path = os.path.join(tempfile.gettempdir(), "doc_chunks.csv")
with open(csv_path, 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(["DOC_NAME", "CHUNK_ID", "CHUNK_TEXT"])
    for i, c in enumerate(guide_chunks):
        w.writerow(["XB_Guide", i, c])
    for i, c in enumerate(prompt_chunks):
        w.writerow(["XB_Prompt", i, c])

total = len(guide_chunks) + len(prompt_chunks)
print(f"Total chunks: {total}")
print(f"CSV written to: {csv_path}")

import snowflake.connector
conn = snowflake.connector.connect(connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME"))
cur = conn.cursor()

print("Loading chunks into DOC_CHUNKS table...")
cur.execute("USE DATABASE XPRESSBEES_PROFITABILITY")
cur.execute("USE SCHEMA RAW")
cur.execute("USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH")
cur.execute("TRUNCATE TABLE IF EXISTS DOC_CHUNKS")
cur.execute(f"PUT file://{csv_path} @DATA_STAGE/docs/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE")
cur.execute("""
COPY INTO DOC_CHUNKS FROM @DATA_STAGE/docs/doc_chunks.csv
FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE'
""")
print("Loaded:", cur.fetchone())

print("Creating Cortex Search Service...")
cur.execute("""
CREATE OR REPLACE CORTEX SEARCH SERVICE XB_DOCS_SEARCH
  ON CHUNK_TEXT
  ATTRIBUTES DOC_NAME
  WAREHOUSE = SNOW_INTELLIGENCE_DEMO_WH
  TARGET_LAG = '1 hour'
  AS (SELECT CHUNK_TEXT, DOC_NAME FROM DOC_CHUNKS)
""")
print("Cortex Search Service created:", cur.fetchone())

cur.close()
conn.close()
print("Done!")
