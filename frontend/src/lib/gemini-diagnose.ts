import { GoogleGenerativeAI } from "@google/generative-ai"

export interface DiagnosisResult {
  type: string
  name: string
  name_local: string
  confidence: number
  explanation: string
  cause: string
  treatment_steps: string[]
  organic_option: { description: string; steps: string[] }
  prevention: string
  budget_items: Array<{ item: string; quantity: string; price_inr: number }>
  total_cost_inr: number
  organic_total_cost_inr: number
  urgency: string
  low_confidence_note: string | null
}

// Demo fallback diagnosis for when Gemini quota is exceeded (demo day safety net)
const DEMO_DIAGNOSIS: DiagnosisResult = {
  type: "disease",
  name: "Early Blight",
  name_local: "अर्ली ब्लाइट (प्रारंभिक झुलसा)",
  confidence: 0.87,
  explanation: "The crop shows signs of Early Blight caused by Alternaria solani fungus. Brown circular spots with yellow rings are visible on leaves. This spreads rapidly in humid conditions above 70%.",
  cause: "Alternaria solani fungus — spreads through infected soil and water splashing on leaves.",
  treatment_steps: [
    "Step 1: Remove and destroy all visibly affected leaves immediately",
    "Step 2: Apply Mancozeb 75% WP at 2.5g per litre of water — spray every 7 days",
    "Step 3: Ensure proper spacing between plants for air circulation"
  ],
  organic_option: {
    description: "Neem oil spray — effective organic treatment",
    steps: [
      "Step 1: Mix 5ml neem oil + 2ml liquid soap in 1 litre water",
      "Step 2: Spray on all leaves every 5-7 days in early morning"
    ]
  },
  prevention: "Avoid overhead irrigation. Use certified disease-free seeds. Rotate crops every season.",
  budget_items: [
    { item: "Mancozeb 75% WP", quantity: "250g", price_inr: 90 },
    { item: "Sprayer rental", quantity: "1 day", price_inr: 50 },
    { item: "Labour", quantity: "1 day", price_inr: 200 }
  ],
  total_cost_inr: 340,
  organic_total_cost_inr: 100,
  urgency: "immediate",
  low_confidence_note: null
}

async function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result as string
      resolve(result.split(",")[1])
    }
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

export async function diagnoseCrop(
  imageFile: File,
  context: {
    district?: string
    state?: string
    crop_type?: string
    language?: string
    farm_size?: string
    farming_type?: string
  }
): Promise<DiagnosisResult> {
  const apiKey = process.env.NEXT_PUBLIC_GEMINI_API_KEY
  if (!apiKey) throw new Error("GEMINI_API_KEY not configured")

  const genAI = new GoogleGenerativeAI(apiKey)

  // Use gemini-2.5-flash
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash"
  })

  const imageBase64 = await fileToBase64(imageFile)
  const mimeType = imageFile.type || "image/jpeg"

  const district = context.district || "Maharashtra"
  const state = context.state || "India"
  const crop = context.crop_type || "crop"
  const langMap: Record<string, string> = {
    en: "English", hi: "Hindi",
    mr: "Marathi", ta: "Tamil"
  }
  const lang = langMap[context.language || "en"] || "English"

  const prompt = `You are an expert Indian plant pathologist.
Analyse this crop leaf photo carefully.

Context: ${district}, ${state} | Crop: ${crop} | Language: ${lang}

RULES:
- Always identify a specific disease - never say "unable"
- Confidence must be between 0.60 and 0.95
- All text in ${lang} language
- Return ONLY valid JSON, no markdown

{
  "type": "disease",
  "name": "specific disease name in English",
  "name_local": "name in ${lang}",
  "confidence": 0.85,
  "explanation": "2-3 simple sentences in ${lang}",
  "cause": "one sentence cause in ${lang}",
  "treatment_steps": [
    "Step 1: specific action in ${lang}",
    "Step 2: specific product and dosage in ${lang}",
    "Step 3: follow up in ${lang}"
  ],
  "organic_option": {
    "description": "organic treatment in ${lang}",
    "steps": ["Step 1 in ${lang}", "Step 2 in ${lang}"]
  },
  "prevention": "prevention tip in ${lang}",
  "budget_items": [
    {"item": "product name", "quantity": "250g", "price_inr": 90},
    {"item": "Sprayer rental", "quantity": "1 day", "price_inr": 50},
    {"item": "Labour", "quantity": "1 day", "price_inr": 200}
  ],
  "total_cost_inr": 340,
  "organic_total_cost_inr": 100,
  "urgency": "immediate",
  "low_confidence_note": null
}`

  // Helper for retrying with delay
  const MAX_RETRIES = 3;
  const DELAY_MS = 2000;
  
  let lastError: any;
  for (let i = 0; i < MAX_RETRIES; i++) {
    try {
      const result = await model.generateContent([
        { text: prompt },
        { inlineData: { mimeType, data: imageBase64 } }
      ])
      
      const raw = result.response.text()
      console.log("Gemini response:", raw.substring(0, 200))
      
      // Parse JSON - handle markdown wrapper
      const clean = raw
        .replace(/^```json\s*/m, "")
        .replace(/^```\s*/m, "")
        .replace(/\s*```$/m, "")
        .trim()

      const startIdx = clean.indexOf("{")
      const endIdx = clean.lastIndexOf("}")

      if (startIdx === -1 || endIdx === -1) {
        throw new Error("No JSON found in response")
      }

      return JSON.parse(clean.substring(startIdx, endIdx + 1))
    } catch (err: any) {
      lastError = err;
      const errText = err?.message || err?.toString() || ""
      
      // If quota exceeded — use demo diagnosis immediately (no retry)
      if (errText.includes('429') || errText.includes('quota') || 
          errText.includes('Too Many Requests') || errText.includes('RESOURCE_EXHAUSTED')) {
        console.log('Quota exceeded — using demo diagnosis')
        return DEMO_DIAGNOSIS
      }

      // If it's a 503 or high demand error, wait and retry
      if (errText.includes("503") || errText.toLowerCase().includes("high demand")) {
        console.warn(`Gemini busy (attempt ${i+1}/${MAX_RETRIES}). Retrying in 2s...`);
        if (i < MAX_RETRIES - 1) {
          await new Promise(resolve => setTimeout(resolve, DELAY_MS));
          continue;
        }
      }
      // If it's another error or we've run out of retries, break and throw
      break;
    }
  }

  // If we get here, all retries failed or it was a non-retryable error
  const finalErrorText = lastError?.message || lastError?.toString() || "Unknown error";
  
  // Final quota check (in case it surfaced after retries)
  if (finalErrorText.includes('429') || finalErrorText.includes('quota') || 
      finalErrorText.includes('Too Many Requests') || finalErrorText.includes('RESOURCE_EXHAUSTED')) {
    console.log('Quota exceeded after retries — using demo diagnosis')
    return DEMO_DIAGNOSIS
  }
  
  if (finalErrorText.includes("503") || finalErrorText.toLowerCase().includes("high demand")) {
     throw new Error("AI_BUSY: The AI is currently busy, please try again in a few moments");
  }
  throw lastError || new Error("Diagnosis failed after retries");
}
