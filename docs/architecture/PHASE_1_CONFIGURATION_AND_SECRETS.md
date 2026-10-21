# Krishi Vikas AI — Phase 1 Configuration & Secrets Management

**Document:** `docs/architecture/PHASE_1_CONFIGURATION_AND_SECRETS.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Security Architect & DevOps Engineer  
**Status:** CONFIGURED & VERIFIED  

---

## 1. Overview & Architectural Principles

Phase 1 migrates Krishi Vikas AI's conversational text chatbot to Groq Cloud while strictly preserving zero-trust security and defense-in-depth principles:
- **Zero Frontend Secrets:** No Groq API keys, tokens, or headers are distributed to Flutter client bundles or web frontends.
- **Strict Server-Side Isolation:** All Groq communications occur exclusively within the FastAPI backend runtime.
- **No Secret Logging:** Requests, responses, exception messages, and diagnostic traces redact authorization headers, tokens, and credentials.
- **Configurable Provider Selection:** Seamless switching between `groq` and `gemini` via environment variable for zero-code rollback.

---

## 2. Environment Configuration Inventory

| Variable Name | Required | Default Value | Target Environment | Description & Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `CHAT_PROVIDER` | Optional | `groq` | Backend (.env / Render) | Controls active chat provider (`groq` or `gemini`). Allows instant rollback without rebuilding. |
| `GROQ_API_KEY` | **Required** (if `CHAT_PROVIDER=groq`) | None | Backend Secret Store | Server-side API key for Groq Cloud inference (`gsk_...`). |
| `GROQ_MODEL` | Optional | `qwen/qwen3.8-27b` | Backend (.env / Render) | Active Groq model identifier verified on the account. |
| `GROQ_TIMEOUT_SECONDS`| Optional | `30.0` | Backend (.env / Render) | Finite upstream HTTP timeout preventing thread/connection hangs. |
| `GROQ_MAX_RETRIES` | Optional | `2` | Backend (.env / Render) | Bounded retry attempts with exponential backoff on transient 429/503 errors. |
| `GEMINI_API_KEY` | **Required** (for Crop Scan / Rollback) | None | Backend Secret Store | API key for Google Gemini multimodal vision (`AIzaSy...`). |
| `GEMINI_CHAT_MODEL` | Optional | `gemini-2.5-flash` | Backend (.env / Render) | Retained Gemini model for rollback chat if selected. |

---

## 3. Secret Sanitization & Error Handling Rules

1. **Authentication Error Sanitization:** If Groq returns `401 Unauthorized` or `Invalid API Key`, the backend returns structured HTTP 503 (`CONFIG_ERROR` / `AUTH_ERROR`) with a user-friendly message (`"The AI assistant is temporarily unavailable. Please try again shortly."`) and records a redacted log entry without revealing key substrings.
2. **Exception Shields:** Stack traces, internal IP addresses, and provider HTTP headers are intercepted by custom exception handlers and never forwarded in API responses.
3. **Flutter Network Layer:** The Flutter app connects to `POST /api/chat` using standard session tokens (if authenticated) and receives normalized payloads (`reply`, `response`, `intent_type`, `request_id`). Flutter is completely agnostic of provider API keys.

---

## 4. Render Deployment Configuration Guide

When deploying the backend on Render:
1. Navigate to **Render Dashboard** -> **Krishi Vikas AI Backend Service** -> **Environment**.
2. Add the following environment variables under **Secret Environment Variables**:
   ```ini
   CHAT_PROVIDER=groq
   GROQ_API_KEY=gsk_********************************
   GROQ_MODEL=qwen/qwen3.8-27b
   GROQ_TIMEOUT_SECONDS=30.0
   GROQ_MAX_RETRIES=2
   ```
3. Retain existing variables (`GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`).
4. Trigger manual deploy with clear cache if dependencies change.
