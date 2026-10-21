# Krishi Vikas AI — Phase 0 Feature Status Audit

**Document:** `docs/architecture/PHASE_0_FEATURE_STATUS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Feature Status Criteria

- **VERIFIED WORKING:** Behavior executed and passed automated/manual tests.
- **PARTIALLY VERIFIED:** Core logic, schemas, and UI components verified, but full end-to-end live flow is subject to external constraints (e.g. API quotas, network).
- **IMPLEMENTED, UNVERIFIED:** Source code and routers exist, but runtime execution on device has not been performed.
- **BROKEN:** Reproducible failure without resolution.
- **MOCK/DEMO ONLY:** Workflow deliberately uses simulated, static, or algorithmic dummy data.
- **NOT IMPLEMENTED:** No implementation exists in the current repository.
- **UNKNOWN/BLOCKED:** Insufficient access or unresolvable dependencies prevent verification.

---

## 2. Evidence-Based Module Status Matrix

| Module | Frontend Entry Point | Backend Route / Service | Data Source | Test Coverage | Current Status | Notes / Next Action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Home Dashboard** | `screens/home/home_screen.dart` | `GET /api/v1/farm/summary`<br>`GET /api/v1/weather/current` | Backend & Local Preferences | Smoke tested in `widget_test.dart` | **VERIFIED WORKING** | UI and bottom navigation functional |
| **Sentinel Map** | `screens/map/sentinel_map_screen.dart` | `GET /api/v1/alerts/map` | OpenStreetMap CDN + Alert clusters | 3 unit/widget tests in `widget_test.dart` | **VERIFIED WORKING** | Blank map resolved via OSM standard tiles; error banner verified |
| **Crop Scan** | `screens/scan/scan_screen.dart`<br>`screens/scan/scan_result_screen.dart` | `POST /api/v1/diagnose` | Gemini 2.5 Flash Multimodal Vision | 4 unit tests in `test_diagnose.py` | **PARTIALLY VERIFIED** | Truthful states verified; fake fallback removed; live call hit 429 quota |
| **AI Chatbot** | `screens/chat/chat_screen.dart` | `POST /api/v1/chat`<br>`POST /chat` | Gemini 2.5 Flash + Groq fallback | 5 unit tests in `test_chat.py` | **PARTIALLY VERIFIED** | Schema & retry UI verified; live Gemini hit 429 quota; ready for Groq migration |
| **My Farm** | `screens/farm/my_farm_screen.dart` | `GET /api/v1/farm/summary` | Supabase `farms` + Algorithmic demo data | Endpoint tested in `test_api_endpoints.py` | **MOCK/DEMO ONLY** | Soil moisture/NPK telemetry curves use algorithmic demo data |
| **Mandi Prices** | `screens/market/mandi_screen.dart` | `GET /api/v1/market/prices` | `backend/data/mandi_prices.json` | Tested in `test_api_endpoints.py` | **VERIFIED WORKING** | Reads static state/district market prices |
| **Govt Schemes** | `screens/schemes/schemes_screen.dart` | `GET /api/v1/schemes` | `backend/data/schemes.json` | Tested in `test_api_endpoints.py` | **VERIFIED WORKING** | Catalog of agricultural subsidies and insurance |
| **Weather** | `screens/weather/weather_screen.dart` | `GET /api/v1/weather/current` | Open-Meteo REST API | Endpoint tested in `test_api_endpoints.py` | **PARTIALLY VERIFIED** | Weather caching works; live external call depends on connection |
| **Disease Alerts** | `screens/alerts/alerts_screen.dart` | `GET /api/v1/alerts` | Cluster aggregation service | Endpoint tested in `test_api_endpoints.py` | **PARTIALLY VERIFIED** | GeoJSON generation verified; push notification delivery unverified |
| **Voice Features** | `widgets/voice_mic_button.dart` | `POST /api/v1/voice/stt`<br>`POST /api/v1/voice/tts` | Device STT / TTS plugins | None (hardware dependent) | **IMPLEMENTED, UNVERIFIED** | Requires physical device microphone and speaker |
| **Authentication** | `screens/auth/login_screen.dart` | Supabase Auth API | Supabase `auth.users` | Schema verified in migration SQL | **IMPLEMENTED, UNVERIFIED** | Phone OTP flow exists; requires live Supabase auth project |
| **Scan History** | `screens/scan/scan_history_screen.dart`| Supabase REST Client | Supabase `diagnoses` table | Schema verified | **PARTIALLY VERIFIED** | Reads user scan records when logged in |
| **RAG / Vector** | N/A | N/A | None | N/A | **NOT IMPLEMENTED** | No pgvector, no chunking, no embedding models |
| **Auto Irrigation**| N/A | N/A | None | N/A | **NOT IMPLEMENTED** | No ESP32 hardware or relay actuation code |
