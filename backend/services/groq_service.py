import os
from groq import AsyncGroq
import json

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()

# Create standard async client
client = AsyncGroq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None

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
    
    if not client:
        print("GROQ_API_KEY not configured. Returning fallback response.")
        fallback_msg = "I am having trouble connecting to my AI brain right now. Please try again later."
        return {
            "reply": fallback_msg,
            "response": fallback_msg,
            "intent_type": "general"
        }

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
    
    try:
        response = await client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": sys_prompt
                },
                {
                    "role": "user",
                    "content": message
                }
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.4,
            max_tokens=450,
        )
        
        reply_text = response.choices[0].message.content.strip() if response.choices else "Sorry, I couldn't process that."
        
        return {
            "reply": reply_text,
            "response": reply_text,
            "intent_type": "general" # Can be evolved with a classifier if needed
        }
        
    except Exception as e:
        print(f"Groq API Error with primary model: {e}")
        # Fallback to a smaller, more stable model
        try:
            response = await client.chat.completions.create(
                messages=[
                    {"role": "system", "content": sys_prompt},
                    {"role": "user", "content": message}
                ],
                model="llama-3.1-8b-instant",
                temperature=0.4,
                max_tokens=450,
            )
            reply_text = response.choices[0].message.content.strip() if response.choices else "Sorry, I couldn't process that."
            return {
                "reply": reply_text,
                "response": reply_text,
                "intent_type": "general"
            }
        except Exception as e2:
            print(f"Groq API Error with fallback model: {e2}")
            error_msg = "Service temporarily unavailable due to a network glitch. Try again soon."
            return {
                "reply": error_msg,
                "response": error_msg,
                "intent_type": "error"
            }
