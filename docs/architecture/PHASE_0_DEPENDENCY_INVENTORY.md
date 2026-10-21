# Krishi Vikas AI — Phase 0 Dependency & Runtime Inventory

**Document:** `docs/architecture/PHASE_0_DEPENDENCY_INVENTORY.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Runtime Environments

| Runtime / Engine | Declared Constraint | Actual Verified Version | Verification Command |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `>=3.3.0 <4.0.0` | **3.44.1** (stable channel) | `flutter --version` |
| **Dart SDK** | `^3.3.0` | **3.12.1** (bundled with Flutter) | `dart --version` |
| **Python** | `>=3.10` | **3.14.3** (Windows AMD64) | `python --version` |
| **Operating System** | Windows / Linux (Render) | Windows 11 Build 26100 | OS Environment |

---

## 2. Frontend Dependencies (`flutter_app/pubspec.yaml`)

| Package | Declared Version | Category | Purpose in Krishi Vikas AI |
| :--- | :--- | :--- | :--- |
| `http` | `^1.2.1` | Networking | REST API client for FastAPI backend calls |
| `provider` | `^6.1.2` | State Management | AppState, ChatState, FarmState management |
| `flutter_map` | `^7.0.2` | Geospatial / UI | Sentinel Map rendering engine |
| `latlong2` | `^0.9.1` | Geospatial | Coordinates, bounds, and distance calculations |
| `image_picker` | `^1.1.2` | Device I/O | Camera capture and gallery selection for Crop Scan |
| `shared_preferences`| `^2.2.3` | Local Storage | Persists offline user preferences and language |
| `google_fonts` | `^6.2.1` | UI Styling | Typography (Poppins, Roboto) |
| `intl` | `^0.19.0` | Localization | Multi-language and currency formatting |
| `flutter_spinkit` | `^5.2.1` | UI Elements | Loading spinners and animation indicators |
| `flutter_svg` | `^2.0.10+1` | UI Elements | Vector icon rendering |
| `fl_chart` | `^0.68.0` | Visualization | Soil moisture and farm sensor telemetry charts |
| `path_provider` | `^2.1.3` | System Storage | Local file caching for images and scan results |
| `uuid` | `^4.4.0` | Utilities | Generates unique session and scan tracking UUIDs |
| `speech_to_text` | `^6.6.1` | Voice | Audio input capture for Marathi/Hindi speech |
| `flutter_tts` | `^4.0.2` | Voice | Text-to-speech output for advisory playback |

---

## 3. Backend Dependencies (`backend/requirements.txt`)

| Package | Declared in `requirements.txt` | Installed Runtime Version | Purpose |
| :--- | :--- | :--- | :--- |
| `fastapi` | `0.111.0` | `0.135.3` | ASGI web application framework |
| `uvicorn` | `0.30.1` | `0.43.0` | ASGI production server |
| `pydantic` | `2.7.4` | `2.12.5` | Schema validation and data parsing |
| `pydantic-settings` | `2.3.4` | `2.7.1` | Environment variable management |
| `python-multipart` | `0.0.9` | `0.0.9` | Form-data parser for multipart image uploads |
| `python-dotenv` | `1.0.1` | `1.0.1` | Loads `.env` file configuration |
| `httpx` | `0.27.0` | `0.27.0` | Asynchronous HTTP client for external integrations |
| `supabase` | `2.5.0` | `2.28.3` | Database and Storage client |
| `google-generativeai`| `0.7.2` | `0.8.6` | Official SDK for Gemini Vision and Gemini Chat |
| `pillow` | `10.3.0` | `10.4.0` | Image processing and format conversion for scans |
| `pytest` | `8.2.2` | `8.3.4` | Test framework |
| `pytest-asyncio` | `0.23.7` | `0.24.0` | Async testing harness for FastAPI endpoints |
| `groq` | `0.9.0` | `0.11.0` | Groq Python SDK (currently used as secondary fallback) |

---

## 4. Architectural Dependency Warnings & Deprecations

During runtime execution and pytest runs, three notable warnings were recorded:
1. **`google-generativeai` Deprecation Warning:**
   ```
   FutureWarning: All support for the `google.generativeai` package has ended. 
   It will no longer be receiving updates or bug fixes. 
   Please switch to the `google.genai` package as soon as possible.
   ```
   *Action:* Phase 1 must keep this in view; the Groq text migration will reduce reliance on this package, and vision calls should eventually migrate to `google-genai`.
2. **`starlette.testclient` StarletteDeprecationWarning:**
   FastAPI's TestClient noted deprecation regarding `httpx` vs `httpx2`. Harmless for testing, but recorded.
3. **`grpcio < 1.83.0` Post-Quantum Cryptography warning:**
   Google Auth noted that `grpcio` will enforce `>= 1.83.0` by late 2026.
