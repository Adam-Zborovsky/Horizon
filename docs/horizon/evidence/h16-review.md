# H16 combined independent review — specification + quality

Reviewer: reviewer/zai-glm-5.3-flash (vendor-disjoint from author
worker/deepseek-v4-pro per orchestrator roster note 2026-11-01). Review card:
t_b8402be1. Scope: the H16 canonical package (outcome ledger + quality
scorecard) delivered on t_5d30ad6d. All source allowlists read-only; this file
and sanitized run evidence are the only writes.

**Verdicts: SPEC_PASS_SOURCE_ONLY — QUALITY_PASS_SOURCE_ONLY.** Every
unexecuted runtime criterion is explicit in §6. Source-only acceptance is not
runtime or release approval; storage-layer and wiring gates remain with the
integration lanes (H15/H17) and the Dev-PC gate remains operator-held.

## 1. Independent verification performed (not author self-report)

Real commands run by this reviewer on the workspace, this run:

| Check | Result |
|---|---|
| `sha256sum` of all 4 delivered artifacts | **4/4 match** `h16-author.md` §1 exactly (model `1f310862…`, service `10649df6…`, test `bb257b17…`, protocol `6a8053b6…`) — confirms the crash-resume left no half-written on-disk state |
| `wc -l` | 50 / 604 / 580 / 167 — all four line counts match the author table |
| `node --test backend/test/research-outcomes.test.cjs` (repo root) | **exit 0 — 28/28 pass, 0 fail** (reproduced independently) |
| `grep -c '^test(' research-outcomes.test.cjs` | 28 — test count claim is exact |
| `node --test backend/test/*.test.cjs` (full aggregate, repo root) | **exit 0 — 357/357 pass, 0 fail**. Author reported 320 at 11:49; the tree grew to 357 under sibling-lane (H09X) concurrent work since; H16's 28 are included and no H16-caused regression is present |
| `grep -c '^ok' h16/verification.log` | 348 ok lines + 2 file-level suite lines — consistent with the author's 320/320 claim |
| `git diff --check` | clean, exit 0 |
| Secret scan (`password|secret|api_key|token|bearer|credential`) over all 4 artifacts | **no matches**; no `.env` reads in the delivered code |
| `git status --porcelain` | H16 paths appear only as untracked additions (`??`); the two tracked modifications (`research.service.js`, `automation.routes.js`) are H09X's concurrent edits — excluded from this review per orchestrator note |
| `red-run.log` authenticity | genuine `MODULE_NOT_FOUND` TAP failure for `outcome.service` at `test.cjs:17` — a real red run, not a fabricated log |
| `contracts.js` dependency surface | `calendarTargetDate` (l.50) and `evaluationSessionDate` (l.73) verified read-only exports with weekend walk-back; `outcome.service.js` requires them, never re-implements date math |

## 2. SPEC review — canonical steps and acceptance

**Verdict: SPEC_PASS_SOURCE_ONLY.**

| Canonical step | Independent verification |
|---|---|
| Prevent settlement before availability, duplicate settlements, original assessment rewrites | `settleForecast` gates on `dateOnly(now) > evaluation_session_date` (`OUTCOME_NOT_AVAILABLE`, service l.542), rejects off-date observation (`INVALID_OUTCOME_DATE`, l.535), replays identical settlement without a second write (`settled_at` unchanged, asserted in test l.384), rejects conflicting replay (`OUTCOME_CONFLICT`, l.568), and backs single-append with a pending→settled CAS in the mongoose adapter (l.248-252). `registerForecast` is idempotent on identical spec and `FORECAST_CONFLICT` on rewrite (l.481-491); the unique `(assessment_id, horizon_months)` index (model l.42) is storage-level backstop. All three canonical prevention targets are exercised by named tests and green on my rerun |
| Append-only realized outcomes, exact calendar dates, method versions | Evaluation date validated against `calendarTargetDate(issue, horizon)` + `evaluationSessionDate(..., isExchangeSession)` (l.468-476) — the exact contract math incl. weekend walk-back (test l.241-257 uses real `contracts.js` functions). Frozen `benchmark` and `versions` recorded immutably; realized direction is computed in code from `benchmark_return` and a contradicting caller value is `INVALID_REALIZED_DIRECTION` (l.549-551) — no invented outcomes can enter the ledger |
| Frozen quality set + baselines; quality separate from forecasting | `FROZEN_QUALITY_SET` (6 dimensions mapped to H09 defect codes) and `STRATEGY_KINDS` (`strategy_appropriate`/`no_change`/`no_llm`) are frozen module constants; `computeScorecard` returns disjoint `forecasting` and `quality` sections (l.397-414). Baselines flow through the same register/settle path, so comparison is equal-input |
| Record insufficient mature observations without advertising an edge | `MIN_MATURE_OBSERVATIONS = 10` gate; `hit_rate: null` below maturity; overall status `insufficient_observations`; `edge_claim: null` always; `calibrated_probability_metrics: null` even when `calibration_evidence` is supplied (test l.519-535) |

**Acceptance 1 — point-in-time valid and idempotent timing: PASS (source).**
Settlement cannot run before the evaluation session has fully passed (strictly
after — conservative), must be observed at exactly the contract evaluation
date, replays idempotently, and conflicts append-only.

**Acceptance 2 — no retrospective lessons; probabilistic metrics only when
valid/calibrated: PASS (source).** The forecast half is immutable at write
time and rewrite-rejected; the scorecard never upgrades an empirical hit rate
into a calibrated probability, never synthesizes per-forecast probabilities,
and never emits an edge claim. `evaluation-protocol.md` §5 matches the code
line-for-line on the scoring rule (`direction === realized_direction`),
maturity gate, and `is_calibrated_probability: false`.

**Protocol-doc fidelity:** every checkable claim in `evaluation-protocol.md`
(§2 field table, §2.1 timing rules, §2.2 realization bands, §3 strategy kinds,
§4 quality set incl. `unknown` excluded from aggregate totals, §5 metrics and
edge prohibition, §6 insufficient-observations state) was checked against the
implementation and matches. §7 limitations honestly enumerate what was NOT
exercised. CONTRACTS.md §10 requirements (immutable assessment ID, forecast
spec, issue/evaluation dates, benchmark definition, version snapshot, later
appended outcome, idempotent append, no settlement before availability,
owner scoping) are each traceable to specific code and tests.

## 3. QUALITY review — security, fidelity, maintainability

**Verdict: QUALITY_PASS_SOURCE_ONLY.**

- **Security/privacy.** Owner scoping on settlement with indistinguishable
  404 for cross-owner and unknown ledger (test l.412-437); no secrets, no
  credential reads, no network, no live data anywhere in the delivered code.
  Inputs are bounded (id/label/version length caps, versions ≤ 20 entries).
- **Test fidelity.** All 28 tests carry specific assertions (exact error
  codes, `settled_at` invariance, record-count invariance after idempotent
  replays, deep content of aggregates). No weakened, deleted, or vacuous
  assertions. The in-memory repository faithfully mirrors the mongoose
  adapter's contract (incl. the `(assessment_id, horizon_months)` collision
  and pending-only CAS). Model probes are `validateSync` + index
  introspection — honestly scoped, never claimed as live-Mongo proof.
- **No invented data.** The realization is computed from a supplied observed
  return against the frozen benchmark; fixtures carry synthetic test returns
  clearly in test scope. No prices, candles, or history are fabricated as
  observed market data.
- **Maintainability.** Clear module boundaries (frozen constants → validators
  → repository adapter → service → pure scorecard); canonicalized
  key-sorted serialization for byte-stable idempotency checks; structured
  error codes; the file reads cleanly at 604 lines with no dead code found.
- **Baseline preservation.** No tracked file modified by this lane; no
  branch/commit/push; no generated-file hand edits; no lockfile or dependency
  changes; existing dirty/untracked baseline untouched.
- **Toolchain honesty.** Node v22.22.2 host run is real and reproducible; the
  author does not claim any unavailable toolchain.

### Non-blocking observations (for the H15 wiring lane / follow-up; no repair requested here)

1. **Hindsight registration is not gated in the module.** `registerForecast`
   does not refuse a forecast whose `evaluation_session_date` has already
   passed relative to the injected clock, so a post-hoc "forecast" could
   enter the ledger if wired without an issue-time gate. Not in the
   canonical step list (which targets settlement timing), and the module is
   unwired — but H15 must register forecasts only at assessment issue time,
   or a follow-up should add the gate.
2. **`registerForecast` idempotency is not owner-checked.** A differing-owner
   identical re-registration for an existing `(assessment_id, horizon_months)`
   returns the existing entry (including `owner_id_internal`) rather than a
   conflict. Route wiring must enforce assessment ownership before calling
   the service; the unique index is intentionally per (assessment, horizon).
3. **UTC-based availability gate.** `dateOnly` uses `toISOString()`, so the
   availability comparison is UTC-date based while evaluation dates are
   exchange-local calendar dates. Conservative in direction (can only delay,
   never enable early settlement), but wiring should be aware.
4. **Multi-primary scorecard edge.** If two `strategy_appropriate` strategy
   IDs are ever present, the last scanned bucket wins as "primary". Harmless
   under the current single-primary protocol; noted for future protocol
   versions.

## 4. Environment note (reviewer-side, not an H16 defect)

Running the aggregate from `backend/` as cwd (instead of the documented repo
root) leaves `MONGODB_URI`/`JWT_SECRET` undefined (dotenv path is cwd-relative)
and collapses 4 suites to file-level load failures (309 tests, 4 fail). From
the repo root — the documented invocation, used by both the author and this
reviewer — the same tree is 357/357 green. Recorded here so a future reviewer
does not misread that artifact as a code regression.

## 5. Verdict

**SPEC_PASS_SOURCE_ONLY — QUALITY_PASS_SOURCE_ONLY.** The H16 package meets
its canonical steps and both acceptance criteria at source-only scope, with
honest, reproducible TDD evidence and an accurate frozen protocol document.
The four observations in §3 are wiring-lane concerns, not defects in the
delivered package; none blocks this gate.

## 6. Explicitly not verified here (deferred, unexecuted criteria)

- **Live MongoDB behavior** — unique-index enforcement and the pending→settled
  CAS were never executed against a real database (integration lane H15/H17).
- **Route wiring / HTTP surface** — no route mounts `OutcomeService`; no HTTP
  behavior was or could be tested here.
- **Live measurement** — no live market data, no live model provider, no
  cost/latency comparison; no forecasting edge is claimed or could be.
- **Calibration** — per-forecast probability output (H07A, held); the
  scorecard never synthesizes it.
- **Flutter/Dev-PC runtime** — no Flutter surface exists in this package;
  nothing deferred to the PC for H16 itself.
- Source-only acceptance is not runtime or release approval.
