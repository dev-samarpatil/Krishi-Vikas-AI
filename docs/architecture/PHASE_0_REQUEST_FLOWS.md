# Krishi Vikas AI — Phase 0 Request Flows & Lifecycles

**Document:** `docs/architecture/PHASE_0_REQUEST_FLOWS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. AI Chat Request Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Farmer as Farmer / User
    participant Flutter as Flutter ChatScreen
    participant ChatState as ChatState / ApiService
    participant Backend as FastAPI (/api/v1/chat)
    participant AIService as AIService (Python)
    participant Gemini as Gemini 2.5 Flash
    participant Groq as Groq (Fallback)

    Farmer->>Flutter: Types question (e.g., in Marathi / English)
    Flutter->>ChatState: sendMessage(text, lang)
    ChatState->>Backend: POST /api/v1/chat {message, language, history, session_id}
    Backend->>AIService: generate_chat_response(...)
    alt Primary Provider (Gemini 2.5 Flash)
        AIService->>Gemini: generate_content(prompt, transport="rest")
        Gemini-->>AIService: Return markdown advisory response
    else Gemini Fails (429 Quota / Network Error)
        AIService->>Groq: Fallback call (qwen/qwen3.8-27b)
        Groq-->>AIService: Return fallback response
    end
    AIService-->>Backend: ChatResponse model
    Backend-->>ChatState: 200 OK {response, language, quick_replies, request_id}
    ChatState-->>Flutter: Render chat bubble
    Flutter-->>Farmer: Display agricultural advisory
```

### Key Chat Implementation Details
- **Endpoint:** `POST /api/v1/chat` and `/chat` (aliased).
- **Request Model:** `ChatRequest` (`message: str`, `language: str = "en"`, `history: List[ChatMessage] = []`, `context: Optional[dict] = None`, `session_id: Optional[str] = None`).
- **Response Model:** `ChatResponse` (`response: str`, `detected_language: str`, `intent: str`, `quick_replies: List[str]`, `references: List[str]`, `request_id: str`).
- **Resilience Fix:** If both Gemini and Groq fail (e.g. Gemini quota exhausted and Groq unconfigured), backend returns `502 Bad Gateway` with structured error details instead of a fake static advisory. Flutter displays a red retry bubble allowing the farmer to re-send.

---

## 2. Crop Scan Request Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Farmer as Farmer
    participant ScanUI as Flutter ScanScreen
    participant Backend as FastAPI (/api/v1/diagnose)
    participant VisionAI as Gemini 2.5 Flash Vision
    participant Supabase as Supabase (Storage & DB)
    participant ResultUI as ScanResultScreen

    Farmer->>ScanUI: Takes photo or selects image
    ScanUI->>Backend: POST /api/v1/diagnose (multipart/form-data: image, crop_hint, language)
    Backend->>Backend: PIL Image validation & MIME verification
    Backend->>VisionAI: generate_content([prompt, PIL_image], transport="rest")
    VisionAI-->>Backend: Structured JSON Diagnosis
    
    alt Image is Not a Plant/Crop
        Backend-->>ScanUI: 200 OK {type: "invalid_image", confidence: 0.0, message: "Please upload a clear crop photo"}
        ScanUI->>ResultUI: Render rejection warning with Retake button
    else Plant is Healthy
        Backend-->>ScanUI: 200 OK {type: "healthy", disease_name: "Healthy Plant", confidence: 0.95}
        ScanUI->>ResultUI: Render green Healthy Crop card
    else Plant is Diseased
        opt Storage Configured
            Backend->>Supabase: Upload image to crop-images bucket
            Backend->>Supabase: Insert diagnosis record in diagnoses table
        end
        Backend-->>ScanUI: 200 OK {type: "diseased", disease_name, confidence, symptoms, treatments}
        ScanUI->>ResultUI: Render pathology card with chemical & bio-treatments
    end
```

### Critical Findings & Verified Bug Fixes
- **Elimination of Fake Fallbacks:** The previous codebase contained a mock fallback (`"Leaf Disease Detected"`, `confidence: 0.85`) that triggered whenever Gemini Vision failed, giving farmers false diagnostic data. This was eliminated:
  - If the AI fails, an explicit `502 Bad Gateway` error is returned.
  - If a non-crop image (e.g. a shoe, chair, or random photo) is submitted, the vision prompt classifies it as `type: "invalid_image"` with `confidence: 0.0`.
  - Non-crop images are **not** written to Supabase `diagnoses`, preserving history integrity.

---

## 3. Sentinel Map Request Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Farmer as Farmer
    participant MapUI as SentinelMapScreen
    participant OSM as OpenStreetMap Tile CDN
    participant Backend as FastAPI (/api/v1/alerts/map)

    Farmer->>MapUI: Opens Sentinel Map screen
    par Tile Rendering
        MapUI->>OSM: Request raster tiles (https://tile.openstreetmap.org/{z}/{x}/{y}.png)
        OSM-->>MapUI: 256x256 PNG tiles
    and Outbreak Markers
        MapUI->>Backend: GET /api/v1/alerts/map?lat=...&lon=...
        Backend-->>MapUI: JSON GeoJSON-like alert clusters
    end
    MapUI->>MapUI: Clamp coordinates to valid WGS84 [-90..90, -180..180]
    MapUI-->>Farmer: Render interactive map with disease outbreak clusters
```

### Verified Map Fixes
- **Root Cause of Blank Map:** The previous code queried `basemaps.cartocdn.com` which blocked anonymous requests or timed out.
- **Fix:** Switched to standard OpenStreetMap raster tiles with `NetworkTileProvider()`, proper HTTP User-Agent (`com.krishivikas.ai`), legal attribution widget, and `errorTileCallback` which displays an in-app error banner if offline.

---

## 4. My Farm Request Lifecycle

- **Entry Point:** `flutter_app/lib/screens/farm/my_farm_screen.dart`
- **Data Flow:**
  - Queries `/api/v1/farm/summary?user_id=...`
  - Fetches farm profile from Supabase `farms` table and recent soil logs from `soil_logs`.
  - **Telemetry Status:** Soil moisture, NPK ratios, and temperature telemetry curves currently use deterministic algorithmic demo values rendered via `fl_chart`. Physical ESP32 sensor hardware is not yet integrated.

---

## 5. Auxiliary Modules Request Flows

| Module | Route / Endpoint | Data Source / Backing Mechanism |
| :--- | :--- | :--- |
| **Mandi Prices** | `GET /api/v1/market/prices` | Local structured dataset `backend/data/mandi_prices.json` |
| **Government Schemes** | `GET /api/v1/schemes` | Local structured dataset `backend/data/schemes.json` |
| **Weather Information** | `GET /api/v1/weather/current` | Open-Meteo REST API with local IMD weather cache fallback |
| **Disease Outbreak Alerts**| `GET /api/v1/alerts` | Algorithmic cluster aggregation based on recent crop scan locations |
| **Voice Assistance (STT/TTS)**| `POST /api/v1/voice/stt` / `/tts` | Device OS speech recognition + backend TTS synthesis endpoint |
