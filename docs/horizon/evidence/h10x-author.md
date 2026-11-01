# H10X author evidence — advanced scheduler recovery and leadership

- Author package: H10X — follow-up: advanced scheduler recovery and leadership
  (leader-gated bounded tick, autonomous recovery sweep, bounded retry; plus the
  carried H10 review F1 poll-counter re-key).
- Author: `worker` (deepseek-v4-pro). Reviewer: `reviewer` (zai/glm-5.3-flash,
  vendor-disjoint). Scope: source-only, hermetic; no live n8n/Mongo/model calls,
  no service lifecycle or publication, no credentials read or written.
- Changed paths this run (only these; nothing else was written):
  1. `backend/src/features/research/run_worker.js` — ADDED `createInMemoryLeaderLease`
     and `createResearchScheduler` (+ exports). +135 lines vs HEAD.
  2. `n8n-workflow.json` — re-keyed `Classify Poll Result` poll counter to the loop
     item (1 jsCode line only; graph/nodes/edges/connections byte-identical).
  3. `backend/test/research-scheduler.test.cjs` — NEW, 8 tests (lease ownership,
     process restart, bounded retry, idempotent daily queueing).
  4. `docs/horizon/evidence/h10/poll-loop-adjudication.md` — corrected overstated
     "bounded counter" wording; appended the H10X F1 re-key note.
  5. `docs/horizon/evidence/h10x/` — this doc + `green-run.log` + `aggregate-run.log`.
- Preserved (untouched): `backend/src/utils/scheduler.js` (dirty briefing-scheduler
  baseline), all other dirty/untracked files from the H07A/H09X/H16 baseline.

## Canonical files (SHA-256, bytes)

| Path | SHA-256 | Bytes |
|---|---|---|
| `backend/src/features/research/run_worker.js` | `0d17393c4cab3437f428d5c9ca4c1e1a576af55902be50053cb2e848d3efc488` | 19497 |
| `n8n-workflow.json` | `8bf6742e80589b9da2c11b1f30f5afde33337739596c5d0087670743ee7585a5` | 15110 |
| `backend/test/research-scheduler.test.cjs` | `dc2a359dbccd812d887010cab81e83d5969c8bac710b654723b30bb110ad60a2` | 15884 |
| `docs/horizon/evidence/h10/poll-loop-adjudication.md` | `2bb46ec05e0580fae110a6cea33b948c649613a3d9b49cb447b8ae45cdc1a6f6` | 4614 |

## Red → green (write tests first, implement, rerun)

1. **RED** — `node --test test/research-scheduler.test.cjs` against the baseline
   `run_worker.js` (HEAD, pre-implementation): **7/8 fail, exit 1**, first failure
   `TypeError: createInMemoryLeaderLease is not a function` (the scheduler factory and
   leader lease did not exist). The one "pass" is the constructor-validation test,
   which asserts a TypeError is thrown for a missing service — it also throws when the
   factory is undefined, so it is not a false green for the feature.
2. **IMPLEMENT** — added `createInMemoryLeaderLease` + `createResearchScheduler` to
   `run_worker.js`; re-keyed the n8n poll counter.
3. **GREEN** — `node --test test/research-scheduler.test.cjs` → **8/8 pass, exit 0**
   (`docs/horizon/evidence/h10x/green-run.log`).

## Commands, exit codes and results (node v22.22.2)

- `node --test test/research-scheduler.test.cjs` (cwd `backend/`) → **exit 0, 8/8**.
- `node --test test/research-scheduler.test.cjs test/research-workflow.test.cjs` → **exit 0, 33/33**
  (8 scheduler + 25 H10 workflow; the modified `n8n-workflow.json` still satisfies
  the no-self-loop / feeder-set / no-credential structural tests).
- `MONGODB_URI='mongodb://placeholder.invalid/horizon' JWT_SECRET='hermetic-placeholder' node --test 'test/*.test.cjs'`
  (cwd `backend/`) → **exit 0, 365/365** across all suites
  (`docs/horizon/evidence/h10x/aggregate-run.log`). No real credential; URL-shaped
  placeholder only (zod env gate). No `.env` read.
- `git diff --check` → **exit 0** (clean).
- `git diff n8n-workflow.json` → exactly one changed line (the `Classify Poll Result`
  `jsCode`); 14 nodes / 16 edges and all feeder sets unchanged.

## Contract mappings

- **CONTRACTS §8 "advanced scheduling is H10X"** + **SPEC §5 "advanced scheduler
  leadership redesign H10X; no new queue service"** → `createResearchScheduler` is a
  pure factory over injected `researchService` (reuses H08 `queueRun`/`recoverAbandonedRuns`),
  a `positions` provider, and a `leadership` lease store — no new queue service, no new
  model, no service lifecycle.
- **SPEC (replan) "one scheduler leader/lease prevents replica duplicates; avoid
  N×15-minute uncontrolled delay"** → `runTick` acquires the named leader lease before any
  side effect and returns `{leader:false}` for a non-leader; a crashed leader's lease
  lapses by TTL and a peer takes over. The tick sweeps + queues atomically (persisted
  idempotency) instead of in-process `setTimeout` stagger.
- **H10 review O2 (no autonomous recovery sweep wired)** → `runTick` invokes
  `researchService.recoverAbandonedRuns()` every leader tick, so a truly-stuck `running`
  run is stalled / an expired `queued` run superseded without a manual trigger.
- **Acceptance "no unbounded delay chain"** → `runScheduledTick` retries a failed tick a
  bounded `maxTickRetries` (default 2) then surfaces the last error; recovery never
  auto-re-queues (stall/supersede only), preserving H08/H10 no-infinite-retry semantics.
- **H10 review F1 (n8n poll counter inert)** → `Classify Poll Result` now re-keys
  `poll_count` to the loop item carried through `Wait Between Polls` (seeded from
  `Normalize Execute Response` on the first poll), so `poll_count < 60` is operational
  and `Mark Poll Timeout` reachable; wording corrected in `poll-loop-adjudication.md`.

## Acceptance checklist

- **No duplicate model execution/deliveries from competing leaders:** one leader per
  tick (lease CAS) + persisted idempotency (H08 `queueRun` key, atomic `claimRun`).
  Verified by `leader lease: exactly one replica runs the tick…` (recovery+queue run
  exactly once across two replicas) and `non-leader tick performs zero side effects`.
- **No unbounded delay chain:** bounded retry (`bounded retry` tests, 3 attempts max),
  TTL-bounded takeover (`process restart` + `in-memory leader lease re-acquirable only
  after TTL expiry`), no auto-re-queue (recovery stalls/supersedes).
- **Preserve baseline + bounded timeout/stall semantics:** `scheduler.js` untouched;
  `run_worker` deadline→stall and `queueDailyUpdateRuns` idempotency unchanged; the
  n8n graph is byte-identical apart from the one re-keyed `jsCode`; `n8n-workflow.json`
  differs only in `Classify Poll Result`.

## Limitations (explicitly unexecuted → not PASS)

- **Hermetic/source-level only.** No live n8n instance, no workflow publication, no
  MongoDB, no live model calls, no production access. Live publication / coordinated
  deployment / live workflow comparison remain operator-only release gates.
- **Cron/service wiring is H15** (same lane as H10 review O3 "router not yet mounted"):
  the scheduler exposes `runTick`/`runScheduledTick` only; no `node-cron` schedule is
  started here.
- **Leader lease is a single-process reference** (`createInMemoryLeaderLease`, CAS via
  an injected clock). A multi-replica deployment needs a Mongo-backed CAS lease with the
  same `tryAcquire`/`release` contract (H15 production wiring).
- **n8n poll counter re-key is correct for the single-run poll path** (the common
  per-run execute→poll→deliver trigger). A multi-run batch still carries the first
  item's count across `Wait Between Polls` — a pre-existing batch-semantics edge; the
  hard termination bound (Node deadline→stall + 30 s wait floor) is unaffected, so no
  unbounded poll is possible regardless.
- **No run-level re-queue retry added:** recovery stalls/supersedes (never auto
  re-queues). `retry_count` (max 2) remains schema-declared but un-incremented; the
  bounded retry implemented here is at the scheduler-tick level. This preserves the
  accepted "stall, don't infinitely retry" semantics.
- **H10 review O1** (daily idempotency key excludes `position_revision`) left as-is to
  preserve "one run per position per UTC day" baseline; recorded, out of this card's
  scope.
- Flutter/runtime/PC criteria are `DEFERRED_TO_DEV_PC` — none attempted; source-only
  acceptance is not runtime or release approval.
