# Krishi Vikas AI — Phase 0 Repository Inventory

**Document:** `docs/architecture/PHASE_0_REPOSITORY_INVENTORY.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Git Repository State

| Attribute | Verified Value | Notes |
| :--- | :--- | :--- |
| **Repository Root** | `c:\Krishi Vikas AI_ Antigravity` | Local absolute path |
| **Remote Origin** | `https://github.com/dev-samarpatil/Krishi-Vikas-AI.git` | Primary GitHub upstream |
| **Current Branch** | `main` | Production branch |
| **Latest Commit Hash** | `468c7c8` | Commit: *feat: implement high-reliability OSM tile fallback and robust coordinate validation for Sentinel Map* |
| **Parent Commit** | `5cae0b8` | Commit: *fix(chat): align chat request payload with backend ChatRequest schema and resolve backend 422* |
| **Submodules** | None | Unified monorepo containing frontend, backend, data, and docs |

---

## 2. Working Tree & Uncommitted State

The current working tree contains active, verified stabilization fixes that have restored the application to working order. These changes must be preserved and not discarded.

### Staged Changes
- `None` (0 staged files).

### Uncommitted Modified Files (Tracked)
1. `flutter_app/lib/screens/chat/chat_screen.dart`:
   - Replaced silent UI dead-ends with structured error message bubbles and interactive retry callbacks.
2. `flutter_app/lib/screens/map/sentinel_map_screen.dart`:
   - Migrated broken CartoDB tiles to OpenStreetMap standard tiles (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
   - Added legal OSM attribution widget.
   - Added `tileProvider: NetworkTileProvider()` and `errorTileCallback` with visual alert banner.
   - Clamped bounds to valid WGS84 coordinates (`[-90.0, 90.0]`, `[-180.0, 180.0]`).
3. `flutter_app/lib/models/scan_response_model.dart`:
   - Added `isInvalidImage` and `isHealthy` boolean getters.
   - Added structured `validationError` and `rawText` fields.
4. `flutter_app/lib/screens/scan/scan_result_screen.dart`:
   - Implemented truthful visual states:
     - Clear rejection card for non-crop images with explicit camera retake button.
     - Green healthy crop status banner when no disease is detected.
     - Standard disease card with treatment plan when pathology is identified.
5. `flutter_app/lib/screens/scan/scan_screen.dart`:
   - Handled non-crop image validation responses and network timeouts with informative user dialogs.
6. `flutter_app/test/widget_test.dart`:
   - Added comprehensive widget and unit tests covering scan model truthful states, OSM tile configuration, coordinate bounds validation, and chat retry handlers.

### Untracked Files & Artifacts
- `flutter_app/build/app/outputs/flutter-apk/app-release.apk` (63.8 MB release APK generated October 21, 2026).
- `backend/tests/test_vision_grounding.py` (unit and live integration tests for vision pipeline).
- `backend/tests/test_api_endpoints.py` (FastAPI router integration test suite).
- `documents/Krishi_Vikas_AI_Phase_0_Implementation_Plan.md` (initial working plan).
- `docs/architecture/` (Phase 0 architecture deliverables).

---

## 3. Sensitive Tracked File Check

A strict audit of Git tracking was performed to verify that no live `.env` files or secret keys were inadvertently committed to the repository history:
- `.gitignore` correctly ignores `.env`, `.env.*`, `*.pem`, `*.key`, `build/`, `.dart_tool/`, and `__pycache__/`.
- Local `.env` is present at repository root but **is correctly untracked by Git**.
- No service account private keys (`*.json`) are tracked in Git.

---

## 4. Preservation & Rollback Plan

To protect the current baseline while preparing for Phase 1:
1. **Safety Tagging / Branching:**
   Prior to implementing Phase 1 code, create a dedicated baseline branch:
   ```bash
   git checkout -b feat/phase-1-groq-migration
   ```
2. **Rollback Command:**
   If any regression occurs during Phase 1:
   ```bash
   git checkout main
   ```
   All verified working code on `main` remains untouched.
