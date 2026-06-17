# Product Requirements Document — Krishi Vikas AI
**Version:** 2.0 | **Date:** June 2026 | **Team:** Algorithm Busters

---

## 1. App Overview

Krishi Vikas AI is a multilingual AI-powered farming assistant for Indian farmers. It combines crop disease diagnosis, voice chat, weather alerts, market prices, government schemes, and farm lifecycle tracking into one mobile-first app. Available as a Flutter mobile app (Android primary) and a Next.js PWA for web access.

---

## 2. Target Users

| Segment | Description |
|---|---|
| Primary | Small/marginal farmers (1–5 acres), semi-literate, smartphone users, aged 25–55 |
| Secondary | Progressive farmers (5–20 acres), multiple crops, multiple plots |
| Languages | Hindi, Marathi, Tamil, English |
| Devices | Android 8+ (primary), iOS 13+ (secondary), low-end phones with 2GB RAM |
| Connectivity | 2G/3G rural areas — app must work with intermittent internet |

---

## 3. Problem Statement

Indian farmers face three critical information gaps:
1. **Diagnosis delay** — crop diseases go unidentified for days, causing major yield loss
2. **Market blindness** — farmers sell at wrong time/wrong mandi due to no price visibility
3. **Scheme inaccessibility** — most eligible farmers never claim government benefits due to complexity and language barriers

Existing apps are English-only, require constant internet, and give generic advice. Krishi Vikas AI solves all three with local language support and AI-powered personalisation.

---

## 4. Core Features

### 4.1 Farm & Crop Management
- Farmer can register multiple farms with name, location (GPS), crop, acreage, soil type
- Each farm has its own lifecycle timeline from sowing to harvest
- Stage-aware push notifications (germination tips, fertiliser schedule, harvest alert)

### 4.2 AI Crop Diagnosis (Scan)
- Camera scan → Roboflow CNN model (primary, for 6–7 in-scope crops)
- Confidence < 70% or out-of-scope crop → silently falls back to Gemini 1.5 Flash
- Returns: disease name, confidence %, treatment steps, organic alternative, ₹ budget, prevention tip
- All in farmer's selected language

### 4.3 Voice + Text AI Chat
- Both text input and mic input available simultaneously
- Full farm context injected into every prompt (crop, stage, soil, weather, past diagnoses)
- Responses are detailed, step-by-step, crop-specific — not generic
- Groq Llama 3.1 70B backend with a strict system prompt

### 4.4 Weather Alerts & Notifications
- Live weather via OpenWeather API
- FCM push notifications triggered when: temp drops >5°C, rain >20mm forecast, wind >40kmph, frost risk
- Each alert includes specific crop-protection advice for the farmer's current crop and stage
- Weather overlay on map (precipitation, temperature layers)

### 4.5 Sentinel Map
- Full-screen Leaflet map
- Disease outbreak clusters generated relative to farmer's actual GPS
- Climate risk overlay using OpenWeather tile layers
- Toggle: Disease Outbreak / Climate Risk

### 4.6 Mandi Prices
- Live Agmarknet data via data.gov.in
- Location-aware: shows nearest APMCs to farmer's GPS
- Price trend indicators (up/down/stable)
- "Where to Sell" recommendation based on price + distance

### 4.7 Government Schemes
- 7+ schemes with eligibility filtering by crop, land size, state
- Full i18n — all labels, descriptions, steps in selected language
- Apply button → official government URL
- Helpline call button

### 4.8 Farm Soil Health
- Per-farm soil score (not global)
- Past diagnosis log stored and displayed per farm
- Organic/Chemical treatment buttons update score
- Score persists in Supabase (not just localStorage)

### 4.9 KVK Specialist Connect
- Nearest 3 KVKs by haversine distance
- Phone call button
- Shown alongside every diagnosis result

### 4.10 Full i18n
- Every string in the app goes through i18next / Flutter intl
- Zero hardcoded UI text
- 4 languages: EN, HI, MR, TA

---

## 5. User Stories

| # | As a... | I want to... | So that... |
|---|---|---|---|
| 1 | Farmer | Scan my crop with my phone camera | I know what disease it has and how to treat it |
| 2 | Farmer | Ask questions in Marathi by voice | I don't need to type or know English |
| 3 | Farmer | See today's tomato price in my nearest mandi | I sell at the best price |
| 4 | Farmer | Get a notification when rain is coming | I can protect my crop in time |
| 5 | Farmer | Track each of my 3 plots separately | I know what to do on each plot today |
| 6 | Farmer | See which government schemes I qualify for | I don't miss free money or insurance |
| 7 | Farmer | See disease outbreaks near me on a map | I can prepare before it reaches my farm |
| 8 | Farmer | Know exactly when to sow and harvest | I optimise my yield each season |
| 9 | Progressive farmer | Get specific advice, not just "consult KVK" | I can act immediately without waiting |
| 10 | New user | Set up my farm in 2 minutes | The app starts helping me immediately |

---

## 6. MVP Scope (V2.0)

**In scope:**
- Flutter Android app + existing Next.js PWA
- Multi-farm support (up to 5 farms per user)
- Full i18n (all 4 languages, zero hardcoded strings)
- Scan fix (Gemini key + correct model)
- Sentinel clusters fix (GPS-relative)
- Weather push notifications (FCM)
- Detailed chat responses (improved system prompt)
- Soil health per-farm with persistent log
- Farm lifecycle timeline (sowing → harvest)
- Mandi prices showing correct local APMCs

**Out of scope for V2.0:**
- iOS app
- Offline CNN model (use Roboflow hosted API for now)
- Satellite imagery / drone integration
- Farmer-to-farmer community/forum
- Loan/credit application flow
- Input supplier marketplace
- Tamil voice (Sarvam — confirm support first)

---

## 7. Success Metrics

| Metric | Target (3 months post-launch) |
|---|---|
| Daily Active Users | 500+ |
| Scans performed | 200+/day |
| Voice chat sessions | 100+/day |
| Push notification open rate | >40% |
| Scheme "Apply" button taps | 50+/day |
| Avg session duration | >4 minutes |
| App crash rate | <1% |
| Scan accuracy (user-confirmed) | >80% |

---

## 8. Features to Avoid in V2.0

- **E-commerce / input shop** — scope creep, trust issues
- **Farmer social network** — moderation burden
- **Loan application** — regulatory complexity
- **Custom satellite imagery** — cost prohibitive
- **WhatsApp bot** — separate product, dilutes focus
- **Paid subscription** — premature monetisation, kills adoption

---
