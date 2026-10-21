# Krishi Vikas AI — Phase 0 Deployment Readiness

**Document:** `docs/architecture/PHASE_0_DEPLOYMENT_READINESS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Hosting Architecture & Render Configuration

The backend is configured for cloud deployment on **Render**:

| Parameter | Configuration Setting | Verification Source |
| :--- | :--- | :--- |
| **Platform** | Render (Web Service) | `backend/Procfile` & Architecture Specs |
| **Procfile Command** | `web: uvicorn main:app --host 0.0.0.0 --port $PORT` | `backend/Procfile` |
| **Python Runtime** | Python 3.10+ / 3.14 (Linux container on Render) | `backend/requirements.txt` |
| **Root Directory** | `backend/` | Render service settings |
| **Build Command** | `pip install -r requirements.txt` | Standard Python build pipeline |
| **Start Command** | `uvicorn main:app --host 0.0.0.0 --port $PORT` | `backend/Procfile` |
| **Public API URL** | `https://krishi-vikas-ai.onrender.com` | `flutter_app/lib/core/constants/app_constants.dart` |
| **Health Check Route** | `GET /health` | `backend/main.py` |

---

## 2. CORS & Network Security Configuration

FastAPI initializes `CORSMiddleware` in `backend/main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows mobile HTTP client & web preflights
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```
- **Mobile Compatibility:** Flutter mobile native clients (Android/iOS) do not enforce browser CORS, but web and emulator environments require permissive preflights.
- **Header Forwarding:** Allows `Authorization`, `Content-Type`, and custom tracking headers (`x-request-id`).

---

## 3. Operational Constraints & Production Gotchas

1. **Render Free-Tier Spin-Down (Cold Start):**
   - Free/starter web services spin down after 15 minutes of inactivity.
   - Initial cold-start request latency is typically **30 to 50 seconds**.
   - *Mitigation in Flutter:* `ApiService` configured with a 30-second timeout, with user-facing retry dialogues if the first request times out.
2. **REST vs gRPC Transport on Render:**
   - On containerized PaaS platforms like Render, gRPC connections for Google AI can fail or hang during stream negotiation.
   - *Verified Fix:* Explicitly using `transport="rest"` in `google.generativeai.configure(...)` ensures rock-solid HTTP/1.1 REST calls to the Google Generative Language endpoints.
3. **Image Payload Constraints:**
   - High-resolution crop images (e.g. 15-20MB RAW camera photos) can cause timeouts over rural 3G/4G connections.
   - *Mitigation in Flutter:* Mobile app compresses and resizes photos to max 1920x1080 JPEG prior to multipart upload.
