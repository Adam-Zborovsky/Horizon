# H07 — Core deterministic metrics, economics and calendar horizons — Author Delivery

- Task: t_0b20800d (H07), delivery_phase: core_source, scope: source-only
- Author: worker (dispatched profile; roster per release note 21:01 UTC: worker/zai/glm-5.3-flash)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup, no files outside the package touched.

## 1. Delivered files

| Path | New/Existing | Lines | SHA-256 |
|---|---|---|---|
| backend/src/features/research/metrics.js | new | 389 | afbe204983180bf1dbe442e57a7ef8f36fedb7444cef1512e9c6f4e808b3710d |
| backend/test/research-metrics.test.cjs | new | 397 | 1b7ff4b3a3823d7127ba7e164c4ec578fdf1bd97ee22fcbd2e4fce1ee7c49349 |
| backend/test/fixtures/research/metrics-fixtures.json | new | 127 | 9206f594052a0326d0ae20295d334f7fac70aade3550d92b05b259ca1eb7127e |

The fixture file is an authorized package output under canonical step 1 ("Write independently checked fixtures"), following the H01/H05 precedent of fixtures under `backend/test/fixtures/research/`. It is listed here explicitly so the reviewer can bind all three paths.

Evidence artifacts: `docs/horizon/evidence/h07/red-run.log` (real TDD red run, exit 1), `docs/horizon/evidence/h07/verification.log` (green runs, regression battery, git diff --check, secret scan, sha256).

No other files were created or modified. `existing_files` in the canonical package is empty; `contracts.js`, routes, app wiring, Flutter sources: untouched.

## 2. Commands and results (this run, host node v22.22.2, hermetic offline)

All commands run foreground in /home/ubuntu/apps/Horizon. No live APIs, no credentials, no DB, no installs.

```
node --test backend/test/research-metrics.test.cjs   -> exit 0; 23 pass, 0 fail (TDD green)
node --test backend/test/research-contracts.test.cjs -> exit 0; 14 pass (H01 predecessor — no regression)
node --test backend/test/market-history.test.cjs     -> exit 0; 12 pass (H05 predecessor — no regression)
node --test backend/test/research-evidence.test.cjs  -> exit 0; 19 pass (H06 predecessor — no regression)
node --test backend/test/research-auth.test.cjs      -> exit 0; 6 pass  (H03 predecessor — no regression)
node --test backend/test/research-history-integration.test.cjs -> exit 0; 11 pass (H15A predecessor — no regression)
git diff --check                                     -> clean
secret scan (credential-literal pattern)             -> no matches
```

Total 85/85 across the six backend suites. `backend/test/positions.test.cjs` was excluded from judgment: it belongs to the in-flight H04 lane, matching the exclusion convention recorded in the H06 re-review.

## 3. TDD record

Red (captured live, full log at docs/horizon/evidence/h07/red-run.log):

```
node --test backend/test/research-metrics.test.cjs
  -> exit 1
  # Error: Cannot find module '../src/features/research/metrics'
```

Tests and fixtures were written first; expected values were computed and cross-checked independently of the implementation with offline double-precision arithmetic (Python) before any implementation existed, including weekday/holiday facts (2024-03-29 Good Friday, 2024-04-01 Easter Monday, 2024-07-01 Monday, 2024-05-05 Sunday).

Green: implementation added, suite rerun -> exit 0, 23/23.

First green run exposed 3 failures, each diagnosed and fixed once (no blind retries):
1. `simpleReturns('100,105')` threw RangeError where a non-array is a type error — implementation now throws TypeError for non-arrays, RangeError for length/content.
2. Frozen-record assignment assertion failed in CJS sloppy mode — test file got `'use strict'`.
3. Author fixture error (mine, caught by the run): 2024-04-01 was not declared a non-session, so evaluation correctly returned 2024-04-01 instead of the intended walk-back to 2024-03-28. Fixture corrected to declare both Good Friday 2024-03-29 and Easter Monday 2024-04-01 as holidays.

## 4. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Independently checked fixtures for returns/averages/volatility/drawdown/relative returns/P&L and calendar horizons | metrics-fixtures.json with `fixture_kind: deterministic_metric_reference`, explicit not-observed-data provenance note, hand-checked expected values | 'metric fixtures are declared, versioned and non-empty'; every computation test consumes fixture values, not inline literals |
| Registry with method/input/source IDs and finite-value/basis guards | `createMetric` (contract-shaped `{id, instrument_id, value, unit, currency, as_of, basis, method, method_version, input_evidence_ids, input_snapshot_ids}`, frozen), `createMetricRegistry` (duplicate-id rejection, sorted reproducible listing, null for unknown) | 'createMetric produces an immutable contract-shaped record...'; 'createMetric guards finite values, basis, method, dates and unique input IDs'; 'metric registry registers, resolves, lists sorted and rejects duplicates' |
| numeric_projection null with explicit limitation; no scenario engine prerequisite | `NUMERIC_PROJECTION_LIMITATION` constant + `nullNumericProjection(extra)` returning `{numeric_projection: null, data_limitations: [...]}`; no scenario module, no projection values anywhere | 'numeric projection stays null with the explicit H07A limitation' (cross-checks fixture text === module constant) |

## 5. Acceptance-criteria mapping

1. "Money/quantity handling is deterministic; same-cost/split/currency assumptions tested" — `profitAndLoss` takes bounded decimal-string economics (contract DECIMAL_LIMITS reused from `./contracts`); zero-P&L same-cost case tested; currency mismatch -> `{status: 'unavailable', reason: 'currency_mismatch'}` (no silent FX, CONTRACTS §2); adjustment-basis mismatch -> `adjustment_basis_mismatch` (splits must be reconciled, CONTRACTS §2); fees/dividends labeled excluded via `excluded_adjustments`; determinism proven by repeated-call deepEqual and a source scan asserting no `Math.random`/`Date.now`/`new Date()`.
2. "Calendar target/evaluation sessions correct at month ends, holidays and leap years" — `outlookHorizons` delegates all arithmetic to H01-owned `contracts.calendarTargetDate`/`evaluationSessionDate` (no reimplementation); fixture cases cover leap clamp (2024-01-31→2024-02-29), non-leap clamp (→2023-02-28), year roll (2024-12-31 h1/h2/h3), as-of leap-day clamp (2024-02-29→2024-03-29), holiday+weekend walk-backs (target Monday 2024-04-01 holiday → 2024-03-28; 2024-07-01 holiday → 2024-06-28; Sunday target → Friday), year-10000 overflow rejection, evaluation never before session_as_of and never after calendar target.
3. "Metric references remain reproducible and code-calculated; no fabricated projection" — all values computed in code from inputs; registry listing is sorted and reproducible; volatility metric labels asserted to exclude expected/probability/direction/forecast vocabulary and the limitation text explicitly states no numeric price forecast exists (CONTRACTS §7 invariant: volatility references are never directional forecasts).

## 6. Limitations and deferred checks

- Source-only delivery: metrics are pure functions not yet wired into any route, service or assessment pipeline; integration into the research pipeline is downstream (H09/H15 lanes per ownership rules).
- `numeric_projection` production is intentionally absent: H07A conditional-scenario/volatility-reference work is a held follow-up and must be independently accepted before any numeric projection exists.
- Host Node v22.22.2 tests do not establish deployment-runtime compatibility.
- No Flutter/frontend checks in scope; all Flutter analysis/generation/tests/device/APK checks remain DEFERRED_TO_DEV_PC per the amendment.
- Decimal-string economics are converted to IEEE-754 doubles for arithmetic; money results are exact binary values for the tested cases, but no decimal-rounding policy is applied (none is specified at contract version 1). No Math.random/Date.now exists in the module (source-asserted).
- The three-year supported-horizon set (1/2/3 months) and the 32-day evaluation walk-back bound are inherited unchanged from contracts.js (H01 ownership).
