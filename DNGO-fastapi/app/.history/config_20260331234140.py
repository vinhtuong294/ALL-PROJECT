from pydantic_settings import BaseSettings
from typing import List




class Settings(BaseSettings):
    # =========================
    # Database
    # =========================
    DATABASE_URL: str = "postgresql://dtrinh:DNgodue@207.180.233.84:5432/dngo"


    # =========================
    # JWT
    # =========================
    JWT_SECRET: str = "your-super-secret-jwt-key-change-this"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7


    # =========================
    # VNPAY
    # =========================
    VNP_TMN_CODE: str
    VNP_HASH_SECRET: str
    VNP_URL: str
    VNP_RETURN_URL: str
    VNP_SECURE_HASH_TYPE: str = "HMACSHA512"


    # =========================
    # CORS
    # =========================
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"


    # =========================
    # Server
    # =========================
    PORT: int = 8000
    DEBUG: bool = False  # Tắt debug để tăng performance


    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]


    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",  # tránh lỗi extra_forbidden
    }

from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    ORS_API_KEY: str

    class Config:
        env_file = ".env"



settings = Settings()
