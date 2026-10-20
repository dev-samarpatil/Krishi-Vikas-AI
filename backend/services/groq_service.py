import os
from dotenv import load_dotenv
from groq import AsyncGroq
import json

load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

_groq_client: AsyncGroq | None = None

def get_groq_client() -> AsyncGroq | None:
    global _groq_client
    if _groq_client is not None:
        return _groq_client
    key = os.getenv("GROQ_API_KEY", "").strip()
    if key:
        _groq_client = AsyncGroq(api_key=key)
    return _groq_client

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
    """Send context-aware message to Groq Llama-3 to get response for farmer."""
    
    client = get_groq_client()

    LANGUAGE_NAMES = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
        "ta": "Tamil"
    }
    
    crops_str = ", ".join(crops) if crops else "Unknown"
    
    sys_prompt = CHAT_SYSTEM_PROMPT.format(
        language=LANGUAGE_NAMES.get(language, "English"),
        district=district,
        state=state,
        soil_type=soil_type,
        crops=crops_str,
        weather_summary=weather_summary,
        season=season,
        crop_stage=crop_stage,
        last_diagnosis=last_diagnosis if last_diagnosis else "None recently",
        market_context=market_context
    )
    
    # Try Groq with verified active models
    if client:
        models_to_try = ["qwen/qwen3.8-27b", "openai/gpt-oss-20b", "openai/gpt-oss-120b"]
        for model_name in models_to_try:
            try:
                response = await client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": sys_prompt},
                        {"role": "user", "content": message}
                    ],
                    model=model_name,
                    temperature=0.4,
                    max_tokens=450,
                )
                reply_text = response.choices[0].message.content.strip() if response.choices else "Sorry, I couldn't process that."
                return {
                    "reply": reply_text,
                    "response": reply_text,
                    "intent_type": "general",
                    "provider": f"groq/{model_name}",
                    "success": True,
                }
            except Exception as groq_err:
                print(f"[GroqService] Error with model {model_name}: {groq_err}")

    # Fallback to Gemini if Groq is unavailable
    try:
        import asyncio
        import google.generativeai as genai
        gemini_key = os.getenv("GEMINI_API_KEY")
        if gemini_key:
            genai.configure(api_key=gemini_key, transport="rest")
            gmodel = genai.GenerativeModel("gemini-2.5-flash")
            full_prompt = f"{sys_prompt}\n\nFarmer: {message}\nAssistant:"
            gemini_resp = await asyncio.to_thread(gmodel.generate_content, full_prompt)
            reply_text = gemini_resp.text.strip()
            return {
                "reply": reply_text,
                "response": reply_text,
                "intent_type": "general",
                "provider": "gemini/gemini-2.5-flash",
                "success": True,
            }
    except Exception as gemini_err:
        print(f"[GroqService] Gemini fallback error: {gemini_err}")

    error_msg = "The AI farming assistant is temporarily unavailable. Please try again soon."
    return {
        "reply": error_msg,
        "response": error_msg,
        "intent_type": "error",
        "success": False,
    }

