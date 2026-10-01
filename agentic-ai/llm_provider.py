import os
from langchain_groq import ChatGroq
from config import settings

_groq_instance = None

def get_groq_provider(api_key: str = None, model: str = None) -> ChatGroq:
    """
    Returns a shared instance of the Groq LLM provider.
    This ensures all agents use the same configured provider.
    """
    global _groq_instance
    
    # Use provided keys from .NET backend headers, or fallback to environment variables
    final_api_key = api_key or settings.GROQ_API_KEY
    final_model = model or settings.GROQ_MODEL
    
    if not final_api_key:
        raise ValueError("GROQ_API_KEY is not configured.")
        
    if _groq_instance is None or api_key is not None:
        # We create a new instance if a dynamic key is provided via header
        _groq_instance = ChatGroq(
            model_name=final_model,
            api_key=final_api_key,
            temperature=0, # User specified temperature=0
            max_retries=3,  # Minimal reusable retry mechanism with backoff for HTTP 429
        )
        
    return _groq_instance
