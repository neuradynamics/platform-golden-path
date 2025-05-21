from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable integration."""

    class Config:
        """Configuration for the settings."""
        case_sensitive = True
        env_file = ".env"
        extra = "ignore"  # Allow extra fields

    # Database settings
    DATABASE_URL: str
    
    # Server settings
    ENVIRONMENT: str = "dev"
    SECRET_KEY: str
    
    # CORS settings
    ALLOWED_ORIGIN_1: str = "http://localhost:3000"
    ALLOWED_ORIGIN_2: Optional[str] = None
    ALLOWED_ORIGIN_3: Optional[str] = None
    
    # Postgres settings
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    POSTGRES_HOST: str = "postgres_db"
    POSTGRES_PORT: str = "5432"
    
    # Email settings
    SENDGRID_API_KEY: Optional[str] = None
    FROM_EMAIL: Optional[str] = None
    
    # Celery settings
    CELERY_BROKER_URL: str = "redis://redis:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://redis:6379/0"
    CELERY_REDBEAT_REDIS_URL: str = "redis://redis:6379/1"
    CELERY_REDBEAT_KEY_PREFIX: str = "redbeat:"
    
    # AI settings
    OPENAI_API_KEY: Optional[str] = None
    
    # Monitoring
    SENTRY_DSN_URL: Optional[str] = None


# Create a singleton instance
settings = Settings()