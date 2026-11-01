# H16 — Forward outcome ledger and quality scorecard — Author Delivery

- Task: t_5d30ad6d (H16), delivery_phase: follow_up, scope: source-only backend
- Author: worker (dispatched profile; roster per release note 2026-11-01: worker/deepseek-v4-pro)
- Reviewer roster (orchestrator 2026-11-01): reviewer/zai/glm-5.3-flash (vendor-disjoint)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup. `git status --short` for the touched paths shows only untracked additions (`??`); the pre-existing `M docs/horizon/UNATTENDED_CONTROL.md` and other lanes' untracked files are not mine and were not touched.

## 1. Delivered files (all new; exactly the canonical package + authorized evidence)

| Path | Lines | SHA-256 |
|---|---|---|
| backend/src/features/research/outcome.model.js | 50 | 1f310862deff626b8afcaf25fc4a56e1454e81d33fb06555b2ba69869dad4358 |
| backend/src/features/research/outcome.service.js | 604 | 10649df643ac26c506e3e6c807d0cf985a0f514a0890bf7aedb00e6876df6196 |
| backend/test/research-outcomes.test.cjs | 580 | bb257b1774471a2c0bcc93a14127f334fd9ee562e9e9406f97864acd0ff28b69 |
| docs/horizon/evidence/evaluation-protocol.md | 167 | 6a8053b68819baa476954711d96d7016bf4a714ddda452492ff379635c292559 |

Evidence artifacts: `docs/horizon/evidence/h16/red-run.log` (real TDD red run, exit 1, `Cannot find module '../src/features/research/outcome.service'`), `docs/horizon/evidence/h16/verification.log` (green run + full regression battery + `git diff --check`). `existing_files` in the canonical package is empty; `contracts.js`, H07 metrics, H08/H09 modules, routes wiring (`app.js`), Flutter sources: untouched (read-only `require('./contracts')` only).

## 2. Commands and results (this run, host node v22.22.2, hermetic offline)

All commands foreground in /home/ubuntu/apps/Horizon. No live APIs, no credentials, no DB connection, no installs, no shell backgrounding, no `.env` read.

```
node --test backend/test/research-outcomes.test.cjs   -> exit 0; 28 pass, 0 fail (TDD green)
node --test backend/test/*.test.cjs                   -> exit 0; 320 pass, 0 fail (full aggregate, no regression)
git diff --check                                        -> clean, exit 0
secret scan (credential-literal pattern over 3 delivered code files) -> no matches
```

Full output in `docs/horizon/evidence/h16/verification.log`.

## 3. TDD record

Red (captured live, full log at `docs/horizon/evidence/h16/red-run.log`):

```
node --test backend/test/research-outcomes.test.cjs -> exit 1
# Error: Cannot find module '../src/features/research/outcome.service'
```

Tests written first (28 tests, six groups: frozen realization, model
invariants, registerForecast, settleForecast, computeScorecard, repository
shape). Then implement model + service -> green (28/28 first run, no iteration
failures; no blind retries). The aggregate grew from the pre-existing 292
suites-only tests to 320 with the 28 new tests, all green.

## 4. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Prevent settlement before availability, duplicate settlements, original assessment rewrites | `outcome.service.js` `settleForecast` (`OUTCOME_NOT_AVAILABLE` gate on injected clock, idempotent identical replay, `OUTCOME_CONFLICT` on differing replay) and `registerForecast` (idempotent identical re-registration, `FORECAST_CONFLICT` on rewrite); unique `(assessment_id, horizon_months)` + `ledger_id` indexes in `outcome.model.js` | tests: settle-before-availability, settle-allowed-after, idempotent-duplicate, conflicting-second-settlement, idempotent-register, prevent-rewrite, owner-scoped |
| Append-only realized horizon/benchmark outcomes using exact calendar evaluation dates and method versions | `registerForecast` validates `evaluation_session_date` against `contracts.calendarTargetDate` + `contracts.evaluationSessionDate` (exact, incl. weekend walk-back); frozen `benchmark` (`benchmark_id/method/method_version/definition/tolerance`) and `versions` (model/prompt/method/snapshot) recorded immutably; `realizeDirection` computes the realized direction in code | tests: exact-evaluation-date, walk-back-accepted, benchmark-realization, invalid-realized-direction, invalid-outcome-date |
| Frozen quality set + no-change/no-LLM/strategy-appropriate baselines; separate quality from forecasting | `FROZEN_QUALITY_SET` (6 dimensions mapped to H09 defect codes), `STRATEGY_KINDS` (`strategy_appropriate`/`no_change`/`no_llm`), `BENCHMARKS.total_return_sign`; `computeScorecard` reports `forecasting` and `quality` as disjoint sections | tests: frozen-constants, quality-aggregation-separate, baseline-comparison |
| Record insufficient mature observations without advertising a forecasting edge | `MIN_MATURE_OBSERVATIONS = 10` gate; `insufficient_observations` status with `hit_rate: null`; `edge_claim: null` always; `calibrated_probability_metrics: null` unless per-forecast calibrated probabilities exist | tests: insufficient-observations, hit-rate-above-threshold-no-edge, excludes-insufficient-evidence, no-fabricated-calibrated-probability |

## 5. Acceptance mapping

| Acceptance | Where proven |
|---|---|
| Outcome timing is point-in-time valid and idempotent | settlement refused before the evaluation session has passed (`OUTCOME_NOT_AVAILABLE`, injected clock); outcome must be observed at exactly `evaluation_session_date` (`INVALID_OUTCOME_DATE`); identical settlement replays without a second write (`settled_at` unchanged); conflicting settlement is `OUTCOME_CONFLICT` |
| No retrospective lessons enter earlier snapshots; probabilistic metrics only when valid/calibrated | forecast half immutable (`immutable: true` fields), rewrite rejected (`FORECAST_CONFLICT`); direction hit rate gated on `MIN_MATURE_OBSERVATIONS`, labeled `is_calibrated_probability: false`, `calibrated_probability_metrics` never fabricated, `edge_claim` always `null` |

## 6. Key decisions

- **Injected clock + exchange predicate.** `OutcomeService` takes `now()` (Date) and `isExchangeSession` (session predicate), matching the H07/H09 injection pattern. Availability is `dateOnly(now) > evaluation_session_date` (strictly after the evaluation session has fully passed), a conservative rule that can never settle early.
- **Benchmark-defined realization in code.** `realizeDirection(benchmark_return, tolerance)` is deterministic; the ledger rejects a caller-asserted direction that contradicts the recorded return, so no invented outcome can be recorded.
- **Strategy kinds are the baseline mechanism.** Baselines (`no_change`, `no_llm`) are recorded as ledger entries with their own `strategy.kind`; the scorecard compares the primary `strategy_appropriate` strategy against them only when both are mature, and labels the comparison `descriptive_only`.
- **Quality and forecasting are disjoint outputs.** The scorecard returns separate `forecasting` and `quality` sections; the frozen quality set reuses H09's planted-defect codes rather than inventing a parallel notion of quality.

## 7. Limitations (not passed here, explicitly deferred)

- **Live measurement.** Cost/latency and the analyst-vs-analyst+reviewer comparison require live runs (H10 integration lane / DEFERRED_TO_DEV_PC); no comparison or superiority claim is made.
- **Calibration.** Calibrated probability metrics require per-forecast probability output (H07A held); the scorecard never synthesizes one.
- **Storage-layer behavior unproven against a live MongoDB.** Unique `(assessment_id, horizon_months)` and `ledger_id` indexes and the pending→settled CAS are implemented in the Mongoose repository and the model is probed via `validateSync`/index introspection, but only the in-memory repository was executed. Live-index/persistence checks belong to the integration lane (H15/H17).
- **Router not mounted.** `OutcomeService` is a standalone module; route wiring is the single-ownership integration change (H15), not H16.
- Node v22.22.2 host ≠ deployment runtime; runtime compatibility remains a release-gate concern. No Flutter surface in this package — nothing deferred to the PC for H16 itself.
