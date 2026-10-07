from unittest.mock import patch
from types import SimpleNamespace

import pytest
from agents.model_factory import support_model
from config import Settings
from models.support_models import SupportSuggestion


@pytest.fixture(autouse=True)
def isolated_settings(monkeypatch):
    # Provider mocks must never receive credentials from the developer's .env.
    global settings
    settings = SimpleNamespace(LLM_PROVIDER="groq", GROQ_API_KEY="test-only-key",
        GROQ_MODEL="test-model", OLLAMA_BASE_URL="http://localhost:11434", OLLAMA_MODEL="test-local-model")
    monkeypatch.setattr("agents.model_factory.Settings", lambda: settings)


def test_groq_uses_bounded_structured_model_without_ollama(monkeypatch):
    monkeypatch.setattr(settings, "LLM_PROVIDER", "groq")
    monkeypatch.setattr(settings, "GROQ_API_KEY", "test-only-key")
    with patch("langchain_groq.ChatGroq") as groq, patch("agents.model_factory.ChatOllama") as ollama:
        support_model()
        groq.assert_called_once_with(api_key="test-only-key", model=settings.GROQ_MODEL,
                                     temperature=0, timeout=20, max_retries=0)
        groq.return_value.with_structured_output.assert_called_once_with(
            SupportSuggestion, method="function_calling")
        ollama.assert_not_called()


def test_groq_requires_key(monkeypatch):
    monkeypatch.setattr(settings, "LLM_PROVIDER", "groq")
    monkeypatch.setattr(settings, "GROQ_API_KEY", "")
    with pytest.raises(ValueError, match="GROQ_API_KEY is required"):
        support_model()


def test_unknown_provider_does_not_silently_fall_back(monkeypatch):
    monkeypatch.setattr(settings, "LLM_PROVIDER", "unknown")
    with pytest.raises(ValueError, match="Unsupported LLM_PROVIDER"):
        support_model()


def test_ollama_remains_available(monkeypatch):
    monkeypatch.setattr(settings, "LLM_PROVIDER", "ollama")
    with patch("agents.model_factory.ChatOllama") as ollama:
        support_model()
        ollama.assert_called_once()
        ollama.return_value.with_structured_output.assert_called_once_with(SupportSuggestion)


def test_provider_changes_in_env_apply_to_next_model(tmp_path, monkeypatch):
    env_file = tmp_path / ".env"
    monkeypatch.delenv("LLM_PROVIDER", raising=False)
    monkeypatch.setattr("agents.model_factory.Settings", lambda: Settings(
        _env_file=env_file, GROQ_API_KEY="test-only-key", GROQ_MODEL="test-model"))
    with patch("langchain_groq.ChatGroq") as groq, patch("agents.model_factory.ChatOllama") as ollama:
        env_file.write_text("LLM_PROVIDER=ollama\n", encoding="utf-8")
        support_model()
        ollama.assert_called_once()
        groq.assert_not_called()
        env_file.write_text("LLM_PROVIDER=groq\n", encoding="utf-8")
        support_model()
        groq.assert_called_once()
