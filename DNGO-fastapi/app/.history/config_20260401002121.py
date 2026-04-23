# app/config.py
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str

    # JWT
    JWT_SECRET: str
    JWT_ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_DAYS: int

    # VNPAY
    VNP_TMN_CODE: str
    VNP_HASH_SECRET: str
    VNP_URL: str
    VNP_RETURN_URL: str
    VNP_IPN_URL: str
    VNP_SECURE_HASH_TYPE: str = "HMACSHA512"

    # CORS
    CORS_ORIGINS: str

    # Server
    PORT: int
    DEBUG: bool

    # Map / other
    ORS_API_KEY: str

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }

settings = Settings()