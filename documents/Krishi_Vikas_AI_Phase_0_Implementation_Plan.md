# Krishi Vikas AI — Phase 0 Implementation Plan
## Baseline Audit, Working-State Freeze, and Integration Readiness

**Document type:** Engineering implementation plan  
**Phase:** 0 — Baseline and Readiness  
**Status:** Planned  
**Primary objective:** Establish a verified, reproducible baseline of the existing working Krishi Vikas AI application before introducing Groq, RAG, crop-intelligence, geospatial-risk, or irrigation upgrades.  
**Execution environment:** Existing project repository and its current development/deployment setup  
**Audience:** Developer, coding agent, reviewer, and project maintainer

---

## 1. Executive Summary

Phase 0 is a controlled audit and stabilization phase. It is not a feature-development phase. Its purpose is to establish exactly what currently exists, what is genuinely working, how the Flutter frontend communicates with the FastAPI backend, which services are used by each module, what data structures already exist, and which tests can be run reliably.

The output must be an evidence-based baseline that later implementation phases can safely build upon. Phase 0 must prevent accidental regressions, avoid duplicate infrastructure, and distinguish verified implementation from assumptions or planned functionality.

### Phase 0 outcomes

By the end of this phase, the team should have:

1. A preserved working Git state and a documented integration branch strategy.
2. A repository and dependency inventory.
3. A verified frontend-to-backend request-flow map.
4. A module-by-module inventory of existing features and AI providers.
5. A documented API contract inventory.
6. A database, storage, and security configuration inventory.
7. A deployment and environment-variable inventory without exposing secrets.
8. A baseline test report with actual results.
9. A list of confirmed defects, risks, technical debt, and unknowns.
10. A prioritized implementation-readiness report for Phase 1 (Groq migration).

**Phase 0 must not migrate the chatbot to Groq, introduce RAG, alter the database schema, or implement irrigation.** Those changes belong to later phases unless a minimal corrective action is essential to restore the existing baseline and is separately documented.

---

## 2. Product and Architecture Context

Krishi Vikas AI is an existing agricultural application. The current application has been restored to a working state after prior chatbot and map issues. The codebase has previously been discussed as containing:

- Flutter mobile frontend.
- Python FastAPI backend running with Uvicorn.
- Google Gemini integration in at least some AI workflows.
- Supabase integration for database and/or storage.
- Backend deployment previously hosted on Render.
- Source control through GitHub.
- Home dashboard.
- Sentinel Map.
- Crop Scan.
- AI Chat.
- My Farm.
- Structured agricultural data, including scheme, mandi-price, and KVK-related data in prior project discussions.

These are **historical context, not proof of the current code state**. The implementation team must verify each item from the actual repository, deployment configuration, and available tests. Do not assume that a module, endpoint, service, or integration remains present or functional merely because it was previously discussed.

### Future direction (context only)

The later roadmap is expected to consider:

1. Moving chatbot text generation from Gemini to Groq.
2. Adding agricultural Retrieval-Augmented Generation (RAG).
3. Connecting crop-scan results to retrieved agricultural knowledge.
4. Improving farm-specific context and shared data contracts.
5. Connecting Sentinel Map to validated geospatial risk data.
6. Developing a deterministic irrigation decision engine.
7. Integrating ESP32 sensors and pump controls with independent safety checks.
8. Recording and verifying farm interventions and outcomes.

Phase 0 only determines the current starting point and prepares for safe implementation.

---

## 3. Scope

### 3.1 Included

- Git status and repository-state inspection.
- Preservation of uncommitted user work.
- Branch and rollback planning.
- Repository structure inventory.
- Frontend and backend entry-point identification.
- Dependency and runtime-version inventory.
- Configuration and environment-variable inventory.
- API endpoint and request/response contract inventory.
- AI-provider usage mapping.
- Supabase schema and storage inventory, where access exists.
- Authentication, authorization, and RLS review at a configuration level.
- Render/deployment configuration review, where files or access exist.
- Baseline test execution.
- Local run and health-check verification where possible.
- Chat, Scan, Map, and My Farm request-flow investigation.
- Identification of mocks, fallbacks, hardcoded sample responses, and demo data.
- Documentation of known failures and unknowns.
- Phase 1 readiness assessment.

### 3.2 Explicitly excluded

Do not perform the following during Phase 0:

- Migrate Gemini chatbot calls to Groq.
- Add RAG or a new vector database.
- Add or replace embedding models.
- Redesign the Flutter UI.
- Rewrite the backend architecture.
- Replace the map library or tile provider without a separate approved fix.
- Change production database schema.
- Delete, rename, or restructure existing database tables.
- Rebuild Crop Scan or replace its vision provider.
- Implement irrigation decisions or hardware control.
- Add ESP32 communication protocols.
- Change authentication or weaken access controls.
- Perform destructive Git operations.
- Deploy unreviewed changes to production.
- Replace real services with mocks in production code.
- Claim any feature is working without evidence.

If a critical issue prevents even the baseline from running, record it and make only the smallest necessary, reversible correction. Document the original behavior, the reason for the correction, the files changed, and the tests run. Do not use this exception as permission for feature work.

---

## 4. Operating Principles and Safety Rules

1. **Inspect before editing.** Never assume file names, routes, schemas, package versions, or environment-variable names.
2. **Preserve the working state.** Do not discard, overwrite, stash destructively, or reset uncommitted user changes.
3. **Evidence over assumptions.** Mark every finding as Verified, Partially Verified, Not Verified, or Blocked.
4. **No secrets in documentation.** Record environment-variable names and whether they are configured, but never record secret values.
5. **No accidental production changes.** Do not run schema-changing commands or deploy changes without explicit scope and authorization.
6. **No invented test results.** Every test must be marked PASSED, FAILED, NOT RUN, or BLOCKED, with command and evidence where possible.
7. **Mocks are not live verification.** Mocked tests establish contract behavior, not external-service availability.
8. **Local is not production.** A local success does not prove the deployed service works.
9. **Keep scope narrow.** Phase 0 documents and verifies; later phases implement new capabilities.
10. **Respect privacy.** Do not export private user data or production records merely to inspect schema.
11. **Do not print credentials.** Avoid shell commands or diagnostics that reveal secret values.
12. **Do not silently suppress errors.** Preserve useful diagnostic information while redacting secrets and personal data.
13. **Protect agricultural truthfulness.** Distinguish actual observations, synthetic/demo records, predictions, and unknown information.
14. **Keep a rollback path.** Any required change must be small, reviewed, and reversible.
15. **Do not use an AI provider name as proof of capability.** Verify the actual call path and model configuration.

---

## 5. Phase 0 Work Breakdown

## Workstream 0.1 — Repository and Git-State Audit

### Objectives

- Establish which repository and branch are being modified.
- Identify uncommitted changes before any action.
- Protect the current working application.
- Establish a safe integration workflow.

### Tasks

1. Confirm repository root and project identity.
2. Inspect `git status --short --branch`.
3. Inspect current branch and recent commit history.
4. Identify modified, staged, untracked, ignored, and generated files.
5. Identify submodules or nested repositories if present.
6. Inspect `.gitignore` for secrets, build outputs, caches, and local configuration.
7. Confirm whether frontend and backend are in one repository or separate repositories.
8. Identify the latest known working commit if it can be established from evidence.
9. Record whether the working tree is clean.
10. Propose a feature branch such as `chore/phase-0-baseline` or `feature/krishi-integration`, following existing repository conventions.
11. Create a branch only if it will not interfere with the current work and the environment permits it.
12. Do not commit, reset, clean, rebase, or force-push without explicit authorization.

### Required evidence

- Repository root.
- Current branch.
- Working-tree status.
- Latest relevant commit identifier.
- Presence of uncommitted work.
- Branch/rollback recommendation.
- Any suspicious tracked secret or configuration file (describe the file, never print the secret).

### Acceptance criteria

- The original working state is preserved.
- No user changes are lost.
- The team knows which branch is the baseline.
- Any branch creation or other Git mutation is documented.

---

## Workstream 0.2 — Repository Structure and Entry Points

### Objectives

Understand how the project is organized and identify the real entry points.

### Tasks

1. List top-level directories and important source files.
2. Identify the Flutter entry point, normally but not necessarily `lib/main.dart`.
3. Identify routing/navigation definitions.
4. Identify API-client and network-service abstractions.
5. Identify FastAPI application initialization and router registration.
6. Identify Uvicorn start configuration.
7. Identify configuration/settings modules.
8. Identify data files, migrations, schemas, and seed/demo data.
9. Identify tests, scripts, CI configuration, Docker files, and deployment manifests.
10. Identify generated files and exclude them from architectural conclusions unless relevant.
11. Determine whether frontend and backend are deployed independently.

### Deliverable

`docs/architecture/PHASE_0_REPOSITORY_INVENTORY.md`

The inventory should list important paths and explain their roles. Avoid dumping the entire directory tree or including build caches.

### Acceptance criteria

- Frontend entry point is verified.
- Backend entry point is verified.
- API-client layer is located.
- Route registration and configuration sources are located.
- Test and deployment configuration locations are known.

---

## Workstream 0.3 — Runtime and Dependency Inventory

### Objectives

Record actual versions and determine whether the project is reproducible.

### Flutter checks

Inspect:

- `pubspec.yaml`
- `pubspec.lock`
- Flutter and Dart versions.
- HTTP/networking libraries.
- Map package and version.
- Image-picker/camera packages.
- State-management approach.
- Serialization packages.
- Supabase packages, if used.
- Test dependencies.

Run applicable commands where available:

```bash
flutter --version
dart --version
flutter pub get
flutter analyze
flutter test
```

Do not run `flutter pub upgrade` as part of baseline auditing. It may introduce unrelated dependency changes. `flutter pub get` should respect the existing lockfile; if it changes the lockfile unexpectedly, inspect and document the change.

### Python/backend checks

Inspect:

- `requirements.txt`, `pyproject.toml`, lockfiles, or equivalent.
- Python version constraints.
- FastAPI and Uvicorn versions.
- Pydantic version.
- Gemini SDK/package and usage sites.
- Supabase SDK/package, if used.
- HTTP client library and timeout configuration.
- Image-processing packages.
- Test dependencies.
- Docker and Render build/start configuration.

Run only commands compatible with the repository's setup, for example:

```bash
python --version
python -m pip check
pytest
```

Use the project's documented environment and test commands where they differ. Do not install or upgrade packages globally. Prefer the existing virtual environment or a project-specific isolated environment.

### Required output

A dependency table containing:

- Component.
- Declared version/constraint.
- Locked or installed version, if verified.
- Where it is used.
- Known compatibility concern.
- Evidence status.

### Acceptance criteria

- Runtime versions are recorded.
- Dependency manifests and lockfiles are identified.
- Existing dependency conflicts are documented.
- No broad dependency upgrade has occurred.

---

## Workstream 0.4 — Frontend-to-Backend Request-Flow Audit

### Objectives

Trace the real request lifecycle for each critical module.

### Required flows

#### Chat

Trace:

`Flutter input → chat state/controller → API client → configured base URL → FastAPI route → provider/client → response/error parsing → Flutter rendering`

Determine:

- The actual endpoint and HTTP method.
- Request JSON fields and headers.
- Authentication requirements.
- Base URL source for development and production.
- Timeout and retry behavior.
- Response parsing rules.
- Error mapping and user-visible fallback messages.
- Whether the current implementation calls Gemini directly or through a service abstraction.
- Whether any fallback response can be mistaken for a genuine answer.

#### Crop Scan

Trace:

`Image selection/capture → validation → upload/request serialization → FastAPI endpoint → actual image bytes → vision provider/model → response validation → UI result → persistence/history`

Determine:

- Whether image bytes reach the backend.
- Whether the image is passed to the actual vision inference call.
- Whether a mock, hardcoded response, or fallback is used in production paths.
- Whether model failures can appear as successful diagnoses.
- Whether results are persisted and under what conditions.

#### Sentinel Map

Trace:

`Map screen → tile configuration/provider → tile requests → overlay data source → API/backend or local dataset → coordinate parsing → marker rendering`

Determine:

- Map package/provider and exact tile URL configuration.
- API-key or authorization requirements.
- Attribution configuration.
- How markers are obtained.
- Whether the base map and overlay data use separate sources.
- Whether observations and predictions are distinguished.
- Whether sample/demo data is clearly identified.
- Whether the last reported blank-map issue is currently reproduced or has been verified fixed.

Do not change the provider during this audit unless a minimal, explicitly documented correction is required to restore baseline operation.

#### My Farm

Trace:

`Screen → state/data service → backend/database → data mapping → soil-health indicator and history`

Determine whether the indicator is computed from actual stored readings, derived by a rule, or displayed as a static/default value.

#### Other modules

Inventory Home, government schemes, mandi prices, weather, alerts, voice features, and any other existing routes or screens found in the repository. Do not assume historical module lists are complete.

### Deliverable

`docs/architecture/PHASE_0_REQUEST_FLOWS.md`

For each flow, include a concise sequence diagram or numbered path, source files, endpoint(s), data contracts, external dependencies, error paths, and verification status.

### Acceptance criteria

- Critical flows have identifiable source files and endpoints.
- Frontend/backend contract mismatches are recorded.
- Actual provider calls are distinguished from mocks and fallbacks.
- Unknown or inaccessible parts are explicitly marked.

---

## Workstream 0.5 — API Contract Inventory

### Objectives

Create a reference for existing endpoints before changing any integration.

### Tasks

1. Enumerate FastAPI routes from the actual application and router registrations.
2. Record HTTP method, path, purpose, request model, response model, and authentication requirement.
3. Record expected status codes and known error formats.
4. Identify routes used by Flutter.
5. Identify routes that appear unused, duplicate, or legacy, without deleting them.
6. Inspect OpenAPI generation if available.
7. Compare Flutter request/response parsing with backend models.
8. Record provider-specific logic that is coupled directly to endpoint handlers.
9. Identify potential backward-compatibility risks for future Groq/RAG work.

### Deliverable

`docs/architecture/PHASE_0_API_CONTRACTS.md`

### Suggested table

| Method | Route | Consumer | Request model | Response model | Auth | Status |
|---|---|---|---|---|---|---|
| Actual value | Actual value | Flutter/service | Actual model | Actual model | Verified/unknown | Verified/unknown |

Do not invent endpoints or use the table above as a claim about existing routes.

### Acceptance criteria

- Actual routes are inventoried.
- Chat and Scan contracts are documented precisely.
- Contract mismatches and error-shape inconsistencies are identified.
- No endpoint is removed or renamed in Phase 0.

---

## Workstream 0.6 — AI Provider and Fallback Audit

### Objectives

Identify exactly which provider powers each AI capability and isolate future migration scope.

### Tasks

Search actual code and configuration for:

- Gemini SDK imports and client initialization.
- Model identifiers and generation calls.
- Image/multimodal calls.
- Embedding generation.
- Any other model/provider SDKs.
- Prompt templates and system instructions.
- Provider-specific response parsing.
- Retry/timeout behavior.
- Fallback responses and mock services.
- Model configuration and environment-variable names.

Build a provider map:

| Capability | Current provider | Actual call site | Input type | Output consumer | Fallback behavior | Verified? |
|---|---|---|---|---|---|---|
| Chat | Inspect | Inspect | Text/context | Flutter | Inspect | Status |
| Crop Scan | Inspect | Inspect | Image/text | Flutter | Inspect | Status |
| Embeddings | Inspect | Inspect | Text | Search system | Inspect | Status |
| Other AI | Inspect | Inspect | Inspect | Inspect | Inspect | Status |

### Specific checks

- Determine whether the chatbot uses Gemini directly or a reusable service abstraction.
- Determine whether the same Gemini client is used by Scan or other features.
- Identify provider coupling in route handlers and business logic.
- Confirm how model names are configured.
- Identify hardcoded model identifiers that may be unavailable.
- Check whether fallback text or sample predictions can be mistaken for successful inference.
- Confirm whether logs expose secrets, user content, or private images.

### Acceptance criteria

- Provider dependencies are mapped per feature.
- Groq migration scope can be isolated to chat where feasible.
- Crop Scan provider is not accidentally changed during chatbot migration.
- Existing fallback paths are documented.

---

## Workstream 0.7 — Supabase, Data Model, and Security Audit

### Objectives

Understand existing data structures and avoid creating duplicate or unsafe schema changes later.

### Tasks

1. Inspect schema migrations and SQL files in the repository.
2. Inventory known tables, views, functions, and storage buckets from available project files or authorized read-only access.
3. Record the purpose of each relevant object.
4. Inspect relationships and key fields.
5. Determine how users and farms are associated.
6. Inspect RLS policies and storage policies where available.
7. Determine whether scan history, farm profiles, sensor readings, or irrigation records already exist.
8. Identify existing vector extensions or embedding columns, if any.
9. Identify structured agricultural JSON files and their loading path.
10. Record whether data is real, synthetic, sample, or unknown.
11. Review data retention and logging risks at a high level.
12. Do not query or export production personal data unless strictly necessary and authorized.

### Future data categories to map (do not create them in Phase 0)

- Farms and crop cycles.
- Scan results.
- Sensor readings.
- Risk assessments.
- Irrigation configurations/events.
- Agricultural knowledge documents and chunks.
- Document source metadata and freshness.
- Farm observations and intervention outcomes.

### Deliverable

`docs/architecture/PHASE_0_DATA_AND_SECURITY_INVENTORY.md`

### Acceptance criteria

- Existing schema and storage are documented to the extent accessible.
- Existing tables are distinguished from proposed future tables.
- RLS/authentication gaps are recorded without weakening controls.
- No schema mutation occurs during the audit.

---

## Workstream 0.8 — Configuration and Secret-Handling Audit

### Objectives

Understand configuration without exposing credentials.

### Tasks

1. Identify environment-variable names referenced by frontend and backend.
2. Identify development, test, and production configuration mechanisms.
3. Identify where the API base URL is selected.
4. Identify configuration for Gemini, Supabase, Render, map provider, and any other external service actually used.
5. Check for hardcoded credentials, private keys, tokens, or secrets in tracked files.
6. Inspect `.gitignore` and example environment files.
7. Ensure documentation uses placeholders, never real values.
8. Record whether each required variable is documented and whether its presence can be verified without printing its value.
9. Identify variables required for local versus production execution.
10. Do not rotate credentials or modify production settings as part of this audit unless an actual exposed secret requires immediate incident handling under an authorized process.

### Deliverable

`docs/architecture/PHASE_0_CONFIGURATION_INVENTORY.md`

### Required format

| Variable name | Used by | Required in | Documented? | Presence verified? | Secret? |
|---|---|---|---|---|---|
| Actual variable name | Component | Local/production/both | Yes/No | Yes/No/Unknown | Yes/No |

Never include secret values in this table.

### Acceptance criteria

- Configuration sources are known.
- Secret values are not copied into documentation or logs.
- Hardcoded-secret concerns are documented safely.
- Production and local base URLs are distinguishable.

---

## Workstream 0.9 — Deployment and Operations Audit

### Objectives

Establish what is deployed and what can be verified.

### Backend / Render checks

Inspect available files and authorized service information for:

- Build command.
- Start command.
- Runtime/Python version.
- Dependency installation.
- Health endpoint.
- Environment-variable requirements.
- Port binding and Uvicorn configuration.
- Logs and error visibility.
- Timeout and request-size configuration.
- Deployment branch and commit, if available.
- Current deployed revision and service health, if access exists.

### Frontend checks

Inspect:

- API base URL configuration.
- Android internet permission and network settings.
- iOS network configuration if relevant.
- Build flavors or environment selection.
- Release-mode configuration.
- Map-provider configuration.
- Whether local development URLs can leak into production builds.

### Operational constraints

- Do not print secret environment values.
- Do not trigger a production deployment merely to test configuration.
- Do not claim a live service is healthy unless a live check was executed.
- If access is unavailable, mark the check BLOCKED or NOT RUN.
- Record any discrepancy between local and deployed configuration.

### Deliverable

`docs/architecture/PHASE_0_DEPLOYMENT_READINESS.md`

---

## Workstream 0.10 — Baseline Testing and Reproducibility

### Objectives

Determine what passes before feature work begins.

### Test categories

#### Backend

- Import/application startup check.
- Existing unit tests.
- Existing API/route tests.
- Pydantic/request validation tests.
- Chat endpoint contract tests.
- Scan endpoint contract tests.
- Database-related tests that can run safely.
- Lint/type checks if configured.

#### Flutter

- Dependency resolution.
- Static analysis.
- Existing unit/widget tests.
- API-client tests if present.
- Chat and Scan state/response parsing tests if present.
- Map widget tests if present.
- Build check only if the required toolchain and target are available.

#### Integration

Where credentials and access allow, verify:

- Backend health endpoint.
- Flutter-to-backend connectivity.
- Chat API contract with a controlled request.
- Scan API contract with a suitable test image.
- Supabase connectivity through a safe read-only operation.
- Actual map tile loading and on-device rendering.
- Deployment health.

### Commands

Use repository-specific commands if they exist. Typical commands include:

```bash
# Flutter
flutter pub get
flutter analyze
flutter test

# Python backend
python --version
python -m pip check
pytest
```

Do not assume these commands are sufficient for every repository. Inspect README, CI configuration, and project scripts first.

### Test result rules

Every test must have one of these statuses:

- **PASSED:** Executed and met its expected result.
- **FAILED:** Executed and did not meet its expected result.
- **NOT RUN:** Not executed.
- **BLOCKED:** Could not run because of a missing tool, dependency, credential, access permission, or environment.
- **REQUIRES LIVE SERVICE:** Cannot be fully established with a mock.
- **REQUIRES PHYSICAL DEVICE:** Requires actual mobile/hardware verification.

A test may need both a status and a note. For example, a mocked provider test can be PASSED while real provider availability remains REQUIRES LIVE SERVICE.

### Required baseline report

Record:

- Command/test name.
- Environment.
- Start time or run identifier when available.
- Result.
- Failure summary.
- Whether failure predates any changes.
- Next action.

Do not make unrelated fixes solely to achieve a green test suite. Record pre-existing failures and decide whether they block the next phase.

---

## Workstream 0.11 — Current Feature Status Verification

### Objectives

Produce a factual status report for each existing application module.

### Status definitions

- **Verified working:** Relevant code path was exercised and passed a suitable test.
- **Partially verified:** Some behavior was tested, but the full workflow was not.
- **Implemented, unverified:** Code exists, but its runtime behavior was not established.
- **Broken:** A reproducible failure exists.
- **Mock/demo only:** The path intentionally uses sample or simulated results.
- **Not implemented:** No relevant implementation was found.
- **Unknown/blocked:** Insufficient evidence or access.

### Module inventory

Audit the actual modules found in the repository, including as applicable:

- Home dashboard.
- Sentinel Map.
- Crop Scan.
- AI Chat.
- My Farm and soil-health indicator.
- Mandi prices.
- Government schemes.
- Weather/climate.
- Alerts.
- Voice features.
- Authentication/profile.
- Scan history.
- Other modules discovered in the code.

For each module, document:

- Frontend entry point.
- Backend route/service.
- External dependencies.
- Data source.
- Error behavior.
- Existing tests.
- Verified status.
- Known issue.
- Follow-up action.

### Acceptance criteria

- No module is labelled fully functional based solely on UI presence.
- Mocked, synthetic, and real data are distinguished.
- Previously reported map/chat/scan issues are rechecked if the necessary environment is available.

---

## Workstream 0.12 — Risk Register and Phase 1 Readiness

### Objectives

Convert findings into a controlled next-step plan.

### Risk categories

- API contract mismatch.
- Provider coupling.
- Missing/incorrect environment variables.
- Deployment drift.
- Dependency incompatibility.
- Lack of regression tests.
- Mock/fallback paths that mimic success.
- RLS or authorization uncertainty.
- Missing farm data contracts.
- Existing vector infrastructure unknown.
- Poor source quality or stale agricultural documents.
- Unverified multilingual behavior.
- Map provider dependence.
- IoT security and safety requirements.
- Incomplete error observability.

### Risk scoring

Use a simple scale:

- Severity: 1 (low) to 5 (critical).
- Likelihood: 1 (unlikely) to 5 (very likely).
- Priority score: Severity × Likelihood.

Include mitigation and owner/next action. Do not use scores to conceal critical safety or security issues; a critical issue may require action regardless of numeric score.

### Phase 1 readiness checklist

Before migrating the chatbot to Groq, confirm:

- [ ] Chat route and API contract are known.
- [ ] The current Gemini call site is identified.
- [ ] Chat and Scan provider dependencies are separated or their coupling is understood.
- [ ] Environment-variable conventions are documented.
- [ ] Existing tests can validate chat request/response behavior.
- [ ] Existing error handling is understood.
- [ ] Frontend compatibility constraints are documented.
- [ ] Deployment process and required configuration are known.
- [ ] Rollback approach is documented.
- [ ] No unresolved critical issue makes the migration unsafe.

If any item is not met, identify the smallest prerequisite task rather than proceeding blindly.

---

## 6. Required Documentation Deliverables

Create or update the following documentation. Adapt directory structure to the repository's existing conventions rather than duplicating an established docs hierarchy.

1. `docs/architecture/PHASE_0_IMPLEMENTATION_PLAN.md` — This plan.
2. `docs/architecture/PHASE_0_REPOSITORY_INVENTORY.md`
3. `docs/architecture/PHASE_0_REQUEST_FLOWS.md`
4. `docs/architecture/PHASE_0_API_CONTRACTS.md`
5. `docs/architecture/PHASE_0_DATA_AND_SECURITY_INVENTORY.md`
6. `docs/architecture/PHASE_0_CONFIGURATION_INVENTORY.md`
7. `docs/architecture/PHASE_0_DEPLOYMENT_READINESS.md`
8. `docs/architecture/PHASE_0_BASELINE_TEST_REPORT.md`
9. `docs/architecture/PHASE_0_FEATURE_STATUS.md`
10. `docs/architecture/PHASE_0_RISK_REGISTER.md`
11. `docs/architecture/PHASE_0_COMPLETION_REPORT.md`

Avoid creating redundant documents if equivalent, current documentation already exists. Update existing documents when appropriate and record the mapping.

Do not put API secrets, user tokens, private personal data, or raw production records in documentation.

---

## 7. Suggested Execution Sequence

Execute work in this order to minimize risk:

### Step 1 — Read-only inspection

- Inspect repository and Git state.
- Read project instructions, README files, manifests, and deployment configuration.
- Identify entry points and critical request flows.
- Do not edit source files.

### Step 2 — Environment and dependency inventory

- Record runtime versions.
- Inspect dependencies and lockfiles.
- Identify test commands.
- Note missing local tools or credentials.

### Step 3 — Contract and provider audit

- Inventory routes and request/response models.
- Trace Chat, Scan, Map, and My Farm.
- Map provider usage and fallback behavior.

### Step 4 — Data/security/configuration audit

- Inspect schema/migrations and RLS configuration where accessible.
- Inventory environment variables without reading their values into logs.
- Review deployment configuration.

### Step 5 — Baseline test execution

- Run existing backend tests.
- Run existing Flutter analysis and tests.
- Run safe integration checks where available.
- Record all failures and limitations.

### Step 6 — Documentation

- Produce the required inventories.
- Record verified facts and unknowns.
- Prepare the risk register.

### Step 7 — Readiness review

- Assess Phase 1 prerequisites.
- Identify blockers.
- Recommend the smallest necessary prerequisite corrections.
- Do not begin Groq migration in Phase 0.

---

## 8. Definition of Done

Phase 0 is complete only when all applicable items below are satisfied.

### Repository protection

- [ ] Current repository and branch are identified.
- [ ] Existing uncommitted work is preserved.
- [ ] Rollback approach is documented.
- [ ] No destructive Git operation was performed.

### Architecture understanding

- [ ] Frontend and backend entry points are identified.
- [ ] Critical request flows are documented.
- [ ] Actual API contracts are inventoried.
- [ ] Provider usage is mapped by feature.
- [ ] Existing mocks and fallback paths are documented.

### Data and configuration

- [ ] Existing database/storage structures are documented to the available level.
- [ ] Security and authorization configuration is reviewed.
- [ ] Environment-variable names are inventoried without exposing values.
- [ ] Deployment configuration is reviewed.
- [ ] No unintended schema or production configuration changes occurred.

### Testing

- [ ] Available backend tests were executed.
- [ ] Available Flutter analysis/tests were executed.
- [ ] Results and failures are recorded accurately.
- [ ] Live-service and device-dependent checks are distinguished from mocks.
- [ ] Existing failures are identified as pre-existing where evidence supports that conclusion.

### Documentation and handoff

- [ ] Required documents exist or their existing equivalents are identified.
- [ ] Feature statuses are evidence-based.
- [ ] Risk register is complete.
- [ ] Phase 1 readiness checklist is completed.
- [ ] Remaining unknowns and blockers are explicit.
- [ ] No Groq migration or RAG implementation was mixed into Phase 0.

A green test suite is desirable, but Phase 0 must not conceal pre-existing failures or expand into uncontrolled refactoring. If a check is blocked, document it and determine whether it blocks Phase 1.

---

## 9. Final Handoff Format

At the end of Phase 0, provide a concise engineering report with these sections:

### A. Baseline summary
- Repository and branch.
- Working-tree status.
- Verified frontend/backend stack.
- Verified deployment arrangement.

### B. Feature status
- Chat.
- Scan.
- Sentinel Map.
- My Farm.
- Other existing modules.

### C. Provider inventory
- Which services use Gemini.
- Whether chat and Scan share provider code.
- Existing embedding/vector-search implementation, if any.
- Other external services.

### D. API and data contracts
- Chat endpoint and schemas.
- Scan endpoint and schemas.
- Relevant farm-data tables.
- Authentication and authorization constraints.

### E. Test report
- Commands executed.
- Passed/failed/blocked/not-run results.
- Pre-existing failures.
- Live/device tests still required.

### F. Risks and blockers
- Critical/high risks first.
- Evidence.
- Mitigation.
- Owner/next action.

### G. Phase 1 recommendation
- Exact files likely to change for Groq.
- Required configuration additions.
- Tests to add or update.
- Rollback plan.
- Any prerequisites that must be resolved first.

### H. Explicit completion statement
Choose one:
- `PHASE 0 COMPLETE`
- `PHASE 0 COMPLETE WITH DOCUMENTED BLOCKERS`
- `PHASE 0 INCOMPLETE`

Explain why. Never claim completion if critical checks were skipped or if the required evidence is missing.

---

## 10. Final Instruction to the Implementing Agent

Begin with read-only repository inspection. Follow the existing project conventions. Preserve the working application. Verify actual code paths instead of guessing from old discussions. Produce evidence-based documentation, run available baseline tests, and prepare a precise Phase 1 Groq migration plan.

Do not implement Groq, RAG, new database tables, crop-intelligence upgrades, map redesign, or irrigation control in this phase.

The purpose of Phase 0 is to establish a trustworthy baseline so subsequent work can be implemented safely, incrementally, and with measurable verification.
