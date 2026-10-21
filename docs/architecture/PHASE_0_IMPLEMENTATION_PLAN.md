# Krishi Vikas AI — Phase 0 Implementation Plan
## Baseline Audit, Working-State Freeze, and Integration Readiness

**Document:** `docs/architecture/PHASE_0_IMPLEMENTATION_PLAN.md`  
**Status:** Completed Baseline Execution  
**Project:** Krishi Vikas AI  
**Execution Mode:** Inspect → Verify → Document → Test → Report  

---

## 1. Executive Summary

Phase 0 establishes a verified, factual baseline of the existing working Krishi Vikas AI application before introducing Groq chatbot migration, RAG retrieval pipelines, crop intelligence, geospatial risk engines, or IoT/irrigation automation.

The primary objective of this phase is stabilization and protection:
1. Preserve all working-state fixes (specifically OpenStreetMap tile migration, truthful scan error states, and chat retry resilience).
2. Document every architectural layer, entry point, dependency, API contract, and data structure from the actual codebase.
3. Execute real baseline tests across frontend and backend, recording actual results without concealing failures or rate limits.
4. Prepare a risk-managed blueprint for Phase 1 without implementing any future phase functionality during Phase 0.

---

## 2. Scope Boundaries

### In-Scope (Completed in Phase 0)
- Git repository state, working tree preservation, and branch inventory.
- Complete inventory of frontend (Flutter/Dart) and backend (FastAPI/Python) dependencies.
- Request-flow tracing for AI Chat, Crop Scan, Sentinel Map, My Farm, Weather, Mandi, and Schemes.
- Complete API contract inventory of all 10 FastAPI routers.
- AI provider inventory covering Gemini 2.5 Flash, Groq fallback, Roboflow fallback, and local models.
- Database, RLS, and Supabase Storage audit from migrations and runtime clients.
- Environment variable and secret audit (documenting variable names and components, zero secret exposure).
- Deployment readiness audit covering Render Procfile, CORS, Uvicorn, and production endpoints.
- Execution of baseline tests (`pytest` and `flutter test`) with verified results.
- Evidence-based feature status matrix and prioritized risk register.
- Phase 1 Groq readiness specification.

### Out-of-Scope (Strictly Enforced)
- No Groq migration implementation.
- No RAG or vector database integration.
- No ESP32 or irrigation hardware code.
- No schema alterations or destructive database changes.
- No modification of working dependencies or unnecessary upgrades.

---

## 3. Execution Sequence & Methodology

The Phase 0 execution followed a strict 13-step sequence:
1. **Repository & Git Inspection:** Verified branch `main`, commit `468c7c8`, and preserved working uncommitted files in Flutter.
2. **Project Structure & Dependency Audit:** Cataloged Flutter `pubspec.yaml` (Flutter 3.44.1, Dart 3.12.1) and Python dependencies (`requirements.txt`, Python 3.14.3, FastAPI 0.135.3).
3. **Request Lifecycle Tracing:** Traced Chat, Crop Scan, Sentinel Map, and My Farm from UI touchpoint to external APIs and response rendering.
4. **API Contract Inventory:** Enumerated all endpoints across `/diagnose`, `/chat`, `/weather`, `/market`, `/schemes`, `/farm`, `/alerts`, `/voice`.
5. **AI Provider & Fallback Audit:** Analyzed Gemini 2.5 Flash, Groq fallback, Roboflow, and mock/fallback traps.
6. **Supabase & Data Security Audit:** Inspected `20260603000000_init_schema.sql` (8 tables, RLS policies, `crop-images` bucket).
7. **Environment Configuration Audit:** Audited all 13 environment variables across backend and client.
8. **Deployment Readiness Audit:** Inspected Render `Procfile`, Uvicorn startup, and CORS settings.
9. **Baseline Testing:** Ran `flutter test` (7/7 PASSED) and `pytest -v` (16 PASSED, 1 FAILED due to Gemini Free-Tier 429 quota exhaustion).
10. **Feature Status Matrix:** Formulated an evidence-based status for all 10 application modules.
11. **Risk Register:** Built a scored risk matrix with concrete mitigations.
12. **Phase 1 Groq Readiness:** Defined precise architectural plan for migrating Chatbot text generation to Groq.
13. **Final Report Generation:** Generated formal deliverables in `docs/architecture/`.
