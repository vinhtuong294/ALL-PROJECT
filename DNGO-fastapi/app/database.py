from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings




# Tạo engine kết nối PostgreSQL
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    pool_recycle=1800,
    pool_timeout=20,
    echo=False,
    connect_args={
        "timeout": 30  # pg8000 uses 'timeout' instead of 'connect_timeout'
    }
)








# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)




# Base class cho models
Base = declarative_base()








# Dependency để lấy database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()