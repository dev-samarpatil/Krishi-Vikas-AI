from fastapi import APIRouter, File, UploadFile, Form, Request, Query
from fastapi.responses import JSONResponse
import google.generativeai as genai
from PIL import Image
import io
import json
import os
import re
import traceback

from services.supabase_service import save_diagnosis
from services.weather_service import get_current_weather
from utils.geocode import reverse_geocode
from utils.json_loader import get_soil_type, get_crop_stage
from utils.haversine import get_nearest_kvks

router = APIRouter()

LANGUAGE_NAMES = {
    "en": "English",
    "hi": "Hindi",
    "mr": "Marathi",
    "ta": "Tamil",
}


def get_model():
    """Get a configured Gemini model instance with REST transport."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not set in .env")
    genai.configure(api_key=api_key, transport="rest")
    model_name = os.getenv("GEMINI_VISION_MODEL", os.getenv("GEMINI_CHAT_MODEL", "gemini-2.5-flash"))
    return genai.GenerativeModel(model_name)

def extract_json_from_gemini(raw_text: str) -> dict:
    """
    Gemini sometimes wraps JSON in markdown or adds 
    extra text. This function handles all cases.
    """
    import re
    import json
    
    text = raw_text.strip()
    
    # Method 1: Direct parse (if clean JSON)
    try:
        return json.loads(text)
    except:
        pass
    
    # Method 2: Strip markdown code blocks
    # Handles ```json ... ``` and ``` ... ```
    patterns = [
        r'```json\s*([\s\S]*?)\s*```',
        r'```\s*([\s\S]*?)\s*```',
    ]
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            try:
                return json.loads(match.group(1).strip())
            except:
                pass
    
    # Method 3: Find JSON object by braces
    # Handles cases where Gemini adds text before/after JSON
    start = text.find('{')
    end = text.rfind('}')
    if start != -1 and end != -1 and end > start:
        try:
            json_str = text[start:end+1]
            return json.loads(json_str)
        except:
            pass
    
    # Method 4: Fix common Gemini JSON formatting issues
    # Sometimes Gemini uses single quotes or trailing commas
    try:
        # Replace single quotes with double quotes
        fixed = text[start:end+1] if start != -1 else text
        fixed = re.sub(r"'([^']*)':", r'"\1":', fixed)
        fixed = re.sub(r":\s*'([^']*)'", r': "\1"', fixed)
        # Remove trailing commas before } or ]
        fixed = re.sub(r',\s*([}\]])', r'\1', fixed)
        return json.loads(fixed)
    except:
        pass
    
    # If all methods fail, raise to trigger fallback
    raise ValueError(
        f"Could not parse JSON from Gemini response. "
        f"Raw text: {text[:300]}"
    )


@router.post("/api/diagnose")
async def diagnose(
    request: Request,
    image: UploadFile = File(...),
    lat: float = Form(default=19.99),
    long: float = Form(default=73.79),
    crop_type: str = Form(default="Unknown"),
    language: str = Form(default="en"),
    farmer_id: str = Form(default="anonymous"),
    farm_size: str = Form(default="Unknown"),
    farming_type: str = Form(default="Unknown"),
    farm_id: str = Form(default=""),
):
    """
    Full crop diagnosis pipeline:
    1. Read + validate image → PIL
    2. Reverse geocode GPS → district/state
    3. Soil, crop stage, weather lookups
    4. Gemini Flash → structured diagnosis JSON
    5. Supabase → save record
    """

    # ── Step 0: Check API Key ──────────────────────────────────────
    if not os.getenv("GEMINI_API_KEY"):
        return JSONResponse(
            status_code=500, 
            content={"error": "Missing API Key for Gemini", "details": "GEMINI_API_KEY is not set in environment variables"}
        )

    raw_text = ""  # for error handling

    try:
        # ── Step 1: Read and validate image ─────────────────────────
        image_bytes = await image.read()
        print(f"[diagnose] Received image: {len(image_bytes)} bytes, type: {image.content_type}")

        # Check for base64 encoded image string
        if image_bytes.startswith(b"data:image"):
            try:
                _, base64_data = image_bytes.split(b",", 1)
                import base64
                image_bytes = base64.b64decode(base64_data)
                print(f"[diagnose] Decoded base64 image (header found): {len(image_bytes)} bytes")
            except Exception as b64_err:
                print(f"[diagnose] Base64 decoding with header failed: {b64_err}")
        else:
            try:
                import base64
                decoded = base64.b64decode(image_bytes, validate=True)
                if len(decoded) > 0 and len(decoded) != len(image_bytes):
                    image_bytes = decoded
                    print(f"[diagnose] Decoded raw base64 image: {len(image_bytes)} bytes")
            except Exception:
                pass

        try:
            pil_image = Image.open(io.BytesIO(image_bytes))
            if pil_image.mode not in ("RGB", "L"):
                pil_image = pil_image.convert("RGB")
            print(f"[diagnose] PIL image: {pil_image.size}, mode: {pil_image.mode}")
        except Exception as img_err:
            print(f"[diagnose] Image conversion error: {img_err}")
            return JSONResponse(
                status_code=400,
                content={"error": "Invalid image format", "detail": str(img_err)},
            )

        # ── Step 2: Reverse geocode GPS → district, state ───────────
        district = "Nashik"
        state = "Maharashtra"
        try:
            geo = await reverse_geocode(lat, long)
            district = geo["district"]
            state = geo["state"]
        except Exception as e:
            print(f"[diagnose] Geocode error (using fallback): {e}")

        # ── Step 3: Context lookups ─────────────────────────────────
        soil_type = get_soil_type(district, getattr(request.app.state, "soil", []))

        crop_info = get_crop_stage(crop_type, state, getattr(request.app.state, "calendar", []))
        season = crop_info.get("season", "unknown")
        crop_stage = crop_info.get("stage", "growing")

        weather_summary = "Weather data unavailable"
        try:
            weather_data = await get_current_weather(lat, long)
            weather_summary = weather_data.get("summary", weather_summary)
        except Exception as e:
            print(f"[diagnose] Weather error (using fallback): {e}")

        # ── Step 4: Build diagnosis prompt with strict visual grounding ──
        lang_name = LANGUAGE_NAMES.get(language, "English")

        prompt = f"""You are an expert Indian plant pathologist and agricultural diagnostician.
Analyse this crop photo carefully with complete visual grounding.

Context provided by farmer:
Location: {district}, {state}
Declared Crop: {crop_type}
Farming Type: {farming_type} | Farm Size: {farm_size}
Weather: {weather_summary} | Soil: {soil_type}
Target Language: {lang_name}

STRICT VISUAL INSPECTION INSTRUCTIONS:
1. NON-CROP / INVALID IMAGE:
   If the image DOES NOT show agricultural plant tissue, crop leaf, stem, or fruit (e.g. photo of a person, document, room, machinery, vehicle, abstract graphic, drawing, or blurred non-plant object):
   You MUST respond with:
   {{
     "type": "invalid_image",
     "name": "Non-crop Image Detected",
     "name_local": "फसल की तस्वीर नहीं है",
     "confidence": 0.0,
     "severity": "none",
     "urgency": "none",
     "explanation": "The submitted photo does not appear to show a crop leaf, stem, or plant tissue. Please upload a clear photo of your crop.",
     "cause": "Image does not depict agricultural foliage or plant disease symptoms.",
     "treatment_steps": [],
     "organic_option": {{"description": "N/A", "steps": []}},
     "prevention": "Point your camera directly at the affected crop leaf in good daylight.",
     "budget_items": [],
     "total_cost_inr": 0,
     "organic_total_cost_inr": 0,
     "low_confidence_note": "Please upload a clear photograph of an agricultural crop leaf or plant."
   }}

2. HEALTHY CROP:
   If the plant foliage appears healthy with no visible signs of pathogen infection, pest infestation, or nutrient deficiency:
   Respond with:
   {{
     "type": "healthy",
     "name": "Healthy Crop",
     "name_local": "स्वस्थ फसल",
     "confidence": 0.92,
     "severity": "low",
     "urgency": "none",
     "explanation": "No symptoms of pests, fungal, bacterial, or viral disease are visible on this crop foliage. The plant tissue looks vigorous.",
     "cause": "Normal plant growth under suitable conditions.",
     "treatment_steps": [
       "Maintain standard balanced irrigation and nutrition schedule",
       "No chemical pesticide or fungicide application needed",
       "Inspect foliage weekly for early pest detection"
     ],
     "organic_option": {{
       "description": "Preventive biological maintenance",
       "steps": [
         "Spray fermented Jeevamrit or compost tea to support leaf microbiome",
         "Install yellow sticky traps along field perimeter"
       ]
     }},
     "prevention": "Continue regular crop rotation and maintain balanced NPK nutrition.",
     "budget_items": [
       {{"item": "Yellow sticky traps (preventive)", "quantity": "5 traps", "price_inr": 100}}
     ],
     "total_cost_inr": 100,
     "organic_total_cost_inr": 50,
     "low_confidence_note": null
   }}

3. INCONCLUSIVE / BLURRED:
   If foliage is shown but symptoms are ambiguous, heavily out of focus, or inconclusive:
   Respond with:
   {{
     "type": "inconclusive",
     "name": "Inconclusive Symptoms",
     "name_local": "अस्पष्ट लक्षण",
     "confidence": 0.45,
     "severity": "medium",
     "urgency": "within_week",
     "explanation": "Visible stress or leaf discoloration is present, but definitive disease classification is inconclusive from this angle/resolution.",
     "cause": "Uncertain - could be early pathogen infection, nutrient deficiency, or environmental stress.",
     "treatment_steps": [
       "Do not apply toxic chemical sprays until disease identity is confirmed",
       "Isolate or monitor affected leaves closely",
       "Retake photo in daylight or consult your nearest KVK"
     ],
     "organic_option": {{
       "description": "Mild neem-based foliar deterrent",
       "steps": ["Apply 5ml neem oil per liter water as a safe broad deterrent"]
     }},
     "prevention": "Consult your local Krishi Vigyan Kendra (KVK) for visual verification.",
     "budget_items": [
       {{"item": "Neem oil spray (safe baseline)", "quantity": "250ml", "price_inr": 120}}
     ],
     "total_cost_inr": 120,
     "organic_total_cost_inr": 120,
     "low_confidence_note": "Symptoms are ambiguous. Please consult your local KVK or re-scan with better lighting."
   }}

4. DISEASE / PEST IDENTIFIED:
   If a specific disease or pest issue IS clearly visible:
   - Identify the TRUE crop shown in photo even if different from declared context.
   - Provide the specific disease name in English and {lang_name}.
   - Calibrate confidence between 0.55 and 0.98 based strictly on visual certainty.
   - Set "severity": "low" | "medium" | "high".
   - Set "urgency": "immediate" | "within_week" | "monitor".
   - Provide concrete, actionable chemical and organic treatment steps, prevention tips, and realistic Indian INR budget estimates.

STRICT JSON OUTPUT RULES:
- Respond ONLY with a single valid JSON object
- Do NOT include any markdown code blocks or backticks (no ```json or ```)
- Do NOT include any text before or after the JSON
- All keys and string values must use double quotes
- Language for explanations and local names: {lang_name}

JSON structure:
{{
  "type": "disease",
  "name": "Specific disease name in English",
  "name_local": "disease name in {lang_name}",
  "confidence": 0.85,
  "severity": "medium",
  "urgency": "immediate",
  "explanation": "What is happening to this crop in 2-3 simple sentences",
  "cause": "What pathogen or condition caused this",
  "treatment_steps": [
    "Step 1: Specific action with product name",
    "Step 2: Specific dosage and application method",
    "Step 3: Follow-up action and timing"
  ],
  "organic_option": {{
    "description": "Specific organic treatment name",
    "steps": [
      "Step 1: Exact organic method with quantities",
      "Step 2: Application frequency and timing"
    ]
  }},
  "prevention": "One specific prevention tip",
  "budget_items": [
    {{"item": "Product name", "quantity": "250g", "price_inr": 90}},
    {{"item": "Labour", "quantity": "1 day", "price_inr": 200}}
  ],
  "total_cost_inr": 290,
  "organic_total_cost_inr": 100,
  "low_confidence_note": null
}}"""

        # ── Step 4.5: Check Roboflow primary scanner ─────────────────
        roboflow_key = os.getenv("ROBOFLOW_API_KEY")
        roboflow_model = os.getenv("ROBOFLOW_MODEL_ID")
        roboflow_detected = False
        roboflow_class = ""
        roboflow_confidence = 0.0

        if roboflow_key and roboflow_model:
            try:
                import base64
                import requests
                # Encode image to base64 for Roboflow API
                b64_image = base64.b64encode(image_bytes).decode("utf-8")
                rf_url = f"https://detect.roboflow.com/{roboflow_model}"
                
                print(f"[diagnose] Calling Roboflow model {roboflow_model}...")
                rf_response = requests.post(
                    rf_url,
                    params={"api_key": roboflow_key},
                    data=b64_image,
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                    timeout=4
                )
                
                if rf_response.status_code == 200:
                    rf_res = rf_response.json()
                    preds = rf_res.get("predictions", [])
                    print(f"[diagnose] Roboflow predictions: {preds}")
                    if preds:
                        # Find the highest confidence prediction
                        best_pred = max(preds, key=lambda x: x.get("confidence", 0.0))
                        conf = best_pred.get("confidence", 0.0)
                        if conf >= 0.40:  # confidence threshold
                            roboflow_class = best_pred.get("class", "")
                            parts = roboflow_class.split("___")
                            rf_crop = parts[0].replace("_", " ").lower() if len(parts) > 1 else roboflow_class.lower()

                            # Only use Roboflow if the detected crop matches the user's selected crop
                            # Or if the user hasn't selected a specific crop ("unknown")
                            if crop_type.lower() == "unknown" or crop_type.lower() == "other" or crop_type.lower() in rf_crop or rf_crop in crop_type.lower():
                                roboflow_confidence = conf
                                roboflow_detected = True
                                print(f"[diagnose] Roboflow detected: {roboflow_class} with confidence {conf}")
                            else:
                                print(f"[diagnose] Roboflow rejected: User crop '{crop_type}' != RF crop '{rf_crop}'")
                else:
                    print(f"[diagnose] Roboflow error response: {rf_response.status_code} - {rf_response.text}")
            except Exception as rf_err:
                print(f"[diagnose] Roboflow execution error (falling back to Gemini): {rf_err}")

        raw_text = ""

        # If Roboflow detected a disease, call text-only Gemini to generate details
        if roboflow_detected:
            parts = roboflow_class.split("___")
            detected_crop = parts[0].replace("_", " ").title() if len(parts) > 1 else crop_type
            detected_disease = parts[1].replace("_", " ").title() if len(parts) > 1 else roboflow_class.replace("_", " ").title()
            
            print(f"[diagnose] Roboflow resolved crop: {detected_crop}, disease: {detected_disease}")
            
            text_prompt = f"""You are an expert Indian plant pathologist.
A crop photo was scanned and Roboflow identified:
Crop: {detected_crop}
Detected Disease/Issue: {detected_disease}
Detection Confidence: {roboflow_confidence:.2f}

Farmer details:
State: {state} | District: {district} | Soil: {soil_type}
Farming type: {farming_type} | Farm size: {farm_size}
Current weather: {weather_summary}
Language for explanation/treatment/local name: {lang_name}

Generate a structured plant pathology report for this disease.
Respond ONLY with a single valid JSON object. Do not include markdown blocks or backticks.
JSON structure:
{{
  "type": "disease",
  "name": "{detected_disease}",
  "name_local": "disease name in {lang_name}",
  "confidence": {roboflow_confidence:.2f},
  "explanation": "What is happening to this crop in 2-3 simple sentences that a farmer can understand",
  "cause": "What organism or condition caused this",
  "treatment_steps": [
    "Step 1: Specific action with specific product name",
    "Step 2: Specific dosage and application method",
    "Step 3: Follow-up action and timing"
  ],
  "organic_option": {{
    "description": "Specific organic treatment name",
    "steps": [
      "Step 1: Exact organic method with quantities",
      "Step 2: Application frequency and timing"
    ]
  }},
  "prevention": "One specific prevention tip for this disease",
  "budget_items": [
    {{"item": "Specific product name", "quantity": "250g", "price_inr": 90}},
    {{"item": "Sprayer rental", "quantity": "1 day", "price_inr": 50}},
    {{"item": "Labour", "quantity": "1 day", "price_inr": 200}}
  ],
  "total_cost_inr": 340,
  "organic_total_cost_inr": 100,
  "urgency": "immediate",
  "low_confidence_note": null
}}"""
            print("[diagnose] Calling Gemini text model with Roboflow context...")
            model = get_model()
            response = model.generate_content(
                text_prompt,
                generation_config=genai.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=4096,
                )
            )
            raw_text = response.text
        else:
            # ── Step 5: Call Gemini Vision with PIL image ──────────────────
            print("[diagnose] Calling Gemini vision API (Fallback)...")
            model = get_model()

            response = model.generate_content(
                [prompt, pil_image],
                generation_config=genai.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=4096,
                )
            )
            raw_text = response.text
        
        print("=" * 50)
        print("GEMINI RAW RESPONSE:")
        print(raw_text)
        print("=" * 50)
        
        print(f"[diagnose] Gemini raw response preview: {raw_text[:200]}...")

        # ── Step 6: Parse JSON — extract correctly ──────────
        try:
            result = extract_json_from_gemini(raw_text)
        except ValueError as e:
            print(f"JSON extraction failed: {e}")
            raise json.JSONDecodeError("Failed to extract JSON", raw_text, 0)

        # ── Step 7: Inject low confidence note if needed ────────────
        confidence = result.get("confidence", 0)
        if confidence < 0.65:
            result["low_confidence_note"] = (
                "AI is moderately confident. Consider consulting "
                "your nearest KVK to confirm this diagnosis."
            )

        # ── Step 8: Attach context metadata for frontend ────────────
        result["_context"] = {
            "district": district,
            "state": state,
            "soil_type": soil_type,
            "season": season,
            "crop_stage": crop_stage,
            "weather": weather_summary,
        }

        # ── Step 9: Save to Supabase (only for real plant diagnoses) ──
        # Do not persist invalid/non-crop images or rejected scans as diseases in farm history
        if result.get("type") in ("disease", "healthy") and result.get("confidence", 0.0) >= 0.40:
            try:
                saved = await save_diagnosis(
                    farmer_id=farmer_id,
                    disease_name=result.get("name", "Unknown"),
                    confidence=result.get("confidence", 0.0),
                    lat=lat,
                    long=long,
                    district=district,
                    crop_type=crop_type,
                    farm_id=farm_id,
                )
                if saved:
                    result["diagnosis_id"] = saved.get("id", "")
            except Exception as db_err:
                print(f"[diagnose] Supabase save failed (non-critical): {db_err}")

        print(f"[diagnose] [OK] Diagnosis success: {result.get('name')} ({result.get('confidence')})")
        return result

    except json.JSONDecodeError as je:
        print(f"[diagnose] JSON parse error: {je}")
        print(f"[diagnose] Raw text was: {raw_text}")
        return JSONResponse(
            status_code=502,
            content={
                "success": False,
                "status": "analysis_unavailable",
                "error": {
                    "code": "MODEL_RESPONSE_INVALID",
                    "message": "AI analysis produced an unparseable response. Please take a clearer photo and try again."
                }
            }
        )

    except Exception as e:
        print(f"[diagnose] [ERROR] Error: {str(e)}")
        traceback.print_exc()
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "status": "server_error",
                "error": {
                    "code": "DIAGNOSIS_FAILED",
                    "message": "Crop diagnosis is temporarily unavailable. Please try again shortly."
                }
            }
        )


# ── Nearest KVK endpoint ────────────────────────────────────────────


@router.get("/api/nearest-kvk")
async def nearest_kvk(
    request: Request,
    lat: float = Query(..., description="Farmer latitude"),
    long: float = Query(..., description="Farmer longitude"),
    limit: int = Query(3, description="Number of results"),
):
    """Find the nearest KVK centres using Haversine distance."""
    kvk_data = getattr(request.app.state, "kvk", [])
    if not kvk_data:
        return {"kvks": []}

    nearest = get_nearest_kvks(lat, long, kvk_data, top_n=limit)
    return {"kvks": nearest}
