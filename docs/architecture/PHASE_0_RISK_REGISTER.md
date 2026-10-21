# Krishi Vikas AI — Phase 0 Risk Register

**Document:** `docs/architecture/PHASE_0_RISK_REGISTER.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Prioritized Risk Matrix

| Risk ID | Risk Description | Empirical Evidence | Severity (1-5) | Likelihood (1-5) | Score (SxL) | Mitigation Strategy | Required Action | Blocks Phase 1? |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :--- | :---: |
| **RSK-001** | **Gemini Free-Tier Rate Limit Exhaustion (429)** | `test_gemini_vision_real_call` failed with HTTP 429 quota exhaustion (limit 20 reqs/day) | 5 | 5 | **25** | Migrate Chatbot to Groq in Phase 1 to eliminate chatbot quota consumption; reserve Gemini quota solely for vision until vision migration. | Complete Phase 1 Groq migration immediately. | **NO (Justifies Phase 1)** |
| **RSK-002** | **AI Service Coupling in `ai_service.py`** | Both Chat and Vision are methods inside `backend/services/ai_service.py` | 4 | 3 | **12** | Keep Groq migration isolated to `generate_chat_response()`; leave `analyze_crop_image()` completely untouched. | Add regression tests for vision when modifying chat. | **YES (Constraint for Phase 1)** |
| **RSK-003** | **Deprecation of `google.generativeai` SDK** | Pytest captured `FutureWarning: All support for google.generativeai package has ended` | 3 | 4 | **12** | Moving chat to Groq decouples conversational text; plan transition of Vision to `google.genai` in future phase. | Schedule SDK upgrade after Phase 1. | **NO** |
| **RSK-004** | **Render Free-Tier Cold-Start Latency (30-50s)** | Render free web service spins down after 15 min inactivity | 3 | 4 | **12** | Client-side timeout handling, retry dialogue with progress indicators; health ping cron. | Document cold-start behavior in deployment specs. | **NO** |
| **RSK-005** | **Working Tree State Preservation** | 6 modified files in `flutter_app/` contain active fixes (OSM, truthful scan states) | 4 | 2 | **8** | Branch isolation (`feat/phase-1-groq-migration`); strict ban on `git reset --hard` or `git clean`. | Preserve working tree changes. | **YES (Prerequisite)** |
| **RSK-006** | **OpenStreetMap Public Tile Usage Limits** | Heavy production traffic can trigger rate limits on `tile.openstreetmap.org` | 3 | 2 | **6** | Added `User-Agent: com.krishivikas.ai` and `errorTileCallback`; evaluate self-hosted vector tiles or Mapbox for scale. | Monitor tile error callback frequency. | **NO** |
| **RSK-007** | **Absence of IoT Sensor Hardware** | Soil telemetry and moisture curves currently rely on algorithmic demo data | 2 | 5 | **10** | Keep demo status clearly isolated from real farm profiles until ESP32 integration phase. | Do not promise live sensor streaming in current UI. | **NO** |
