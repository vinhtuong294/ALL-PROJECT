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
        "connect_timeout": 30,  # Tăng lên 30s để ổn định hơn với remote DB
        "options": "-c statement_timeout=25000"  # Timeout query sau 25s
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