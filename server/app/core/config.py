import json
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)


class Settings(BaseSettings):
    PROJECT_NAME: str = "Mobile Calendar API"
    MONGODB_URL: str
    DATABASE_NAME: str = "calendar_db"
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    BACKEND_CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080",
    ]
    RATE_LIMIT_REQUESTS: int = 10
    RATE_LIMIT_WINDOW_SECONDS: int = 60
    RATE_LIMIT_PATHS: list[str] = [
        "/api/v1/auth/login",
        "/api/v1/auth/register",
        "/api/v1/events/sync",
        "/api/v1/events/*",
        "/api/v1/categories/*",
    ]
    RATE_LIMIT_METHODS: list[str] = ["POST", "PATCH", "DELETE"]
    TRUST_PROXY_HEADERS: bool = False
    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, value: str) -> str:
        if len(value) < 32:
            raise ValueError("SECRET_KEY must be at least 32 characters long")
        return value

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Any) -> list[str]:
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return []
            if raw.startswith("["):
                parsed = json.loads(raw)
                return [str(origin).strip() for origin in parsed if str(origin).strip()]
            return [origin.strip() for origin in raw.split(",") if origin.strip()]
        if isinstance(value, list):
            return [str(origin).strip() for origin in value if str(origin).strip()]
        return []

    @field_validator("RATE_LIMIT_PATHS", mode="before")
    @classmethod
    def parse_rate_limit_paths(cls, value: Any) -> list[str]:
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return []
            if raw.startswith("["):
                parsed = json.loads(raw)
                return [str(path).strip() for path in parsed if str(path).strip()]
            return [path.strip() for path in raw.split(",") if path.strip()]
        if isinstance(value, list):
            return [str(path).strip() for path in value if str(path).strip()]
        return []

    @field_validator("RATE_LIMIT_METHODS", mode="before")
    @classmethod
    def parse_rate_limit_methods(cls, value: Any) -> list[str]:
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return []
            if raw.startswith("["):
                parsed = json.loads(raw)
                return [str(method).strip().upper() for method in parsed if str(method).strip()]
            return [method.strip().upper() for method in raw.split(",") if method.strip()]
        if isinstance(value, list):
            return [str(method).strip().upper() for method in value if str(method).strip()]
        return []


settings = Settings()
