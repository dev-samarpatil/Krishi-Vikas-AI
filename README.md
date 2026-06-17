# 🌾 Krishi Vikas AI — AI-Powered Farming Assistant

<p align="center">
  <img src="flutter_app/assets/images/app_logo.png" alt="Krishi Vikas AI Logo" width="120"/>
</p>

<p align="center">
  <strong>Empowering Indian Smallholder Farmers with AI, Voice, and Real-Time Data</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.135+-009688?logo=fastapi" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Next.js-16+-000000?logo=next.js" alt="Next.js"/>
  <img src="https://img.shields.io/badge/Supabase-2.x-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Gemini-2.5_Flash-4285F4?logo=google" alt="Gemini AI"/>
  <img src="https://img.shields.io/badge/Version-2.0.0-green" alt="Version"/>
</p>

---

## 📖 Table of Contents

1. [Project Overview](#-project-overview)
2. [Key Features](#-key-features)
3. [Architecture Overview](#-architecture-overview)
4. [Tech Stack](#-tech-stack)
5. [Repository Structure](#-repository-structure)
6. [Flutter Mobile App](#-flutter-mobile-app)
   - [App Screens & Navigation](#app-screens--navigation)
   - [State Management](#state-management)
   - [Localization](#localization)
   - [Key Dependencies](#flutter-key-dependencies)
7. [Python Backend (FastAPI)](#-python-backend-fastapi)
   - [API Endpoints](#api-endpoints)
   - [AI Services](#ai-services)
   - [Data Files](#data-files)
8. [Next.js Admin Frontend](#-nextjs-admin-frontend)
9. [Database (Supabase)](#-database-supabase)
   - [Schema Tables](#schema-tables)
   - [Row Level Security](#row-level-security)
10. [Environment Variables](#-environment-variables)
11. [Local Development Setup](#-local-development-setup)
    - [Prerequisites](#prerequisites)
    - [Backend Setup](#backend-setup)
    - [Flutter App Setup](#flutter-app-setup)
    - [Frontend Setup](#frontend-setup)
12. [Deployment](#-deployment)
13. [API Reference](#-api-reference)
14. [Supported Crops & Languages](#-supported-crops--languages)
15. [Data Sources](#-data-sources)
16. [Contributing](#-contributing)
17. [License](#-license)

---

## 🌟 Project Overview

**Krishi Vikas AI** is a full-stack, AI-powered farming companion designed specifically for **Indian smallholder farmers**. It bridges the technology gap by bringing cutting-edge AI directly to farmers through a multilingual mobile app that works in **English, Hindi, Marathi, and Tamil**.

The platform solves three critical problems faced by Indian farmers:

1. **Disease Detection** — Farmers often lose 20–40% of their yield due to undetected or misidentified crop diseases. Krishi Vikas AI provides instant, photo-based diagnosis using Google Gemini Vision AI and Roboflow object detection.

2. **Market Ignorance** — Farmers sell at a loss because they don't know current Mandi prices. The app delivers live market prices from Agmarknet across multiple markets sorted by proximity.

3. **Scheme Inaccessibility** — Billions in government subsidies go unclaimed because farmers don't know which schemes apply to them. The app personalizes and explains government schemes in the farmer's own language.

### Target Users
- Smallholder farmers across India (primarily Maharashtra)
- Farming landholding ranging from <1 acre to 10+ acres
- Crops: Tomato, Wheat, Rice, Cotton, Onion, Potato, Sugarcane, Corn

---

## 🚀 Key Features

### 🔬 AI Crop Disease Scanner
- **Dual AI Pipeline**: Roboflow object detection model (primary) → Google Gemini 2.5 Flash Vision (fallback)
- Identifies 50+ crop diseases including Early Blight, Late Blight, Rust, Smut, Bollworm, Yellow Mosaic Virus, and more
- Returns structured diagnosis with: disease name, confidence score, cause, step-by-step treatment, organic alternative, budget estimate, and urgency level
- Context-aware: considers location, soil type, crop growth stage, and current weather
- Supports both chemical and organic treatment recommendations
- Saves all diagnoses to Supabase for history tracking and soil health scoring

### 🤖 AI Chat Assistant (Voice + Text)
- Powered by **Groq LLaMA 3.3 70B** (primary) with **LLaMA 3.1 8B Instant** fallback
- Context-aware: knows the farmer's location, crop, soil type, weather, and recent diagnosis
- Intent detection: automatically fetches live Mandi prices if market-related keywords (price, bhav, mandi, rate) are detected
- Responds in the farmer's chosen language (EN/HI/MR/TA)
- Practical advice: gives specific product names, dosages, and timing

### 🎙️ Voice Input & Output (Sarvam AI)
- **Speech-to-Text**: Sarvam Saaras v3 model — supports Hindi (hi-IN), Marathi (mr-IN), Tamil (ta-IN), and English (en-IN)
- **Text-to-Speech**: Sarvam Bulbul v3 model — natural Indian language voices (Priya, Shruti, Kavitha)
- Supports audio formats: WAV, WebM, MP4, M4A, MP3, OGG

### 🌤️ Weather Intelligence
- **Current weather** via OpenWeatherMap API
- **5-day forecast** with rain prediction, temperature, humidity
- **Crop-specific climate alerts** — e.g., Maize flooding risk, Cotton whitefly risk, Rice flooding risk
- Alerts generated in farmer's language using Gemini AI
- Alert levels: `urgent` (harvest/flood/heatwave) or `advisory` (fungal/pest risk)

### 📈 Live Mandi Prices
- Fetches live data from **Agmarknet** (Government of India's agricultural marketing portal)
- **Supabase cache**: data cached for 6 hours to prevent repeated API calls
- **Static JSON fallback** for offline/demo scenarios
- Shows: Modal Price, Min Price, Max Price, Price Trend (up/flat/down)
- Distance-sorted: markets sorted by proximity using Haversine formula

### 🏛️ Government Schemes
- Comprehensive database of **Central and State Government schemes**
- Filtered by: State, Crop Type, and Farm Size
- Schemes matched to farmer's exact profile
- **Scheme Application Guide**: Gemini generates step-by-step application instructions in the farmer's language

### 🗺️ Sentinel Farm Map
- Interactive Flutter Map showing farm boundaries
- Displays KVK (Krishi Vigyan Kendra) locations
- Nearest KVK finder using Haversine distance calculation

### 🌱 Soil Health Tracker
- Dynamic soil health score (0–100) per farm
- Score calculated from diagnosis history:
  - Base: 70 points
  - Healthy scan: +2
  - Mild disease (confidence < 0.70): −5
  - Moderate disease (0.70–0.84): −10
  - Severe disease (≥ 0.85): −20
  - Treatment logged: +5
  - Repeated disease occurrence: −5 additional
- **Badges**: 🌿 Organic Champion (score ≥ 81) | 🌱 Soil Guardian (score ≥ 61)
- Visual soil health dial widget

### 🔔 Push Notifications (FCM)
- Firebase Cloud Messaging integration
- Platform-aware initialization (Android/iOS/Web)
- FCM token registration with backend

### 🔐 Authentication
- **Supabase Phone Auth** (OTP via SMS)
- JWT tokens stored securely in Hive local storage
- Session expiry detection with automatic redirect

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                │
│                                                                     │
│  ┌──────────────────┐          ┌──────────────────────────────────┐ │
│  │   Flutter App     │          │    Next.js Admin Frontend        │ │
│  │  (Mobile + Web)   │          │    (React 19 + TypeScript)       │ │
│  │  iOS/Android/Web  │          │    Leaflet Maps + Tailwind       │ │
│  └────────┬─────────┘          └──────────────┬───────────────────┘ │
└───────────┼──────────────────────────────────┼─────────────────────┘
            │ HTTPS / REST                      │ HTTPS / REST
┌───────────▼──────────────────────────────────▼─────────────────────┐
│                        BACKEND (FastAPI)                            │
│          Python 3.x — Deployed on Render.com                        │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                     API Routes                                 │ │
│  │  /api/diagnose   /api/chat      /api/weather   /api/market    │ │
│  │  /api/schemes    /api/voice-stt /api/voice-tts /api/alerts    │ │
│  │  /api/nearest-kvk              /api/log-treatment             │ │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐  │
│  │  Gemini 2.5  │ │ Groq LLaMA  │ │  Sarvam AI   │ │OpenWeather│  │
│  │  Flash Vision│ │   3.3 70B   │ │ STT/TTS v3   │ │  API      │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └───────────┘  │
│                                                                     │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐    │
│  │  Roboflow Vision │ │  Agmarknet API   │ │  Static JSON     │    │
│  │  (Disease Model) │ │  (Mandi Prices)  │ │  (Schemes/Soil)  │    │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────────┐
│                      DATABASE (Supabase)                            │
│         PostgreSQL + Row Level Security + Supabase Auth             │
│                                                                     │
│  users | farms | diagnoses | soil_logs | chat_sessions              │
│  farm_timeline | push_tokens | weather_alerts_log | mandi_cache     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Mobile App (Flutter)
| Technology | Version | Purpose |
|---|---|---|
| Flutter | ≥ 3.16.0 | Cross-platform UI framework |
| Dart SDK | ≥ 3.2.0 | Programming language |
| Flutter Riverpod | ^2.6.1 | State management |
| Go Router | ^14.8.1 | Declarative navigation |
| Dio | ^5.4.3 | HTTP client |
| Supabase Flutter | 2.12.4 | Auth + database client |
| Hive Flutter | ^1.1.0 | Local storage / caching |
| Firebase Messaging | ^15.0.4 | Push notifications |
| Firebase Core | ^3.1.1 | Firebase initialization |
| Flutter Map | ^7.0.2 | OpenStreetMap integration |
| Geolocator | ^12.0.0 | GPS location |
| Geocoding | ^4.0.0 | Reverse geocoding |
| Image Picker | ^1.1.2 | Camera / gallery access |
| Camera | ^0.12.0 | Live camera feed |
| FL Chart | ^0.68.0 | Charts and graphs |
| Lottie | ^3.1.0 | Animated illustrations |
| Speech to Text | ^7.4.0 | On-device speech recognition |
| Flutter TTS | ^4.2.5 | Text-to-speech output |
| Flutter Localizations | SDK | i18n support |
| Google Fonts | ^6.3.3 | Premium typography |
| Shimmer | ^3.0.0 | Loading skeleton UI |
| Connectivity Plus | ^6.0.3 | Network status monitoring |

### Python Backend
| Technology | Version | Purpose |
|---|---|---|
| FastAPI | 0.135.3 | Async REST API framework |
| Uvicorn | 0.43.0 | ASGI server |
| Google Generative AI | 0.8.6 | Gemini 2.5 Flash (Vision + Text) |
| Groq | ≥0.9.0 | LLaMA 3.3 70B chat |
| Supabase Python | 2.28.3 | Database client |
| Pillow | 12.2.0 | Image processing |
| httpx | 0.28.1 | Async HTTP client (Sarvam AI) |
| Pydantic | 2.12.5 | Request/response validation |
| python-dotenv | 1.2.2 | Environment configuration |

### Frontend (Next.js Admin)
| Technology | Version | Purpose |
|---|---|---|
| Next.js | ^16.2.2 | React framework |
| React | ^19.2.4 | UI library |
| TypeScript | ^5 | Type safety |
| Tailwind CSS | ^4 | Styling |
| Leaflet / React Leaflet | 1.9.4 | Interactive maps |
| Google Generative AI | ^0.24.1 | Gemini client |
| Axios | ^1.14.0 | HTTP requests |
| Lucide React | 0.263.1 | Icon library |

### Infrastructure
| Service | Purpose |
|---|---|
| Supabase | PostgreSQL database, Auth (OTP), Storage |
| Render.com | Backend API deployment |
| Firebase | Push Notifications (FCM) |
| Agmarknet | Government live Mandi price data |
| OpenWeatherMap | Weather data & 5-day forecasts |
| Roboflow | Crop disease CV model hosting |
| Sarvam AI | Indian language STT + TTS |

---

## 📁 Repository Structure

```
Krishi Vikas AI_ Antigravity/
│
├── 📱 flutter_app/              # Flutter mobile + web application
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── core/
│   │   │   ├── constants/       # App-wide constants (URLs, keys, config)
│   │   │   ├── router/          # GoRouter navigation config
│   │   │   ├── theme/           # Light/Dark theme definitions
│   │   │   └── supabase_client.dart
│   │   ├── features/
│   │   │   ├── auth/            # Splash, Onboarding, Phone OTP Auth
│   │   │   ├── home/            # Home dashboard, Settings, Notifications
│   │   │   ├── scan/            # Camera, Preview, Loading, Scan Result
│   │   │   ├── chat/            # AI Chat (voice + text)
│   │   │   ├── farm/            # My Farm, Farm Setup, Farm Detail
│   │   │   ├── mandi/           # Live market prices
│   │   │   ├── schemes/         # Government schemes browser
│   │   │   ├── map/             # Sentinel farm map (Leaflet)
│   │   │   └── soil/            # Soil health screen
│   │   ├── shared/
│   │   │   ├── models/          # Data models (Farm, Diagnosis, Mandi, Weather, User)
│   │   │   ├── providers/       # Global Riverpod providers (auth, locale)
│   │   │   ├── repositories/    # Repository pattern abstractions
│   │   │   ├── services/        # API client, local storage, push notifications
│   │   │   └── widgets/         # Shared widgets (ShellScaffold, SoilHealthDial)
│   │   └── l10n/                # ARB translation files (EN, HI, MR, TA)
│   ├── assets/
│   │   ├── images/              # App logo, illustrations
│   │   ├── lottie/              # Lottie animations
│   │   └── data/                # Bundled static data
│   ├── pubspec.yaml             # Flutter dependency manifest
│   └── .env                     # Local environment variables
│
├── 🐍 backend/                  # Python FastAPI REST API
│   ├── main.py                  # App entry, lifespan, CORS, router mounts
│   ├── routes/
│   │   ├── diagnose.py          # POST /api/diagnose, GET /api/nearest-kvk
│   │   ├── chat.py              # POST /api/chat
│   │   ├── weather.py           # GET /api/weather, POST /api/climate-alert
│   │   ├── market.py            # GET /api/market (Mandi prices)
│   │   ├── schemes.py           # GET /schemes, POST /api/schemes, POST /api/scheme-guide
│   │   ├── voice_stt.py         # POST /api/voice-stt (Speech to Text)
│   │   ├── voice_tts.py         # POST /api/voice-tts (Text to Speech)
│   │   ├── alerts.py            # Weather alert notifications
│   │   ├── farm.py              # Farm management endpoints
│   │   └── log_treatment.py     # POST /api/log-treatment
│   ├── services/
│   │   ├── gemini_service.py    # Google Gemini 2.5 Flash integration
│   │   ├── groq_service.py      # Groq LLaMA 3.3 70B chat
│   │   ├── sarvam_service.py    # Sarvam STT + TTS (Indian languages)
│   │   ├── supabase_service.py  # DB CRUD, soil health scoring, caching
│   │   └── weather_service.py   # OpenWeatherMap integration
│   ├── utils/
│   │   ├── geocode.py           # Reverse geocoding (lat/long → district/state)
│   │   ├── haversine.py         # Haversine distance calculator
│   │   ├── json_loader.py       # Soil type & crop stage lookups
│   │   └── agmarknet.py         # Agmarknet live price fetcher
│   ├── requirements.txt         # Python dependencies
│   ├── Procfile                 # Render.com deployment config
│   └── .env.example             # Environment variable template
│
├── 🌐 frontend/                 # Next.js admin dashboard
│   ├── src/
│   │   ├── app/                 # Next.js App Router pages
│   │   ├── components/          # React UI components
│   │   ├── context/             # React context providers
│   │   ├── lib/                 # Utility functions
│   │   └── types/               # TypeScript type definitions
│   ├── public/                  # Static assets
│   ├── package.json             # Node.js dependencies
│   └── next.config.mjs          # Next.js configuration
│
├── 🗄️ supabase/
│   └── migrations/
│       └── 20260603000000_init_schema.sql   # Complete database schema
│
├── 📊 data/                     # Static JSON data files loaded at startup
│   ├── soil_mapping.json        # State/district → soil type mapping
│   ├── crop_calendar.json       # Crop season & growth stage by region
│   ├── schemes.json             # Government scheme definitions
│   ├── mandi_prices.json        # Static Mandi price fallback
│   ├── Central Government Schemes.json
│   ├── State Government Schemes.json
│   └── KVK/                     # KVK directory (state-wise JSON files)
│
├── .env                         # Root-level environment variables (shared)
├── .gitignore
└── README.md
```

---

## 📱 Flutter Mobile App

The Flutter app is the primary user interface targeting Android and iOS devices, with web support enabled.

### App Screens & Navigation

The app uses **GoRouter** for declarative, type-safe navigation with a **ShellRoute** for bottom navigation.

#### Pre-Auth Flow
| Screen | Route | Description |
|---|---|---|
| SplashScreen | `/` | App logo + initialization check |
| OnboardingScreen | `/onboarding` | Introduction slides for new users |
| PhoneAuthScreen | `/phone-auth` | Supabase OTP phone authentication |
| FarmSetupScreen | `/farm-setup` | Initial farm profile creation |

#### Main Shell (Bottom Navigation — 5 Tabs)
| Tab | Route | Description |
|---|---|---|
| HomeScreen | `/home` | Dashboard: weather, quick actions, recent activity |
| SentinelMapScreen | `/map` | Farm map with KVK locations |
| ScanCameraScreen | `/scan` | Live camera for crop scanning |
| ChatScreen | `/chat` | AI farming assistant (voice + text) |
| MyFarmScreen | `/my-farm` | Farm management & soil health |

#### Detail Screens
| Screen | Route | Description |
|---|---|---|
| ScanPreviewScreen | `/scan/preview` | Review captured image before analysis |
| ScanLoadingScreen | `/scan/loading` | AI processing animation |
| ScanResultScreen | `/scan-result` | Full diagnosis with treatment plan |
| FarmDetailScreen | `/farm/:farmId` | Individual farm details |
| MandiPricesScreen | `/mandi-prices` | Live market prices |
| SchemesScreen | `/schemes` | Government schemes list |
| SchemeDetailScreen | `/schemes/:schemeId` | Scheme details + application guide |
| SoilHealthScreen | `/soil-health/:farmId` | Soil health score + history |
| SettingsScreen | `/settings` | Language, account, preferences |
| NotificationsScreen | `/notifications` | Weather and disease alerts |

### State Management

The app uses **Flutter Riverpod 2.x** with `riverpod_annotation` for code-generated providers:

- **`authStateProvider`** — Watches Supabase session status; triggers redirect on expiry
- **`localeProvider`** — Manages selected language (EN/HI/MR/TA); persisted in Hive
- **`appRouterProvider`** — GoRouter instance reactive to auth state
- **Feature-level providers** — Each feature (scan, chat, farm, mandi) has its own providers and notifiers

### Localization

Full **i18n support** using Flutter's `flutter_localizations` package with **ARB files**:

| Language | Code | ARB File |
|---|---|---|
| English | `en` | `app_en.arb` |
| Hindi | `hi` | `app_hi.arb` |
| Marathi | `mr` | `app_mr.arb` |
| Tamil | `ta` | `app_ta.arb` |

Language is persisted locally via Hive and can be changed in Settings.

### Flutter Key Dependencies

```yaml
# pubspec.yaml (key dependencies)
flutter_riverpod: ^2.6.1       # State management
go_router: ^14.8.1             # Navigation
dio: ^5.4.3+1                  # HTTP networking
supabase_flutter: 2.12.4       # Auth + database
hive_flutter: ^1.1.0           # Local storage
firebase_messaging: ^15.0.4    # Push notifications
flutter_map: ^7.0.2            # OpenStreetMap
geolocator: ^12.0.0            # GPS
image_picker: ^1.1.2           # Camera access
fl_chart: ^0.68.0              # Charts
speech_to_text: ^7.4.0         # Voice input
flutter_tts: ^4.2.5            # Voice output
lottie: ^3.1.0                 # Animations
google_fonts: ^6.3.3           # Typography
```

---

## 🐍 Python Backend (FastAPI)

### Overview

The FastAPI backend is the central intelligence layer. It:
- Processes crop images through the AI diagnosis pipeline
- Serves as proxy for all third-party AI/API calls
- Manages Supabase database operations
- Loads all static JSON data **once at startup** (via `lifespan` context) and stores in `app.state` to avoid repeated disk reads

### API Endpoints

#### Diagnosis
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/diagnose` | Full crop disease diagnosis pipeline |
| `GET` | `/api/nearest-kvk` | Find nearest KVK centres |
| `POST` | `/api/log-treatment` | Log chosen treatment (organic/chemical) |
| `POST` | `/api/log-diagnosis` | Store client-side diagnosis to Supabase |
| `POST` | `/api/test-vision` | Debug endpoint for Gemini Vision testing |

#### Chat & Voice
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/chat` | Context-aware farmer chat via Groq LLaMA |
| `POST` | `/farms/{id}/chat` | Farm-specific chat |
| `POST` | `/api/voice-stt` | Audio → text (Sarvam Saaras v3) |
| `POST` | `/api/voice-tts` | Text → audio (Sarvam Bulbul v3) |

#### Weather
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/weather` | Current weather + 5-day forecast |
| `POST` | `/api/climate-alert` | Crop-specific climate risk alerts |

#### Market & Schemes
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/market` | Live Mandi prices (Agmarknet + cache + fallback) |
| `GET` | `/mandi/prices` | Alias for market endpoint |
| `GET` | `/schemes` | Government schemes (query-param filtered) |
| `POST` | `/api/schemes` | Government schemes (body filtered) |
| `POST` | `/api/scheme-guide` | AI-generated scheme application guide |

#### Health & Utilities
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Health check |
| `GET` | `/api/health` | Detailed health + data load status |
| `GET` | `/api/test-gemini` | Test Gemini API connectivity |
| `POST` | `/push/register` | Register FCM push token |

### AI Services

#### `services/gemini_service.py` — Google Gemini 2.5 Flash
- **Vision Diagnosis**: Sends PIL image + farm context prompt → returns structured JSON
- **Text-only Mode**: When Roboflow detects disease, Gemini generates detailed treatment without re-processing image
- **Scheme Guide Generation**: Creates localized step-by-step application instructions
- **Alert Text Generation**: Produces urgent, 2-sentence weather alerts in the farmer's language
- JSON extraction handles Gemini's markdown-wrapped responses gracefully (4 fallback methods)

#### `services/groq_service.py` — Groq LLaMA 3.3 70B
- Primary model: `llama-3.3-70b-versatile` (temperature 0.4, max 450 tokens)
- Fallback model: `llama-3.1-8b-instant` on API failure
- System prompt includes full farm context: location, soil, weather, crop stage, recent diagnosis, and market prices
- Market intent detection: pre-fetches Mandi prices if keywords like "price", "bhav", "mandi" appear

#### `services/sarvam_service.py` — Sarvam AI (Indian Languages)
- **STT**: `saaras:v3` model — supports hi-IN, mr-IN, ta-IN, en-IN
- **TTS**: `bulbul:v3` model — Indian voices: Priya (Hindi/English), Shruti (Marathi), Kavitha (Tamil)
- Returns base64-encoded audio for TTS

#### `services/weather_service.py` — OpenWeatherMap
- Current weather: temperature, humidity, description, wind speed
- 5-day forecast: aggregated daily summaries with rain_mm, temp_max, humidity
- Data used by climate alert engine and diagnosis context

### Data Files

Loaded once at startup into `app.state`:

| File | Content | Records |
|---|---|---|
| `data/soil_mapping.json` | State → district → soil type | All Indian states |
| `data/crop_calendar.json` | State → crop → season + growth stage | Major crop regions |
| `data/schemes.json` | Government scheme definitions | 50+ schemes |
| `data/mandi_prices.json` | Static price fallback | Sample prices |
| `data/KVK/*.json` | State-wise KVK directories | ~700+ KVKs across India |
| `data/Central Government Schemes.json` | Central scheme details | Ministry-level schemes |
| `data/State Government Schemes.json` | State-specific schemes | Maharashtra + others |

---

## 🌐 Next.js Admin Frontend

A supplementary admin/dashboard web interface built with Next.js 16, React 19, and TypeScript.

**Key Technologies:**
- **Next.js 16** with App Router
- **React 19** (latest concurrent features)
- **TypeScript 5** for type safety
- **Tailwind CSS 4** for styling
- **Leaflet + React Leaflet** for farm maps
- **Google Generative AI** SDK for direct Gemini calls
- **Lucide React** for icons

```
frontend/src/
├── app/         # Next.js App Router pages & layouts
├── components/  # Reusable React components
├── context/     # React context (auth, language, farm state)
├── lib/         # API helpers, utilities
└── types/       # TypeScript interfaces
```

---

## 🗄️ Database (Supabase)

### Schema Tables

#### `users`
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Maps to `auth.uid()` |
| `phone` | TEXT (UNIQUE) | Phone number (OTP auth) |
| `name` | TEXT | Farmer's name |
| `language` | TEXT | Preferred language: `en`, `hi`, `mr`, `ta` |
| `created_at` | TIMESTAMPTZ | Registration timestamp |

#### `farms`
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Farm identifier |
| `user_id` | UUID (FK) | References `users.id` |
| `name` | TEXT | Farm name (e.g., "मुख्य शेत") |
| `crop` | TEXT | Primary crop (e.g., `tomato`) |
| `crop_variety` | TEXT | Optional variety (e.g., "Hybrid F1") |
| `farm_size` | TEXT | Size range: `<1`, `1-2`, `2-5`, `5-10`, `10+` |
| `size_unit` | TEXT | Default `acres` |
| `farming_type` | TEXT | `organic`, `conventional`, `mixed` |
| `district` | TEXT | District name |
| `state` | TEXT | Indian state name |
| `lat` / `lng` | DECIMAL(9,6) | GPS coordinates |
| `soil_type` | TEXT | From soil mapping lookup |
| `sowing_date` | DATE | When crop was sown |
| `expected_harvest_date` | DATE | Projected harvest date |
| `current_stage` | TEXT | `sowing`, `germination`, `vegetative`, `flowering`, `harvest` |
| `soil_score` | INTEGER | Dynamic score 0–100 |
| `is_active` | BOOLEAN | Active farm flag |

#### `diagnoses`
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Diagnosis ID |
| `farm_id` | UUID (FK) | References `farms.id` |
| `user_id` | UUID (FK) | References `users.id` |
| `image_url` | TEXT | Supabase Storage path |
| `crop` | TEXT | Crop being scanned |
| `disease_name` | TEXT | Detected disease |
| `confidence` | DECIMAL(5,2) | AI confidence % |
| `model_used` | TEXT | `roboflow` or `gemini` |
| `severity` | TEXT | `low`, `medium`, `high` |
| `treatment_type` | TEXT | `organic` or `chemical` |
| `treatment_steps` | JSONB | Step-by-step treatment array |
| `cost_estimate` | JSONB | Budget breakdown |
| `prevention_tip` | TEXT | Prevention advice |
| `language` | TEXT | Language of response |
| `weather_at_scan` | JSONB | Weather snapshot at scan time |

#### `soil_logs`
Tracks every change to a farm's soil health score:
- `action`: `organic_treatment`, `chemical_treatment`, `diagnosis`
- `score_change`: delta (e.g., +10, −5)
- `score_after`: new absolute score
- `note`: disease name or treatment description

#### `chat_sessions`
Stores conversation history per farm:
- `messages`: JSONB array of `{role, content, timestamp}`
- Linked to both `user_id` and optionally `farm_id`

#### `farm_timeline`
Tracks growth stage progression:
- `stage`: sowing → germination → vegetative → flowering → harvest
- `tasks`: JSONB array of farm tasks with due dates

#### `push_tokens`
Firebase Cloud Messaging tokens:
- `fcm_token`: Device FCM token
- `platform`: `android` or `ios`

#### `weather_alerts_log`
Audit log of all weather alerts sent:
- `alert_type`: `heavy_rain`, `frost`, `heat_wave`, `strong_wind`
- `weather_data`: JSONB snapshot of forecast data used

#### `mandi_cache` (Runtime Table)
6-hour cache for Agmarknet API responses:
- Key: `(state, district, commodity)`
- `data`: JSONB price array
- `created_at`: Cache timestamp

### Row Level Security

**All tables have RLS enabled.** Every policy follows the same pattern:

```sql
CREATE POLICY "Users own their [resource]"
  ON [table] FOR ALL USING (auth.uid() = user_id);
```

This means farmers can **only access their own data** — no cross-user data leakage is possible.

### Supabase Storage

A private bucket `crop-images` stores uploaded crop photos:
- Upload restricted to authenticated users only
- Each user can only read their own uploaded images

---

## 🔑 Environment Variables

### Root `.env` (Shared by Backend)

| Variable | Description | Required |
|---|---|---|
| `GEMINI_API_KEY` | Google Gemini API key (AI Vision + Text) | ✅ Yes |
| `GROQ_API_KEY` | Groq API key (LLaMA 3.3 70B chat) | ✅ Yes |
| `SARVAM_API_KEY` | Sarvam AI key (Indian STT/TTS) | ✅ Yes |
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key | ✅ Yes |
| `SUPABASE_URL` | Supabase project URL | ✅ Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous key (client-side) | ✅ Yes |
| `SUPABASE_SERVICE_KEY` | Supabase service role key (backend only) | ✅ Yes |
| `ROBOFLOW_API_KEY` | Roboflow API key (crop disease CV model) | ⚠️ Optional |
| `ROBOFLOW_MODEL_ID` | Roboflow model ID (e.g., `crop-disease-ai-gf0gn/1`) | ⚠️ Optional |
| `FIREBASE_SERVICE_ACCOUNT_B64` | Base64-encoded Firebase service account JSON | ⚠️ Optional |

### Flutter App `.env` (`flutter_app/.env`)

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key |
| `ROBOFLOW_API_KEY` | Roboflow API key |
| `ROBOFLOW_MODEL_ID` | Roboflow model ID |

> ⚠️ **Security Note**: The root `.env` file contains active API keys. **Never commit `.env` files to version control.** Rotate all keys before open-sourcing or sharing the repository.

---

## 🚀 Local Development Setup

### Prerequisites

Ensure you have the following installed:

- **Flutter SDK** ≥ 3.16.0 ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** ≥ 3.2.0 (included with Flutter)
- **Python** ≥ 3.11 ([Install Python](https://python.org))
- **Node.js** ≥ 18.x + npm ([Install Node.js](https://nodejs.org))
- **Git**
- **Android Studio** or **Xcode** (for mobile emulation)

### Backend Setup

```bash
# 1. Navigate to the backend directory
cd backend

# 2. Create and activate a Python virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate

# 3. Install all dependencies
pip install -r requirements.txt

# 4. Ensure root .env is configured with all required API keys
# (see Environment Variables section above)

# 5. Start the development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# The API will be available at: http://localhost:8000
# Interactive docs (Swagger UI): http://localhost:8000/docs
# ReDoc docs: http://localhost:8000/redoc
```

**Verify the server started correctly** by checking console output:
```
[OK] GEMINI_API_KEY loaded: AIzaSyCV...
[OK] GROQ_API_KEY: loaded
[OK] SARVAM_API_KEY: loaded
[START] Krishi Vikas AI — Loading data files...
   [OK] soil_mapping.json loaded (36 states)
   [OK] crop_calendar.json loaded (5 regions)
   [OK] Loaded 52 schemes
   [OK] KVK directory loaded (731 KVKs across India)
   [OK] mandi_prices.json loaded
[READY] All data loaded. Server ready!
```

### Flutter App Setup

```bash
# 1. Navigate to the Flutter app directory
cd flutter_app

# 2. Create .env file (copy from example and fill in values)
copy .env.example .env
# Edit .env with your actual API keys

# 3. Install Flutter dependencies
flutter pub get

# 4. Generate Riverpod code (for annotated providers)
dart run build_runner build --delete-conflicting-outputs

# 5. Run on connected device or emulator
flutter run

# For specific platform:
flutter run -d android
flutter run -d ios
flutter run -d web
flutter run -d windows

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release
```

**Important**: The Flutter app's `baseUrl` is hardcoded to `https://krishi-vikas-ai.onrender.com`. For local development, update `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart` to `http://10.0.2.2:8000` (Android emulator) or `http://localhost:8000` (web/desktop).

### Frontend Setup

```bash
# 1. Navigate to the frontend directory
cd frontend

# 2. Install Node.js dependencies
npm install

# 3. Create .env.local with required variables
copy .env.local.example .env.local
# Edit .env.local with your API keys

# 4. Start the development server
npm run dev

# The frontend will be available at: http://localhost:3000

# Build for production
npm run build
npm run start
```

---

## ☁️ Deployment

### Backend (Render.com)

The backend is deployed on **Render.com** as a web service:

- **URL**: `https://krishi-vikas-ai.onrender.com`
- **Procfile**: `web: uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Environment**: Set all environment variables in Render Dashboard

```
Procfile contents:
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Flutter App

| Platform | Command | Output |
|---|---|---|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `flutter build appbundle` | For Play Store submission |
| iOS | `flutter build ios --release` | Xcode archive for App Store |
| Web | `flutter build web` | Static files in `build/web/` |

### Database

Apply the Supabase migration:

```bash
# Using Supabase CLI
supabase db push

# Or manually run in Supabase SQL editor:
# supabase/migrations/20260603000000_init_schema.sql
```

---

## 📡 API Reference

### `POST /api/diagnose`

Full AI crop disease diagnosis pipeline.

**Request** (`multipart/form-data`):
```
image       : File    (crop photo — JPG/PNG/WebP, max 5MB)
lat         : float   (farmer GPS latitude, default 19.99)
long        : float   (farmer GPS longitude, default 73.79)
crop_type   : string  (e.g., "tomato", "wheat", "cotton")
language    : string  ("en" | "hi" | "mr" | "ta", default "en")
farmer_id   : string  (Supabase user UUID)
farm_size   : string  ("1-2", "2-5", etc.)
farming_type: string  ("organic" | "conventional" | "mixed")
farm_id     : string  (optional, Farm UUID for soil score update)
```

**Response** (`application/json`):
```json
{
  "type": "disease",
  "name": "Early Blight",
  "name_local": "अर्ली ब्लाइट",
  "confidence": 0.87,
  "explanation": "Your tomato plant has Early Blight, caused by the Alternaria fungus...",
  "cause": "Alternaria solani fungus",
  "treatment_steps": [
    "Step 1: Remove and destroy all infected leaves immediately",
    "Step 2: Spray Mancozeb 75WP at 2g/litre water",
    "Step 3: Repeat spray every 7-10 days for 3 applications"
  ],
  "organic_option": {
    "description": "Neem Oil Spray",
    "steps": [
      "Mix 5ml neem oil in 1L water with a few drops of soap",
      "Spray on all leaf surfaces every 7 days"
    ]
  },
  "prevention": "Avoid overhead irrigation and maintain 60cm row spacing",
  "budget_items": [
    {"item": "Mancozeb 75WP", "quantity": "250g", "price_inr": 90},
    {"item": "Sprayer rental", "quantity": "1 day", "price_inr": 50},
    {"item": "Labour", "quantity": "1 day", "price_inr": 200}
  ],
  "total_cost_inr": 340,
  "organic_total_cost_inr": 80,
  "urgency": "immediate",
  "low_confidence_note": null,
  "diagnosis_id": "uuid-xxxx",
  "_context": {
    "district": "Nashik",
    "state": "Maharashtra",
    "soil_type": "Red Loamy",
    "season": "kharif",
    "crop_stage": "vegetative",
    "weather": "Partly cloudy, 28°C, humidity 72%"
  }
}
```

**Urgency values**: `"immediate"`, `"within_week"`, `"monitor"`

---

### `POST /api/chat`

Context-aware farmer AI assistant.

**Request** (`application/json`):
```json
{
  "message": "मेरी टमाटर की फसल पर पीले धब्बे हैं, क्या करूं?",
  "language": "hi",
  "lat": 20.0,
  "long": 73.8,
  "crop": "tomato",
  "last_diagnosis": "Early Blight",
  "district": "Nashik"
}
```

**Response**:
```json
{
  "reply": "**समस्या:** आपकी टमाटर पर Early Blight के लक्षण दिख रहे हैं...",
  "response": "...",
  "intent_type": "general"
}
```

---

### `GET /api/market`

Live Mandi prices.

**Query Parameters**:
- `state`: State name (default: `Maharashtra`)
- `district`: District name (default: `Nashik`)
- `crop`: Crop name (default: `Tomato`)
- `lat`: Farmer latitude (optional, for distance sorting)
- `lon`: Farmer longitude (optional)
- `radius`: Search radius in km (default: `50.0`)

**Response**:
```json
{
  "source": "live",
  "prices": [
    {
      "crop": "Tomato",
      "market": "Nashik APMC",
      "modal_price": 1450,
      "min_price": 1200,
      "max_price": 1800,
      "trend": "up",
      "trend_percent": "8%",
      "distance_km": 12.5,
      "lat": 20.0075,
      "lng": 73.7554
    }
  ]
}
```

**Source values**: `"live"` (Agmarknet), `"cache"` (Supabase cache), `"fallback"` (static JSON)

---

### `POST /api/voice-stt`

Convert farmer's voice to text.

**Request** (`multipart/form-data`):
```
audio    : File    (WAV/WebM/MP4/M4A/MP3/OGG audio file)
language : string  ("hi" | "mr" | "ta" | "en")
```

**Response**:
```json
{
  "transcript": "मुझे टमाटर की फसल के बारे में जानना है"
}
```

---

### `POST /api/voice-tts`

Convert AI text response to speech.

**Request** (`application/json`):
```json
{
  "text": "आपकी फसल में Early Blight रोग है...",
  "language": "hi"
}
```

**Response**: Audio file (WAV format, base64-encoded in JSON response)

---

### `GET /api/weather`

Current weather + 5-day forecast.

**Query Parameters**: `lat`, `lon`, `lang`

**Response**:
```json
{
  "current": {
    "temp": 28.5,
    "humidity": 72,
    "description": "Partly cloudy",
    "wind_speed": 12.3,
    "summary": "Partly cloudy, 28°C, humidity 72%"
  },
  "forecast": [
    {"date": "2026-06-18", "temp_max": 32, "temp_min": 22, "rain_mm": 5.2, "humidity": 80}
  ]
}
```

---

## 🌾 Supported Crops & Languages

### Crops
| Crop | Detection | Market Prices | Schemes |
|---|---|---|---|
| Tomato 🍅 | ✅ | ✅ | ✅ |
| Wheat 🌾 | ✅ | ✅ | ✅ |
| Rice 🍚 | ✅ | ✅ | ✅ |
| Cotton | ✅ | ✅ | ✅ |
| Onion 🧅 | ✅ | ✅ | ✅ |
| Potato 🥔 | ✅ | ✅ | ✅ |
| Sugarcane | ✅ | ✅ | ✅ |
| Corn/Maize 🌽 | ✅ | ✅ | ✅ |
| Pepper Bell | ✅ | — | — |
| Other | ✅ (Gemini only) | — | — |

### Languages
| Language | Code | UI | Chat | Voice STT | Voice TTS | Diagnosis |
|---|---|---|---|---|---|---|
| English | `en` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hindi | `hi` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Marathi | `mr` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tamil | `ta` | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 📊 Data Sources

| Data | Source | Update Frequency |
|---|---|---|
| Mandi Prices | [Agmarknet](https://agmarknet.gov.in) — Govt of India | Live (6hr cache) |
| Weather | [OpenWeatherMap](https://openweathermap.org) | Real-time |
| Crop Disease AI | [Roboflow](https://roboflow.com) + [Google Gemini](https://ai.google.dev) | Real-time |
| Soil Mapping | ICAR soil classification data | Static (at startup) |
| Crop Calendar | Agro-climatic zone data | Static (at startup) |
| KVK Directory | ICAR-National Institute of Agricultural Extension Management | Static (at startup) |
| Government Schemes | Ministry of Agriculture (PM-KISAN, PMFBY, etc.) | Curated JSON |

---

## 🤝 Contributing

1. **Fork** the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "feat: add amazing feature"`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a **Pull Request**

### Contribution Areas
- 🌍 Adding new regional languages (Telugu, Kannada, Bengali, Punjabi)
- 🌾 Expanding the crop disease model training dataset
- 🏛️ Adding more state/district-specific government schemes
- 📱 UI/UX improvements for low-literacy farmers
- 🔊 Offline voice recognition improvements
- 🗺️ Enhanced farm mapping features

---

## 📄 License

This project is built for social impact — empowering Indian smallholder farmers with AI.

---

## 👨‍💻 Developer

Built with ❤️ for the farmers of India.

**Samar Patil** — Full-Stack Developer  
GitHub: [@dev-samarpatil](https://github.com/dev-samarpatil)

---

<p align="center">
  <strong>🌱 Jai Jawan Jai Kisan 🌱</strong><br/>
  <em>Technology in the service of agriculture</em>
</p>
