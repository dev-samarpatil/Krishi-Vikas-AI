# Krishi Vikas AI — Phase 1 Groq Migration Readiness

**Document:** `docs/architecture/PHASE_0_PHASE_1_READINESS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Migration Overview

Phase 1 will transition the agricultural conversational chatbot text generation from Google Gemini (`gemini-2.5-flash`) to **Groq Cloud**, while keeping the multimodal Crop Scan vision pipeline completely independent on Gemini Vision.

---

## 2. Technical Call Sites & Architecture

| Parameter | Current Baseline | Phase 1 Target |
| :--- | :--- | :--- |
| **FastAPI Route** | `POST /api/v1/chat` and `POST /chat` | Unchanged (`POST /api/v1/chat` & `POST /chat`) |
| **Service File** | `backend/services/ai_service.py` | `backend/services/ai_service.py` |
| **Primary Method** | `AIService.generate_chat_response(...)` | `AIService.generate_chat_response(...)` |
| **Primary AI Client** | `google.generativeai.GenerativeModel` | `groq.Groq` / `AsyncGroq` client |
| **Model Config** | `gemini-2.5-flash` | Configurable (e.g., `llama-3.3-70b-versatile` or `qwen/qwen-2.5-32b`) |
| **Crop Scan Vision** | `gemini-2.5-flash` | **Unchanged** (Gemini Vision preserved) |
| **Flutter Contract** | `ChatRequest` / `ChatResponse` | **100% Identical** (Zero Flutter code changes required) |

---

## 3. Decoupling Verification

A critical Phase 0 requirement was verifying whether Chat and Crop Scan share AI provider initialization:
- **Finding:** Inside `backend/services/ai_service.py`, `self.chat_model` and `self.vision_model` are instantiated separately.
- **Verification:** `analyze_crop_image()` does not depend on `generate_chat_response()`.
- **Phase 1 Guardrail:** Updating the chat text generator to instantiate a Groq client will have zero side effects on the crop vision pipeline.

---

## 4. Configuration & Environment Blueprint

Phase 1 will introduce the following environment variable conventions:
- `GROQ_API_KEY`: Secret API key for Groq Cloud.
- `CHAT_PROVIDER`: Provider toggle (`"groq"` with `"gemini"` fallback).
- `GROQ_CHAT_MODEL`: Configurable model name (default: `llama-3.3-70b-versatile`).

---

## 5. Rollback Strategy & Dual-Provider Resilience

To prevent downtime or outages during the migration:
1. **Fallback Hierarchy:**
   ```
   Primary: Groq Cloud (Ultra-low latency, high throughput)
       ↓ (If Groq rate limit / network error)
   Secondary: Gemini 2.5 Flash
       ↓ (If both fail)
   Explicit Error: HTTP 502 with structured retry bubble
   ```
2. **Instant Rollback:**
   If Groq encounters operational issues, setting `CHAT_PROVIDER="gemini"` in `.env` or Render immediately restores the pure Gemini chat behavior without requiring code deployment.

---

## 6. Pre-Implementation Checklist for Phase 1

- [x] Phase 0 baseline documented and frozen.
- [x] Baseline unit and widget test suites passing.
- [x] Flutter request/response schema verified.
- [x] `groq` Python SDK installed in environment (`0.11.0` installed).
- [ ] Create git branch `feat/phase-1-groq-migration`.
- [ ] Implement `GroqChatProvider` in `backend/services/ai_service.py`.
- [ ] Add unit tests in `backend/tests/test_chat_groq.py`.
- [ ] Verify Marathi and Hindi advisory generation via Groq.
