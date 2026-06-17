# Implementation Plan — Krishi Vikas AI
**Version:** 2.0 | Step-by-step build phases

---

## Phase 0: Fix Existing Bugs (Day 1)
**Before anything new — make current app demo-ready.**

| Task | How | Deliverable |
|---|---|---|
| Fix Gemini API key | New Google Cloud project → aistudio.google.com → new key → `NEXT_PUBLIC_GEMINI_API_KEY` in Vercel env vars | Scan works |
| Fix Gemini model name | Change to `gemini-1.5-flash` in frontend API call | No more 404 |
| Fix Sentinel clusters | Replace hardcoded Nashik coords with `farmerLat + 0.07` offset | Clusters near blue dot |
| Fix soil score default | Change initial score from 0 to 50 | Better UX |
| Fix badge underscore | Remove `_` in "🌱_soil guardian" | Cosmetic fix |
| Upgrade Render | Paid $7/mo plan | No sleep on demo |

---

## Phase 1: Backend Upgrades (Days 2–5)

### 1.1 Supabase Schema
- Run all SQL from Backend Schema doc in Supabase SQL editor
- Enable RLS on all tables
- Create `crop-images` storage bucket
- Test with Supabase client

### 1.2 New FastAPI Endpoints
- `/farms` CRUD
- `/scan` — hybrid Roboflow + Gemini pipeline
- `/farms/{id}/diagnoses` — fetch diagnosis log
- `/farms/{id}/soil/log` — post soil action, update score
- `/farms/{id}/chat` — chat with full context injection
- `/push/register` — save FCM token

### 1.3 Improved Scan Pipeline
- Integrate Roboflow Hosted API (Python `inference-sdk` or direct HTTP)
- Confidence threshold logic (≥70% → use, <70% → Gemini)
- Context injection (district, crop, soil, weather, stage)
- Return structured JSON response

### 1.4 Improved Chat System Prompt
- Write detailed system prompt (see TRD Section 8)
- Test with 20 sample farmer queries in EN + MR
- Confirm responses are specific and actionable

### 1.5 Weather Alert Cron
- APScheduler job every 3 hours
- OpenWeather API per unique user location
- Threshold checks
- Firebase Admin SDK push send
- Log to `weather_alerts_log`

**Deliverables:** All backend endpoints working, tested with Postman/curl

---

## Phase 2: Next.js PWA Upgrades (Days 5–10)

### 2.1 Full i18n Audit
- Install `i18next` + `react-i18next`
- Create `/locales/en.json`, `hi.json`, `mr.json`, `ta.json`
- Audit every component — replace ALL hardcoded strings with `t('key')`
- Test language switch across all 11 screens

### 2.2 Multi-Farm Support
- Farm switcher UI (header dropdown)
- Farm setup flow (add/edit/delete farm)
- All screens respect selected farm context
- Persist selected farm in localStorage

### 2.3 Soil Health Per-Farm
- Fetch diagnosis log from Supabase for selected farm
- Render log list (date, disease, treatment)
- Soil score read/write from Supabase (not just localStorage)

### 2.4 Sentinel Map Fix
- GPS-relative cluster generation
- OpenWeather map tile layers for Climate Risk tab
  - Precipitation: `https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=KEY`
  - Temperature: similar URL with `temp_new`
- Layer toggle working

### 2.5 Chat Upgrades
- Add text input field alongside mic button
- Connect to improved backend system prompt
- TTS play button on AI responses

### 2.6 Mandi Location Fix
- Use farmer's actual GPS to find nearest APMC
- Filter Agmarknet results by nearest districts

**Deliverables:** PWA fully working across all features, all languages

---

## Phase 3: Flutter App Setup (Days 10–18)

### 3.1 Project Init
```bash
flutter create krishi_vikas_ai
```
Add dependencies to `pubspec.yaml`:
- `riverpod`, `go_router`, `dio`, `hive_flutter`
- `firebase_messaging`, `flutter_map`
- `image_picker`, `camera`
- `flutter_localizations`, `intl`
- `supabase_flutter`

### 3.2 Auth Screen
- Phone number input
- OTP verification via Supabase Auth
- Guest mode flow
- JWT stored in Hive

### 3.3 Onboarding / Farm Setup
- Language selection screen
- Farm details form
- GPS location with manual fallback
- Save to Supabase `farms` table

### 3.4 Bottom Navigation
- 5 tabs: Home, Map, Scan (FAB), Chat, My Farm
- GoRouter setup with all routes

### 3.5 Home Screen
- Farm selector
- Weather widget (OpenWeather)
- Outbreak alert banner
- Scan hero card
- Market prices strip
- Voice FAB

### 3.6 Scan Screen
- Camera capture + gallery upload
- Image compression
- POST to `/scan` endpoint
- Result screen with all fields
- "Save to Farm Log" → POST to `/farms/{id}/soil/log`

### 3.7 Chat Screen
- Text input + mic button
- Sarvam STT integration (mic → text)
- POST to `/farms/{id}/chat`
- Sarvam TTS on AI response (play button)
- Conversation history in Hive

### 3.8 Sentinel Map
- flutter_map with OpenStreetMap tiles
- Blue dot (geolocator package)
- Disease cluster markers
- OpenWeather tile layer overlays
- Toggle pills

### 3.9 My Farm Tab
- Farm switcher
- Farm lifecycle timeline (horizontal stepper)
- Soil health dial (CustomPainter SVG-style)
- Diagnosis log list (from Supabase)
- Government schemes list

### 3.10 Push Notifications
- Firebase Messaging setup (google-services.json)
- FCM token registration → POST to `/push/register`
- Foreground + background notification handling
- Deep link: notification tap → relevant screen

### 3.11 Full i18n
- ARB files for all 4 languages
- All widgets use `AppLocalizations.of(context).key`
- Language stored in Hive, applied at app root

**Deliverables:** Flutter Android APK working end-to-end

---

## Phase 4: Testing (Days 18–22)

| Test | Method |
|---|---|
| Scan accuracy | 50 real crop photos, check disease match |
| Voice chat | Test 20 queries in EN + MR |
| Push notifications | Trigger manually via backend, verify receive |
| Offline mode | Turn off wifi, check cached states |
| Multi-farm flow | Create 3 farms, switch between, verify data isolation |
| i18n completeness | Switch to each language, check every screen |
| Low-end device | Test on Android 8, 2GB RAM |
| Performance | App startup < 3 seconds |

---

## Phase 5: Deployment (Days 22–25)

| Task | Steps |
|---|---|
| Backend | Push to GitHub → auto-deploy on Render |
| PWA | Push to GitHub → auto-deploy on Vercel |
| Flutter Android | `flutter build apk --release` → Google Play Console → Internal Testing → Production |
| Environment variables | All API keys in Render env vars (never in code) |
| Firebase | Add `google-services.json` to Flutter (gitignored) |

---

## Phase 6: Final Polish (Days 25–28)

- App icon + splash screen (Flutter)
- Play Store listing: screenshots, description in EN + HI
- Error tracking (Sentry free tier — optional)
- Analytics (Firebase Analytics — track scan count, chat sessions, DAU)
- README update

---

## API Keys Needed — Complete List

| Key | Where to Get | Where to Add |
|---|---|---|
| Gemini API Key | aistudio.google.com | Render env: `GEMINI_API_KEY` |
| Roboflow API Key | roboflow.com → Settings | Render env: `ROBOFLOW_API_KEY` |
| Groq API Key | console.groq.com | Render env: `GROQ_API_KEY` |
| Sarvam API Key | sarvam.ai | Render env: `SARVAM_API_KEY` |
| OpenWeather API Key | openweathermap.org | Render env: `OPENWEATHER_API_KEY` |
| Supabase URL + Anon Key | supabase.com → project settings | Render env + Flutter `.env` |
| Firebase Service Account JSON | Firebase Console → Project Settings → Service Accounts | Render env (base64 encoded) |
| Firebase google-services.json | Firebase Console → Android app | Flutter `android/app/` (gitignored) |

---

## Vibe Coder — Where to Upload Docs

Upload all 5 docs to Vibe Coder's **"Project Knowledge"** or **"Context"** section (varies by platform):
- In **Cursor**: add to `.cursorrules` or `docs/` folder, reference in chat
- In **Bolt.new**: paste PRD + App Flow in the initial prompt
- In **Lovable**: upload to project context before starting
- In **v0**: paste relevant sections per component you're building

**Recommended order to give the AI:**
1. PRD (what to build)
2. Backend Schema (database structure)
3. App Flow (screen by screen)
4. TRD (tech decisions)
5. Implementation Plan (phase by phase)

---
