import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "ChargeSync Agentic AI Service"
    APP_VERSION: str = "1.0.0"
    HOST: str = "0.0.0.0"
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # LLM Settings (supports local Ollama or hosted OpenAI/Anthropic/compatible providers)
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "gemini")
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    OLLAMA_MODEL: str = os.getenv("OLLAMA_MODEL", "llama3.2:latest")
    
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")
    
    
    # Benchmark defaults
    DEFAULT_CHARGE_DELTA_PERCENT: float = 0.70  # 10% -> 80% SoC benchmark

settings = Settings()
