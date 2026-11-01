# H08 — Durable run state, evidence snapshots and thesis memory — Combined Independent Review

- Task: t_a24089d1 (reviewer), delivery_phase: core_source, scope: source-only backend
- Reviewer: `reviewer/deepseek-v4-pro`. Author lane: `worker` (zai/glm-5.3-flash per author handoff; roster note in card lists zai author, deepseek reviewer — vendor-disjoint).
- Author delivery: t_4c2206e0 (controller-verified delivery-only closure).
- Date: 2026-10-31

## Verdicts

- **SPEC: `SPEC_PASS_SOURCE_ONLY`**
- **QUALITY: `QUALITY_FAIL_SOURCE`** — one blocking finding (F1), four non-blocking observations.

Rationale for the split: all three canonical acceptance criteria and every enumerated review-scope item are met and independently re-verified at source scope (see below). One internal model/service contract inconsistency (F1) is a real defect that will produce a live-storage failure on a path the author's own test asserts as success, and weakens the snapshot instrument-binding check — a robustness/correctness defect that fails QUALITY independent of the acceptance criteria.

---

## F1 (blocking) — `instrument_id` is required by the snapshot/assessment models but nullable through `queueRun`

- `backend/src/features/research/research.service.js:441-443` — `queueRun` computes `instrumentId = typeof request.instrument_id === 'string' && request.instrument_id ? request.instrument_id : null`, so an instrument-less queue produces a `null` instrument.
- `backend/src/features/research/research_snapshot.model.js:16` — `instrument_id: { type: String, required: true, immutable: true }`.
- `backend/src/features/research/research_assessment.model.js:19` — `instrument_id: { type: String, required: true, immutable: true }`.
- `backend/src/features/research/research.routes.js:113` — passes `instrument_id: body.instrument_id` through unvalidated.
- `backend/test/research-state.test.cjs:1009-1022` (test 24) — POSTs a run body with **no** `instrument_id` and asserts `202`.

Consequences:

1. At the live MongoDB layer, `queueRun` with no `instrument_id` creates a snapshot with `instrument_id: null`, which the snapshot model rejects (`required: true` rejects `null`), throwing a raw Mongoose `ValidationError` that the repository's `create` catch (11000/`MongoServerError` only, `research.service.js:276-283`) does not translate — surfacing as an untyped 500. The author's route test asserts `202` for this exact request, encoding behavior that contradicts the author's own model schema.
2. `recordRunResult` (`research.service.js:692-695`) skips the snapshot-instrument mismatch check when either side is null (`if (snapshot.instrument_id && boundInstrument && …)`), so an instrument-less run would also bypass the §8 "callback binds … snapshot" instrument-binding guard; the assessment `instrument_id: boundInstrument` would likewise be `null` against a `required: true` model field.

The contract (CONTRACTS §4 `EvidenceSnapshot`, §5 `ResearchAssessment`, and the accepted H04/H06/H07 lineage) requires `instrument_id` on snapshots and assessments. The service, route, and one test must be made consistent with the models — the minimal fix is to reject a queue without a non-empty `instrument_id` at `queueRun` (`INVALID_INPUT`), and to update test 24 to send an instrument (or assert the rejection). Alternatively the models must be relaxed, but that contradicts the §4/§5 contract shape, so requiring it is the contract-consistent resolution.

This is H08-owned (all four files are in H08's canonical package), not an integration-lane dependency.

---

## Non-blocking observations (do not gate; record for the integration lane)

- **O1 — orphaned snapshot on lost create race.** `queueRun` writes the snapshot (`research.service.js:456`) before the run `create` (`:496`). If the run create loses a concurrent idempotency race (`DUPLICATE_RUN`), the just-created snapshot is orphaned (its `run_id` never materializes). Not a correctness/security violation (no duplicate run, no cross-owner write), but a data-hygiene leak. Transactional snapshot+run write is an integration-lane concern.
- **O2 — `session_as_of` coerced to `null`.** `recordRunResult` (`research.service.js:714`) stores `session_as_of: typeof result.session_as_of === 'string' ? … : null`, while the assessment model requires a non-null `String`. Fails closed at live Mongo (ValidationError), and deep 422 validation is explicitly H09's boundary — acceptable, but the service should not silently normalize an absent required field to `null`.
- **O3 — `completeRun` does not verify `evidence_snapshot_id`/`assessment_id` existence.** `completeRun` (`research.service.js:620-637`) records reference strings without the `evidenceSnapshotLookup` existence check that `recordRunResult` performs. Asymmetry is disclosed ("automation's own completion path"); the assessment-creation path (`recordRunResult`) is the one that enforces binding. Acceptable for H08, but the automation lane must not treat `completeRun` references as verified.
- **O4 — lifecycle ops not owner-parameterized.** `claimRun`/`heartbeatRun`/`completeRun` operate on `run_id` alone; owner binding for these is the H03 `createRunCallbackAuthorizer`'s responsibility at the automation route layer (not exposed via the 4-endpoint public router). Consistent with the H03 contract and the accepted `h03-quality.md` observation; the "delivery" path (`recordRunResult`) does enforce `caller_owner_id === run.owner_id_internal` (`research.service.js:658-660`), which is the acceptance-criterion owner binding.
- **O5 — `idempotency_key` capped at 160 by `assertOwnerScopedId` (`research.service.js:405`), while the model/zod cap is 255.** Over-restriction only; a 161–255-char key is rejected as `INVALID_INPUT`. Minor.

---

## Acceptance-criteria verification (independent, source + runtime)

| Acceptance | Verdict | Evidence |
|---|---|---|
| Concurrent callbacks cannot create duplicate assessments or cross-owner writes | **MET** | unique `{run_id}` index (`research_assessment.model.js:34`); `recordRunResult` owner check → `OWNER_DENIED` (`service.js:658-660`); concurrent `Promise.all` → exactly 1 assessment, loser idempotent (test 9); replay idempotent (test 10); cross-owner denied with no trace (test 12) |
| Prior judgments identified as judgments; triggered/retired/replaced checkpoints retain history | **MET** | `artifact_kind: 'judgment'` immutable (`research_assessment.model.js:24`); `buildChangesSincePrevious` → `{artifact_kind:'judgment', is_evidence:false}` (`service.js:984-992`, test 20); append-only `history` with previous/new status, terminal guard (`thesis_state.model.js`, `service.js:911-948`, tests 18-19) |
| Crashed/expired run becomes stalled or recoverable, never forever running | **MET** | `recoverAbandonedRuns` stalls expired running → `RUN_STALLED`, supersedes expired queued, idempotent, healthy untouched (`service.js:763-787`, tests 15-16); completion after deadline refused `RUN_DEADLINE_EXCEEDED` (`service.js:601-605`, test 8) |

## Enumerated review-scope items

- Run lifecycle states (queued→running→succeeded/limited/failed/stalled/superseded) — verified in model enum + service transitions.
- `lease_nonce` CAS claim + fail-closed — `claimQueued` is `findOneAndUpdate({_id, status:'queued'})` (`service.js:141-147`); `lease_nonce`/`lease_expires_at` materialized on claim only (`service.js:545-553`), nullable `null` on queued (H03 release-gate observation 3 closed).
- Idempotency via canonical payload digest — `canonicalize` key-sorted recursive serialization (`service.js:26-38`); same key+payload → replay, same key+different payload → `IDEMPOTENCY_CONFLICT` (tests 1-2); persisted across restart (test 1).
- Revision supersession — newer revision supersedes older incomplete runs (`supersedeStale`, `service.js:524-530`); superseded run cannot publish (`REVISION_CONFLICT`, test 14).
- `recoverAbandonedRuns` stall/supersede idempotency — tests 15-16.
- Concurrent callback dedup — test 9.
- Assessment immutability / `artifact_kind` judgment / `is_evidence` false — tests 20, 23.
- Append-only checkpoint history — tests 18-19.
- Isolated router (4 endpoints, owner from `req.user`, `lease_nonce` stripped) — `research.routes.js:35-40, 61-134`, test 24.

## Independent reproduction (not author self-report)

Host: Node v22.22.2, `/home/ubuntu/apps/Horizon`, hermetic/offline, no DB/network.

- `node --test backend/test/research-state.test.cjs` → **24/24 pass, exit 0** (re-run independently).
- Predecessor regression (independently re-run): research-contracts 14/14, research-metrics 24/24, research-evidence 19/19, research-auth 6/6, market-history 12/12, research-history-integration 11/11, positions 41/41.
  - Positions grew from the author's 40 to 41 during this review: `backend/test/positions.test.cjs` (21:52:59) and `backend/src/features/positions/position.service.js` (21:53:28) were being modified by a concurrent lane mid-review (a transient 1-fail was observed and self-resolved to 41/41 green). Not attributable to H08; H08 touches no positions file.
- `sha256sum` of all 7 delivered files → **matches the author's recorded hashes exactly** (5f7325de…, 582db67a…, a386f579…, 058e451d…, 7478a5c0…, cb232634…, 103b311d…). No drift since delivery.
- Secret-pattern scan (AKIA/sk-/private-key/BEGIN PRIVATE KEY/password/api_key/secret/Bearer-token/mongodb-credential) across all 7 delivered files → **no matches**.
- `git diff --check` → clean, exit 0. `git status --porcelain` → H08 paths are untracked (`?? backend/src/features/research/`, `?? backend/test/`); tracked modifications (`app.js`, `env.js`, `briefing.*`, `scheduler.js`) are other lanes' concurrent activity, none H08-owned. No commit/push/reset/clean; baseline preserved.

## Deferred / unexecuted criteria (explicit — never PASS from source)

- **Live-Mongo storage behavior** (unique/partial-unique indexes, `findOneAndUpdate` CAS, `updateMany`, real required-field rejection of `instrument_id: null`) → not exercised; in-memory repositories + `validateSync` probes only. This is also where F1's 500 would manifest. Integration lane (H15/H17).
- **Router mounting in `app.js`** → H15 single-ownership file; isolated router only.
- **Automation endpoints** (`/automation/research/runs/:id/…`, §9) and the H03 authorizer's live lease-nonce verification → H09/H10 boundary.
- **Deep assessment-schema validation** (`researchAssessmentSchema.parse`, 422) → H09 boundary.
- **Node v22.22.2 host ≠ deployment runtime**; runtime compatibility is a release-gate concern.
- **Flutter/device/APK** → N/A for this package (no Flutter surface); nothing deferred to the Dev PC for H08 itself.

## Baseline / invariant compliance

No secrets in output/logs/fixtures. No `.env` or credential-store read. No ports/DNS/tunnel changes. No shell backgrounding. No commit/push/history rewrite. Observed market data untouched; no invented prices/candles (H08 has no market-data surface). Only the 7 canonical files + evidence were produced; `contracts.js` (pre-existing, H01-owned) and `app.js` were not modified by H08. Reviewer modified no source; wrote only this evidence file.

---

# Targeted re-review (2026-10-31, ~22:10) — F1 + O2 repair

Repair lane: t_66520884 (author). This section records the independent re-verification of the blocking F1 and same-class O2 only; the FAIL history above is preserved for audit and O1/O3/O4/O5 remain with the integration lane, unchanged.

## Re-review verdicts

- **SPEC: `SPEC_PASS_SOURCE_ONLY`** (unchanged — no specification surface was touched by the repair).
- **QUALITY: `QUALITY_PASS_SOURCE_ONLY`** — F1 and O2 both resolved; no new findings introduced.

## F1 — RESOLVED (independently verified)

- `queueRun` now requires `instrument_id` via `assertOwnerScopedId(request.instrument_id, 'instrument_id')` (`research.service.js:409`), throwing `INVALID_INPUT` **before any write** — no snapshot (`:457`) and no run (`:497`) is persisted on a rejected queue. The prior null coercion is gone.
- Snapshot-binding is strict with no null-bypass: `if (snapshot.instrument_id !== boundInstrument) throw SNAPSHOT_CONFLICT` (`research.service.js:697-700`). Both sides are non-null at creation (queue requires it; models `required: true`), so a null on either side is itself a mismatch.
- Models byte-identical to original delivery (`research_snapshot.model.js` `a386f579…`, `research_assessment.model.js` `582db67a…`) — `instrument_id`/`session_as_of` `required: true` preserved; the service conforms to the models, never the reverse.
- `research.routes.js` intentionally unchanged (`cb232634…` matches original) — forwards `instrument_id` to `queueRun`, which enforces the requirement at the service boundary (no duplicate route-level check needed).
- Test 24 (router) reworked: instrument-less POST now asserts **400** with `code === 'INVALID_INPUT'`; happy-path queue/replay bodies carry `instrument_id`. New service-level test (`research-state.test.cjs:320-333`) rejects `undefined`/`null`/`''` and asserts **no orphan run and no orphan snapshot** persisted.

## O2 — RESOLVED (independently verified)

- `recordRunResult` now rejects absent/non-string `session_as_of` as `INVALID_INPUT` (`research.service.js:704-710`) **before any write**; `create` stores `session_as_of: result.session_as_of` directly (no silent null). Deep date-shape validation stays at H09's boundary per the review's own scoping.
- New test (`research-state.test.cjs:530-555`) covers `undefined`/`null`/`42` and asserts no assessment persisted and the run stays `running`.

## Status-code adjudication — 400 is correct

CONTRACTS line 192 distinguishes `400 malformed request` from `422 invalid researched result`. An instrument-less queue is a malformed request, so `INVALID_INPUT → 400` (the router's existing `ERROR_STATUS` map) is correct; the repair card's `(422)` wording was wrong, and the repair correctly kept 400 rather than silently following it.

## Independent reproduction (reviewer, Node v22.22.2, hermetic/offline)

- `node --test backend/test/research-state.test.cjs` → **26/26 pass, exit 0** (independently re-run; grew 24 → 26).
- `node --test backend/test/*.test.cjs` → **153/153 pass, exit 0** (independently re-run).
- SHA-256 of the two changed files match the repair's records exactly: `research.service.js` `cffd2caf…`, `research-state.test.cjs` `029f9051…`. Routes and both models unchanged (hashes above match the original delivery), confirming the allowlist was honored.
- `git diff --check` → clean, exit 0.
- Red-first evidence in `h08-repair.md:29-46` is genuine: the pre-repair route returned `202 !== 400` for the instrument-less POST, reproducing the review's core defect verbatim.

## Remaining limitations (unchanged, not re-scoped)

Live-Mongo required-field/index behavior, router mounting, automation endpoints and the H03 authorizer lease verification, and deep assessment-schema validation remain integration-lane (H15/H17/H09/H10) deferred; O1/O3/O4/O5 remain with the integration lane. Nothing here is a runtime/release acceptance.
