# Krishi Vikas AI — Phase 0 Baseline Test Report

**Document:** `docs/architecture/PHASE_0_BASELINE_TEST_REPORT.md`  
**Date:** October 21, 2026  
**Auditor:** Senior QA & Release Engineer  

---

## 1. Test Execution Summary

| Test Suite | Environment | Total Tests | Passed | Failed | Status / Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Flutter Widget & Unit Tests** | `flutter_app/test/` | 7 | 7 | 0 | **PASSED (100%)** |
| **Backend Unit & Endpoint Tests** | `backend/tests/` | 16 | 16 | 0 | **PASSED (100%)** |
| **Backend Live AI Integration Test** | `backend/tests/` | 1 | 0 | 1 | **FAILED (429 Rate Limit)** |
| **Mobile Release Compilation** | Gradle / Android SDK | 1 | 1 | 0 | **PASSED (APK built)** |

---

## 2. Flutter Test Results (`flutter test`)

Command executed: `flutter test`  
Execution time: 4.1 seconds  
Overall Status: **PASSED (7/7)**

| Test Name | File | Result | Verified Capability |
| :--- | :--- | :--- | :--- |
| `ScanResponseModel parses invalid_image truthful payload correctly` | `widget_test.dart` | **PASSED** | Validates that non-crop rejection payloads (`confidence: 0.0`) parse accurately |
| `ScanResponseModel parses healthy plant payload correctly` | `widget_test.dart` | **PASSED** | Validates that healthy crop responses parse with `isHealthy: true` |
| `SentinelMap coordinates clamping handles out of bounds lat/lon safely` | `widget_test.dart` | **PASSED** | Verifies coordinate clamping to `[-90, 90]` and `[-180, 180]` prevents map projection crash |
| `SentinelMap has OpenStreetMap tile URL template configured` | `widget_test.dart` | **PASSED** | Confirms active tile provider points to `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| `SentinelMap error banner displays when tile error occurs` | `widget_test.dart` | **PASSED** | Verifies offline/tile loading failure surfaces in-app warning banner |
| `Chat retry callback is triggered on error bubble interaction` | `widget_test.dart` | **PASSED** | Verifies tapping error bubble retry button dispatches retry action |
| `Smoke test: App widget tree initializes` | `widget_test.dart` | **PASSED** | App root widget initializes without crashing |

---

## 3. Backend Test Results (`pytest -v`)

Command executed: `pytest -v`  
Execution time: 30.13 seconds  
Overall Status: **16 PASSED, 1 FAILED (Live Quota Exhaustion)**

### 3.1 Unit, Router, and Mock Tests (16/16 PASSED)

| Test File | Test Identifier | Result | Description |
| :--- | :--- | :--- | :--- |
| `tests/test_api_endpoints.py` | `test_root_endpoint` | **PASSED** | Verifies `GET /` returns status online |
| `tests/test_api_endpoints.py` | `test_health_endpoint` | **PASSED** | Verifies `GET /health` returns healthy status |
| `tests/test_api_endpoints.py` | `test_weather_current_mock` | **PASSED** | Verifies weather endpoint serialization |
| `tests/test_api_endpoints.py` | `test_market_prices_static` | **PASSED** | Verifies mandi prices load from JSON dataset |
| `tests/test_api_endpoints.py` | `test_schemes_list` | **PASSED** | Verifies government schemes catalog returns valid schema |
| `tests/test_api_endpoints.py` | `test_alerts_map_geojson` | **PASSED** | Verifies Sentinel Map alert cluster payload structure |
| `tests/test_api_endpoints.py` | `test_farm_summary` | **PASSED** | Verifies My Farm summary profile and soil telemetry schema |
| `tests/test_chat.py` | `test_chat_request_validation` | **PASSED** | Verifies Pydantic schema validation for chat payloads |
| `tests/test_chat.py` | `test_chat_response_structure` | **PASSED** | Verifies chat response contains detected language and quick replies |
| `tests/test_chat.py` | `test_chat_history_preservation` | **PASSED** | Verifies multi-turn conversation context is preserved |
| `tests/test_chat.py` | `test_chat_multilingual_marathi` | **PASSED** | Verifies Marathi character encoding and system prompt directives |
| `tests/test_chat.py` | `test_chat_error_fallback_handling` | **PASSED** | Verifies graceful fallback and 502 error generation on total outage |
| `tests/test_diagnose.py` | `test_diagnose_rejects_non_image_file` | **PASSED** | Verifies non-image file uploads return HTTP 400 |
| `tests/test_diagnose.py` | `test_diagnose_parses_healthy_crop` | **PASSED** | Verifies schema accepts healthy plant classifications |
| `tests/test_diagnose.py` | `test_diagnose_parses_invalid_image_rejection` | **PASSED** | Verifies schema accepts `invalid_image` classifications |
| `tests/test_diagnose.py` | `test_diagnose_removes_fake_leaf_disease_fallback` | **PASSED** | Confirms code does not return fake disease diagnosis when vision model fails |

### 3.2 Live Service Test (1 FAILED — Quota Exhausted)

| Test File | Test Identifier | Result | Root Cause & Evidence |
| :--- | :--- | :--- | :--- |
| `tests/test_vision_grounding.py` | `test_gemini_vision_real_call` | **FAILED**<br>(`REQUIRES LIVE SERVICE`) | `google.api_core.exceptions.TooManyRequests: 429 POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`<br>**Quota Exceeded:** `limit: 20 requests/day on Free Tier` for `gemini-2.5-flash`. |

*Detailed Failure Analysis:*  
The live test genuinely transmitted a synthetic leaf image to Google's Gemini 2.5 Flash endpoint. Because the project's free-tier Gemini API key has a hard limit of 20 requests per day per project, the request was rejected with HTTP 429. This provides definitive empirical proof that:
1. The code is actively attempting live calls to `gemini-2.5-flash` rather than returning a local mock.
2. The free-tier 20 req/day quota limit is an urgent operational constraint, directly justifying the planned Phase 1 Groq migration!

---

## 4. Mobile Release Build

- **Artifact:** `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- **Size:** 63.8 MB
- **Compilation Outcome:** Clean Gradle release build with ProGuard/R8 optimizations.
