# Krishi Vikas AI — Phase 1 Risk Register

**Document:** `docs/architecture/PHASE_1_RISK_REGISTER.md`  
**Date:** October 21, 2026  
**Auditor:** Principal Risk & Reliability Architect  
**Status:** ALL PHASE 1 RISKS MITIGATED & ACCEPTABLE  

---

## 1. Risk Matrix

| Risk ID | Risk Description | Severity | Likelihood | Mitigation Strategy | Verification Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **RSK-01** | **Crop Scan Inadvertent Degradation:** Modifying chat logic damages Crop Scan vision pipeline. | High | Low | Complete decoupling: `routes/diagnose.py` does not import or share chat provider state. | `test_diagnose_regression.py` (6 tests) and live grounding test pass 100%. | **MITIGATED** |
| **RSK-02** | **Groq Model Incompatibility / Deprecation:** Configured model identifier decommissioned by Groq. | High | Medium | Made model dynamically configurable via `GROQ_MODEL`. Validated active account models (`qwen/qwen3.8-27b`). | Live API query confirms active model; fallback to Gemini supported. | **MITIGATED** |
| **RSK-03** | **API Key / Secret Leakage:** Exposure of Groq or Gemini API keys in client bundles, errors, or logs. | Critical | Low | Zero frontend keys. Authentication errors sanitized to exclude headers. Exception shields intercept raw traces. | `test_03_authentication_failure_not_retryable` and `test_08_internal_error_hides_secrets` pass. | **MITIGATED** |
| **RSK-04** | **API Contract Incompatibility:** Flutter chat screen fails to parse new provider payload. | Critical | Low | Preserved exact keys: `reply`, `response`, `intent_type`, `provider`, `request_id`, status 200/503. | `flutter test` and end-to-end FastAPI test client pass cleanly. | **MITIGATED** |
| **RSK-05** | **Groq Cloud Transient Rate Limits (429):** Free or standard tier quota spikes during peak usage. | Medium | Medium | Bounded retries (up to 2) with exponential backoff; secondary resilient fallback to Gemini if configured. | `test_04_rate_limit_with_retry_exhaustion` and `test_07_groq_failure_fallback_to_gemini` pass. | **MITIGATED** |
| **RSK-06** | **Hallucinated Chemical Dosages / Dangerous Advice:** AI giving inaccurate pesticide concentrations. | High | Medium | Agricultural safety prompt explicitly warns farmers to follow manufacturer product labels and consult local KVK. | Prompt safety tests pass; live outputs verified. | **MITIGATED** |
| **RSK-07** | **Rollback Incomplete / High Downtime:** Difficult recovery if Groq service fails post-deployment. | Medium | Low | Zero-code rollback via `CHAT_PROVIDER=gemini` environment variable switch. | `test_11_rollback_provider_selection` proves instant rollback. | **MITIGATED** |
