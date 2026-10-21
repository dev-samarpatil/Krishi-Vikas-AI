# Krishi Vikas AI — Phase 1 Baseline Confirmation

**Document:** `docs/architecture/PHASE_1_BASELINE_CONFIRMATION.md`  
**Date:** October 21, 2026  
**Environment:** Windows 11, Python 3.14.3, Flutter 3.x, Groq SDK 0.9.0+  
**Status:** BASELINE CONFIRMED  

---

## 1. Executive Summary

Prior to modifying any source code for Phase 1 (Groq Chatbot Integration), full baseline test suites were executed across both the Python FastAPI backend and the Flutter mobile application.

The baseline verification confirmed:
1. **Backend Test Suite:** 17 tests executed via `pytest -v`.
   - **17/17 PASSED (100%)**
   - Verified tests:
     - 10 chat endpoint regression & contract tests (`test_chat_regression.py`)
     - 6 crop scan / diagnosis tests (`test_diagnose_regression.py`)
     - 1 live Gemini vision grounding test (`test_vision_grounding.py`)
2. **Flutter Test Suite:** 7 tests executed via `flutter test`.
   - **7/7 PASSED (100%)**
   - Verified tests:
     - BudgetItem parsing & serialization
     - Map coordinate clamping
     - Chat error UI & retry interaction
     - Map imagery fallback banner
     - Crop scan model classification (healthy, diseased, inconclusive, invalid)
     - Crop scan error UI display & retry button
3. **Pre-existing Operational Constraints:**
   - Gemini free-tier quota is subject to 20 requests/day per project limits.
   - Deprecation warnings emitted for `google.generativeai` recommending future transition to `google.genai`.
   - These constraints reinforce the primary rationale of migrating conversational chat to Groq in Phase 1.

---

## 2. Baseline Test Execution Records

### 2.1 Backend Pytest Execution

```text
============================= test session starts =============================
platform win32 -- Python 3.14.3, pytest-9.1.1, pluggy-1.7.0
rootdir: C:\Krishi Vikas AI_ Antigravity\backend
collected 17 items

tests/test_chat_regression.py::TestChatbotRegression::test_01_simple_greeting PASSED [  5%]
tests/test_chat_regression.py::TestChatbotRegression::test_02_soybean_cultivation_query PASSED [ 11%]
tests/test_chat_regression.py::TestChatbotRegression::test_03_marathi_agricultural_query PASSED [ 17%]
tests/test_chat_regression.py::TestChatbotRegression::test_04_empty_message_validation PASSED [ 23%]
tests/test_chat_regression.py::TestChatbotRegression::test_05_malformed_request_body PASSED [ 29%]
tests/test_chat_regression.py::TestChatbotRegression::test_06_missing_api_keys PASSED [ 35%]
tests/test_chat_regression.py::TestChatbotRegression::test_07_gemini_upstream_failure PASSED [ 41%]
tests/test_chat_regression.py::TestChatbotRegression::test_08_internal_error_hides_secrets PASSED [ 47%]
tests/test_chat_regression.py::TestChatbotRegression::test_09_mandi_price_interceptor PASSED [ 52%]
tests/test_chat_regression.py::TestChatbotRegression::test_10_farm_scoped_chat_endpoint PASSED [ 58%]
tests/test_diagnose_regression.py::test_diagnose_empty_image_rejected PASSED [ 64%]
tests/test_diagnose_regression.py::test_diagnose_invalid_image_format_rejected PASSED [ 70%]
tests/test_diagnose_regression.py::test_diagnose_non_crop_detection_not_forced_into_disease PASSED [ 76%]
tests/test_diagnose_regression.py::test_diagnose_unparseable_gemini_response_returns_502_not_fake_disease PASSED [ 82%]
tests/test_diagnose_regression.py::test_diagnose_valid_disease_parsed_and_saved PASSED [ 88%]
tests/test_diagnose_regression.py::test_diagnose_invalid_image_never_saved_to_supabase PASSED [ 94%]
tests/test_vision_grounding.py::test_gemini_vision_real_call PASSED [100%]

================== 17 passed, 3 warnings in 75.56s ==================
```

### 2.2 Flutter Test Execution

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

---

## 3. Git Working-Tree Baseline

- Branch: `main` (up to date with `origin/main`)
- Existing uncommitted working modifications preserved:
  - `flutter_app/lib/features/chat/presentation/screens/chat_screen.dart`
  - `flutter_app/lib/features/map/presentation/screens/sentinel_map_screen.dart`
  - `flutter_app/lib/features/scan/models/scan_response_model.dart`
  - `flutter_app/lib/features/scan/presentation/screens/scan_result_screen.dart`
  - `flutter_app/lib/features/scan/presentation/screens/scan_screen.dart`
  - `flutter_app/test/widget_test.dart`
- Untracked directories: `docs/architecture/`, `documents/`
- Rule compliance: All existing files and modifications are retained without destructive operations.

---

## 4. Shared Code & Isolation Confirmation

- **Chat Workflow:** `backend/routes/chat.py` receives `/api/chat` requests and calls `chat_with_farmer`.
- **Crop Scan Workflow:** `backend/routes/diagnose.py` receives `/api/v1/diagnose` and `/api/diagnose` image uploads and calls Gemini Vision directly via `get_model()`.
- **Finding:** Crop Scan does not import or share conversational chat code from `backend/routes/chat.py`. The two workflows are already decoupled at the router level.
