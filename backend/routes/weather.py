from fastapi import APIRouter
from pydantic import BaseModel
from services.weather_service import get_current_weather, get_5day_forecast
from services.gemini_service import generate_alert_text, LANGUAGE_NAMES

router = APIRouter()

CLIMATE_ALERT_PROMPT = """
You are an agricultural weather advisor.
Generate a SHORT urgent alert for a farmer in {language}.

Situation:
- Farmer location: {lat}, {long}
- Crop: {crop}
- Crop stage: {crop_stage}
- Alert type: {alert_type}
- Forecast detail: {forecast_detail}

Alert types and what to say:
- harvest_urgent: Heavy rain coming, mature crop must be harvested NOW
- irrigation_needed: Heatwave coming, crop needs water immediately
- fungal_risk: High humidity for 3+ days, spray preventative fungicide
- frost_warning: Temperature dropping below 5°C, cover sensitive crops
- fertilizer_timing: Heavy rain expected, delay fertilizer application to prevent runoff
- gray_leaf_spot_risk: High humidity and warm temperatures increase Gray Leaf Spot risk, monitor leaves
- maize_rainfall_risk: Heavy rainfall risk, ensure proper field drainage
- whitefly_risk: Hot and humid conditions increase Whitefly risk, check undersides of leaves
- boll_rot_risk: Rain during boll formation increases rot risk, monitor closely
- flooding_risk: Excessive rain expected, maintain bunds and manage water levels

Write ONE short, actionable, and urgent message in {language}.
Maximum 2 sentences. Be specific about the timeframe and the recommended action.
Return ONLY the alert text string, no JSON.
"""

class ClimateAlertRequest(BaseModel):
    lat: float
    long: float
    crop: str = "Unknown"
    crop_stage: str = "Unknown"
    language: str = "en"

@router.get("/api/weather")
async def weather(lat: float = 19.997, lon: float = 73.789, lang: str = "en"):
    """Get current weather + 5-day forecast for given coordinates."""
    current = await get_current_weather(lat, lon, lang)
    forecast = await get_5day_forecast(lat, lon, lang)
    return {"current": current, "forecast": forecast}

@router.post("/api/climate-alert")
async def climate_alert(req: ClimateAlertRequest):
    """Assess 5-day forecast against crop conditions to issue climate warnings."""
    forecast = await get_5day_forecast(req.lat, req.long)
    if not forecast:
        return {"alert_level": None, "message": ""}
    
    alert_type = None
    forecast_detail = ""

    crop_lower = req.crop.lower()
    stage_lower = req.crop_stage.lower()

    rain_next_3_days = sum(day.get('rain_mm', 0) for day in forecast[:3])
    max_temp = max(day.get('temp_max', 0) for day in forecast)
    high_humidity_days = sum(1 for day in forecast[:3] if day.get('humidity', 0) > 85)

    # 1. CROP-SPECIFIC ALERTS
    if crop_lower == "maize":
        if rain_next_3_days > 20 and stage_lower in ["vegetative", "flowering", "unknown"]:
            alert_type = "fertilizer_timing"
            forecast_detail = f"Heavy rain ({rain_next_3_days}mm). Delay fertilizer application to prevent runoff."
        elif high_humidity_days >= 2 and max_temp > 25:
            alert_type = "gray_leaf_spot_risk"
            forecast_detail = "High humidity and warm temp increase Gray Leaf Spot risk. Monitor leaves."
        elif rain_next_3_days > 30:
            alert_type = "maize_rainfall_risk"
            forecast_detail = "Heavy rainfall risk. Ensure proper field drainage to prevent waterlogging."
            
    elif crop_lower == "cotton":
        if max_temp > 32 and high_humidity_days >= 2:
            alert_type = "whitefly_risk"
            forecast_detail = "Hot, humid conditions increase Whitefly risk. Check undersides of leaves."
        elif rain_next_3_days > 15 and stage_lower == "boll formation":
            alert_type = "boll_rot_risk"
            forecast_detail = f"Rain ({rain_next_3_days}mm) during boll formation increases rot risk."

    elif crop_lower == "rice":
        if rain_next_3_days > 50:
            alert_type = "flooding_risk"
            forecast_detail = f"Excessive rain ({rain_next_3_days}mm) predicted. Maintain bunds to prevent extreme flooding."

    # 2. GENERAL ALERTS (fallback if no crop-specific alert triggered)
    if not alert_type:
        if rain_next_3_days > 10 and stage_lower == "mature":
            alert_type = "harvest_urgent"
            forecast_detail = f"Heavy rain ({rain_next_3_days}mm) expected in the next 3 days."
        elif max_temp > 40:
            alert_type = "irrigation_needed"
            forecast_detail = f"Heatwave expected reaching {max_temp}°C."
        elif high_humidity_days >= 3:
            alert_type = "fungal_risk"
            forecast_detail = "High humidity (>85%) predicted for 3 consecutive days."

    if not alert_type:
        return {"alert_level": None, "message": ""}
    
    prompt = CLIMATE_ALERT_PROMPT.format(
        language=LANGUAGE_NAMES.get(req.language, "English"),
        lat=round(req.lat, 2),
        long=round(req.long, 2),
        crop=req.crop,
        crop_stage=req.crop_stage,
        alert_type=alert_type,
        forecast_detail=forecast_detail
    )
    
    message = await generate_alert_text(prompt)
    alert_level = "urgent" if alert_type in ["harvest_urgent", "irrigation_needed", "flooding_risk"] else "advisory"

    return {
        "alert_level": alert_level,
        "message": message
    }
