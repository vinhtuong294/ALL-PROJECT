import sqlite3
import pandas as pd
conn = sqlite3.connect('DNGO-fastapi/app/database.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [t[0] for t in cursor.fetchall()]
print("Tables:", tables)
for table in tables:
    cursor.execute(f"SELECT COUNT(*) FROM {table};")
    count = cursor.fetchone()[0]
    print(f"Table {table}: {count} rows")
