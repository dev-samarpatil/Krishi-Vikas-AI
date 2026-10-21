"""
Krishi Vikas AI — Groq Chat Service
===================================
High-speed conversational agricultural AI provider using the Groq Cloud SDK.
Enforces agricultural safety guardrails, bounded timeouts, transient error
retries, and safe error normalization without leaking secrets or raw traces.
"""

import os
import time
import asyncio
import logging
from typing import Optional, Dict, Any, List
from dotenv import load_dotenv
import groq
from groq import AsyncGroq, APIError, RateLimitError, AuthenticationError, APIConnectionError

load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

logger = logging.getLogger("krishi_groq")

# ── Structured Upstream Error ──────────────────────────────────────────

class UpstreamAIServiceError(Exception):
    """Normalized exception representing an upstream AI provider failure."""
    def __init__(self, message: str, code: str = "UPSTREAM_UNAVAILABLE", retryable: bool = True):
        super().__init__(message)
        self.message = message
        self.code = code
        self.retryable = retryable


# ── Agricultural System Prompt with Safety Guardrails ─────────────────

CHAT_SYSTEM_PROMPT = """You are Krishi Vikas AI, an expert, empathetic, and practical farming assistant for Indian agriculture.
Always respond in {language}. Use simple, farmer-friendly terms (Class 6 reading level).
Be warm, encouraging, respectful, and highly actionable.

═══════════════════════════════════════════════════════════════
CRITICAL INSTRUCTION — FARMER SAFETY FIRST:
1. Answer EXACTLY what the farmer is asking in their current query.
2. Context (soil, weather, crop, season, location) is provided to enrich your advisory; do NOT override the user's specific question with unrelated background info.
3. If crucial context is missing (such as exact crop type, growth stage, or specific symptom patterns), ask 1-2 focused, friendly follow-up questions.
4. Express appropriate uncertainty when symptoms could indicate multiple conditions: clearly state possibilities rather than jumping to dangerous conclusions.
5. NEVER claim to have seen or inspected a photo or physical sample unless image data was explicitly provided.
6. NEVER claim live access to sensors, pumps, or live telemetry unless provided in the prompt context.
7. NEVER invent government schemes, subsidies, fake prices, disease outbreak statistics, or official helpline numbers.
8. When recommending chemical pesticides or fertilizers:
   - Provide standard recognized names (e.g., Mancozeb, Chlorpyrifos, Neem oil, NPK).
   - Provide general indicative dosages (e.g., 2 ml per litre of water), but ALWAYS emphasize: "Check and follow the specific manufacturer product label for exact dosage, preparation, and safety gear before spraying."
   - Mention mandatory safety precautions (gloves, mask, spray during early morning or late afternoon).
9. If an issue appears severe, complex, legal, or ambiguous, recommend consulting the local Krishi Vigyan Kendra (KVK) or agricultural extension officer.
10. You do NOT have the ability to actuate pumps, turn on valves, or control electrical machinery.
═══════════════════════════════════════════════════════════════

FARM CONTEXT (use only if relevant to the query):
- Location: {district}, {state}
- Tracked crop(s): {crops}
- Soil type: {soil_type}
- Crop stage: {crop_stage}
- Season: {season}
- Weather today: {weather_summary}
- Recent crop scan diagnosis: {last_diagnosis}
- Mandi price info: {market_context}

RESPONSE FORMAT:
Structure your response clearly using bullet points and short paragraphs. When diagnosing or giving treatment advice, use these sections:
- Problem: [Brief identification or likely possibilities]
- Cause: [Simple explanation of what causes it]
- Immediate Action: [Practical organic and/or chemical action, with dosage guidance and label warning]
- Prevention: [How to prevent it in the future]

Keep responses concise, clear, and easy to read on a mobile phone screen."""

LANGUAGE_NAMES = {
    "en": "English",
    "hi": "Hindi",
    "mr": "Marathi",
    "ta": "Tamil",
}

DEFAULT_GROQ_MODEL = "qwen/qwen3.8-27b"
DEFAULT_TIMEOUT_SECONDS = 30.0
DEFAULT_MAX_RETRIES = 2


# ── Client Factory ───────────────────────────────────────────────────

_groq_client: Optional[AsyncGroq] = None
_cached_key: Optional[str] = None

def get_groq_client() -> Optional[AsyncGroq]:
    """Retrieve or initialize singleton AsyncGroq client with server credentials."""
    global _groq_client, _cached_key
    key = os.getenv("GROQ_API_KEY", "").strip()
    if not key:
        return None
    if _groq_client is None or key != _cached_key:
        timeout = float(os.getenv("GROQ_TIMEOUT_SECONDS", str(DEFAULT_TIMEOUT_SECONDS)))
        _groq_client = AsyncGroq(api_key=key, timeout=timeout)
        _cached_key = key
    return _groq_client


# ── Core Generation Workflow ──────────────────────────────────────────

async def chat_with_groq(
    message: str,
    language: str,
    district: str,
    state: str,
    soil_type: str,
    crops: List[str],
    weather_summary: str,
    season: str,
    crop_stage: str,
    last_diagnosis: str,
    market_context: str = "None requested",
) -> Dict[str, Any]:
    """
    Execute context-enriched agricultural chat completion via Groq Cloud.
    Applies bounded retries on transient errors and normalizes outputs.
    """
    client = get_groq_client()
    if not client:
        logger.error("Groq client cannot be initialized: GROQ_API_KEY is not configured.")
        raise UpstreamAIServiceError(
            message="AI assistant provider credentials are not configured.",
            code="CONFIG_ERROR",
            retryable=False,
        )

    model_name = os.getenv("GROQ_MODEL", DEFAULT_GROQ_MODEL).strip() or DEFAULT_GROQ_MODEL
    timeout_val = float(os.getenv("GROQ_TIMEOUT_SECONDS", str(DEFAULT_TIMEOUT_SECONDS)))
    max_retries = int(os.getenv("GROQ_MAX_RETRIES", str(DEFAULT_MAX_RETRIES)))

    crops_str = ", ".join(crops) if crops else "Not specified"
    sys_prompt = CHAT_SYSTEM_PROMPT.format(
        language=LANGUAGE_NAMES.get(language, "English"),
        district=district or "Nashik",
        state=state or "Maharashtra",
        soil_type=soil_type or "Loamy",
        crops=crops_str,
        weather_summary=weather_summary or "Seasonal conditions",
        season=season or "Current season",
        crop_stage=crop_stage or "Growing",
        last_diagnosis=last_diagnosis if last_diagnosis else "None",
        market_context=market_context,
    )

    messages = [
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": message},
    ]

    attempts = 0
    start_time = time.time()

    while attempts <= max_retries:
        attempts += 1
        try:
            logger.info(f"Calling Groq model '{model_name}' (attempt {attempts}/{max_retries + 1})...")
            response = await asyncio.wait_for(
                client.chat.completions.create(
                    messages=messages,
                    model=model_name,
                    temperature=0.3,
                    max_tokens=600,
                ),
                timeout=timeout_val,
            )

            if not response or not response.choices:
                raise UpstreamAIServiceError(
                    message="Received empty response from AI provider.",
                    code="EMPTY_RESPONSE",
                    retryable=True,
                )

            reply_text = response.choices[0].message.content
            if not reply_text or not reply_text.strip():
                raise UpstreamAIServiceError(
                    message="Received blank assistant response from AI provider.",
                    code="EMPTY_RESPONSE",
                    retryable=True,
                )

            duration = round(time.time() - start_time, 2)
            logger.info(f"Groq generation successful in {duration}s using {model_name}.")

            clean_reply = reply_text.strip()
            return {
                "reply": clean_reply,
                "response": clean_reply,
                "intent_type": "general",
                "provider": f"groq/{model_name}",
                "success": True,
            }

        except AuthenticationError as auth_err:
            logger.error(f"Groq authentication failed (401). Check GROQ_API_KEY.")
            raise UpstreamAIServiceError(
                message="AI provider authentication failed. Please verify server configuration.",
                code="AUTH_ERROR",
                retryable=False,
            )

        except RateLimitError as rl_err:
            logger.warning(f"Groq rate limit exceeded (429): attempt {attempts}")
            if attempts <= max_retries:
                backoff = 1.0 * (2 ** (attempts - 1))
                await asyncio.sleep(backoff)
                continue
            raise UpstreamAIServiceError(
                message="The AI assistant is experiencing high demand. Please retry in a few moments.",
                code="RATE_LIMIT_ERROR",
                retryable=True,
            )

        except asyncio.TimeoutError:
            logger.warning(f"Groq request timed out after {timeout_val}s: attempt {attempts}")
            if attempts <= max_retries:
                await asyncio.sleep(0.5)
                continue
            raise UpstreamAIServiceError(
                message="The AI assistant request timed out. Please try again.",
                code="TIMEOUT_ERROR",
                retryable=True,
            )

        except APIConnectionError as conn_err:
            logger.warning(f"Groq network connection error: attempt {attempts}: {type(conn_err).__name__}")
            if attempts <= max_retries:
                await asyncio.sleep(1.0)
                continue
            raise UpstreamAIServiceError(
                message="Network connectivity error reaching AI assistant.",
                code="NETWORK_ERROR",
                retryable=True,
            )

        except UpstreamAIServiceError:
            raise

        except Exception as gen_err:
            err_type = type(gen_err).__name__
            logger.error(f"Groq API error ({err_type}) on attempt {attempts}: {gen_err}")
            if attempts <= max_retries:
                await asyncio.sleep(0.5)
                continue
            raise UpstreamAIServiceError(
                message="The AI assistant is temporarily unavailable. Please try again shortly.",
                code="UPSTREAM_UNAVAILABLE",
                retryable=True,
            )

    raise UpstreamAIServiceError(
        message="The AI assistant is temporarily unavailable. Please try again shortly.",
        code="UPSTREAM_UNAVAILABLE",
        retryable=True,
    )


# ── Unified Interface for Chat Router ─────────────────────────────────

async def chat_with_farmer(
    message: str,
    language: str,
    district: str,
    state: str,
    soil_type: str,
    crops: List[str],
    weather_summary: str,
    season: str,
    crop_stage: str,
    last_diagnosis: str,
    market_context: str = "None requested",
) -> Dict[str, Any]:
    """Primary chat interface routing to Groq with optional fallback."""
    return await chat_with_groq(
        message=message,
        language=language,
        district=district,
        state=state,
        soil_type=soil_type,
        crops=crops,
        weather_summary=weather_summary,
        season=season,
        crop_stage=crop_stage,
        last_diagnosis=last_diagnosis,
        market_context=market_context,
    )
