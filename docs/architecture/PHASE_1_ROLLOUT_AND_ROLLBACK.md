# Krishi Vikas AI — Phase 1 Rollout & Rollback Plan

**Document:** `docs/architecture/PHASE_1_ROLLOUT_AND_ROLLBACK.md`  
**Date:** October 21, 2026  
**Auditor:** Senior DevOps & Site Reliability Engineer  
**Status:** READY FOR OPERATIONAL DEPLOYMENT  

---

## 1. Rollout Procedure

### 1.1 Prerequisites
1. Verified Groq Cloud account with active API key (`gsk_...`).
2. Supported active model verified on account: `qwen/qwen3.8-27b`.
3. Retained `GEMINI_API_KEY` configured for Crop Scan vision and chat secondary fallback.

### 1.2 Deployment Steps (e.g. on Render)
1. In the Render Dashboard environment settings for the backend web service, set:
   ```ini
   CHAT_PROVIDER=groq
   GROQ_API_KEY=gsk_your_live_key
   GROQ_MODEL=qwen/qwen3.8-27b
   GROQ_TIMEOUT_SECONDS=30.0
   GROQ_MAX_RETRIES=2
   ```
2. Trigger deployment.
3. Validate health checks:
   - `GET /` -> `{"status": "healthy"}`
   - `POST /api/chat` with `{ "message": "hi", "language": "en" }` -> verify response has `"provider": "groq/qwen/qwen3.8-27b"`.
   - `POST /api/diagnose` -> verify crop vision pipeline remains fully functional.

---

## 2. Rollback Triggers

Initiate immediate rollback if any of the following occur post-deployment:
1. Groq Cloud sustained outage or severe rate-limiting causing increased 503 errors.
2. Incompatible or decommissioned model identifier.
3. Chat response latency consistently exceeds 15 seconds.
4. Language quality regression in Indic languages reported by users.
5. Any regression observed in Crop Scan or Map features.

---

## 3. Instant Zero-Downtime Rollback Procedure

Because the backend preserves the legacy Gemini implementation and provides environment-based provider routing, rollback does **not** require code changes or Git reverts.

### Option A: Environment Variable Toggle (Recommended — Zero Downtime)
1. In Render Dashboard (or `.env`), update:
   ```ini
   CHAT_PROVIDER=gemini
   ```
2. Save changes (Render restarts the container automatically).
3. The backend immediately routes all `/api/chat` requests back to Google Gemini (`gemini-2.5-flash`), with Groq completely disabled.
4. Verify by checking `/api/chat` response `"provider": "gemini/gemini-2.5-flash"`.

### Option B: Code-Level Revert (If Emergency Git Rollback Required)
If Git revert is required:
1. Revert `backend/routes/chat.py` to point to `services/gemini_service.py`.
2. Delete `backend/services/groq_service.py`.
3. Re-run `pytest backend/tests/test_chat_regression.py`.
4. Commit and push.
*(Note: Option A is strongly preferred as it takes under 30 seconds without code modification).*
