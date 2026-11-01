# H08 — Durable run state, evidence snapshots and thesis memory — Author Delivery

- Task: t_4c2206e0 (H08), delivery_phase: core_source, scope: source-only backend
- Author: worker (dispatched profile; roster per release note 2026-10-31 21:31 UTC: worker/zai/glm-5.3-flash)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup. `git status --porcelain` for the touched paths shows only untracked additions (`??`), no tracked-file modifications. No files outside the package were created or modified.

## 1. Delivered files (all new; exactly the canonical package)

| Path | Lines | SHA-256 |
|---|---|---|
| backend/src/features/research/research_run.model.js | 66 | 5f7325de4ef943a9510603f8aa8a5e94cd04e0a676ee36f717bfcf6aa4950b2d |
| backend/src/features/research/research_assessment.model.js | 39 | 582db67a6cab992a8c4992223c333a8dc3bc3ec119e6e7d11a41f0bf3b637da4 |
| backend/src/features/research/research_snapshot.model.js | 28 | a386f5793fa7e15494a26360a2ec65b6215c82d42910b63c2a04178ff813a69f |
| backend/src/features/research/thesis_state.model.js | 93 | 058e451d8b96a45b17ab81030c9858678527b08f6855dc684ea8611667551c56 |
| backend/src/features/research/research.service.js | 1018 | 7478a5c05abc28bdb0aa279e48414b12628802279b57865b6324b8bbc18edfc9 |
| backend/src/features/research/research.routes.js | 149 | cb232634700277aaa84c95ed91df5526667edf91633c1e498f56257ee0ce71a6 |
| backend/test/research-state.test.cjs | 1089 | 103b311d35a49bfc5a862da9a5bb248ec5f10c47dd6157a191bae6d4a0814311 |

Evidence artifacts: `docs/horizon/evidence/h08/red-run.log` (real TDD red run, exit 1), `docs/horizon/evidence/h08/verification.log` (green run + full regression battery + git diff --check + status). `existing_files` in the canonical package is empty; `contracts.js`, evidence/metrics modules, routes wiring (`app.js`), Flutter sources: untouched.

## 2. Commands and results (this run, host node v22.22.2, hermetic offline)

All commands foreground in /home/ubuntu/apps/Horizon. No live APIs, no credentials, no DB connection, no installs, no shell backgrounding.

```
node --test backend/test/research-state.test.cjs             -> exit 0; 24 pass, 0 fail (TDD green)
node --test backend/test/research-contracts.test.cjs         -> exit 0; 14 pass (H01 predecessor — no regression)
node --test backend/test/research-metrics.test.cjs           -> exit 0; 24 pass (H07 predecessor — no regression)
node --test backend/test/research-evidence.test.cjs          -> exit 0; 19 pass (H06 predecessor — no regression)
node --test backend/test/research-auth.test.cjs              -> exit 0;  6 pass (H03 predecessor — no regression)
node --test backend/test/market-history.test.cjs             -> exit 0; 12 pass (H05 predecessor — no regression)
node --test backend/test/research-history-integration.test.cjs -> exit 0; 11 pass (H15A predecessor — no regression)
node --test backend/test/positions.test.cjs                  -> exit 0; 40 pass (H04 predecessor — no regression)
git diff --check                                             -> clean, exit 0
secret scan (credential-literal pattern over delivered files) -> no matches
```

Total 150/150 across the eight backend suites. Full output in `docs/horizon/evidence/h08/verification.log`.

## 3. TDD record

Red (captured live, full log at docs/horizon/evidence/h08/red-run.log):

```
node --test backend/test/research-state.test.cjs -> exit 1
# Error: Cannot find module '../src/features/research/research.service'
```

The red log is produced from an isolated scratch copy of `backend/` with the six new modules removed (symlinked node_modules, real failure, exit 1); the workspace itself was never modified by that probe. The original first red run predated creation of the evidence directory, so its transcript was not durably captured — this scratch reproduction is the honest equivalent and its provenance is disclosed here.

Tests written first. Green: implementation added, suite rerun -> exit 0, 24/24.

First green iterations exposed 4 failures, each diagnosed once (no blind retries), all author test-fixture errors, none implementation-logic changes:
1. Tests 17/20 completed success runs via `completeRun`, which correctly persists no assessment — rewritten to drive `recordRunResult`, the actual assessment-creating path.
2. Mongoose schema probes omitted required fields (`run_input_ref`, snapshot `run_id`/`created_at`, checkpoint `_id`).
3. Checkpoint kind invariants were initially in a `pre('validate')` hook whose errors do not surface through `validateSync` — moved to path validators (equivalent enforcement, now observable at document level).
4. Test asserted `parsed.lease_nonce === undefined` on a passthrough zod parse (it is `null`); corrected the assertion.

## 4. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Persisted idempotency, duplicate claim, owner isolation, revision superseding, checkpoint change tests | `backend/test/research-state.test.cjs` written first | red-run.log, §3 |
| Immutable assessment/snapshot references, exact position revisions, separate last-success/latest-attempt | `research_assessment.model.js` (immutable fields, unique run_id, `artifact_kind: 'judgment'`), `research_snapshot.model.js` (immutable run-input reference, payload digest), run `position_revision` immutable + `REVISION_CONFLICT` publication guard, `getPositionResearchState` | tests 2, 13, 14, 16, 17, 21, 23 |
| Atomic claims/idempotency, immutable run input/result refs, heartbeat/deadline/stalled, safe restart recovery | `research.service.js` `queueRun` (canonical payload digest, persisted idempotency, active-run rule), `claimRun` (CAS `claimQueued`, `lease_nonce`/`lease_expires_at` materialized), `heartbeatRun`, `completeRun` invariants + deadline enforcement, `recoverAbandonedRuns` (running→stalled `RUN_STALLED`, queued→superseded, idempotent) | tests 1, 5, 6, 7, 8, 9, 14, 15, 16 |
| Isolated read/run router | `research.routes.js` `createResearchRouter` (GET latest, GET assessments, POST runs w/ Idempotency-Key, GET run) — owner derived from `req.user._id`, cross-owner 404 indistinguishable, `lease_nonce` stripped from public views | test 24 |

## 5. Acceptance mapping

| Acceptance | Where proven |
|---|---|
| Concurrent callbacks cannot create duplicate assessments or cross-owner writes | test 9 (`Promise.all` two deliveries → exactly 1 assessment, loser idempotent), test 10 (replay idempotent), test 12 (`OWNER_DENIED`, no trace), backed by unique `run_id` index; test 11 binding conflicts (revision/snapshot/instrument) |
| Prior judgments identified as judgments; triggered/retired/replaced checkpoints retain history | `artifact_kind: 'judgment'` + `buildChangesSincePrevious` → `{artifact_kind: 'judgment', is_evidence: false}` (test 20); checkpoint history append-only with previous/new status, trigger→replace→retire transitions and terminal-state guard (tests 18, 19) |
| Crashed/expired run becomes stalled or recoverable, never forever running | `recoverAbandonedRuns` stalls expired running runs (`RUN_STALLED`), supersedes expired queued runs, idempotent, untouched healthy runs (test 15); fresh-service restart recovery (test 16); completion after deadline refused `RUN_DEADLINE_EXCEEDED` (test 8) |

## 6. Key decisions

- **H03 lease interface materialized** (per release note + `docs/horizon/evidence/h03-quality.md` observation 3): `lease_nonce` / `lease_expires_at` are nullable fields on the run model, set only by an atomic queued→running claim; the H03 authorizer's fail-closed behavior for absent fields is preserved (queued runs carry `null`).
- **Superseding policy**: queueing a run at a newer position revision explicitly supersedes older incomplete runs of the same position (status `superseded` with `finished_at`); completing a superseded run is `REVISION_CONFLICT` — publication against stale economics is impossible.
- **Idempotency digest** is computed over a recursively key-sorted canonical serialization, so replay detection is byte-stable.
- **Fail-closed snapshot binding**: result delivery verifies snapshot existence and instrument match through an injected `evidenceSnapshotLookup`; when the integration lane has not wired it, delivery is refused (`SNAPSHOT_CONFLICT`), never trusted.
- **Public API hygiene**: router views strip `lease_nonce`; error codes map to the §9 status table (400/403/404/409), cross-owner reads are indistinguishable 404.

## 7. Limitations (not passed here, explicitly deferred)

- **Storage-layer behavior unproven against a live MongoDB**: unique/partial-unique indexes (`{owner, position, idempotency_key}` unique; one-active-run partial filter), `findOneAndUpdate` CAS and `updateMany` are implemented in the Mongoose repositories but only the in-memory repositories and `validateSync` document probes were executed. Live-index/persistence checks belong to the integration lane (H15/H17), per hermetic-tests-only scope.
- **Router not mounted**: isolated router only; `app.js` mounting is the H15 lane's single-ownership file.
- **Automation endpoints** (`/automation/research/runs/:id/...`, §9) are the H09/H10 boundary; H08 provides the run state, lease fields and result-recording service those endpoints call.
- **Deep assessment-schema validation** (`researchAssessmentSchema.parse`) of delivered results is the H09 result-validation boundary (422); H08 validates binding fields (run binding, revision, snapshot, status enum, ownership) and stores the assessment payload immutably.
- Node v22.22.2 host ≠ deployment runtime; runtime compatibility remains a release-gate concern. No Flutter surface in this package — nothing deferred to the PC for H08 itself.
- Generalized stage replay/recovery is H09X per the canonical package; `retry_count` is persisted but no automatic retry loop is implemented here.
