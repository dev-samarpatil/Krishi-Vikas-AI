# Krishi Vikas AI — Phase 0 AI Provider & Fallback Inventory

**Document:** `docs/architecture/PHASE_0_AI_PROVIDER_INVENTORY.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. AI Provider Mapping

| Feature | Primary Provider | Configured Model | Source Files | Input Type | Output Consumer | Fallback Behavior | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Conversational Chatbot** | **Google Gemini** | `gemini-2.5-flash` (`transport="rest"`) | `backend/services/ai_service.py`<br>`backend/routers/chat.py` | Text (Hindi, Marathi, English) + chat history | `flutter_app/lib/screens/chat/chat_screen.dart` | Groq fallback (`qwen/qwen3.8-27b`), followed by structured HTTP 502 with error bubble | **VERIFIED WORKING** (Subject to API key quota) |
| **Crop Scan (Vision)** | **Google Gemini Multimodal** | `gemini-2.5-flash` (`transport="rest"`) | `backend/services/ai_service.py`<br>`backend/routers/diagnose.py` | Multipart Image (`image/jpeg`, `image/png`) | `flutter_app/lib/screens/scan/scan_result_screen.dart` | No mock fallback; returns explicit HTTP 502 on model failure; returns `type: "invalid_image"` on non-plant photos | **VERIFIED WORKING** (Grounding verified; hit 429 quota in live test) |
| **Secondary Chat Fallback** | **Groq Cloud** | `qwen/qwen3.8-27b` / `llama-3.3-70b-versatile` | `backend/services/ai_service.py` | Text prompt | Internal fallback inside `AIService` | Re-raises exception if Groq fails or `GROQ_API_KEY` is unset | **IMPLEMENTED, CONDITIONAL** |
| **Roboflow Inference** | **Roboflow Hosted API** | Optional model | `backend/services/vision_service.py` | Image binary | Alternative crop vision pipeline | Skips if `ROBOFLOW_API_KEY` is not provided | **INACTIVE / OPTIONAL** |

---

## 2. Gemini Configuration & SDK Analysis

### 2.1 Initialization
- Configured via:
  ```python
  import google.generativeai as genai
  genai.configure(api_key=settings.GEMINI_API_KEY, transport="rest")
  ```
- **Crucial Setting:** `transport="rest"` was explicitly required to avoid gRPC connection hangs on restricted Windows and Render hosting environments.
- **Model Identifier:** `gemini-2.5-flash` is used across both chat and vision methods.

### 2.2 Deprecation Notice
The Google Generative AI package logs:
```
FutureWarning: All support for the `google.generativeai` package has ended. 
It will no longer be receiving updates or bug fixes. 
Please switch to the `google.genai` package as soon as possible.
```
*Impact on Phase 1:* Moving chatbot generation to Groq in Phase 1 isolates the text pipeline and decouples it from this deprecated package. Vision will remain on Gemini until a planned migration to `google.genai` or specialized vision models.

---

## 3. Fallback & Mock Behavior Audit

### 3.1 Historical Vulnerability (Eliminated)
In previous revisions, whenever the Gemini Vision API failed (due to network timeout, missing key, or rate limits), the backend caught the error and returned a hardcoded success response:
```json
{
  "disease_name": "Leaf Disease Detected",
  "confidence": 0.85,
  "symptoms": ["Yellowing of leaves", "Brown spots"],
  "treatments": {"organic": ["Neem oil spray"], "chemical": ["Mancozeb"]}
}
```
*Audit Finding:* This mock response created a catastrophic safety risk for farmers by presenting fabricated pathology data as genuine diagnosis.

### 3.2 Current Verified Behavior
- The mock fallback has been completely removed from `analyze_crop_image`.
- If Gemini Vision raises an error or exhausts quota, the backend now returns `HTTP 502 Bad Gateway` with the actual provider error message.
- If the image contains a non-plant subject (e.g., shoe, room, face), the system prompts Gemini to inspect visual features and returns `type: "invalid_image"`, `confidence: 0.0`.
- The Flutter client inspects `type: "invalid_image"` and renders an explicit rejection warning card directing the farmer to retake the photo.

---

## 4. Chat & Vision Service Decoupling for Phase 1

`AIService` (`backend/services/ai_service.py`) encapsulates both `generate_chat_response` and `analyze_crop_image`.
- **Finding:** While both methods currently utilize `gemini-2.5-flash`, their execution paths are separate methods inside the service class.
- **Phase 1 Safety Rule:** When Phase 1 migrates `generate_chat_response` to Groq, `analyze_crop_image` must remain completely intact and untouched. The Groq SDK will only be wired into the conversational pipeline.
