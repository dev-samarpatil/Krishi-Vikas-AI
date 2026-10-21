# Krishi Vikas AI — Phase 1 Test Execution Report

**Document:** `docs/architecture/PHASE_1_TEST_REPORT.md`  
**Date:** October 21, 2026  
**Auditor:** Senior QA & Test Automation Engineer  
**Status:** ALL TESTS PASSED (100%)  

---

## 1. Test Execution Summary

| Test Suite | Environment | Total Tests | Passed | Failed | Skipped | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Backend Groq Provider Unit Tests** | `backend/tests/test_groq_service.py` | 8 | 8 | 0 | 0 | **PASSED (100%)** |
| **Backend Chat Regression & Contract Tests** | `backend/tests/test_chat_regression.py` | 13 | 13 | 0 | 0 | **PASSED (100%)** |
| **Backend Crop Diagnosis Tests** | `backend/tests/test_diagnose_regression.py` | 6 | 6 | 0 | 0 | **PASSED (100%)** |
| **Backend Vision Grounding Test** | `backend/tests/test_vision_grounding.py` | 1 | 1 | 0 | 0 | **PASSED (100%)** |
| **Flutter Mobile UI & Widget Tests** | `flutter_app/test/widget_test.dart` | 7 | 7 | 0 | 0 | **PASSED (100%)** |
| **Live Groq End-to-End Chat Smoke Test** | Python / TestClient (Live API) | 2 | 2 | 0 | 0 | **PASSED (100%)** |
| **Total Test Verification** | Cross-platform | **37** | **37** | **0** | **0** | **PASSED (100%)** |

---

## 2. Detailed Test Breakdown

### 2.1 Backend Unit & Regression Suite (`pytest -v`)
Command: `pytest -v`  
Execution time: ~30.5 seconds  
Results: **28/28 PASSED**

```text
tests/test_chat_regression.py::TestChatbotRegression::test_01_simple_greeting_groq_primary PASSED [  3%]
tests/test_chat_regression.py::TestChatbotRegression::test_02_soybean_cultivation_query PASSED [  7%]
tests/test_chat_regression.py::TestChatbotRegression::test_03_marathi_agricultural_query PASSED [ 10%]
tests/test_chat_regression.py::TestChatbotRegression::test_04_empty_message_validation PASSED [ 14%]
tests/test_chat_regression.py::TestChatbotRegression::test_05_malformed_request_body PASSED [ 17%]
tests/test_chat_regression.py::TestChatbotRegression::test_06_missing_api_keys PASSED [ 21%]
tests/test_chat_regression.py::TestChatbotRegression::test_07_groq_failure_fallback_to_gemini PASSED [ 25%]
tests/test_chat_regression.py::TestChatbotRegression::test_08_internal_error_hides_secrets PASSED [ 28%]
tests/test_chat_regression.py::TestChatbotRegression::test_09_mandi_price_interceptor PASSED [ 32%]
tests/test_chat_regression.py::TestChatbotRegression::test_10_farm_scoped_chat_endpoint PASSED [ 35%]
tests/test_chat_regression.py::TestChatbotRegression::test_11_rollback_provider_selection PASSED [ 39%]
tests/test_chat_regression.py::TestChatbotRegression::test_12_api_v1_chat_alias_endpoint PASSED [ 42%]
tests/test_chat_regression.py::TestChatbotRegression::test_13_upstream_total_failure_returns_503 PASSED [ 46%]
tests/test_diagnose_regression.py::test_diagnose_empty_image_rejected PASSED [ 50%]
tests/test_diagnose_regression.py::test_diagnose_invalid_image_format_rejected PASSED [ 53%]
tests/test_diagnose_regression.py::test_diagnose_non_crop_detection_not_forced_into_disease PASSED [ 57%]
tests/test_diagnose_regression.py::test_diagnose_unparseable_gemini_response_returns_502_not_fake_disease PASSED [ 60%]
tests/test_diagnose_regression.py::test_diagnose_valid_disease_parsed_and_saved PASSED [ 64%]
tests/test_diagnose_regression.py::test_diagnose_invalid_image_never_saved_to_supabase PASSED [ 67%]
tests/test_groq_service.py::test_01_successful_groq_response PASSED      [ 71%]
tests/test_groq_service.py::test_02_missing_api_key_raises_config_error PASSED [ 75%]
tests/test_groq_service.py::test_03_authentication_failure_not_retryable PASSED [ 78%]
tests/test_groq_service.py::test_04_rate_limit_with_retry_exhaustion PASSED [ 82%]
tests/test_groq_service.py::test_05_empty_completion_handling PASSED     [ 85%]
tests/test_groq_service.py::test_06_timeout_handling PASSED              [ 89%]
tests/test_groq_service.py::test_07_transient_error_recovers_on_retry PASSED [ 92%]
tests/test_groq_service.py::test_08_prompt_safety_guardrails_presence PASSED [ 96%]
tests/test_vision_grounding.py::test_gemini_vision_real_call PASSED      [100%]
```

### 2.2 Flutter Client Suite (`flutter test`)
Command: `flutter test`  
Execution time: ~4.5 seconds  
Results: **7/7 PASSED**

```text
00:00 +0: BudgetItem Model Tests fromJson should parse valid JSON correctly
00:00 +1: BudgetItem Model Tests toJson should convert BudgetItem to JSON correctly
00:00 +2: Map Coordinate Clamping Tests Outbreak coordinates are clamped to valid geographical bounds
00:00 +3: Chat Error UI & Retry Tests Error bubble displays message and triggers retry on press
00:00 +4: Map Imagery Fallback Banner Tests Tile load error banner renders correctly and dismisses on retry
00:00 +5: Crop Scan Dynamic Representation & Truthful State Tests ScanResponseModel correctly identifies healthy vs disease vs inconclusive vs invalid
00:00 +6: Crop Scan Dynamic Representation & Truthful State Tests Scan error UI displays genuine failure reason and retry button
00:00 +7: All tests passed!
```

### 2.3 Live End-to-End Chat Smoke Tests
Live invocations against the actual FastAPI `/api/chat` route using the live `GROQ_API_KEY`:

1. **English Agronomy Query:**
   - Input: `"Explain one basic way a farmer can conserve soil moisture."`
   - HTTP Status: `200 OK`
   - Provider: `groq/qwen/qwen3.8-27b`
   - Response: Contextualized advice for Nashik loamy soil discussing mulching and moisture conservation.
   - Outcome: **VERIFIED WORKING LIVE**.

2. **Marathi Agronomy Query:**
   - Input: `"सोयाबीनची लागवड कशी करावी?"`
   - HTTP Status: `200 OK`
   - Provider: `groq/qwen/qwen3.8-27b`
   - Response: 2,702 bytes of fluent Marathi agronomic instructions.
   - Outcome: **VERIFIED WORKING LIVE**.

---

## 3. Regression Analysis

- **Crop Scan (`routes/diagnose.py`):** 100% unaffected. All 6 unit/contract tests and the live grounding call passed without modification.
- **Sentinel Map & Farm UI:** All model parsing and coordinate clamping widget tests passed.
- **Mandi Prices & Schemes:** Static and dynamic mock queries in chat regression suite passed cleanly.
