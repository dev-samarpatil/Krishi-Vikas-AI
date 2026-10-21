# Krishi Vikas AI — Phase 0 Configuration & Environment Inventory

**Document:** `docs/architecture/PHASE_0_CONFIGURATION_INVENTORY.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Environment Variable Audit (Names Only — Zero Secret Exposure)

| Variable Name | Consuming Component | Local Dev Requirement | Production Requirement | Contains Secret? | Presence Verified in `.env` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GEMINI_API_KEY` | `backend/services/ai_service.py`<br>`backend/core/config.py` | Required for Chat & Vision | Required for Chat & Vision | **YES** | Verified present |
| `GROQ_API_KEY` | `backend/services/ai_service.py` | Optional fallback (Mandatory in Phase 1) | Optional fallback (Mandatory in Phase 1) | **YES** | Verified present |
| `SUPABASE_URL` | `backend/core/supabase.py`<br>`backend/core/config.py` | Required for DB & Storage | Required for DB & Storage | No (Public URL) | Verified present |
| `SUPABASE_KEY` / `SUPABASE_ANON_KEY` | `backend/core/supabase.py` | Required for client queries | Required for client queries | **YES** | Verified present |
| `SUPABASE_SERVICE_KEY` | `backend/core/supabase.py` | Optional for backend workers | Required for backend admin tasks | **YES** | Verified present |
| `ROBOFLOW_API_KEY` | `backend/services/vision_service.py` | Optional | Optional | **YES** | Configured/Optional |
| `ROBOFLOW_MODEL` | `backend/services/vision_service.py` | Optional | Optional | No | Configured/Optional |
| `ENVIRONMENT` | `backend/core/config.py` | Optional (default: `development`) | Recommended (`production`) | No | Verified present |
| `PORT` | Render runtime / `backend/Procfile` | Optional (default: `8000`) | Required (injected by Render) | No | Managed by host |
| `BACKEND_URL` | `flutter_app/lib/core/constants/app_constants.dart` | `http://10.0.2.2:8000` (emulator) / `http://localhost:8000` | `https://krishi-vikas-ai.onrender.com` | No | Verified in Flutter constants |
| `CORS_ORIGINS` | `backend/main.py` | Optional (default `["*"]`) | Configurable list of domains | No | Configured in FastAPI |
| `WEATHER_API_KEY` | `backend/routers/weather.py` | Optional (falls back to Open-Meteo) | Optional | **YES** | Optional |
| `FCM_SERVER_KEY` | `backend/services/notification_service.py` | Optional | Optional | **YES** | Optional |

---

## 2. Hardcoded Secret & Tracked File Audit

A comprehensive scan across all Git-tracked source code files was performed:
- **No hardcoded secret keys** were found in `backend/*.py`, `flutter_app/lib/*.dart`, or markdown files.
- The root `.env` file is properly excluded by `.gitignore` and is **not tracked in Git**.
- Production credentials are injected via environment variables in the Render dashboard and local `.env` file.
- Client-side constants (`flutter_app/lib/core/constants/app_constants.dart`) only reference the public Render domain (`https://krishi-vikas-ai.onrender.com`) and default timeouts. No private API keys or database service keys are bundled into the Flutter application code.
