# H07A — Auditable numerical scenarios and overlay production — Author Delivery

- Task: t_c6b1da9e (H07A), delivery_phase: follow_up, scope: source-only
- Author: worker (dispatched profile; roster per release note: author deepseek-v4-pro / worker, reviewer zai/glm-5.3-flash — vendor-disjoint)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup, no files outside the package touched.
- Resume note: prior run 276 crashed infrastructure-side (gateway session loss) mid-delivery at ~11:48 UTC. On-disk partial state (scenarios-fixtures.json 11:46, research-scenarios.test.cjs 11:47, scenarios.js 11:48) was verified first, not rewritten, and the remaining scope (this evidence file) completed. See operator note 11:58 UTC.

## 1. Delivered files

| Path | New/Existing | Lines | SHA-256 |
|---|---|---|---|
| backend/src/features/research/scenarios.js | new | 341 | 605dd5bba076b11861fac7c9ba9590c9541b333876ee446b4c9577db17235758 |
| backend/test/research-scenarios.test.cjs | new | 306 | 9b3f4604385f019d26581a5f5459ac18da7447c9854d47415dde4d5ad9e02845 |
| backend/test/fixtures/research/scenarios-fixtures.json | new | 69 | f94b61571b580f1fe3d50610b1b3027e4eb5f6187f9c299b3614932e673d4e26 |

The fixture file is an authorized package output under canonical step 1 ("independently computed fixture arithmetic"), following the H01/H05/H07 precedent of fixtures under `backend/test/fixtures/research/`. It is listed here explicitly so the reviewer can bind all three paths.

No other files were created or modified. `existing_files` in the canonical package is empty; `contracts.js`, `metrics.js`, routes, app wiring, Flutter sources: untouched. `scenarios.js` is **not wired** into any service/route/assessment pipeline (verified by source scan) — integration is H09/H15 ownership.

## 2. Commands and results (this run, host node v22.22.2, hermetic offline)

All commands run foreground in /home/ubuntu/apps/Horizon. No live APIs, no credentials, no DB, no installs, no shell backgrounding.

```
node --test backend/test/research-scenarios.test.cjs  -> exit 0; 28 pass, 0 fail (green)
  # tests 28  # pass 28  # fail 0  # skipped 0
```

Regression battery (predecessor suites, no regressions):

```
node --test backend/test/research-metrics.test.cjs    -> exit 0; 24 pass, 0 fail  (H07 predecessor)
node --test backend/test/research-contracts.test.cjs  -> exit 0; 14 pass, 0 fail  (H01 predecessor)
node --test backend/test/market-history.test.cjs      -> exit 0; 12 pass, 0 fail  (H05 predecessor)
node --test backend/test/research-evidence.test.cjs   -> exit 0; 19 pass, 0 fail  (H06 predecessor)
node --test backend/test/research-auth.test.cjs       -> exit 0;  6 pass, 0 fail  (H03 predecessor)
```

Checks:

```
git diff --check                                          -> clean
trailing-whitespace scan (3 files)                        -> none
CR scan (3 files)                                         -> 0
secret scan (credential/secret pattern, 3 files)          -> no matches
```

## 3. Fixture arithmetic — independently recomputed (this run)

Every expected bound in `scenarios-fixtures.json` was recomputed **independently in Python** (IEEE-754 double, offline) — not by re-running the JS fixtures — and matched bit-for-bit:

```
conditional_bounds (anchor * (1 + shift)):
  full_three_bound   anchor=100.0  lower=-0.10 central=+0.02 upper=+0.15 -> 90.0 / 102.0 / 114.99999999999999   MATCH
  band_no_central    anchor=100.0  lower=-0.25 central=null  upper=+0.30 -> 75.0 / null / 130.0                  MATCH
  fractional_anchor  anchor=42.5   lower=-0.05 central=null  upper=+0.05 -> 40.375 / null / 44.625               MATCH

volatility_bounds (anchor * (1 ± z*vol*sqrt(horizon_months/12))):
  three_month         anchor=100.0 vol=0.20 h=3 z=1.0 -> 90.0 / 110.00000000000001                              MATCH
  one_month           anchor=250.0 vol=0.30 h=1 z=1.0 -> 228.34936490538905 / 271.65063509461095                 MATCH
  three_month_high_vol anchor=100.0 vol=1.50 h=3 z=1.0 -> 25.0 / 175.0                                           MATCH
```

Note `full_three_bound` upper = 114.99999999999999 and `three_month` upper = 110.00000000000001 are the correctly-rounded IEEE-754 doubles for `100 * 1.15` and `100 * 1.10` respectively — disclosed floating-point rounding, absorbed by the tests' 1e-12 relative tolerance. No NaN/Infinity can reach output (all guards `assertFinitePositiveNumber`).

## 4. TDD record

Tests and fixtures were written first (prior run); expected values were cross-checked independently of the implementation with offline double-precision arithmetic (Python) before the implementation existed. The first green run in the prior session was interrupted by the infrastructure crash before its evidence was written; the on-disk state is the completed green implementation. This run re-verified the green state (28/28) and re-ran the independent recomputation above rather than trusting the self-report.

## 5. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Retain original H07 conditional scenario/volatility reference requirements, methods, inputs and independently computed fixture arithmetic | `conditionalScenarioBounds(anchorPrice, shifts)` and `volatilityReferenceBounds(anchorPrice, annualizedVolatility, {horizon_months, z_multiple})` as reproducible, separately auditable arithmetic; fixture `fixture_kind: deterministic_scenario_reference` with explicit not-observed-data / not-calibrated-forecast provenance | 'conditionalScenarioBounds reproduces independently computed bounds for every fixture'; 'volatilityReferenceBounds reproduces independently computed bands for every fixture' |
| Produce optional projection objects only with auditable assumptions and compatible basis; do not manufacture daily paths | `createConditionalScenario`, `createVolatilityReference`, `createProjection` produce frozen contract-shaped projections validated against `numericProjectionSchema`; only endpoint/range markers (lower/central/upper) are produced — no daily paths, no future candles; `calibrated_forecast` is gated (RangeError), never fabricated | 'createConditionalScenario builds a frozen contract-shaped projection'; 'createVolatilityReference builds a frozen reference band with no central path'; 'createProjection rejects calibrated_forecast as gated, not fabricated' |

## 6. Acceptance-criteria mapping

1. "Conditional ranges are not calibrated probabilities or directional volatility forecasts."
   - `calibration` is always `null` on produced projections; `createProjection('calibrated_forecast')` throws `CALIBRATED_FORECAST_GATE` (requires model/version, held-out evaluation, coverage/calibration definition and observed validation evidence — CONTRACTS §7 — and is gated, not a launch claim).
   - `CONDITIONAL_SCENARIO_LIMITATION` states the bounds are "not calibrated probabilities, not an expected direction, and not a forecast path".
   - `VOLATILITY_REFERENCE_LIMITATION` states the band is "not a directional forecast, not a probability interval, and not the analyst expected path"; volatility reference carries no central path (rejected if provided).
   - Tests assert the limitation text matches `/not calibrated probabilities/i`, `/not.*expected direction/i`, `/not a directional forecast/i`, `/not.*probability interval/i`.

2. "Null/insufficient inputs remain explicit; downstream optional renderer contract preserved."
   - `nullScenarioProjection(extraLimitations)` returns frozen `{numeric_projection: null, data_limitations: [...]}` — explicit null, never a fabricated number.
   - `volatilityReferenceBounds` throws (RangeError) when the band would reach or cross zero rather than clamping — insufficient inputs stay explicit.
   - Every produced object is validated against the authoritative `numericProjectionSchema` from `./contracts` before return, so the downstream optional-renderer contract (CONTRACTS §7 `NumericProjection`) can never be violated.

## 7. Limitations and deferred checks

- Source-only delivery: `scenarios.js` exports pure functions/factories not yet wired into any route/service/assessment pipeline. Wiring the projections into the outlook (`numeric_projection`) pipeline is H09/H15 ownership; H07's `metrics.js` placeholder `nullNumericProjection` remains unchanged and its limitation text ("held for H07A and has not been independently accepted") is stale only after H07A independent acceptance — retiring it is downstream wiring, not H07A scope.
- Host Node v22.22.2 tests do not establish deployment-runtime compatibility.
- No Flutter/frontend checks in scope; all Flutter analysis/generation/tests/device/APK checks remain DEFERRED_TO_DEV_PC per the amendment.
- Anchor prices, shifts and volatility figures are synthetic arithmetic samples (not observed market data, not user positions); observed market data and conditional scenarios remain separate per invariant.
- The module's only `Date` construction is `new Date(Date.UTC(year, month, 0))` in the ISO date/timestamp validators — deterministic days-in-month calendar arithmetic, not a clock read (mirrors metrics.js Note D/E). No `Math.random`, no `Date.now`, no no-arg `new Date()`, no network, no DB, no `process.env` in `scenarios.js` (source-asserted).
