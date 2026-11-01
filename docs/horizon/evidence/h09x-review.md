# H09X — Combined independent specification and quality review

- Reviewer: independent reviewer profile (vendor-disjoint from the author per roster).
- Date: 2026-11-01. Scope: source-only combined review; all source allowlists treated READ-ONLY.
- Author evidence: `docs/horizon/evidence/h09x-author.md`; logs under `docs/horizon/evidence/h09x/`.
- Basis: SPEC.md §4 "Follow-up H09X" table, CONTRACTS.md §8 L168 / §9 L188–198, TASKS.md H09X (L738), AMENDMENT-2026-10-30.md.
- Historical findings preserved below; no source was repaired by the reviewer.

## Verdicts

**SPEC: PASS (SPEC_PASS_SOURCE_ONLY)** — all source-verifiable acceptance criteria verified independently; every runtime/PC criterion is explicitly unexecuted (see Deferred criteria).

**QUALITY: PASS (QUALITY_PASS_SOURCE_ONLY)** — implementation quality verified at source level; no blocking defects.

Source-only acceptance is not runtime/release approval.

## Independent verification performed (reviewer's own commands, not author self-report)

1. **5/5 SHA-256 recomputed and matched the author's table exactly**
   (`sha256sum` + `stat -c %s`, this workspace):
   - `backend/src/features/research/tool_registry.js` — `122e8942bda86995648fbc06d4d0b1e3d1e994f7553a72ca6fa78ea7282e7f26`, 16507 bytes.
   - `backend/test/research-runtime.test.cjs` — `8d7ae5fed673d89e4a23ab006bc8bc349c3ece9c934196fd20a66770e31043fc`, 31468 bytes.
   - `backend/src/features/research/automation.routes.js` — `364ddcd15946cd4ba47bdceab8ef3c91e3c685443fef4be3a72c32d64b98aabc`, 16482 bytes.
   - `backend/src/features/research/research.service.js` — `35a753d05269edc4406128dfee4761d1e3fc8f08b47a325ff08c445df6dc9bc7`, 48667 bytes.
   - `backend/src/features/research/agent_runtime.js` — `3df087bbad44fd83ef3e05731f5e69e4ec1aba7ac5a661a9e9d129449ce6bc1a`, 13340 bytes.
2. **`agent_runtime.js` byte-identical to the accepted H09 baseline, independently confirmed**:
   the recomputed hash equals the hash recorded in `docs/horizon/evidence/h09-review.md` L91
   (`3df087bb…bc1a`), and `git diff --stat -- <path>` is empty. The single bounded pipeline
   (one `modelClient.complete` call site at line 212 inside the ≤2-attempt loop; line 116 is a
   type check) is intact; no reviewer stage, no model resolver, no second model pipeline.
3. **Named suite rerun**: `node --test backend/test/research-runtime.test.cjs` → exit 0,
   **37/37 pass** (reviewer rerun log: `docs/horizon/evidence/h09x/reviewer-green-rerun.log`).
   37 tests independently counted in the test file — matches.
4. **Full aggregate rerun**: `node --test backend/test/*.test.cjs` → exit 0, **357/357 pass**
   (reviewer rerun log: `docs/horizon/evidence/h09x/reviewer-aggregate-rerun.log`).
5. `git diff --check` → exit 0 (clean).
6. **Red phase evidence integrity**: `red-run.log` contains a genuine pre-implementation
   `MODULE_NOT_FOUND` for `../src/features/research/tool_registry` (failing-tests-first invariant
   honored; the log is preserved, not rewritten).
7. **Dynamic-execution scan**: no `eval(`, `Function(`, `child_process`, `exec*`, `fetch(`,
   `http.request`, `https.` in `tool_registry.js`. The module is pure data + validation + budget
   accounting; resolvers are injected, never dynamic.
8. **Cross-lane coupling scan**: `tool_registry.js` requires only `node:crypto`;
   `automation.routes.js` requires only express + in-lane modules. No import of H16/H07A
   `outcome.*`/`scenarios.js` from any H09X file — accepted-lane artifacts are not coupled.
9. **Secret scan of evidence**: no credentials, bearer tokens or key material in the h09x logs;
   nonce values appearing in tests/logs are synthetic fixture constants (`deadbeef…`).

## SPEC compliance (criterion-by-criterion)

| Requirement (source) | Evidence | Status |
|---|---|---|
| Ten typed tools with exact per-stage allowlists (SPEC §4 table) | Registry `TOOL_DEFINITIONS` matches the SPEC table tool-for-tool and stage-for-stage; tests 1–4 assert names and allowlists | PASS (source) |
| Tool requests carry only `tool_name`/`arguments`/`stage`/`request_id` (CONTRACTS §9 L196) | `REQUEST_KEYS` allowlist; any other top-level key → `UNEXPECTED_FIELD` (test 11) | PASS (source) |
| Never accept owner IDs, URLs, commands, code, SQL, raw queries (CONTRACTS §9 L196) | `FORBIDDEN_ARGUMENT_KEYS` blocklist (owner_id/user_id/url/uri/command/cmd/code/sql/query/eval/path/file/token/key/secret/credential(s)/password/host/hostname/endpoint) → `FORBIDDEN_ARGUMENT` (test 12); `owner_id` absent from every tool schema | PASS (source) |
| Stage is an enum, never arbitrary code or model name (CONTRACTS §9 L198) | `STAGES` frozen 5-value enum, `validateStage` strict (tests 2, 14); router passes `req.params.stage` through `advanceStage`/registry validation | PASS (source) |
| Synthesis-only position tools not invocable from analyst/reviewer (CONTRACTS §9 L196) | `synthesis_only` flag + `SYNTHESIS_ONLY_STAGE` rejection in registry and executor (tests 10, 33) | PASS (source) |
| Budgets named code constants (SPEC §4): 8 read calls, 1 retrieval pass, 1 position read, 0 reviewer web tools | `TOOL_BUDGETS` frozen constants (tests 5); call budget enforced per run:stage → 429 `CALL_BUDGET_EXHAUSTED` with remaining counter (tests 16, 35); response cap 64 KiB → 413 `RESPONSE_TOO_LARGE` (test 17) | PASS (source) — see Observation 2 on `ANALYST_MAX_RETRIEVAL_PASSES` |
| Scoped stage/tools endpoints (CONTRACTS §9 L188–189) | `POST /runs/:runId/stages/:stage` under `research:stages`, `POST /runs/:runId/tools` under `research:tools`, both `requireOwner`; scope enforcement tested (test 30); fail-closed 503 without configured runtime (test 36) | PASS (source) |
| Lease/run-nonce binding, expired/replay rejected (CONTRACTS §9 L196) | `authorizeRunLease`: exact run-id header + constant-time nonce compare (`crypto.timingSafeEqual`), expired lease → 409, wrong nonce → 403, cross-owner run → indistinguishable 404 (tests 28–29, 37) | PASS (source) |
| Persisted stage replay; identical artifact idempotent, different artifact conflict; no backward transition (CONTRACTS §8 L168, §9 L198) | `advanceStage`: canonical-JSON SHA-256 digest, idempotent `replayed:true` without re-execution, `STAGE_REPLAY_CONFLICT`, `STAGE_OUT_OF_ORDER`, CAS via `updateIfStatus` (tests 20–23); `replayStage` read-only | PASS (source) |
| Stage replay must not re-charge a completed call (CONTRACTS §9 L198) | Executor retry cache serves identical `run_id:request_id` without counting a new call (tests 18); stage replay path never re-executes | PASS (source) |
| Generalized recovery preserves immutable references and deadlines; deadline expiry never silently resumed (CONTRACTS §8 L168) | `recoverIncompleteRun` returns `input_snapshot_id`/`run_input_ref`/`deadline_at`/`position_revision`/`created_at` byte-identical, mutates nothing (test 25); expired running run handed to `recoverAbandonedRuns` → `stalled`, non-resumable (test 26) | PASS (source) |
| No additional model reviewer stage without frozen evidence; no automatic paid calls (SPEC §4 L111/§6, TASKS H09X step 2) | No model reviewer stage introduced; reviewer stage is deterministic-only (`REVIEWER_MAX_WEB_TOOLS=0`, no resolver in tests); `agent_runtime.js` byte-identical (check 2); no quality/cost/latency superiority claim anywhere in the changed files or author evidence | PASS (source) |
| No replay/repair of immutable input refs | `advanceStage`/`replayStage`/`recoverIncompleteRun` never write `run_input_ref`, `input_snapshot_id`, `deadline_at`, `position_revision` | PASS (source) |

## Quality assessment

- **Security posture is genuinely fail-closed.** Lease authorization precedes any work in both
  endpoints; unknown tool/stage/argument rejected before resolver dispatch; missing tool runtime
  → 503; cross-owner runs are indistinguishable 404s. Constant-time nonce comparison with a
  length pre-check is standard practice (run id is not secret and is compared with `===`).
- **Correctness mechanics**: canonical-JSON digest for replay equality; `structuredClone` at
  repository boundaries prevents aliasing; CAS via `updateIfStatus(['running'])` with an explicit
  concurrent-change rejection; budget consumed atomically before resolver dispatch.
- **Tests are real coverage, not theater**: 37 scenarios cover registry shape, forbidden keys,
  budgets (429/413), idempotent retry, replay/conflict/ordering/deadline, recovery immutability,
  and endpoint-level auth (scope, nonce, lease, owner, runtime-missing). Fixtures are synthetic
  with injected repositories/resolvers — no observed market data, no live I/O.
- **Ownership respected**: only the four in-scope source paths changed; `agent_runtime.js`
  untouched; no generated-file hand editing; no lockfile changes; no app.js mounting (H15 lane).

### Non-blocking observations (suggestions; none block these verdicts)

1. **Retry-cache key is `runId:requestId` without stage/tool** (`tool_registry.js` L386).
   A caller reusing one `request_id` across stages, or for a different tool, within the same run
   would be served the earlier cached outcome (HTTP 200) instead of a stage/tool mismatch
   rejection. No test covers cross-stage reuse. Recommend including `stage` (and ideally
   `tool_name`) in the cache key in a future repair card; the contract's idempotency language
   ("idempotent retries do not count as new delivery") is still satisfied as written.
2. **`ANALYST_MAX_RETRIEVAL_PASSES` is declared but not enforced.** No retrieval-pass counter
   exists in any H09X file; the "one bounded follow-up retrieval pass" concept belongs to the
   agent loop, and `agent_runtime.js` is deliberately untouched. Acceptable for source-only scope
   (the enforced budgets — call/stage/response — are all in code), but the constant is currently
   decorative. Should be wired when the generalized runtime is actually mounted.
3. **`recoverIncompleteRun` on an expired run triggers a global `recoverAbandonedRuns()` sweep**,
   i.e. a single-run recovery request can stall/supersede other expired runs. Consistent with the
   existing sweep semantics and arguably desirable, but it is a side effect beyond the requested
   run; worth a deliberate decision when the recovery runtime goes live.
4. **Failed tool calls consume budget and are not cached** (`RESOLVER_FAILED`,
   `RESPONSE_TOO_LARGE`): retrying a failed call re-charges. Defensible — only *completed* calls
   get the no-re-charge guarantee per CONTRACTS §9 — noted for completeness.
5. Cosmetic: the `ERROR_STATUS` comment groups the H09X 400/503 entries under a "409 stage/tool
   conflicts" heading (`automation.routes.js`).

## Deferred criteria (explicitly NOT executed or verified by this review)

All of the following remain **DEFERRED_TO_DEV_PC / operator release gates** and are NOT covered
by the PASS verdicts above:

- No live model/provider call, no live MongoDB, no live n8n publication, no live market data —
  all fixtures synthetic; runtime/live-model acceptance is an operator gate.
- The `automation.routes.js` router is not mounted in `app.js` (H15 integration-lane wiring,
  cf. H10 finding O3): the stage/tools endpoints do not exist live until mounted.
- Durable Mongo-backed stage-artifact persistence exercised only against the repository
  abstraction, not a live store.
- All Flutter analysis/generation/tests/device/APK checks — DEFERRED_TO_DEV_PC, none attempted.
- Vendor/credential provisioning for the backend model provider — operator-only; not touched.
- No production operations, no DNS/tunnel changes, no commit/push — none performed.

## Verdict summary

- **SPEC: PASS (SPEC_PASS_SOURCE_ONLY)** — 13/13 source-verifiable criteria verified
  independently; every unexecuted PC/runtime criterion listed explicitly above.
- **QUALITY: PASS (QUALITY_PASS_SOURCE_ONLY)** — 5 non-blocking observations recorded; none
  violates an acceptance criterion or invariant.

This review independently inspected source and reproduced the safe offline checks; it is not an
author test self-report. Reviewer rerun logs: `docs/horizon/evidence/h09x/reviewer-green-rerun.log`,
`docs/horizon/evidence/h09x/reviewer-aggregate-rerun.log`.
