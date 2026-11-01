# H10 combined independent review — specification + quality

- Reviewer: `reviewer` (deepseek-v4-pro). Author: `worker` (zai/glm-5.3-flash, continuation). Vendor-disjoint.
- Date: 2026-11-01. Scope: source-only; H10 package contract (thin n8n trigger/poll/delivery + bounded run worker).
- Author delivery verified via continuation `t_2f4f4574`; this is independent acceptance, not a re-run of author claims.

## Verdict

| Verdict | Result |
|---|---|
| SPEC | **SPEC_PASS_SOURCE_ONLY** |
| QUALITY | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts pass at source-only scope. Every unexecuted runtime/PC criterion is listed in Limitations. No source was repaired; no cards created; no delegation.

## Independent checks run (all reproduced by reviewer, node v22.22.2)

1. **SHA-256 of the 4 canonical files** — all match author hashes:
   - `automation.routes.js` `5621771f…be7f`
   - `run_worker.js` `65e41c55…c816`
   - `research-workflow.test.cjs` `c23be153…b67b`
   - `n8n-workflow.json` `58a83741…7967` (baseline, unchanged)
2. **research-workflow suite**: `node --test test/research-workflow.test.cjs` → exit 0, **25/25**.
3. **Full 11-suite aggregate**: `node --test test/market-history… test/research-workflow.test.cjs` (11 suites, explicit list) with URL-shaped placeholder env → exit 0, **223/223**.
4. **history-integration env gate**: passes **11/11** with `MONGODB_URI=mongodb://…invalid…` placeholder (zod requires a URL-shaped value; a bare word yields "Invalid URL"). Hermetic — no Mongo connection, no `.env` read, no real credential.
5. **`git diff --check`** → clean (exit 0).
6. **Poll-loop structural adjudication** independently recomputed from `n8n-workflow.json` (14 nodes / 16 edges): `Poll Run Status` feeders = `[Polling Required?, Wait Between Polls]`; `Wait Between Polls` feeders = `[Poll Budget Remaining?]`; no self-loop; budget gate `poll_count < 60` present; 30 s wait node present; no node named `Poll Budget Gate`. The author's test-side-only fix is **correct** (the old assertion referenced a nonexistent node).

## Contract fidelity (source-level, independently traced)

- **§8 leases / idempotency / claims**: `run_worker.beginRun` claims once per run id via `researchService.claimRun` (atomic `claimQueued` CAS in H08 `research.service.js`); an already-claimed/terminal run replays persisted status, never re-claims. Concurrency is suppressed by a synchronous in-flight map registered before the first `await` on the claim. `queueDailyUpdateRuns` keys `daily_update:<UTC-date>:<position_id>` and reuses H08 `queueRun` persisted idempotency. Verified by tests: duplicate-schedule, concurrent-execute, terminal-replay, restart-replay.
- **§8 deadlines/stalls**: expired-queue claim refused up front (`deadline_at <= now`) → `recoverAbandonedRuns` supersedes; post-deadline synthesis completion records a stall (`DEADLINE_EXCEEDED` → recovery `RUN_STALLED`), never a fake success; `toStatusView` exposes `heartbeat_at`/`deadline_at` honestly and strips `lease_nonce`/`owner_id_internal`/`request_payload`. Verified by deadline/stall/no-success-rewrite tests.
- **§9 automation surface**: scoped service identity (not a user JWT, not the n8n key) via `createAutomationMiddleware`; server-derived owner binding (`loadOwnedRun` + `caller_owner_id` from `req.automation.ownerId`/run, never body `userId`); run-bound lease nonce on callbacks (H03 `createRunCallbackAuthorizer`, constant-time compare, lease-expiry fail-closed); `202 accepted`/`200 replay`/`409 conflict`/`422 INVALID_RESULT` status map matches CONTRACTS §9 (L186–192). Cross-owner and missing ids are indistinguishable 404. Verified by authz/scope/cross-owner/nonce/422 tests.
- **Interface wiring**: `run_worker` → H08 `ResearchService` (`claimRun`/`recordRunResult`/`completeRun`/`recoverAbandonedRuns`/`queueRun`) and → H09 `runMarketSynthesis` envelope and → `result_validator.validateAssessmentDelivery` all match signatures. `automation.routes` → H03 middleware/authorizer matches (authorizer reads `run.lease_nonce`/`lease_expires_at`, present in the H08 `fromDoc` projection). No literal credential anywhere; the test `authorization` header is `` `Bearer ${crypto.randomBytes(32)}` `` (random per-test; a Hermes output-redaction artifact renders it `***` in tool dumps — confirmed via `od -c`).

## Findings

### F1 — poll budget counter is functionally inert in `n8n-workflow.json` (NON-BLOCKING, pre-existing baseline)

`Classify Poll Result` computes `poll_count: (previous.poll_count || 0) + 1` where `previous = $('Normalize Execute Response').item.json`. That node runs once at workflow start and emits `poll_count: 0`; its output never changes across loop iterations, and the `Poll Run Status` HTTP response does not carry `poll_count` back. Consequently `poll_count` is recomputed as `0 + 1 = 1` on every iteration — the `Poll Budget Remaining?` gate (`poll_count < 60`) never trips and `Mark Poll Timeout` is unreachable.

Effect: the "bounded 60× poll" budget is **structurally present but operationally decorative**. The loop's real termination bound is (a) the run reaching a terminal status — guaranteed by H10's Node-side deadline→stall, which is correct and tested — plus (b) the 30 s `Wait Between Polls` floor. It is not a tight spin loop.

Why non-blocking: the file is operator-owned baseline (`existing_files`), byte-identical this run (hash verified) and correctly left untouched; the H10 acceptance criterion "unbounded 422 loop" concerns the backend delivery path, which is correctly deterministic/bounded. H10's own new files correctly implement the run-lifecycle boundedness.

Action: flag to the orchestrator. `n8n-workflow.json` is in **H10X**'s `existing_files`; the counter should be re-keyed to the loop item (or carried through the wait node) in that follow-up. The author's `h10/poll-loop-adjudication.md` claim "bounded 60× poll" overstates the counter's effectiveness and should be corrected to "structurally bounded; counter currently inert — termination via terminal status + wait floor".

### O1 — daily idempotency key excludes `position_revision` (NON-BLOCKING)

`queueDailyUpdateRuns` keys `daily_update:<date>:<position_id>`. A same-day revision bump replays the stale run rather than queueing a fresh run for the new revision. Consistent with "one run per position per UTC day", but a mid-day revision change is not re-researched until the next day. Edge case; helper is not yet wired to any cron.

### O2 — no autonomous recovery sweep wired (NON-BLOCKING, per contract deferral)

`recoverExpiredRuns` is exposed but no cron/scheduler invokes it; stalls/supersedes materialize lazily (on next claim attempt or explicit sweep). Matches the card's explicit deferral ("advanced scheduler/leader redesign is H10X"; "preserve existing scheduler behavior outside this scope"). A truly-stuck run would stay `running` until a sweep runs.

### O3 — router not yet mounted (NON-BLOCKING, integration lane)

`createAutomationRouter` is not mounted in `app.js`. Its `runs` repository and the worker's `runLookup` must resolve to the same store in production (both are injected; the test harness wires them consistently). Wiring is H15's responsibility ("Mount automation router and bounded run worker").

## Concurrent-lane observation (not a blocker for H10)

`backend/test/research-panel-integration.test.cjs` (H15B lane, created 08:17 — after the controller's 223/223 verification at 08:11) currently has 5 failing tests, all tagged `H15B:`. It is outside H10's file ownership. H10's own suite (25/25) and the 11-suite aggregate (223/223) remain green; flagging only so the controller is aware the aggregate glob now spans 12 suites with a red sibling lane file.

## Limitations (explicitly unexecuted → not PASS)

- No live n8n instance, no workflow publication, no MongoDB, no live model calls, no production access. Coordinated deployment / live workflow comparison remain **operator release gates**.
- No Flutter analysis/tests/device/APK in this package — n/a to H10; any runtime/PC criterion is `DEFERRED_TO_DEV_PC`, not PASS.
- Source-only acceptance is not runtime or release approval.

## Conclusion

H10's deliverable (leases, duplicate suppression, deadline→stall honesty, bounded deterministic 422 delivery, server-derived owner binding, thin-n8n/fat-Node separation) is correct, contract-faithful and independently test-verified (25/25 workflow, 223/223 aggregate). No blocking defect in H10's own files. F1 is a real defect in operator-owned baseline (`n8n-workflow.json`) with a clear H10X owner — recorded, non-blocking for this gate.
