import os
import uuid
import logging
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional

from services.groq_service import (
    chat_with_farmer as chat_with_groq,
    UpstreamAIServiceError as GroqUpstreamError,
)
from services.gemini_service import (
    chat_with_farmer as chat_with_gemini,
    UpstreamAIServiceError as GeminiUpstreamError,
)
from services.weather_service import get_current_weather
from utils.geocode import reverse_geocode
from utils.json_loader import get_soil_type, get_crop_stage
from utils.agmarknet import fetch_mandi_prices

logger = logging.getLogger("krishi_chat")
router = APIRouter()


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="Farmer's message to the chatbot")
    language: str = Field(default="en", description="Target language code: en, hi, mr, ta")
    lat: Optional[float] = Field(default=19.997, description="Latitude")
    long: Optional[float] = Field(default=73.789, description="Longitude")
    crop: Optional[str] = None
    last_diagnosis: Optional[str] = None
    district: Optional[str] = None


@router.post("/api/chat")
@router.post("/api/v1/chat")
@router.post("/chat")
@router.post("/farms/{id}/chat")
async def chat(req: ChatRequest, fastapi_req: Request, id: Optional[str] = None):
    """
    Process context-aware agricultural chat utilizing Groq as the primary
    high-speed AI engine (Phase 1), with Gemini rollback/fallback options.
    Enriches responses with localized soil, weather, crop stage, and live mandi prices.
    """
    request_id = str(uuid.uuid4())

    # 1. Input validation
    clean_message = req.message.strip()
    if not clean_message:
        return JSONResponse(
            status_code=400,
            content={
                "success": False,
                "error": {
                    "code": "EMPTY_MESSAGE",
                    "message": "Message cannot be empty.",
                    "request_id": request_id,
                    "retryable": False,
                }
            }
        )

    # 2. Configuration verification
    provider_pref = os.getenv("CHAT_PROVIDER", "groq").strip().lower()
    has_groq = bool(os.getenv("GROQ_API_KEY", "").strip())
    has_gemini = bool(os.getenv("GEMINI_API_KEY", "").strip())

    if not has_groq and not has_gemini:
        logger.error(f"[{request_id}] Neither GROQ_API_KEY nor GEMINI_API_KEY is configured.")
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "reply": "AI service is currently not configured on the server.",
                "response": "AI service is currently not configured on the server.",
                "error": {
                    "code": "CONFIG_ERROR",
                    "message": "AI assistant provider credentials are not configured.",
                    "request_id": request_id,
                    "retryable": False,
                }
            }
        )

    try:
        # 3. Context resolution: location, soil, calendar, weather, mandi
        district = req.district or None
        state = "Maharashtra"
        try:
            geo = await reverse_geocode(req.lat, req.long)
            district = district or geo.get("district")
            state = geo.get("state", "Maharashtra")
        except Exception as geo_err:
            logger.warning(f"[{request_id}] Geocode fallback used: {geo_err}")
            district = district or "Nashik"
            state = "Maharashtra"

        soil_type = "Loamy"
        calendar_data = {}
        if hasattr(fastapi_req.app.state, "soil"):
            soil_type = get_soil_type(district, fastapi_req.app.state.soil)
        if hasattr(fastapi_req.app.state, "calendar"):
            calendar_data = fastapi_req.app.state.calendar

        crop_info = {"season": "unknown", "stage": "unknown"}
        if req.crop:
            crop_info = get_crop_stage(req.crop, state, calendar_data)

        weather_summary = "Normal seasonal conditions"
        try:
            weather = await get_current_weather(req.lat, req.long)
            weather_summary = weather.get("summary", weather_summary)
        except Exception as weather_err:
            logger.warning(f"[{request_id}] Weather fetch non-fatal error: {weather_err}")

        # Intent Interceptor: Pre-fetch mandi data if price keywords exist
        market_context = "None requested"
        test_message = clean_message.lower()
        if any(keyword in test_message for keyword in ["price", "mandi", "bhav", "rate", "sell", "market", "dam", "kimat"]):
            if req.crop:
                try:
                    prices = await fetch_mandi_prices(state, district, req.crop)
                    if prices:
                        top_market = prices[0]
                        market_context = (
                            f"Today's {req.crop} price in {top_market['market']} is "
                            f"₹{top_market['modal_price']}/Quintal "
                            f"(Min: ₹{top_market['min_price']}, Max: ₹{top_market['max_price']})"
                        )
                    else:
                        market_context = f"Market price data currently unavailable for {req.crop} in your nearby district."
                except Exception as mandi_err:
                    logger.warning(f"[{request_id}] Mandi price lookup error: {mandi_err}")
                    market_context = "Market data service is temporarily unreachable."
            else:
                market_context = "No specific crop specified. Ask the farmer which crop's price they need."

        # 4. Execute AI Generation with server-controlled provider selection
        result = None
        generation_error = None

        if provider_pref == "gemini":
            # Retained rollback path
            logger.info(f"[{request_id}] Routing chat request to Gemini (Rollback Provider)...")
            try:
                result = await chat_with_gemini(
                    message=clean_message,
                    language=req.language,
                    district=district,
                    state=state,
                    soil_type=soil_type,
                    crops=[req.crop] if req.crop else [],
                    weather_summary=weather_summary,
                    season=crop_info.get("season", "unknown"),
                    crop_stage=crop_info.get("stage", "growing"),
                    last_diagnosis=req.last_diagnosis or "None",
                    market_context=market_context,
                )
            except Exception as e:
                generation_error = e
        else:
            # Primary path: Groq
            logger.info(f"[{request_id}] Routing chat request to Groq (Primary Provider)...")
            try:
                result = await chat_with_groq(
                    message=clean_message,
                    language=req.language,
                    district=district,
                    state=state,
                    soil_type=soil_type,
                    crops=[req.crop] if req.crop else [],
                    weather_summary=weather_summary,
                    season=crop_info.get("season", "unknown"),
                    crop_stage=crop_info.get("stage", "growing"),
                    last_diagnosis=req.last_diagnosis or "None",
                    market_context=market_context,
                )
            except Exception as groq_err:
                logger.warning(f"[{request_id}] Groq provider failed: {type(groq_err).__name__} - {groq_err}")
                # Optional resilient fallback to Gemini if configured
                if has_gemini:
                    logger.info(f"[{request_id}] Attempting secondary fallback to Gemini...")
                    try:
                        result = await chat_with_gemini(
                            message=clean_message,
                            language=req.language,
                            district=district,
                            state=state,
                            soil_type=soil_type,
                            crops=[req.crop] if req.crop else [],
                            weather_summary=weather_summary,
                            season=crop_info.get("season", "unknown"),
                            crop_stage=crop_info.get("stage", "growing"),
                            last_diagnosis=req.last_diagnosis or "None",
                            market_context=market_context,
                        )
                    except Exception as gem_err:
                        logger.error(f"[{request_id}] Gemini secondary fallback also failed: {gem_err}")
                        generation_error = groq_err
                else:
                    generation_error = groq_err

        if generation_error:
            raise generation_error

        reply_text = result.get("reply") or result.get("response") or "No response generated."

        return {
            "success": True,
            "reply": reply_text,
            "response": reply_text,
            "intent_type": result.get("intent_type", "general"),
            "provider": result.get("provider", "groq"),
            "request_id": request_id,
        }

    except (GroqUpstreamError, GeminiUpstreamError) as ai_err:
        logger.error(f"[{request_id}] Upstream AI service error: {ai_err.code} - {ai_err.message}")
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "reply": ai_err.message,
                "response": ai_err.message,
                "error": {
                    "code": ai_err.code,
                    "message": ai_err.message,
                    "request_id": request_id,
                    "retryable": ai_err.retryable,
                }
            }
        )
    except Exception as e:
        logger.exception(f"[{request_id}] Unhandled error in chat route: {type(e).__name__}")
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "reply": "The farming assistant encountered an internal issue. Please try again shortly.",
                "response": "The farming assistant encountered an internal issue. Please try again shortly.",
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "The assistant encountered a temporary issue. Please try again.",
                    "request_id": request_id,
                    "retryable": True,
                }
            }
        )
