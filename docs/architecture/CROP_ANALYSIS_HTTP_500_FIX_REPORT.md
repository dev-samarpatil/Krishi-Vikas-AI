# Crop Analysis HTTP 500 Diagnosis & Fix Report

**Project:** Krishi Vikas AI  
**Date:** 2026-10-22  
**Final Status:** `FIXED AND LIVE VERIFIED`  
**Milestone:** Crop Diagnosis Engine Stability & Error Resilience  

---

## 1. Executive Summary

Farmers using Krishi Vikas AI encountered a critical error upon scanning their crops:
```
Analysis Failed
DioException [bad response]: This exception was thrown because the response has a status code of 500
```
This report documents the end-to-end investigation, evidence-based root cause identification, architectural corrections applied across the Python FastAPI backend and Flutter client, test regression results, and the live AI verification confirming full resolution.

---

## 2. Root Cause Analysis (Confirmed by Logs)

Investigation of backend logs, exception tracebacks, and live endpoint reproduction revealed three intersecting issues that produced HTTP 500:

### Cause A: Gemini Free Tier Quota Exhaustion on Hardcoded Model
* The default vision model in `backend/routes/diagnose.py` and `backend/.env.example` was set to `gemini-2.5-flash`.
* `gemini-2.5-flash` had hit its free-tier daily quota limit (`20 requests/day`), returning:
  ```
  google.api_core.exceptions.TooManyRequests: 429 POST ... Quota exceeded for metric: 
  generativelanguage.googleapis.com/generate_content_free_tier_requests, limit: 20, model: gemini-2.5-flash
  ```

### Cause B: Unhandled Generic Exception Mapping into HTTP 500
* In `backend/routes/diagnose.py`, the upstream `429 TooManyRequests` (and any other upstream Google API error, such as `DeadlineExceeded` or `PermissionDenied`) was caught by a generic `except Exception as e:` block.
* This converted upstream quota, rate limit, or network status codes directly into `status_code=500` with code `DIAGNOSIS_FAILED`.

### Cause C: Windows Terminal CharMap Unicode Crash on Hindi/Indic Output
* Even when Gemini Vision returned a valid diagnosis containing Devanagari / Indic script (e.g., local Hindi crop names like `फसल की तस्वीर नहीं है` or Marathi translations), the backend executed:
  ```python
  print(raw_text)
  ```
* On Windows hosts with default console encoding (`charmap` / `cp1252`), attempting to print non-ASCII characters to `sys.stdout` threw:
  ```
  UnicodeEncodeError: 'charmap' codec can't encode characters in position ...: character maps to <undefined>
  ```
* Because `UnicodeEncodeError` is a subclass of `ValueError` and `Exception`, it crashed the request into `HTTP 500 DIAGNOSIS_FAILED` immediately after the AI model had successfully analyzed the crop!

### Cause D: Raw Technical DioException Exposed to Flutter Users
* In Flutter `scan_provider.dart`, the error state stored `e.toString().replaceAll('Exception: ', '')`.
* When Dio received a 500 (or 429), it displayed raw internal networking strings (`DioException [bad response]: ... status code of 500`) directly to farmers on `ScanLoadingScreen`.
* Furthermore, `runScan()` lacked a check for `if (state.status == ScanStatus.loading) return;`, allowing duplicate concurrent submissions when farmers rapidly pressed "Retry Analysis".

### Cause E: Supabase Diagnosis Table Column Mismatch
* `save_diagnosis` in `backend/services/supabase_service.py` attempted to insert `crop_type` into `diagnoses`, whereas the database table schema defined the column as `crop` and `user_id` as foreign key, throwing non-critical save errors.

---

## 3. Relevant Files Modified

| File | Component | Nature of Modification |
|---|---|---|
| `backend/routes/diagnose.py` | FastAPI Endpoint | Switched default vision model to `gemini-flash-lite-latest`, added multi-candidate model fallback chain, implemented status code mapping (400, 413, 429, 502, 503, 500), and added `safe_log` for Windows Unicode safety. |
| `backend/main.py` | FastAPI Application | Added `@app.get("/health")` endpoint alias, updated test endpoints to use configured vision model. |
| `backend/.env.example` | Configuration Template | Updated recommended model from `gemini-2.5-flash` to `gemini-flash-lite-latest`. |
| `.env` | Local Environment | Configured `GEMINI_VISION_MODEL=gemini-flash-lite-latest`. |
| `backend/services/supabase_service.py` | Database Service | Aligned `save_diagnosis` payload with `diagnoses` table schema (`crop`, `user_id`). |
| `backend/tests/test_diagnose_regression.py` | Regression Tests | Added tests for 429 quota exhaustion, 503 auth failure, 503 network timeout, 413 payload limit, isolated live test. |
| `backend/tests/test_vision_grounding.py` | Vision Unit Tests | Updated to use configured model rather than hardcoded `gemini-2.5-flash`. |
| `flutter_app/lib/features/scan/presentation/providers/scan_provider.dart` | Flutter Riverpod State | Added `getReadableScanErrorMessage` mapping DioExceptions, status codes (400, 413, 415, 422, 429, 500, 502, 503) and timeouts to friendly messages; added concurrency lock to prevent duplicate scans. |
| `flutter_app/test/widget_test.dart` | Flutter Widget Tests | Added 8 unit tests validating error mapping, Dio exception suppression, and retry behavior. |

---

## 4. Exact Fixes Implemented

### 4.1 Backend Dynamic Vision Model Fallback Chain
In `backend/routes/diagnose.py`:
```python
DEFAULT_VISION_MODEL = "gemini-flash-lite-latest"

def generate_content_with_fallback(contents, generation_config=None) -> str:
    primary_model = os.getenv("GEMINI_VISION_MODEL") or DEFAULT_VISION_MODEL
    candidate_models = [
        primary_model,
        "gemini-flash-lite-latest",
        "gemini-2.5-flash-lite",
        "gemini-flash-latest",
        "gemini-2.5-flash",
        "gemini-pro-latest",
    ]
    ...
```
If a model encounters `TooManyRequests` or `ResourceExhausted` (429), it automatically tries the next candidate model in the chain before returning an error.

### 4.2 Windows Console Unicode Safe Logging
```python
def safe_log(msg: Any):
    """Safely print log messages on Windows console regardless of terminal charmap encoding."""
    text = str(msg)
    try:
        print(text)
    except UnicodeEncodeError:
        try:
            encoding = getattr(sys.stdout, "encoding", "utf-8") or "utf-8"
            print(text.encode(encoding, errors="backslashreplace").decode(encoding))
        except Exception:
            pass
```

### 4.3 Semantic HTTP Status Code Mapping
* **`400 Bad Request`**: Empty file (`0` bytes) or corrupt non-image bytes (`INVALID_IMAGE_FORMAT`).
* **`413 Payload Too Large`**: Uploaded image exceeds 15 MB limit.
* **`429 Too Many Requests`**: AI service rate limit or free tier quota exhausted (`AI_QUOTA_EXCEEDED`).
* **`502 Bad Gateway`**: Upstream AI model produced unparseable JSON or garbage (`MODEL_RESPONSE_INVALID`).
* **`503 Service Unavailable`**: API key missing, unauthenticated, permission denied, or upstream network timeout (`AI_SERVICE_UNAVAILABLE`).
* **`500 Internal Server Error`**: Unexpected internal server faults (`DIAGNOSIS_FAILED`), with sensitive credentials and internal stack traces sanitized from client responses.

### 4.4 Flutter Dio Error Handling & Concurrency Guard
In `flutter_app/lib/features/scan/presentation/providers/scan_provider.dart`:
* Added `getReadableScanErrorMessage(e)` to extract backend `error.message` or translate HTTP status codes (400, 413, 415, 422, 429, 500, 502, 503) into human-friendly explanations.
* Replaced raw technical Dio strings with farmer-centric notifications:
  * Server error: *"We couldn't analyze your crop right now. Please try again shortly."*
  * Quota / rate limit: *"Crop analysis is temporarily busy. Please try again in a few moments."*
  * Connection failure: *"Unable to connect to the server. Check your internet connection."*
  * Invalid image: *"This image could not be processed. Please select or capture a clearer image."*
* Added concurrent request protection:
  ```dart
  if (state.status == ScanStatus.loading) return;
  ```
* Reuses existing `state.imageFile` on user retry without re-picking.

---

## 5. Test Execution and Actual Results

### 5.1 Backend Pytest Suite
* **Diagnose Regression Tests (`backend/tests/test_diagnose_regression.py`):**
  * `test_diagnose_empty_image_rejected`: **PASSED**
  * `test_diagnose_invalid_image_format_rejected`: **PASSED**
  * `test_diagnose_non_crop_detection_not_forced_into_disease`: **PASSED**
  * `test_diagnose_unparseable_gemini_response_returns_502_not_fake_disease`: **PASSED**
  * `test_diagnose_valid_disease_parsed_and_saved`: **PASSED**
  * `test_diagnose_invalid_image_never_saved_to_supabase`: **PASSED**
  * `test_diagnose_gemini_quota_exceeded_returns_429`: **PASSED**
  * `test_diagnose_gemini_auth_failure_returns_503`: **PASSED**
  * `test_diagnose_gemini_network_timeout_returns_503`: **PASSED**
  * `test_diagnose_payload_too_large_returns_413`: **PASSED**
  * `test_diagnose_live_integration_real_model`: **PASSED**
* **Full Backend Regression Suite (`pytest backend/tests -v`):**
  * **70 passed, 0 failed, 3 warnings in 120.16s**

### 5.2 Flutter Test Suite (`flutter test`)
* **14 passed, 0 failed in 10.4s**
  * `BudgetItem Model Tests`: **PASSED** (2/2)
  * `Map Coordinate Clamping Tests`: **PASSED** (1/1)
  * `Chat Error UI & Retry Tests`: **PASSED** (1/1)
  * `Map Imagery Fallback Banner Tests`: **PASSED** (1/1)
  * `Crop Scan Dynamic Representation & Truthful State Tests`: **PASSED** (2/2)
  * `Crop Scan Dio Error Handling & Status Code Mapping Tests`: **PASSED** (7/7)

---

## 6. Live AI Vision End-to-End Verification

A real plant pathology image of a tomato leaf exhibiting dark brown concentric lesions was submitted to `POST /api/diagnose`.

### Execution Trace:
1. **Request Received:** 828,487 bytes, `image/jpeg`.
2. **Roboflow Primary Scanner:** 
   * Prediction: `Tomato_Early_blight` with **99.49% confidence**.
3. **Gemini Vision Advisory Engine (`gemini-flash-lite-latest`):**
   * Model responded successfully with structured JSON pathology advisory.
4. **Endpoint Output:**
   * **HTTP Status Code:** `200 OK`
   * **Diagnosis Name:** `Tomato Early Blight`
   * **Pathogen Identified:** `Alternaria solani`
   * **Confidence:** `0.99`
   * **Treatment Steps:** Mancozeb 75% WP or Difenoconazole 25% EC with dosage instructions.
   * **Organic Option:** Neem Oil and Copper Fungicide foliar spray.
   * **Budget Breakdown:** Mancozeb (₹150), Sprayer rental (₹100), Labour (₹400) — Total: ₹650.
   * **Supabase Integration:** Saved record without schema errors.

### Simulated Failure Verification:
* Mocked Gemini quota exhaustion returned `HTTP 429` with `code: AI_QUOTA_EXCEEDED`.
* Flutter error handler translated this into *"Crop analysis is temporarily busy. Please try again in a few moments."* without crashing or showing Dio tracebacks.
* Farm disease history integrity preserved (non-crop images and errors are never saved as diseases).

---

## 7. Remaining Limitations and Recommendations

1. **Free Tier Quota Management:** While `gemini-flash-lite-latest` currently provides ample quota and lower latency, production deployment should consider a paid Google Cloud project key with explicit billing limits to avoid free-tier throttling during peak harvest seasons.
2. **Roboflow Network Resilience:** Roboflow is configured as a fast primary classifier. In offline or high-latency scenarios, the system gracefully falls back directly to Gemini Vision.
