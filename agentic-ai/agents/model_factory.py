from langchain_ollama import ChatOllama
from config import Settings
from models.support_models import SupportSuggestion


def support_model():
    """One provider boundary. Credentials and provider settings stay server-side."""
    # Uvicorn's default reload watcher does not watch .env. Read configuration
    # for each analysis so provider/model changes apply to the next request.
    settings = Settings()
    provider = settings.LLM_PROVIDER.strip().lower()
    if provider == "groq":
        from langchain_groq import ChatGroq

        if not settings.GROQ_API_KEY.strip():
            raise ValueError("GROQ_API_KEY is required when LLM_PROVIDER=groq.")
        return ChatGroq(
            api_key=settings.GROQ_API_KEY, model=settings.GROQ_MODEL,
            temperature=0, timeout=20, max_retries=0,
        ).with_structured_output(SupportSuggestion, method="function_calling")
    if provider != "ollama":
        raise ValueError("Unsupported LLM_PROVIDER. Use groq or ollama.")
    return ChatOllama(
        base_url=settings.OLLAMA_BASE_URL, model=settings.OLLAMA_MODEL,
        temperature=0, client_kwargs={"timeout": 20},
    ).with_structured_output(SupportSuggestion)
