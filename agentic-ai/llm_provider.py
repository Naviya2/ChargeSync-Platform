import os
from langchain_google_genai import ChatGoogleGenerativeAI
from config import settings

_gemini_instance = None

def get_gemini_provider(api_key: str = None, model: str = None) -> ChatGoogleGenerativeAI:
    """
    Returns a shared instance of the Gemini LLM provider.
    This ensures all agents use the same configured provider.
    """
    global _gemini_instance
    
    # Use provided keys from .NET backend headers, or fallback to environment variables
    final_api_key = api_key or settings.GEMINI_API_KEY
    final_model = model or settings.GEMINI_MODEL
    
    if not final_api_key:
        raise ValueError("GEMINI_API_KEY is not configured.")
        
    if _gemini_instance is None or api_key is not None:
        # We create a new instance if a dynamic key is provided via header
        _gemini_instance = ChatGoogleGenerativeAI(
            model=final_model,
            google_api_key=final_api_key,
            temperature=0.2,
            max_retries=3,  # Minimal reusable retry mechanism with backoff for HTTP 429
        )
        
    return _gemini_instance
