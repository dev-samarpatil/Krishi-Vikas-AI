import google.generativeai as genai
import os
import json
from PIL import Image
import io
from pydantic import BaseModel
from typing import Optional, Literal


# ── Pydantic Output Schema ──────────────────────────────────────────

class BudgetItem(BaseModel):
    item: str
    quantity: str
    price_inr: int


class OrganicOption(BaseModel):
    description: str
    steps: list[str]


class DiagnosisResponse(BaseModel):
    type: Literal["disease", "deficiency", "pest", "unclear"]
    name: str
    name_local: str
    confidence: float
    explanation: str
    cause: str
    treatment_steps: list[str]
    organic_option: OrganicOption
    prevention: str
    budget_items: list[BudgetItem]
    total_cost_inr: int
    organic_total_cost_inr: int
    urgency: Literal["immediate", "within_week", "monitor"]
    low_confidence_note: Optional[str] = None


class SchemeGuideResponse(BaseModel):
    summary: str
    likely_eligible: bool
    eligibility_reason: str
    documents_needed: list[str]
    application_steps: list[str]
    where_to_apply: str
    timeline: str
    helpline: str


# ── Diagnosis prompt template ────────────────────────────────────────

DIAGNOSIS_SYSTEM_PROMPT = """
You are an expert Indian agricultural scientist and
plant pathologist analysing a crop photo.

Farmer context:
- Location: {district}, {state}, India
- Soil type: {soil_type}
- Crop: {crop_type}
- Weather: {weather_summary}
- Crop stage: {crop_stage}

IMPORTANT INSTRUCTIONS:
1. Always provide your BEST DIAGNOSIS even if not 100% certain
2. If you can see any abnormality, identify what it most
   likely is — never return "unable to identify" unless
   the image is completely black or has no plant visible
3. The minimum confidence you should return is 0.45 —
   even a likely guess is more helpful than "unknown"
4. Common Indian crop diseases to consider:
   Early Blight, Late Blight, Powdery Mildew,
   Downy Mildew, Leaf Curl, Yellow Mosaic Virus,
   Bacterial Wilt, Anthracnose, Rust, Smut,
   Spider Mite damage, Aphid damage,
   Nitrogen deficiency (yellowing),
   Phosphorus deficiency (purple tint),
   Iron deficiency (interveinal chlorosis)

5. If the image quality is low, still give your best
   estimate based on visible symptoms and note it with
   slightly lower confidence (0.55-0.65)

Respond ONLY in {language} language.
Return ONLY valid JSON with no markdown:
{{
  "type": "disease" or "deficiency" or "pest",
  "name": "name in English",
  "name_local": "name in {language}",
  "confidence": 0.75,
  "explanation": "2-3 simple sentences what happened",
  "cause": "brief cause",
  "treatment_steps": [
    "Step 1: ...",
    "Step 2: ...",
    "Step 3: ..."
  ],
  "organic_option": {{
    "description": "organic treatment",
    "steps": ["Step 1: ..."]
  }},
  "prevention": "prevention tip",
  "budget_items": [
    {{"item": "product name", "quantity": "250g", "price_inr": 90}},
    {{"item": "labour", "quantity": "1 day", "price_inr": 200}}
  ],
  "total_cost_inr": 290,
  "organic_total_cost_inr": 100,
  "urgency": "immediate",
  "low_confidence_note": null
}}
"""

SCHEME_GUIDE_PROMPT = """
You are a government scheme advisor helping an Indian farmer understand
how to apply for a government benefit.

Scheme: {scheme_name}
Benefit: {benefit_description}
Farmer location: {district}, {state}
Farmer's language: {language}

Explain in VERY simple language (Class 5 reading level):
1. What this scheme gives them
2. Whether they are likely eligible (based on: small/marginal farmer, owns land, has Aadhaar)
3. Exactly what documents they need to bring
4. Step-by-step where to go and what to do to apply
5. How long it takes and what happens next

Respond ENTIRELY in {language} and guarantee JSON output.
"""

# ── SDK Configuration ────────────────────────────────────────────────

DEFAULT_GEMINI_MODEL = "gemini-2.5-flash"
CONFIGURED_GEMINI_MODEL = os.getenv("GEMINI_CHAT_MODEL", DEFAULT_GEMINI_MODEL).strip() or DEFAULT_GEMINI_MODEL

_gemini_configured = False
_active_api_key = None

def get_gemini_client():
    global _gemini_configured, _active_api_key
    key = os.getenv("GEMINI_API_KEY", "").strip()
    if key and (not _gemini_configured or key != _active_api_key):
        try:
            genai.configure(api_key=key, transport="rest")
            _gemini_configured = True
            _active_api_key = key
        except Exception as err:
            print(f"[GeminiService] Failed to configure genai: {err}")
    return _gemini_configured

# Initial configuration attempt
get_gemini_client()
model = genai.GenerativeModel(DEFAULT_GEMINI_MODEL)

LANGUAGE_NAMES = {
    "en": "English",
    "hi": "Hindi",
    "mr": "Marathi",
    "ta": "Tamil",
}



# ── Async Diagnosis Function ─────────────────────────────────────────

async def diagnose_crop(
    image_bytes: bytes,
    district: str,
    state: str,
    soil_type: str,
    crop_type: str,
    weather_summary: str,
    season: str,
    crop_stage: str,
    language: str,
) -> dict:
    """Send crop image + context to Gemini 1.5 Flash and get structured diagnosis."""

    prompt = DIAGNOSIS_SYSTEM_PROMPT.format(
        district=district,
        state=state,
        soil_type=soil_type,
        crop_type=crop_type,
        weather_summary=weather_summary,
        season=season,
        crop_stage=crop_stage,
        language=LANGUAGE_NAMES.get(language, "English"),
    )

    image = Image.open(io.BytesIO(image_bytes))
    if image.mode != 'RGB':
        image = image.convert('RGB')

    try:
        response = await model.generate_content_async(
            [prompt, image],
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json",
                response_schema=DiagnosisResponse,
            ),
        )

        result = json.loads(response.text)

        # Inject low confidence note
        if result.get("confidence", 0) < 0.65:
            result["low_confidence_note"] = (
                "I'm not fully certain about this diagnosis. "
                "Please visit your nearest KVK for confirmation before treating."
            )

        return result

    except Exception as e:
        print(f"Gemini API Error: {e}")
        return {
            "type": "unclear",
            "name": "Unable to identify",
            "name_local": "",
            "confidence": 0.0,
            "explanation": "The analysis failed or the photo is unclear. Please retake it in good lighting.",
            "cause": "",
            "treatment_steps": [],
            "organic_option": {"description": "", "steps": []},
            "prevention": "",
            "budget_items": [],
            "total_cost_inr": 0,
            "low_confidence_note": "Analysis failed. Please try again with a clearer photo.",
        }

async def generate_alert_text(prompt: str) -> str:
    """Generate a short alert text using Gemini 1.5 Flash based on a prompt."""
    try:
        response = await model.generate_content_async(prompt)
        if response.text:
            return response.text.strip()
        return "Warning: Check your crops."
    except Exception as e:
        print(f"Gemini alert generation error: {e}")
        return "Warning: Check your crops."


async def generate_scheme_guide(
    scheme_name: str,
    benefit_description: str,
    district: str,
    state: str,
    language: str
) -> dict:
    """Generate a step-by-step scheme application guide."""
    prompt = SCHEME_GUIDE_PROMPT.format(
        scheme_name=scheme_name,
        benefit_description=benefit_description,
        district=district,
        state=state,
        language=LANGUAGE_NAMES.get(language, "English"),
    )

    try:
        response = await model.generate_content_async(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json",
                response_schema=SchemeGuideResponse,
            ),
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"Gemini Scheme Guide API Error: {e}")
        return {
            "summary": "Error analyzing this scheme. Please try again later.",
            "likely_eligible": False,
            "eligibility_reason": "Analysis failed.",
            "documents_needed": ["Aadhaar Card", "Bank Passbook", "Land Records (7/12)"],
            "application_steps": ["Visit your nearest CSC or Gram Panchayat.", "Ask about this scheme."],
            "where_to_apply": "CSC or KVK",
            "timeline": "Unknown",
            "helpline": "1551 (Kisan Call Center)"
        }


# ── Agricultural Chat System ──────────────────────────────────────────

class UpstreamAIServiceError(Exception):
    def __init__(self, message: str, code: str = "UPSTREAM_UNAVAILABLE", retryable: bool = True):
        super().__init__(message)
        self.message = message
        self.code = code
        self.retryable = retryable


CHAT_SYSTEM_PROMPT = """
You are Krishi Vikas AI, an expert and practical farming assistant for Indian agriculture.
Always respond in {language}. Use simple, farmer-friendly terms (Class 6 reading level).
Be warm, encouraging, and highly practical.

═══════════════════════════════════════════════════════════════
CRITICAL RULE — READ THIS FIRST:
The user's current message is the ONLY thing that matters. Answer EXACTLY what they ask.
NEVER override the user's current question with background context.
═══════════════════════════════════════════════════════════════

FARM CONTEXT (use to enrich your answer if relevant):
- Location: {district}, {state}
- Tracked crop(s): {crops}
- Soil type: {soil_type}
- Crop stage: {crop_stage}
- Season: {season}
- Weather today: {weather_summary}
- Recent diagnosis: {last_diagnosis}
- Latest Market Price context: {market_context}

YOUR ADVICE MUST BE HIGHLY PRACTICAL:
- When advising on diseases, pests, or nutrient deficiencies, provide SPECIFIC chemical or organic names (e.g., Chlorpyrifos, Neem oil, NPK 19:19:19).
- Give EXACT dosage (e.g., 2 ml/liter of water or 1 kg/acre).
- Specify timing (e.g., spray in the early morning or late evening).
- Include necessary precautions.
- ONLY recommend consulting a KVK (Krishi Vigyan Kendra) if the problem is completely unidentifiable, highly complex, or legal. Do NOT use it as a generic fallback.

STRUCTURE YOUR RESPONSE:
When diagnosing a problem, giving a solution, or advising, structure your reply using these exact headings (translated to {language} if necessary):
Problem: [Identify the issue]
Cause: [Why it happens]
Immediate Action: [Specific pesticide/fertilizer, dosage, timing, and precautions]
Prevention: [How to stop it next time]

Keep replies concise, clear, and actionable. Use bullet points for readability.
"""


async def chat_with_farmer(
    message: str,
    language: str,
    district: str,
    state: str,
    soil_type: str,
    crops: list[str],
    weather_summary: str,
    season: str,
    crop_stage: str,
    last_diagnosis: str,
    market_context: str = "None requested",
) -> dict:
    """
    Context-aware agricultural chat assistant.
    Primary: Google Gemini API (gemini-2.5-flash / configurable model).
    Secondary / Fallback: Groq (qwen/qwen3.8-27b, openai/gpt-oss-20b).
    Raises UpstreamAIServiceError if all upstream providers are unavailable.
    """
    import asyncio

    crops_str = ", ".join(crops) if crops else "Unknown"
    sys_prompt = CHAT_SYSTEM_PROMPT.format(
        language=LANGUAGE_NAMES.get(language, "English"),
        district=district or "Unknown",
        state=state or "India",
        soil_type=soil_type or "Unknown",
        crops=crops_str,
        weather_summary=weather_summary or "Unknown",
        season=season or "Current season",
        crop_stage=crop_stage or "Current stage",
        last_diagnosis=last_diagnosis if last_diagnosis else "None recently",
        market_context=market_context
    )

    full_prompt = f"{sys_prompt}\n\nFarmer: {message}\nAssistant:"

    # 1. Primary AI Provider: Google Gemini
    if get_gemini_client():
        # Models to attempt: primary configured, then default fallback if different
        gemini_models_to_try = [CONFIGURED_GEMINI_MODEL]
        if DEFAULT_GEMINI_MODEL not in gemini_models_to_try:
            gemini_models_to_try.append(DEFAULT_GEMINI_MODEL)

        for g_model_name in gemini_models_to_try:
            try:
                gmodel = genai.GenerativeModel(g_model_name)
                # Call generate_content in thread with strict timeout
                def _call_gemini():
                    return gmodel.generate_content(
                        full_prompt,
                        request_options={"timeout": 20.0}
                    )
                
                resp = await asyncio.wait_for(asyncio.to_thread(_call_gemini), timeout=25.0)
                if resp and resp.text:
                    reply_text = resp.text.strip()
                    return {
                        "reply": reply_text,
                        "response": reply_text,
                        "intent_type": "general",
                        "provider": f"gemini/{g_model_name}",
                        "success": True,
                    }
            except asyncio.TimeoutError:
                print(f"[GeminiService] Model {g_model_name} timed out after 25s.")
            except Exception as gemini_err:
                print(f"[GeminiService] Error with model {g_model_name}: {type(gemini_err).__name__}")

    # 2. Secondary AI Provider: Groq (Fallback)
    groq_key = os.getenv("GROQ_API_KEY", "").strip()
    if groq_key:
        try:
            from groq import AsyncGroq
            groq_client = AsyncGroq(api_key=groq_key)
            groq_models = ["qwen/qwen3.8-27b", "openai/gpt-oss-20b", "openai/gpt-oss-120b"]

            for m_name in groq_models:
                try:
                    groq_resp = await asyncio.wait_for(
                        groq_client.chat.completions.create(
                            messages=[
                                {"role": "system", "content": sys_prompt},
                                {"role": "user", "content": message}
                            ],
                            model=m_name,
                            temperature=0.4,
                            max_tokens=450,
                        ),
                        timeout=20.0
                    )
                    if groq_resp.choices:
                        reply_text = groq_resp.choices[0].message.content.strip()
                        return {
                            "reply": reply_text,
                            "response": reply_text,
                            "intent_type": "general",
                            "provider": f"groq/{m_name}",
                            "success": True,
                        }
                except Exception as groq_err:
                    print(f"[GeminiService] Groq fallback failed with model {m_name}: {type(groq_err).__name__}")
        except Exception as groq_init_err:
            print(f"[GeminiService] Groq client initialization failed: {groq_init_err}")

    # If all providers failed or are unconfigured:
    raise UpstreamAIServiceError(
        message="The AI assistant is temporarily unavailable. Please try again in a moment.",
        code="UPSTREAM_UNAVAILABLE",
        retryable=True
    )

