# H03 combined independent review — scoped automation security and tenancy

Reviewer: `reviewer/deepseek-v4-pro`. Author lane: `worker/gemini-3.8-flash` (vendor-disjoint, 2026-10-31 roster). Scope: source-only combined SPEC + QUALITY review. No source files were changed; no live API, database, credential store, `.env`, n8n workflow, scheduler, or production service was touched.

## Verdicts

- **SPEC: `SPEC_PASS_SOURCE_ONLY`** — all three acceptance criteria are satisfied and independently reproduced at source scope.
- **QUALITY: `QUALITY_PASS_SOURCE_ONLY`** — fail-closed authentication is correct, constant-time comparison is used, owner binding is enforced, and the named + aggregate suites pass. Remaining limitations are explicit and correctly attributed to downstream owners.

Source-only acceptance does not prove runtime, deployment, Flutter/device, live-credential, or release readiness. All unexecuted PC/runtime criteria are listed in §Boundaries.

---

## Artifacts inspected

| File | SHA-256 | Matches author evidence |
|---|---|---|
| `backend/src/middleware/automation.middleware.js` | `a737df5a5c8be4cd86cca9b2549eb282996213e8c310200e1e55bb828f2669a7` | yes |
| `backend/src/features/briefing/briefing.routes.js` | `bdc3917adae14e4a9bf7334a1d063bb49022afe67f6f4dfda09cbef9a18ed631` | yes |
| `backend/src/features/briefing/briefing.controller.js` | `0ae95c14c688421a2a96c29f11b0266ec8fe48db9eda71fd3558f6b0384bb53d` | yes |
| `backend/src/config/env.js` | `aa91cfb639dcdabffce55c76f12a284173d56be7d7e44e0362b78734ec1bb5cb` | yes |
| `backend/test/research-auth.test.cjs` | `994911879ec4627d280d4911a3f21fe04fa7ba5ca220f8519aec9e182f7a1f8f` | yes |

All five delivered hashes match the author's `h03-author.md` continuation addendum exactly. `git diff --check` is clean (exit 0).

## Independent reproduction (not author self-report)

Host runtime: Node `v22.22.2`.

1. `node --test backend/test/research-auth.test.cjs` → **exit 0; 6 passed, 0 failed.**
2. `node --test backend/test/research-contracts.test.cjs` (H01) → **exit 0; 14 passed, 0 failed.**
3. `node --test backend/test/market-history.test.cjs` (H05) → **exit 0; 11 passed, 0 failed.**
4. `node --test backend/test/*.test.cjs` → **exit 0; 31 passed, 0 failed** (6 auth + 14 contracts + 11 market). The author's "28 aggregate" figure predates H05's suite growing from 8 to 11 tests in the concurrent timeout-repair lane; the current aggregate is 31/31 green, and the H05 growth is cross-lane, not an H03 regression.
5. `node --check` on the middleware, router, controller, `env.js`, and the test file → all exit 0.
6. `git diff --check` → exit 0.

### Independent edge-case probes

Beyond the author's own suite, I ran 11 additional assertions directly against the exported helpers (scratch probe, not committed):

- Empty scopes + token present → 401 `automation_auth_unavailable` (fail closed).
- `requireOwner` with empty-string ownerId → 401 `automation_owner_unavailable`.
- Unparseable configured expiry → 401 `automation_auth_unavailable` (fail closed, not silently open).
- Oversized parsed body with no `content-length` header → 413 `automation_body_too_large`.
- Callback authorizer: missing `research:callback` scope → `automation_scope_denied`.
- `position_revision` of 0 → `automation_run_invalid`.
- Automation owner ≠ `run.owner_id_internal` → `automation_owner_denied` (cross-owner binding).
- Expired lease → `automation_lease_expired`.
- `x-horizon-run-id` mismatch → `automation_callback_denied`.
- Wrong nonce → `automation_nonce_denied`.
- Empty and >128-char delivery ID → `automation_callback_denied`.

All probes passed. Result: `ALL INDEPENDENT PROBES PASSED` (exit 0). My first probe run failed due to a bug in my own probe harness (wrong argument order), not the implementation; after correcting the harness the full set passed on the first retry.

### Secret scan

Grep for common secret/credential patterns across all five delivered files returned only the Zod schema declaration `JWT_SECRET: zod.string()` (a field name, not a value). No literal tokens, keys, or credentials are present. `env.js` adds only four `.optional()` schema fields and reads no values; the tests generate their tokens via `crypto.randomBytes(32)`. No `.env` or credential store was read during this review.

---

## Specification assessment (acceptance criteria)

**1. "Anonymous legacy sensitive routes fail in tests; wrong/expired scopes and replay conflicts fail."** — SATISFIED. `POST /api/v1/briefing` and `GET /api/v1/briefing/config/system` now require the automation identity (`briefing:write` / `briefing:read` respectively) via `automationMiddleware`, which is evaluated before the `rejectOwnerSpoofing` and controller handlers. Anonymous (401 `automation_auth_required`), invalid token (401 `automation_auth_invalid`), expired configured token (401 `automation_auth_expired`), insufficient scope (403 `automation_scope_denied`), and replay conflict (409 `automation_replay_conflict`) paths are all covered by the named suite and my probes. The middleware fails closed when configuration is absent (401 `automation_auth_unavailable`).

**2. "Client-supplied userId cannot authorize new position/research operations."** — SATISFIED at source scope. Two independent mechanisms: (a) the legacy controller now derives the authoritative owner from `req.automation.ownerId` (set server-side by the middleware), rejects a mismatched client `userId` with 403 `automation_owner_denied`, and strips the client `userId` before `briefingService.save`; (b) the run-callback helper `createRunCallbackAuthorizer` rejects any automation context whose `ownerId` differs from `run.owner_id_internal` with `automation_owner_denied`, binding owner from the run record and never from a client-supplied field. The previously failing `research-auth.test.cjs:232` cross-owner assertion (documented in the author's continuation addendum and in `h05-review.md`) is now present at lines 236–243 of the test file and passes; my independent cross-owner probe confirms the denial.

**3. "No real credential read/generated/stored by worker; live credential setup remains release gate."** — SATISFIED. `env.js` declares `AUTOMATION_SERVICE_TOKEN`, `AUTOMATION_SERVICE_SCOPES`, `AUTOMATION_OWNER_ID`, `AUTOMATION_SERVICE_TOKEN_EXPIRES_AT` as optional schema fields only. No value is read, generated, stored, or placed in fixtures; no `.env` or credential store access; secret scan is clean. Live provisioning and coordinated n8n deployment are explicitly deferred to primary/admin as the release gate.

## Quality assessment

Correctness and safety positives:

- Token and nonce comparison use `crypto.timingSafeEqual` via `constantTimeEquals` with a length guard, avoiding the exception `timingSafeEqual` throws on unequal-length buffers.
- Fail-closed posture is consistent: missing token, empty scopes, missing/invalid owner, unparseable or expired `expiresAt`, and oversized bodies all return safe denials before `next()`.
- Scope normalization handles both array and whitespace/comma-separated string forms; `requiredScopes.every(...)` enforces the exact required set.
- Body bound is enforced on both `content-length` and the parsed body (`safeJsonSize`), with a default 64 KiB cap and a configurable override.
- Owner binding in the callback helper is enforced before lease/nonce/replay acceptance, closing the cross-owner gap the continuation addendum identified.
- The replay digest keys on `run.id:deliveryId` and rejects a conflicting body for the same delivery ID with 409; identical retries are idempotent.
- The test suite exercises the real briefing controller (owner stripping) in addition to the middleware, and uses an ephemeral loopback server with generated in-memory values only.

Non-blocking observations (do not block; note for downstream owners):

- **Body cap vs global parser.** The 64 KiB route-level cap runs after `express.json({ limit: '50mb' })` in `backend/src/app.js` has already parsed the body into memory. H03 rejects oversized bodies before controller/service work, but a transport-level parser reduction requires the integration lane (H15A owns `app.js`) — a documented, correctly-attributed limitation, not a claim of full transport protection.
- **In-memory replay.** The replay cache is deliberately bounded and non-durable; process-restart replay protection is not claimed. H10 must connect `createRunCallbackAuthorizer` to H08's persisted run/lease/idempotency records. The digest is computed from `JSON.stringify(body)`, so key-ordering differences in an otherwise-identical retry could surface as a false conflict — the durable idempotency layer should canonicalize.
- **Lease field shape.** The helper reads `run.lease_nonce` / `run.lease_expires_at`, which are referenced conceptually in CONTRACTS §9 ("run-bound lease nonce") but are not fields in the canonical `ResearchRun` schema (CONTRACTS §8 / `contracts.js:479-545`). H08/H10 must materialize these fields (or adapt the helper) at integration. This is a forward-looking interface, not a defect in H03's own acceptance.
- `constantTimeEquals` short-circuits on unequal length, which in principle leaks the configured token's length to an attacker. With the prescribed high-entropy random token this is negligible; a hash-then-compare would close it entirely if desired.

## Cross-lane note (H05)

`h05-review.md` recorded an aggregate failure `backend/test/research-auth.test.cjs:232` ("Missing expected exception") at the time of its review, which it correctly attributed to the H03 lane rather than H05. That assertion is now the passing cross-owner denial case; H05's own timeout repair continues in parallel against its own files. My aggregate run is 31/31 with the H05 suite at 11 tests (its current size); no H03-owned failure is present.

## Boundaries

- SPEC/QUALITY verdicts are `_SOURCE_ONLY`. Not verified: runtime/deployment behavior, Flutter analysis/generation/tests/device/APK (`DEFERRED_TO_DEV_PC`), live credential provisioning, n8n workflow publication, database persistence/readback, and full-release readiness.
- The focused authorization/privacy threat review is a separate downstream gate (`t_3edefdf5`); this combined review does not substitute for it.
- No source repairs, no commit/push, no branch change, no baseline alteration. Historical evidence files were preserved.
