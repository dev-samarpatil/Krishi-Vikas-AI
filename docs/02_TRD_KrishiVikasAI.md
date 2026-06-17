# Technical Requirements Document — Krishi Vikas AI
**Version:** 2.0 | **Date:** June 2026

---

## 1. Architecture Overview

```
[Flutter App / Next.js PWA]
        ↓ HTTPS
[FastAPI Backend — Render]
        ↓
[Supabase PostgreSQL + Auth]
[Roboflow Hosted API]
[Gemini 1.5 Flash API]
[Groq Llama 3.1 70B]
[Sarvam STT/TTS]
[OpenWeather API]
[Agmarknet data.gov.in]
[Firebase Cloud Messaging]
```

---

## 2. Frontend Stack

| Layer | Technology | Reason |
|---|---|---|
| Mobile App | Flutter 3.x (Dart) | Single codebase Android + iOS + Web; best Android performance; large Indian dev community |
| Web App | Next.js 14 PWA (keep existing) | Already deployed; web fallback for feature phones |
| State Management | Riverpod (Flutter) | Better than Provider; testable; no BuildContext dependency |
| Navigation | GoRouter | Deep linking support; declarative |
| i18n | Flutter Intl + ARB files | Full translation coverage; zero hardcoded strings |
| Maps | flutter_map + OpenStreetMap | Free; no Google Maps billing surprise |
| Push Notifications | firebase_messaging | FCM — industry standard for Android |
| Local Storage | Hive (Flutter) | Fast NoSQL local DB; works offline |
| Camera | image_picker + camera | Standard Flutter camera access |
| HTTP | Dio | Interceptors for auth headers; retry logic |

---

## 3. Backend Stack

| Layer | Technology | Reason |
|---|---|---|
| Framework | FastAPI Python 3.11 | Already running; async; fast |
| Server | Uvicorn + Gunicorn | Production-grade ASGI |
| Database | Supabase PostgreSQL | Already connected; RLS built-in; free tier |
| Auth | Supabase Auth (JWT) | Row-level security; OTP via phone number (farmer-friendly) |
| Task Queue | APScheduler (in-process) | Weather cron jobs; lightweight; no Redis needed at this scale |
| Push | Firebase Admin SDK | Send FCM notifications from backend |
| Hosting | Render (upgrade to paid $7/mo) | No sleep on paid tier — critical for demo and prod |

---

## 4. Database — Supabase PostgreSQL

See separate Backend Schema document for full table definitions.

Key tables: `users`, `farms`, `diagnoses`, `chat_sessions`, `soil_logs`, `farm_timeline`, `weather_alerts_log`, `push_tokens`

---

## 5. Authentication

- **Method:** Supabase Auth with phone number OTP (no email — farmers don't have email)
- **Flow:** Enter phone → receive SMS OTP → verified → JWT issued
- **Token:** JWT stored in Flutter Hive / Next.js localStorage
- **RLS:** All Supabase queries scoped to `auth.uid()` — farmers can only see their own data
- **Fallback:** Allow guest mode (localStorage only) for first-time users before signup

---

## 6. External APIs

| API | Usage | Key Storage | Limit |
|---|---|---|---|
| Roboflow Hosted API | CNN crop disease classification | Backend `.env` | 10,000 calls/month free |
| Gemini 1.5 Flash | Fallback diagnosis + out-of-scope crops | Backend `.env` | 1,500/day free |
| Groq Llama 3.1 70B | AI chat responses | Backend `.env` | 14,400 req/day free |
| Sarvam Saaras | STT (speech to text) | Backend `.env` | Check plan |
| Sarvam Bulbul v3 | TTS (text to speech) | Backend `.env` | Check plan |
| OpenWeather | Current weather + forecast + map tiles | Backend `.env` | 1,000 calls/day free |
| Agmarknet | Live mandi prices | Backend `.env` (or direct) | Public API |
| Firebase FCM | Push notifications | Backend service account JSON | Free |
| Nominatim OSM | Reverse geocoding | No key needed | Fair use |
| Supabase | DB + Auth | Backend `.env` | Free tier |

**All API keys stored server-side in backend `.env` only. Never in Flutter app or frontend.**

---

## 7. Scan Feature — Hybrid AI Architecture

```
User takes photo
        ↓
Backend receives image
        ↓
Step 1: Roboflow API call
        ↓
Confidence >= 70% AND crop in scope?
    YES → Return Roboflow result
    NO  → Step 2: Gemini 1.5 Flash
                  (full image + context)
                        ↓
                  Return Gemini result
        ↓
Combine with: GPS district, soil type, crop,
weather, stage → final structured response
        ↓
Return to Flutter app (farmer never sees which model ran)
```

---

## 8. Chat — System Prompt Architecture

Every Groq call includes a system prompt with full farm context:

```
You are an expert Indian agricultural advisor. 
Farmer details: {crop}, {stage}, {district}, {state}, {soil_type}, {farm_size}
Recent weather: {weather_summary}
Past diagnoses: {last_3_diagnoses}
Language: Respond ONLY in {language}.
Rules:
- Give specific, actionable, step-by-step advice
- Name exact pesticides/fertilisers with dosage
- Give timing (morning/evening, days after sowing)
- Never say "consult KVK" as the only advice
- If unsure, give best likely answer then suggest KVK as additional resource
```

---

## 9. Push Notification Architecture

```
APScheduler cron — every 3 hours:
  For each unique farmer GPS location:
    → OpenWeather API call
    → Check thresholds:
        temp drop > 5°C in 6hrs → alert
        rain > 20mm in 12hrs → alert  
        wind > 40kmph → alert
        frost risk (temp < 4°C) → alert
    → If alert triggered:
        → Get all farmers at that location
        → Generate crop-specific advice (Groq)
        → Send FCM push via Firebase Admin SDK
        → Log to weather_alerts_log table
```

---

## 10. i18n Architecture

- Flutter: ARB files per language (`app_en.arb`, `app_hi.arb`, `app_mr.arb`, `app_ta.arb`)
- Every UI string referenced as `AppLocalizations.of(context).someKey`
- Zero hardcoded strings in any widget
- Backend chat/diagnosis responses: language passed in every API call, model responds in that language
- Audit process: grep for any hardcoded strings before each release

---

## 11. Offline Strategy

| Feature | Offline Behaviour |
|---|---|
| Crop scan | Queued locally, sent when online |
| Chat | Show "No connection" with last response cached |
| Mandi prices | Show cached prices with "Last updated X hours ago" |
| Weather | Show cached forecast |
| Government schemes | Always available (static JSON bundled) |
| KVK directory | Always available (bundled) |
| Soil score | Read/write from Hive local DB, sync to Supabase when online |

---

## 12. Deployment Plan

| Component | Platform | Plan |
|---|---|---|
| Flutter Android | Google Play Store | Free (one-time $25) |
| Flutter iOS | App Store | $99/year (later) |
| Next.js PWA | Vercel | Free tier |
| FastAPI Backend | Render | $7/month (no sleep) |
| Database | Supabase | Free tier (upgrade at scale) |
| Push | Firebase | Free tier |

---

## 13. Security Requirements

- All API keys server-side only
- Supabase RLS enabled on all tables
- JWT expiry: 7 days, refresh token: 30 days
- Image uploads: validate file type + size (<5MB) before processing
- Rate limiting on scan endpoint: 20 requests/hour per user
- HTTPS only (Render + Vercel enforce this)
- No PII in logs

---
