from sqlalchemy import create_engine

DB_CONFIG = {
    "host":     "207.180.233.84",
    "port":     5432,
    "database": "dngo",
    "user":     "dtrinh",
    "password": "DNgodue"    # ← password mới
}

def get_engine():
    url = (
        f"postgresql+psycopg2://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
        f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )
    return create_engine(url)