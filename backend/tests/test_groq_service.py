"""
Unit tests for backend/services/groq_service.py
Verifies parsing, models, timeout, retry, authentication errors, rate limiting,
empty completions, and absence of credential leakage in exceptions.
"""

import os
import sys
import asyncio
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from groq import AuthenticationError, RateLimitError, APIConnectionError

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from services.groq_service import (
    chat_with_groq,
    chat_with_farmer,
    get_groq_client,
    UpstreamAIServiceError,
    CHAT_SYSTEM_PROMPT,
)


@pytest.mark.asyncio
async def test_01_successful_groq_response():
    """Verify standard Groq completion parsing and output normalization."""
    mock_client = AsyncMock()
    mock_choice = MagicMock()
    mock_choice.message.content = "Problem: Powdery mildew\nImmediate Action: Spray Neem oil @ 5ml/L."
    mock_response = MagicMock(choices=[mock_choice])
    mock_client.chat.completions.create.return_value = mock_response

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_test123", "GROQ_MODEL": "qwen/qwen3.8-27b"}):
        result = await chat_with_groq(
            message="My leaves have white powder",
            language="en",
            district="Nashik",
            state="Maharashtra",
            soil_type="Black",
            crops=["Grape"],
            weather_summary="Humid",
            season="Kharif",
            crop_stage="Flowering",
            last_diagnosis="None",
        )

        assert result["success"] is True
        assert "Powdery mildew" in result["reply"]
        assert result["response"] == result["reply"]
        assert result["provider"] == "groq/qwen/qwen3.8-27b"
        assert result["intent_type"] == "general"


@pytest.mark.asyncio
async def test_02_missing_api_key_raises_config_error():
    """Missing GROQ_API_KEY must raise UpstreamAIServiceError with code CONFIG_ERROR."""
    with patch("services.groq_service.get_groq_client", return_value=None):
        with pytest.raises(UpstreamAIServiceError) as exc_info:
            await chat_with_groq(
                message="Hello",
                language="en",
                district="Pune",
                state="Maharashtra",
                soil_type="Loamy",
                crops=[],
                weather_summary="Sunny",
                season="Rabi",
                crop_stage="Sowing",
                last_diagnosis="None",
            )
        assert exc_info.value.code == "CONFIG_ERROR"
        assert exc_info.value.retryable is False


@pytest.mark.asyncio
async def test_03_authentication_failure_not_retryable():
    """HTTP 401 AuthenticationError must raise AUTH_ERROR without retrying and without leaking key."""
    mock_client = AsyncMock()
    mock_request = MagicMock()
    mock_request.headers = {"authorization": "Bearer gsk_super_secret_test_key_12345"}
    mock_client.chat.completions.create.side_effect = AuthenticationError(
        message="Invalid API Key provided",
        response=MagicMock(status_code=401, headers={}),
        body={"error": {"message": "Invalid API Key"}}
    )

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_super_secret_test_key_12345"}):
        with pytest.raises(UpstreamAIServiceError) as exc_info:
            await chat_with_groq(
                message="Pest attack on cotton",
                language="en",
                district="Nagpur",
                state="Maharashtra",
                soil_type="Black",
                crops=["Cotton"],
                weather_summary="Cloudy",
                season="Kharif",
                crop_stage="Boll formation",
                last_diagnosis="None",
            )

        assert exc_info.value.code == "AUTH_ERROR"
        assert exc_info.value.retryable is False
        # Ensure secret key is not in the error message
        assert "gsk_super_secret_test_key_12345" not in str(exc_info.value)


@pytest.mark.asyncio
async def test_04_rate_limit_with_retry_exhaustion():
    """HTTP 429 RateLimitError must retry up to MAX_RETRIES then raise RATE_LIMIT_ERROR."""
    mock_client = AsyncMock()
    mock_client.chat.completions.create.side_effect = RateLimitError(
        message="Rate limit reached for model",
        response=MagicMock(status_code=429, headers={}),
        body={"error": {"message": "Rate limit exceeded"}}
    )

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_test", "GROQ_MAX_RETRIES": "1"}), \
         patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
        with pytest.raises(UpstreamAIServiceError) as exc_info:
            await chat_with_groq(
                message="Fertilizer dose for wheat",
                language="en",
                district="Indore",
                state="Madhya Pradesh",
                soil_type="Alluvial",
                crops=["Wheat"],
                weather_summary="Cool",
                season="Rabi",
                crop_stage="Tillering",
                last_diagnosis="None",
            )

        assert exc_info.value.code == "RATE_LIMIT_ERROR"
        assert exc_info.value.retryable is True
        # Verify it retried
        assert mock_client.chat.completions.create.call_count == 2
        mock_sleep.assert_called_once()


@pytest.mark.asyncio
async def test_05_empty_completion_handling():
    """Empty completion choices or blank content must raise EMPTY_RESPONSE."""
    mock_client = AsyncMock()
    mock_response = MagicMock(choices=[])
    mock_client.chat.completions.create.return_value = mock_response

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_test", "GROQ_MAX_RETRIES": "0"}):
        with pytest.raises(UpstreamAIServiceError) as exc_info:
            await chat_with_groq(
                message="Water schedule for onion",
                language="en",
                district="Nashik",
                state="Maharashtra",
                soil_type="Clay",
                crops=["Onion"],
                weather_summary="Sunny",
                season="Rabi",
                crop_stage="Bulb development",
                last_diagnosis="None",
            )

        assert exc_info.value.code == "EMPTY_RESPONSE"


@pytest.mark.asyncio
async def test_06_timeout_handling():
    """Asyncio timeout triggers TIMEOUT_ERROR when retries are exhausted."""
    mock_client = AsyncMock()
    mock_client.chat.completions.create.side_effect = asyncio.TimeoutError()

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_test", "GROQ_MAX_RETRIES": "1", "GROQ_TIMEOUT_SECONDS": "0.1"}), \
         patch("asyncio.sleep", new_callable=AsyncMock):
        with pytest.raises(UpstreamAIServiceError) as exc_info:
            await chat_with_groq(
                message="Delayed monsoon advisory",
                language="en",
                district="Solapur",
                state="Maharashtra",
                soil_type="Shallow",
                crops=["Jowar"],
                weather_summary="Dry",
                season="Kharif",
                crop_stage="Sowing",
                last_diagnosis="None",
            )

        assert exc_info.value.code == "TIMEOUT_ERROR"
        assert exc_info.value.retryable is True


@pytest.mark.asyncio
async def test_07_transient_error_recovers_on_retry():
    """A transient connection error that succeeds on second try returns valid result."""
    mock_client = AsyncMock()
    mock_choice = MagicMock()
    mock_choice.message.content = "Apply Trichoderma for root rot control."
    mock_response = MagicMock(choices=[mock_choice])

    # First call raises connection error, second call succeeds
    mock_client.chat.completions.create.side_effect = [
        APIConnectionError(request=MagicMock()),
        mock_response
    ]

    with patch("services.groq_service.get_groq_client", return_value=mock_client), \
         patch.dict(os.environ, {"GROQ_API_KEY": "gsk_test", "GROQ_MAX_RETRIES": "2"}), \
         patch("asyncio.sleep", new_callable=AsyncMock):
        result = await chat_with_groq(
            message="Chilli plant wilt problem",
            language="en",
            district="Kolhapur",
            state="Maharashtra",
            soil_type="Red",
            crops=["Chilli"],
            weather_summary="Humid",
            season="Kharif",
            crop_stage="Vegetative",
            last_diagnosis="None",
        )

        assert result["success"] is True
        assert "Trichoderma" in result["reply"]
        assert mock_client.chat.completions.create.call_count == 2


def test_08_prompt_safety_guardrails_presence():
    """Verify that agricultural safety instructions exist in CHAT_SYSTEM_PROMPT."""
    assert "FARMER SAFETY FIRST" in CHAT_SYSTEM_PROMPT
    assert "label" in CHAT_SYSTEM_PROMPT.lower()
    assert "kvk" in CHAT_SYSTEM_PROMPT.lower()
    assert "uncertainty" in CHAT_SYSTEM_PROMPT.lower()
    assert "NEVER claim to have seen or inspected a photo" in CHAT_SYSTEM_PROMPT
    assert "You do NOT have the ability to actuate pumps" in CHAT_SYSTEM_PROMPT
