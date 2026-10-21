# Krishi Vikas AI — Phase 1 Implementation Plan
## Chat Provider Migration to Groq (Text Chat Only)

**Document type:** Implementation specification  
**Phase:** 1  
**Status:** Ready for repository-aware execution after Phase 0 review  
**Primary objective:** Migrate the existing agricultural chatbot's text-generation provider to Groq while preserving the current Flutter UI, backend API contract, authentication, and all unrelated application features.

---

## 1. Executive Summary

Phase 1 replaces the current provider used by the **text-chat workflow only** with Groq. The migration must be based on the real repository findings recorded during Phase 0—not assumptions about the existing implementation.

The work must be narrowly scoped, reversible, tested, and documented. The existing chat experience should continue to work through the same frontend-to-backend flow wherever possible. Crop image inference, crop-scan models, map rendering, farm records, mandi prices, government schemes, weather, voice workflows, and irrigation are explicitly out of scope unless a minimal compatibility change is strictly required and approved.

**Core rule:** Groq is a text-generation provider, not a crop-image classifier, geospatial renderer, sensor controller, or source of guaranteed agricultural truth. Do not route crop images to Groq as though it were a vision model unless the current selected Groq model's documented capabilities explicitly support the exact use case and the project owner separately approves that design. Phase 1 does not include that change.

### Required outcome

- The existing chat route and response contract remain compatible with the Flutter client, unless Phase 0 proves a contract change is unavoidable. Any unavoidable change must be backward-compatible and documented.
- Backend chat generation uses Groq through a server-side API key.
- No Groq secret is embedded in Flutter code, mobile assets, Git history, logs, or client-delivered configuration.
- Chat errors are handled safely and observably; provider failures are not disguised as successful AI answers.
- Tests demonstrate provider configuration, request construction, response parsing, timeout handling, malformed responses, rate limiting, and fallback/error behavior.
- Crop Scan and all other features remain unchanged.
- Rollback to the prior provider can be performed through configuration or a small, documented code revert.

---

## 2. Phase 1 Scope

### 2.1 In scope

1. Read and follow repository instructions, architecture, and Phase 0 findings.
2. Locate the actual chat endpoint, service, provider client, Flutter call site, DTOs/schemas, and tests.
3. Add a backend-only Groq provider integration using the repository's existing language/framework and dependency conventions.
4. Keep the public chat API contract stable.
5. Add environment-based configuration and validation.
6. Add safe request timeouts, bounded retries where appropriate, and clear error mapping.
7. Preserve existing chat prompt behavior and language handling where feasible.
8. Add unit/integration tests with mocked HTTP/provider responses.
9. Update `.env.example` or the project's equivalent with variable names only.
10. Add documentation, rollout/rollback steps, and a Phase 1 completion report.
11. Run relevant tests and regression tests for affected features.

### 2.2 Explicitly out of scope

Do **not** implement in Phase 1:

- RAG, vector search, embeddings, document ingestion, knowledge-base construction, or source-grounding pipelines.
- Crop-image model changes, image classification, disease detection changes, or image upload redesign.
- Sentinel Map redesign, geospatial scoring, marker changes, map tile/API-key work, or hotspot prediction.
- Soil-health algorithm changes, farm-data schema migrations, or dashboard redesign.
- Automated irrigation, pump control, ESP32 firmware, sensor integration, or hardware actions.
- Mandi-price, scheme, weather, notifications, or voice-feature redesign.
- Supabase schema migrations unless Phase 0 identifies a strictly necessary, approved blocker.
- Frontend redesign, new chat UI features, or unrelated refactoring.
- Switching the whole application from Gemini to Groq. Only the text-chat generation path is targeted.
- Claiming that Groq's answer is verified agricultural advice. RAG and source citations belong to a later phase.
- Production deployment or secret rotation without explicit authorization and a reviewed rollout plan.

If a necessary change crosses an excluded boundary, stop and document the dependency rather than expanding scope silently.

---

## 3. Inputs and Preconditions

Before editing code, inspect and reconcile the following Phase 0 artifacts where present:

- `PHASE_0_COMPLETION_REPORT.md`
- `PHASE_0_REQUEST_FLOWS.md`
- `PHASE_0_API_CONTRACTS.md`
- `PHASE_0_AI_PROVIDER_INVENTORY.md`
- `PHASE_0_CONFIGURATION_INVENTORY.md`
- `PHASE_0_BASELINE_TEST_REPORT.md`
- `PHASE_0_FEATURE_STATUS.md`
- `PHASE_0_RISK_REGISTER.md`
- `PHASE_0_PHASE_1_READINESS.md`

The exact path may differ; locate the actual files instead of creating duplicates blindly.

### Preconditions

Phase 1 should begin only after:

- The actual chat call path is identified end to end.
- It is known whether Chat and Crop Scan share a provider client, prompt service, or configuration.
- Existing API request and response shapes are recorded.
- Baseline tests and known failures are documented.
- The current provider and rollback route are understood.
- Environment-variable names and deployment configuration are known without exposing secret values.
- The working tree is understood and user changes are preserved.

If a precondition is missing, perform the minimum additional audit and document it before implementation.

---

## 4. Implementation Principles

1. **Repository truth over assumptions:** Follow the real codebase, naming, framework, and dependency versions.
2. **Minimal change:** Modify the smallest set of files needed for the chat path.
3. **Contract stability:** Do not change Flutter-visible request/response formats without evidence and compatibility planning.
4. **Server-side secrets:** The Groq API key must remain on the backend.
5. **Provider isolation:** Keep provider-specific code behind a narrow service/client boundary where practical.
6. **No silent fake success:** Do not return a fabricated answer after a provider failure.
7. **Explicit failure semantics:** Return the repository's established error format and appropriate HTTP status codes.
8. **Bounded resilience:** Use finite timeouts and limited retries; avoid retry storms.
9. **Privacy by default:** Do not log full prompts, user messages, API keys, authorization headers, or sensitive farm/person information.
10. **Backward compatibility:** Keep old app versions functioning wherever the existing API supports them.
11. **Testability:** Provider calls must be mockable; unit tests must not require a live Groq key.
12. **Rollback first:** Keep the previous provider available until Groq has passed validation, unless Phase 0 confirms it is already removed and the owner approves the implications.

---

## 5. Target Architecture

Use the architecture that best matches the current repository. The conceptual flow should be:

```text
Flutter Chat UI
    |
    | Existing authenticated request and DTO
    v
Existing FastAPI chat endpoint
    |
    v
Chat orchestration / validation layer
    |
    v
Text-generation provider interface or service
    |
    +---- Groq provider (Phase 1 target)
    |
    +---- Previous provider (temporary rollback option, if feasible)
    |
    v
Normalized internal result
    |
    v
Existing response schema
    |
    v
Flutter renders assistant message
```

### Architecture requirements

- Keep the existing endpoint and frontend contract wherever possible.
- Do not put provider credentials or provider SDK calls in Flutter.
- Do not create a new microservice solely for this migration.
- Do not introduce a general-purpose agent framework or large abstraction layer.
- If the project already has a provider interface, extend it. If not, create only a small interface/helper where it materially improves testability and rollback.
- Normalize provider-specific response fields before returning them to the existing API route.
- Keep crop image inference and other AI pipelines on their current path.

---

## 6. Phase 1 Work Packages

### Work Package 1 — Repository and Baseline Confirmation

**Goal:** Confirm the exact implementation target before changing code.

Tasks:
1. Read repository instructions, Phase 0 reports, and relevant architecture documents.
2. Inspect `git status`, current branch, and recent changes.
3. Locate the Flutter chat UI and API client.
4. Trace the request to the backend endpoint and then to the provider call.
5. Identify authentication, input validation, rate limits, prompt assembly, and response serialization.
6. Locate shared AI/provider code used by Crop Scan or other features.
7. Run the baseline tests identified in Phase 0.
8. Record any pre-existing failures separately from new failures.

Deliverable:
- `docs/architecture/PHASE_1_BASELINE_CONFIRMATION.md`

Acceptance:
- Exact files and request flow are listed.
- No code changes have been made before the scope and shared-code risks are understood.
- Any uncertainty is explicitly stated.

### Work Package 2 — Configuration and Secret Management

**Goal:** Configure Groq securely and predictably.

Use project-consistent environment configuration. Variable names below are proposals; reconcile them with existing naming conventions before implementation:

- `GROQ_API_KEY` — required secret for Groq.
- `GROQ_MODEL` — explicit model identifier supported by the current Groq account/API.
- `GROQ_BASE_URL` — optional only if needed; default to the provider's documented endpoint.
- `GROQ_TIMEOUT_SECONDS` — bounded request timeout.
- `CHAT_PROVIDER` — optional provider selector if the existing architecture supports safe provider selection.
- Existing provider key/model variables — preserve during the rollback window.

Requirements:
1. Never place a real API key in source code, `.env.example`, tests, screenshots, logs, or documentation.
2. Add variable names and safe example values only to `.env.example` or its equivalent.
3. Validate required settings at startup or at the point of use, consistent with existing project conventions.
4. Fail clearly if Groq is selected but its key/model configuration is missing.
5. Do not print secret values during validation.
6. Avoid logging the full environment or settings object.
7. Do not assume a model identifier from memory. Use the model currently supported for the account and confirm it against official Groq documentation or the configured account before deployment.
8. If the deployment environment is Render, document where the variables must be configured, but do not alter live settings without authorization.
9. Do not expose `GROQ_API_KEY` through Flutter build-time variables, public Vite variables, app constants, or API responses.

Deliverable:
- Configuration updates plus `PHASE_1_CONFIGURATION_AND_SECRETS.md`

Acceptance:
- Missing key produces a clear, non-secret diagnostic.
- Secret scanning and repository review reveal no newly added credentials.
- Tests can configure a fake key without making network calls.

### Work Package 3 — Groq Provider Client

**Goal:** Add a small backend integration that invokes Groq text generation.

Tasks:
1. Check whether the repository already uses an HTTP client or provider SDK; reuse compatible dependencies where practical.
2. Choose a supported Groq API integration appropriate to the existing Python/FastAPI stack.
3. Pin or constrain any new dependency according to repository conventions.
4. Keep the provider client isolated from the HTTP route and Flutter UI.
5. Build the request from validated chat input and the existing system/developer prompt rules.
6. Send only the data needed for the generation task.
7. Set a finite connection/read timeout.
8. Parse the response defensively and validate that assistant text is present and non-empty.
9. Normalize the provider output into an internal result type or existing project schema.
10. Map provider errors to stable internal exceptions, without leaking raw provider responses to the client.
11. Keep API key and authorization header server-side.
12. Make provider calls injectable/mockable in tests.
13. Avoid adding streaming unless the existing chat API already supports streaming and migration can preserve it exactly.

Potential internal failure categories:
- Missing configuration
- Authentication/permission failure from provider
- Rate limit/quota exceeded
- Provider timeout
- Provider unavailable/network error
- Invalid or unexpected provider response
- Request rejected due to invalid input

Do not expose raw SDK exception text, request headers, internal hostnames, or stack traces to users.

Deliverable:
- A provider client/service in the repository's established location.
- Unit tests for the client.

Acceptance:
- A valid mocked response returns normalized assistant text.
- Missing/empty/malformed response is rejected safely.
- Timeout and provider exceptions are mapped to stable internal errors.
- Tests run without live provider credentials.

### Work Package 4 — Chat Flow Integration

**Goal:** Route only the existing text-chat workflow to Groq.

Tasks:
1. Update the existing chat service or provider selection point.
2. Preserve existing endpoint path, HTTP method, request fields, response fields, and authentication behavior.
3. Preserve existing chat-history behavior and role ordering where supported.
4. Keep system instructions separate from user-provided content.
5. Preserve language behavior and the current supported languages; do not promise new language support without tests.
6. Preserve conversation context limits and input-size safeguards.
7. Avoid accidentally forwarding internal metadata, tokens, file paths, or secrets to Groq.
8. Ensure user messages cannot override trusted system instructions merely by containing phrases such as “ignore previous instructions.”
9. If a conversation contains images or attachments, follow the existing chat contract. Do not silently send image data to a text-only model or break existing image handling.
10. Keep Crop Scan on its existing model/provider and verify the call graph after integration.
11. Preserve the current response serialization so the Flutter UI does not need changes.
12. If provider selection is configurable, validate allowed values and make the default explicit.
13. If the old provider is retained for rollback, ensure provider selection is server-controlled, not user-controlled from arbitrary request payloads.

Deliverable:
- Integrated chat path and contract regression tests.
- `PHASE_1_CHAT_INTEGRATION.md`

Acceptance:
- The same Flutter client request continues to work.
- Only chat text generation changes provider.
- No provider key is required or included on the client.
- Crop Scan and other AI workflows are not unintentionally changed.

### Work Package 5 — Prompt and Agricultural-Safety Behavior

**Goal:** Preserve useful behavior without misrepresenting model output as verified knowledge.

Tasks:
1. Review the current chat system prompt and retain valuable existing instructions.
2. Keep responses farmer-friendly, clear, and appropriate to the app's supported languages.
3. Encourage the model to ask for missing context such as crop, growth stage, location, symptoms, and recent weather when relevant.
4. Instruct the model to express uncertainty where information is incomplete.
5. Avoid definitive diagnosis or exact pesticide/fertilizer dosage without adequate context and a reliable basis.
6. Encourage users to follow local label directions and consult qualified local agricultural experts for high-risk or ambiguous cases.
7. Do not invent government schemes, market prices, weather readings, disease prevalence, official phone numbers, or citations.
8. Do not claim that a recommendation was checked against official sources during Phase 1.
9. Keep urgent safety instructions conservative, especially around chemicals, water, electricity, machinery, and livestock.
10. Do not allow the model to trigger irrigation or any external action.

Important limitation:
- These prompt improvements are guardrails, not proof of factual correctness. Grounded retrieval and trusted-source citations are planned for a later phase.

Deliverable:
- Versioned prompt or documented prompt changes and prompt-focused tests.

Acceptance:
- Prompt does not claim access to live farm data unless that data is actually supplied.
- The model is instructed to acknowledge uncertainty and avoid fabricated current facts.
- Tests check prompt construction and role separation, not subjective model quality alone.

### Work Package 6 — Errors, Timeouts, Retries, and Rate Limits

**Goal:** Make failures understandable and prevent cascading requests.

Requirements:
1. Use the existing project error-response format.
2. Return a client-safe message that the chat service is temporarily unavailable when the provider fails; do not present it as an AI-generated answer.
3. Use appropriate HTTP statuses consistent with the existing API:
   - Invalid input: existing validation behavior, typically 400/422.
   - Missing server configuration: 500-class internal configuration failure.
   - Provider rate/quota limit: 429 or a documented mapped status, consistent with the app contract.
   - Provider timeout: 504 where compatible with current API conventions.
   - Provider outage/network failure: 502/503 where compatible with current API conventions.
4. Do not expose provider stack traces or raw provider response bodies.
5. Use finite retries only for transient failures and only if safe.
6. Do not blindly retry requests rejected for invalid credentials, invalid model, or invalid input.
7. Respect provider retry guidance such as `Retry-After` where supported.
8. Use exponential backoff with jitter only if the existing architecture supports it and the total request time remains bounded.
9. Avoid retrying a request after a successful provider response.
10. Avoid unbounded or nested retries in both HTTP client and application code.
11. Ensure cancellation/disconnect behavior is handled according to existing framework conventions.
12. Add rate limiting or per-user request controls only if an existing mechanism is present or a minimal change is approved; do not introduce a new infrastructure dependency in this phase.

Acceptance:
- Failure behavior is deterministic and covered by tests.
- UI does not display a blank assistant message or fake successful answer.
- Logs contain enough operational context to diagnose issues without exposing user content or secrets.

### Work Package 7 — Logging, Privacy, and Security

**Goal:** Keep diagnostics useful without leaking sensitive information.

Tasks:
1. Log request correlation ID if the project has one.
2. Log provider name, duration, status category, retry count, and error category.
3. Avoid logging full prompts, full user messages, assistant output, API keys, auth headers, cookies, or raw provider payloads by default.
4. Review any chat persistence behavior; preserve existing retention and access rules.
5. Ensure authentication and authorization are unchanged.
6. Ensure the server never returns secrets or internal exception details.
7. Confirm CORS and API exposure are not broadened as part of the migration.
8. Check for prompt injection risks at the application boundary; treat retrieved/user-provided content as untrusted (full RAG defenses are deferred).
9. Confirm dependency changes do not introduce known critical vulnerabilities where the project's available tooling permits.
10. Add or update secret scanning checks if the repository already uses them.

Deliverable:
- `PHASE_1_SECURITY_AND_PRIVACY_REVIEW.md`

Acceptance:
- No secret or full conversation content appears in newly added logs.
- Existing authentication and access controls remain active.
- Security review records verified findings and limitations.

### Work Package 8 — Automated Testing

**Goal:** Validate the migration without depending on a live Groq service.

Implement tests that fit the repository's existing framework and conventions.

#### Provider-client unit tests
- Correct request endpoint and authorization construction, without exposing secrets.
- Valid successful response.
- Empty assistant content.
- Malformed JSON/response shape.
- Missing configuration.
- Invalid credentials response.
- Invalid model response.
- Rate limit response.
- Timeout.
- Connection failure.
- Unexpected provider status.
- Response parsing with optional fields absent.
- Model configuration is passed as configured, not hard-coded silently.

#### Chat integration tests
- Existing request schema remains accepted.
- Existing response schema remains unchanged.
- Authentication behavior remains unchanged.
- Conversation history and roles are preserved appropriately.
- Empty/oversized/invalid user input follows existing validation.
- Provider failure maps to the existing client-safe error contract.
- Provider output is normalized before response serialization.
- Provider selection cannot be overridden by arbitrary client input.
- Chat uses Groq when selected.
- Crop Scan still uses its original inference path.

#### Regression tests
Run relevant tests for:
- Chat.
- Crop Scan/disease detection.
- Sentinel Map APIs.
- My Farm and soil health.
- Mandi prices.
- Government schemes.
- Weather/alerts.
- Authentication and shared backend dependencies.

Only tests affected by the change need to be added, but existing tests must be run and results documented. Do not alter unrelated tests merely to make the suite green.

#### Optional live smoke test
A live smoke test may be performed only when an authorized environment and valid secret are available. It must:
- Use a non-sensitive test prompt.
- Avoid printing the secret.
- Avoid logging personal data.
- Record date/time, environment, configured model identifier, latency, and outcome without recording the API key.
- Be labeled separately from automated mock tests.

Acceptance:
- New tests pass.
- Relevant regression tests pass, or pre-existing failures are explicitly separated.
- No test is described as passed unless it was actually executed and passed.

### Work Package 9 — Flutter Compatibility

**Goal:** Ensure the existing mobile client continues to work without unnecessary UI changes.

Tasks:
1. Keep the existing chat API call signature and DTOs.
2. Confirm parsing of successful responses.
3. Confirm parsing of the established error format.
4. Ensure loading indicators, retry affordance, and empty/error states behave correctly.
5. Prevent duplicate submissions if the existing UI already guards against them.
6. Do not redesign the chat screen or introduce new UI features.
7. If no Flutter change is necessary, document why and verify through tests or a controlled manual smoke test.

Acceptance:
- No required Flutter changes, or only a minimal justified compatibility fix.
- Chat does not hang indefinitely on a provider timeout.
- Error state is understandable and does not display raw backend/provider errors.

### Work Package 10 — Deployment and Rollout Readiness

**Goal:** Prepare a controlled release without modifying production without permission.

Tasks:
1. Update deployment documentation with the required environment variable names.
2. Confirm the deployment platform's environment-variable mechanism from repository/deployment configuration.
3. Document how to set the Groq key securely in the hosting dashboard or secret manager.
4. Keep the prior provider's configuration available during the validation/rollback window if applicable.
5. Make provider selection server-controlled and reversible if the architecture supports it.
6. Deploy only when explicitly authorized.
7. After an authorized deployment, verify:
   - Backend health endpoint.
   - Chat request succeeds with a harmless prompt.
   - Failure path behaves safely.
   - Crop Scan and other critical endpoints remain healthy.
   - Logs contain no secrets or full user content.
8. If canary/feature-flag capability exists, use it. Do not build a complex rollout system for this phase.
9. Document the rollback steps and conditions.

Potential rollback triggers:
- Chat errors rise above the pre-migration baseline.
- Typical response latency becomes unacceptable.
- Provider quota/authentication fails.
- Flutter parsing breaks.
- Crop Scan or another unrelated AI workflow regresses.
- Sensitive content appears in logs.
- Provider output is frequently empty or malformed.

Deliverable:
- `PHASE_1_ROLLOUT_AND_ROLLBACK.md`

Acceptance:
- Rollback is documented and actionable.
- No production change is claimed unless verified.
- Prior provider can be restored using the documented configuration or code revert where feasible.

### Work Package 11 — Documentation and Completion Report

Create or update the following files under the repository's established documentation directory. Do not create duplicate documentation if equivalent files already exist; update them or reference their actual paths.

1. `PHASE_1_BASELINE_CONFIRMATION.md`
2. `PHASE_1_CONFIGURATION_AND_SECRETS.md`
3. `PHASE_1_CHAT_INTEGRATION.md`
4. `PHASE_1_SECURITY_AND_PRIVACY_REVIEW.md`
5. `PHASE_1_TEST_REPORT.md`
6. `PHASE_1_ROLLOUT_AND_ROLLBACK.md`
7. `PHASE_1_RISK_REGISTER.md`
8. `PHASE_1_COMPLETION_REPORT.md`

Each document must distinguish:
- Implemented and verified
- Implemented but not verified
- Not implemented
- Blocked
- Requires live service
- Requires manual UI validation
- Not applicable

The completion report must list changed files, test commands and real outputs/status, known issues, configuration still needed, rollback instructions, and recommendation for Phase 2 readiness.

---

## 7. Suggested Execution Order

Execute in this order to minimize risk:

1. Confirm Phase 0 artifacts and working-tree state.
2. Capture baseline tests.
3. Map shared provider dependencies and isolate the chat call path.
4. Agree on exact Groq model configuration based on current supported account/API options.
5. Add configuration and secret validation.
6. Implement provider client and unit tests.
7. Integrate provider into the existing chat service while preserving the API contract.
8. Add prompt/safety guardrails without expanding into RAG.
9. Add error mapping, bounded timeout/retry behavior, and safe logging.
10. Run chat tests.
11. Run Crop Scan and related regression tests.
12. Review Flutter compatibility.
13. Perform security and dependency checks available in the repository.
14. Update documentation.
15. Review diff for scope creep and accidental secrets.
16. Run final test suite and compare against baseline.
17. Produce completion report and recommend go/no-go.

Do not deploy until the repository changes, tests, and rollback path have been reviewed and deployment is explicitly authorized.

---

## 8. Configuration Design Guidance

Use existing project conventions. The following is an example design, not a mandate to rename current settings:

```text
CHAT_PROVIDER=groq
GROQ_API_KEY=<set-in-server-environment>
GROQ_MODEL=<verified-model-id>
GROQ_TIMEOUT_SECONDS=30
```

Important:
- Do not copy the placeholder into production as a real value.
- Do not expose any of these values through a public frontend build configuration.
- `CHAT_PROVIDER` should be omitted if the repository uses another established provider-selection mechanism.
- A model identifier must be verified for the target account and API before deployment.
- Keep old-provider configuration only as long as needed for the approved rollback window.

---

## 9. API Contract Compatibility Checklist

Use the Phase 0 contract report to complete this checklist with actual field names and values.

| Contract area | Requirement |
|---|---|
| Endpoint path and method | Unchanged unless a documented compatibility issue requires otherwise |
| Authentication | Same requirements and authorization behavior |
| Request JSON | Existing field names/types remain accepted |
| Chat history | Existing format and role ordering preserved |
| Response JSON | Same fields/types/status patterns |
| Error response | Existing error envelope preserved where possible |
| Language handling | Existing supported language behavior retained |
| Attachments/images | Existing behavior preserved; no unapproved provider change |
| Timeouts | Bounded and compatible with client timeout |
| Logging | No secrets or full user content by default |

Record actual contract values in `PHASE_1_CHAT_INTEGRATION.md`; do not invent endpoint names or fields.

---

## 10. Risk Register

| Risk | Likelihood | Impact | Mitigation | Verification |
|---|---|---|---|---|
| Chat and Scan share provider code | Medium/High until audited | High | Isolate chat call site; test Scan path | Call-graph review + regression test |
| API contract changes accidentally | Medium | High | Preserve DTOs and route; contract tests | Compare Phase 0 contract |
| Groq model unavailable to account | Medium | High | Verify configured model before release | Authorized smoke test |
| API key exposed | Low/Medium | Critical | Server-only secret, scanning, no secret logs | Diff and secret scan |
| Rate limits or quota exhaustion | Medium | Medium/High | Bounded handling and clear errors | Simulated 429 test |
| Provider outage or timeout | Medium | Medium | Timeouts and safe error state | Mocked failure tests |
| Unfounded agricultural claims | Medium | High | Conservative prompt; defer grounded RAG | Prompt tests and manual review |
| Language quality differs | Medium | Medium | Test supported languages; retain prompt | Manual evaluation |
| Hidden fallback masks failure | Medium | High | Remove/label fallback only where needed; test errors | Forced-failure test |
| Unrelated feature regression | Low/Medium | High | Narrow diff and regression suite | Feature regression results |
| Rollback unavailable | Low/Medium | High | Keep prior provider/config during window | Rollback rehearsal or review |

Update likelihood and impact based on Phase 0 evidence; do not leave guesses labeled as verified facts.

---

## 11. Definition of Done

Phase 1 is complete only when all applicable items below are satisfied:

### Implementation
- [ ] Groq is integrated into the backend text-chat path.
- [ ] Chat endpoint and Flutter contract remain compatible.
- [ ] Crop Scan remains on its existing inference path.
- [ ] Configuration is environment-based and secret-safe.
- [ ] Timeouts and provider errors are handled predictably.
- [ ] No fabricated fallback answer is presented as a successful model response.
- [ ] No unrelated feature or schema changes were introduced.

### Testing
- [ ] Provider unit tests pass.
- [ ] Chat integration/contract tests pass.
- [ ] Relevant regression tests pass or pre-existing failures are documented.
- [ ] Missing key, timeout, malformed response, and rate limit cases are tested.
- [ ] Secret scan/diff review is completed where tooling exists.
- [ ] Live smoke test is clearly marked as not run if credentials or authorization are unavailable.

### Security and operations
- [ ] No secrets appear in code, tests, documentation, logs, or client bundle.
- [ ] Existing authentication and authorization remain unchanged.
- [ ] Logs avoid full prompts and user content by default.
- [ ] Rollback procedure is documented and feasible.
- [ ] Deployment status is accurately reported.

### Documentation
- [ ] All required reports are updated.
- [ ] Changed files and commands are listed.
- [ ] Remaining blockers and manual steps are explicit.
- [ ] Phase 2 prerequisites are documented.

---

## 12. Final Status Rules

The implementation agent must select exactly one status:

### `PHASE 1 COMPLETE`
Use only if the implementation and all applicable automated checks pass, the API contract is preserved, Crop Scan regression checks pass, the security review is complete, and documentation is finalized. Live production verification is separately labeled and is not implied by this status.

### `PHASE 1 COMPLETE WITH DOCUMENTED BLOCKERS`
Use if the code and offline tests are complete but a live Groq key, deployment authorization, hosting access, or manual device validation is unavailable. State precisely what remains unverified.

### `PHASE 1 INCOMPLETE`
Use if the chat integration is partial, important tests fail, the chat contract is broken, a secret is exposed, unrelated features regress, or rollback is not understood.

Never report `COMPLETE` solely because files were edited or the build succeeded.

---

## 13. Phase 2 Readiness

Phase 1 should leave the codebase ready for a later agricultural RAG phase without implementing RAG now.

Record:
- The exact chat service/provider boundary where retrieval context can later be inserted.
- The prompt assembly location and separation of trusted instructions from user input.
- Existing chat history and context-size constraints.
- Whether embeddings/vector search dependencies already exist, without enabling them.
- Which trusted agricultural sources would need approval.
- Data privacy constraints for storing or retrieving farm/user information.
- Any architectural coupling that must be addressed before RAG.
- Explicit statement that Phase 1 does not provide source-grounded agricultural answers.

Do not install vector databases, add embedding calls, create chunks, or modify schemas in Phase 1.

---

## 14. Instructions for the Coding Agent

When using this plan with an AI coding agent:

1. Inspect the repository and all Phase 0 artifacts before editing.
2. Do not assume paths, route names, class names, framework versions, or model identifiers.
3. Preserve user changes and do not run destructive Git commands.
4. Make incremental, reviewable changes.
5. Do not deploy, rotate secrets, or modify production settings without explicit authorization.
6. Do not claim tests passed unless they were executed.
7. Do not invent files, schemas, endpoints, environment values, or live service outcomes.
8. If Phase 0 reveals a major architecture mismatch, stop and document the issue before expanding scope.
9. Do not use RAG or other excluded features as a shortcut to answer-quality problems.
10. Finish with a concise summary, changed-file list, actual test results, outstanding blockers, rollback instructions, and exact Phase 1 status.

**End of Phase 1 Implementation Plan**
