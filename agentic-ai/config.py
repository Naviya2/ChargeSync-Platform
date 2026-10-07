import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=Path(__file__).resolve().with_name(".env"), extra="ignore")

    APP_NAME: str = "ChargeSync Agentic AI Service"
    APP_VERSION: str = "2.0.0"
    HOST: str = "0.0.0.0"
    PORT: int = int(os.getenv("PORT", "8000"))

    # LLM Settings (supports local Ollama or hosted Groq/OpenAI/Anthropic/compatible providers)
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "groq")
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    OLLAMA_MODEL: str = os.getenv("OLLAMA_MODEL", "llama3.2:latest")
    AGENT_SERVICE_API_KEY: str = os.getenv("AGENT_SERVICE_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    GROQ_MODEL: str = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")

    # Benchmark defaults
    DEFAULT_CHARGE_DELTA_PERCENT: float = 0.70  # 10% -> 80% SoC benchmark

settings = Settings()
