import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

class Settings(BaseSettings):
    PROJECT_NAME: str = "Mobile Calendar API"
    MONGODB_URL: str 
    DATABASE_NAME: str = "calendar_db"
    SECRET_KEY: str = "SUPER_SECRET_KEY"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    class Config:
        env_file = ".env" 
        extra = "ignore"

settings = Settings()