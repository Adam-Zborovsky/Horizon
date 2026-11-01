# H10X — Combined independent specification and quality review

- **Card:** H10X — Follow-up: advanced scheduler recovery and leadership (`t_bff36241`)
- **Reviewer:** `reviewer` (zai / glm-5.3-flash). Author: `worker` (deepseek-v4-pro) — vendor-disjoint per H10X invariants.
- **Date:** 2026-11-01. Workspace: `/home/ubuntu/apps/Horizon` (existing dirty main baseline preserved; no commits, no source edits by the reviewer).
- **Scope:** one combined independent review, separate SPEC and QUALITY verdicts. Source-only: no live n8n, no MongoDB, no model calls, no publication, no service lifecycle, no Flutter/PC checks. Historical findings (H10 F1/O1/O2/O3, H08, H09X) preserved and referenced, not rewritten.
- **Evidence written by this review:** `docs/horizon/evidence/h10x-review.md` (this file) + sanitized rerun log `docs/horizon/evidence/h10x/review-reruns.log`. All source allowlists read-only.

## 1. Independent verification (all executed by this reviewer; see `h10x/review-reruns.log`)

| # | Check | Command (real) | Result |
|---|---|---|---|
| V1 | Canonical hashes | `sha256sum` + `wc -c` on the 4 H10X paths | **4/4 match** the author table exactly (`0d17393c…`, `8bf6742e…`, `dc2a359d…`, `2bb46ec0…`; sizes 19497 / 15110 / 15884 / 4614) |
| V2 | n8n graph isolation | `git diff n8n-workflow.json` line counts | **added=1, removed=1** — only `Classify Poll Result` `jsCode`; 14 nodes, connections otherwise byte-identical |
| V3 | scheduler.js baseline | `git diff backend/src/utils/scheduler.js` | **empty** — dirty briefing-scheduler baseline untouched |
| V4 | Whitespace hygiene | `git diff --check` | exit 0 |
| V5 | Scheduler suite | `node --test test/research-scheduler.test.cjs` (cwd `backend/`, node v22.22.2) | **8/8 pass, exit 0** |
| V6 | Scheduler + n8n structural suite | `node --test test/research-scheduler.test.cjs test/research-workflow.test.cjs` | **33/33 pass, exit 0** — the re-keyed workflow still satisfies no-self-loop / feeder-set / no-credential tests |
| V7 | Full backend aggregate | `MONGODB_URI='mongodb://placeholder.invalid/horizon' JWT_SECRET='hermetic-placeholder' node --test 'test/*.test.cjs'` | **365/365 pass, exit 0** — matches the author's claimed count |
| V8 | Red-first reproduction | HEAD `run_worker.js` (`git show`) in an isolated `/tmp` tree + the H10X test file | **7/8 fail, exit 1**, first error `TypeError: createInMemoryLeaderLease is not a function`; sole pass is the constructor-validation test (vacuous for a missing factory, exactly as the author disclosed) |
| V9 | Write-scope audit | `find … -newermt '2026-11-01 12:20'` over `backend/`, `n8n-workflow.json`, `evidence/h10` | exactly the 4 H10X paths (+ evidence logs) — **no collateral writes** |
| V10 | Log sanitization | grep of `h10x/*.log` for secret-shaped strings | clean; only test names containing the word "token"; env placeholders only |

## 2. SPEC review (verdict at §5.1)

### 2.1 Acceptance: "No duplicate model execution or deliveries from competing leaders; no unbounded delay chain"

- **Leader gating:** `createResearchScheduler`/`runTick` (run_worker.js:458–479) acquires the named lease **before any side effect** and returns `{leader:false}` for a non-leader. Independently read: the non-leader path touches neither `recoverAbandonedRuns` nor `positions()` nor `queueRun`. Verified behaviorally by tests 2 and 3 (gated recovery proves the follower attempts while the lease is held; call counters assert `recover=1, queue=1` across two replicas and `recover=0, queue=0` for the non-leader).
- **No split brain:** the in-memory lease is a synchronous check-and-set over one Map in single-threaded JS — no interleave between the expiry read (line 391) and the write (line 395). Expired leases are re-acquirable by anyone (test 5), so a crashed leader is taken over, not wedged. `release` refuses to delete a peer's re-acquired lease (owner check, line 401), so a slow tick cannot steal leadership back.
- **Defense in depth (the decisive point):** even across a hypothetical lease race, the scheduler only *queues and sweeps* — it never executes models. Model execution is owned by the H10 run worker behind persisted idempotency (`queueRun` key `daily_update:<date>:<position>` — test 6 proves same-day re-ticks replay, never duplicate) and the H08 atomic `claimRun` CAS with `lease_nonce`. The author documents this layering; independently confirmed against the H08/H10 accepted semantics.
- **No unbounded delay chain:** `runScheduledTick` retries ≤ `maxTickRetries` (default 2 → ≤3 attempts; capped 0–10 by validation) then surfaces the last error (tests 7 and 8 assert exactly 3 attempts in both the transient-recovery and permanent-failure cases). Recovery **stalls/supersedes, never auto-re-queues** — verified in test 4 (`RUN_STALLED` / superseded persisted states). No `setTimeout`/`setInterval` chains exist anywhere in the new code.

### 2.2 Acceptance: "Preserve original dirty scheduler/workflow baseline and core bounded timeout/stall semantics"

- `backend/src/utils/scheduler.js` byte-identical to the dirty baseline (V3). Note: TASKS.md lists scheduler.js under "**modify only within scope**" — permission, not obligation; leaving it untouched is compliant and matches the controller-scoped review note ("Verify scheduler.js (briefing baseline) untouched").
- `run_worker.js` changes are strictly additive (+135 lines): `createRunWorker`, `queueDailyUpdateRuns`, `toStatusView` and all H10 deadline→stall / replay / fail-closed-delivery semantics are unmodified (full-file read, lines 1–317 unchanged logic; the new code begins at line 366).
- n8n graph byte-identical apart from the one `jsCode` line (V2).

### 2.3 Contract mappings (independently confirmed against the source docs)

- CONTRACTS.md:198 "advanced scheduling is H10X … no new queue service" → `createResearchScheduler` is a pure factory over the injected `researchService` (reuses H08 `queueRun`/`recoverAbandonedRuns`); no new queue service, model, or lifecycle. Confirmed.
- SPEC.md:157 "advanced scheduler leadership redesign H10X; no new queue service" → satisfied as above.
- SPEC.md:165 / TASKS.md:821 deferred-held follow-up — this card is a follow-up review, not a full-release gate; H18 remains the gate.
- H10 review O2 ("no autonomous recovery sweep wired") → `runTick` invokes `recoverAbandonedRuns()` every leader tick (line 464–466); test 4 proves a crashed leader's stuck `running` run is stalled and its expired `queued` run superseded without a manual trigger. **O2 is now closed for the backend source** (cron wiring remains H15).
- H10 review O3 (router not mounted) → unchanged; H15 lane, correctly untouched.
- H10 review O1 (idempotency key excludes `position_revision`) → preserved as accepted baseline; disclosed by the author as out of scope. Historical finding retained.

### 2.4 H10 review F1 carry — the n8n poll-counter re-key

- The diff re-keys `poll_count` from the never-changing `$('Normalize Execute Response')` snapshot to the loop item carried through `Wait Between Polls`, seeding from `Normalize Execute Response` on the first poll, with a `try/catch` guard for the not-yet-executed node. Independently traced against the graph: `Wait Between Polls` is `n8n-nodes-base.wait` (30 s), which passes its input item through, so the carried count survives each iteration; `Poll Budget Remaining?` reads `$json.poll_count < 60` and `Mark Poll Timeout` becomes reachable. The F1 defect is genuinely repaired for the single-run poll path.
- The batch-semantics edge (multi-run batches carry the first item's count) is accurately disclosed as pre-existing; the hard termination bounds (Node deadline→stall + 30 s wait floor) are unaffected, so no unbounded poll is possible regardless.
- `poll-loop-adjudication.md` correction is accurate and preserves the H10 history: the old "bounded counter" wording is explicitly superseded, and the layered bound (budget counter + deadline→stall + wait floor) is stated. The H10 review's requested wording correction was applied, not overwritten.

### 2.5 Test requirement ("Tests cover lease ownership, process restart and bounded retry with isolated inputs")

The 8 tests deliver exactly this: lease ownership (tests 1–3, 5), process restart (test 4), bounded retry (tests 7–8), plus idempotent daily queueing (test 6). All inputs isolated: in-memory repositories, injected clock, injected lease store, synthetic fixtures — no `.env` read, no MongoDB, no HTTP, no cron, no publication. Red-first is genuine (V8).

## 3. QUALITY review (verdict at §5.2)

**Strengths.** Validation of every injected dependency is thorough (factory throws `TypeError` on missing/malformed `researchService`, `positions`, `leadership`, out-of-range `maxTickRetries`). The lease is released in a `finally`, so a failed tick cannot wedge leadership. The `try/catch` around `$('Wait Between Polls')` handles n8n's unexecuted-node reference honestly. Logs carry codes and attempt counts only — no payloads or credentials. The tests use a real `ResearchService` over in-memory repositories (not just mocks of the service itself), which exercises the actual queue/claim/recover logic.

**Non-blocking observations (recorded for lane owners; none violate this card's acceptance):**

- **Q1 — no lease renewal during long ticks (H15).** A tick exceeding `leaseTtlMs` (default 60 s) would let a peer take over mid-tick. Safety still holds (the leader only queues idempotently and sweeps stall/supersede; execution is claim-CAS-gated), and the author discloses it, but the H15 Mongo-backed lease should either use a TTL comfortably above the worst tick duration or support renewal. Production wiring is H15's lane.
- **Q2 — no fencing token on the lease store itself.** `tryAcquire`/`release` carry no generation counter. Moot for the single-process reference (synchronous CAS) and execution-level fencing exists at `claimRun` (`lease_nonce`); noted so the H15 Mongo lease design does not drop fencing silently if it ever widens the lease's responsibilities.
- **Q3 — bounded retry has no backoff.** The ≤3 attempts are immediate. Bounded, so the "no unbounded delay chain" acceptance is met; a small fixed delay between attempts would be kinder to a struggling dependency. Taste-level; not a defect.
- **Q4 — test 1's red-run pass is vacuous.** The constructor-validation test passes against the baseline because an undefined factory also throws `TypeError`. The author disclosed this in `h10x-author.md` rather than hiding it; the other 7 tests fail genuinely, so red-first integrity stands.
- **Q5 — `retry_count` (max 2) remains schema-declared but un-incremented.** Correctly disclosed: the bounded retry implemented here is at the scheduler-tick level, and recovery stalls/supersedes rather than re-queues, preserving the accepted "stall, don't infinitely retry" semantics.

## 4. Explicitly unexecuted / deferred (not PASS, never inferred from source)

- **DEFERRED_TO_DEV_PC:** all Flutter analysis/generation/tests/device/APK criteria; runtime behavior of the published n8n workflow on a live n8n instance; live MongoDB CAS-lease semantics; live model calls.
- **H15 lane:** cron/node-cron wiring of `runTick`/`runScheduledTick`, the Mongo-backed CAS leader lease, automation router mounting, shared run store between router and worker.
- **Operator-only:** live workflow publication, coordinated replica deployment, live workflow comparison.
- Source-only acceptance is **not** runtime or release approval. H18 remains the full-release gate; H19 is operator-only.

## 5. Verdicts

### 5.1 SPEC — **SPEC_PASS_SOURCE_ONLY**

Every H10X card criterion, step and invariant checked against real output (V1–V10). Both acceptance criteria verified at source level with behavioral test evidence independently rerun. F1 repaired; O2 closed at source level for the backend; O1/O3 correctly preserved/held. All unexecuted criteria are explicit in §4.

### 5.2 QUALITY — **QUALITY_PASS_SOURCE_ONLY**

The leader-lease/scheduler design is correct for its declared scope, honest about its single-process reference nature, defensive where it must be (persisted idempotency + claim CAS), and cleanly additive to the accepted H10 baseline. Five non-blocking observations (Q1–Q5) recorded for the appropriate lanes; none block this card.

*No blocking defects found. No source repairs made or needed by this review.*
