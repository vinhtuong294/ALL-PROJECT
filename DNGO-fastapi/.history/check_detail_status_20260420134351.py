import psycopg2
from collections import Counter

# Database connection
conn = psycopg2.connect(
    host="207.180.233.84",
    port="5432",
    database="dngo",
    user="dtrinh",
    password="DNgodue"
)

cur = conn.cursor()

# Check what detail_status values exist
cur.execute("SELECT detail_status, COUNT(*) FROM order_detail GROUP BY detail_status;")
results = cur.fetchall()

print("Current detail_status values in database:")
for status, count in results:
    print(f"  - '{status}': {count} rows")

cur.close()
conn.close()
