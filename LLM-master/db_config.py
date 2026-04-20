"""
db_config.py – Cau hinh ket noi PostgreSQL.
Doc tu bien moi truong (khuyen nghi) hoac fallback ve gia tri mac dinh.
"""
import os
from sqlalchemy import create_engine

# Uu tien bien moi truong, fallback ve gia tri cung neu khong co .env
DB_HOST     = os.getenv("DB_HOST",     "207.180.233.84")
DB_PORT     = os.getenv("DB_PORT",     "5432")
DB_NAME     = os.getenv("DB_NAME",     "dngo")
DB_USER     = os.getenv("DB_USER",     "dtrinh")
DB_PASSWORD = os.getenv("DB_PASSWORD", "DNgodue")

def get_engine():
    url = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    return create_engine(url, pool_pre_ping=True, pool_size=5, max_overflow=10)