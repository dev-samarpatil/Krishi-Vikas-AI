# Krishi Vikas AI — Phase 0 API Contract Inventory

**Document:** `docs/architecture/PHASE_0_API_CONTRACTS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Global Endpoints

### 1.1 Root Status
- **Path:** `GET /`
- **Purpose:** Service liveness verification.
- **Request:** None.
- **Response Schema:**
  ```json
  {
    "status": "online",
    "service": "Krishi Vikas AI Backend",
    "version": "1.0.0"
  }
  ```
- **Status Codes:** `200 OK`
- **Auth:** None.

### 1.2 Health Check
- **Path:** `GET /health`
- **Purpose:** Readiness probe for Render deployment and local checks.
- **Request:** None.
- **Response Schema:**
  ```json
  {
    "status": "healthy",
    "database": "connected" | "unconfigured",
    "ai_service": "operational",
    "timestamp": "2026-10-21T02:00:00Z"
  }
  ```
- **Status Codes:** `200 OK`

---

## 2. Crop Diagnosis & Treatment Router (`/api/v1`)

### 2.1 Diagnose Crop Image
- **Path:** `POST /api/v1/diagnose`
- **Purpose:** Multimodal plant disease diagnosis and leaf health analysis.
- **Request:** `multipart/form-data`
  - `file`: `UploadFile` (JPEG/PNG image binary).
  - `crop_hint`: `Optional[str]` (e.g. `"Cotton"`, `"Tomato"`).
  - `language`: `Optional[str]` (default `"en"`).
- **Response Schema (`DiagnosisResponse`):**
  ```json
  {
    "type": "diseased" | "healthy" | "invalid_image",
    "disease_name": "Late Blight" | "Healthy Plant" | "None",
    "confidence": 0.94,
    "pathogen_type": "Fungus" | null,
    "symptoms": ["Dark water-soaked lesions on leaves"],
    "treatments": {
      "organic": ["Apply Trichoderma harzianum or neem oil spray"],
      "chemical": ["Mancozeb 75 WP @ 2g/litre water"]
    },
    "preventative_measures": ["Ensure good field drainage"],
    "validation_error": null | "No plant leaf identified",
    "scan_id": "uuid-string"
  }
  ```
- **Status Codes:** `200 OK`, `400 Bad Request` (corrupted image), `502 Bad Gateway` (AI vision provider failure).
- **Consumer:** `flutter_app/lib/screens/scan/scan_screen.dart`.

### 2.2 Log Applied Treatment
- **Path:** `POST /api/v1/log_treatment`
- **Purpose:** Farmer logs treatment applied to a diagnosed crop.
- **Request Body:**
  ```json
  {
    "diagnosis_id": "uuid-string",
    "treatment_type": "chemical" | "organic",
    "treatment_name": "Mancozeb 75 WP",
    "notes": "Applied in morning"
  }
  ```
- **Response:** `{"success": true, "log_id": "uuid"}`.

---

## 3. Conversational AI Chat Router (`/api/v1/chat` & `/chat`)

### 3.1 Send Chat Message
- **Path:** `POST /api/v1/chat` (and backward-compatible alias `POST /chat`)
- **Purpose:** Real-time conversational agronomy advisor.
- **Request Body (`ChatRequest`):**
  ```json
  {
    "message": "माझ्या कापसावर बोंडअळीचा प्रादुर्भाव झाला आहे, काय करावे?",
    "language": "mr",
    "history": [
      {"role": "user", "content": "..."},
      {"role": "assistant", "content": "..."}
    ],
    "context": {"crop": "Cotton", "district": "Pune"},
    "session_id": "optional-uuid"
  }
  ```
- **Response Body (`ChatResponse`):**
  ```json
  {
    "response": "कापसावरील बोंडअळीच्या नियंत्रणासाठी खालील उपाययोजना करा...",
    "detected_language": "mr",
    "intent": "pest_control",
    "quick_replies": [
      "औषधाची फवारणी कशी करावी?",
      "सेंद्रिय उपाय कोणते आहेत?"
    ],
    "references": ["KVK Pune Agronomy Guide"],
    "request_id": "req-982314"
  }
  ```
- **Status Codes:** `200 OK`, `422 Unprocessable Entity` (invalid payload), `502 Bad Gateway` (both Gemini and Groq fail).
- **Consumer:** `flutter_app/lib/screens/chat/chat_screen.dart`.

---

## 4. Geospatial & Outbreak Router (`/api/v1/alerts`)

### 4.1 Get Outbreak Alerts List
- **Path:** `GET /api/v1/alerts`
- **Query Params:** `lat: Optional[float]`, `lon: Optional[float]`, `radius_km: Optional[int] = 50`.
- **Response:** Array of outbreak alerts with severity, affected crop, and advisory.

### 4.2 Sentinel Map Outbreak Clusters
- **Path:** `GET /api/v1/alerts/map`
- **Query Params:** `min_lat: float`, `max_lat: float`, `min_lon: float`, `max_lon: float`.
- **Response:** GeoJSON-compatible FeatureCollection containing risk polygons and marker points.
- **Consumer:** `flutter_app/lib/screens/map/sentinel_map_screen.dart`.

---

## 5. Market & Schemes Routers

### 5.1 Mandi Prices
- **Path:** `GET /api/v1/market/prices`
- **Query Params:** `crop: Optional[str]`, `state: Optional[str]`, `district: Optional[str]`.
- **Response:**
  ```json
  [
    {
      "market": "Pune APMC",
      "commodity": "Soybean",
      "min_price": 4200,
      "max_price": 4850,
      "modal_price": 4600,
      "date": "2026-10-20"
    }
  ]
  ```

### 5.2 Government Schemes
- **Path:** `GET /api/v1/schemes`
- **Query Params:** `category: Optional[str]`.
- **Response:** List of central/state agricultural schemes with eligibility, benefits, and application links.

---

## 6. Weather & Voice Routers

### 6.1 Weather Current & Forecast
- **Path:** `GET /api/v1/weather/current`
- **Query Params:** `lat: float`, `lon: float`.
- **Response:** Temperature, humidity, precipitation probability, wind speed, and spray suitability advisory.

### 6.2 Voice STT & TTS
- **Path:** `POST /api/v1/voice/stt` (audio file upload -> transcribed text).
- **Path:** `POST /api/v1/voice/tts` (text payload -> audio buffer/stream).
