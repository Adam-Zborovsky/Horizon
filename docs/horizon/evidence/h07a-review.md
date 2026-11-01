# H07A — Combined Independent Specification and Quality Review

- Reviewer: reviewer profile (zai/glm-5.3-flash); author deepseek-v4-pro (worker) — vendor-disjoint per orchestrator note of 2026-11-01.
- Card: t_2a08ee8c; author delivery card t_c6b1da9e (controller-verified 4/4 hashes before release).
- Review model: one combined independent review, separate SPEC and QUALITY verdicts. Author self-report treated as claims, not evidence. No source repairs, no new cards.
- Date: 2026-11-01. Workspace: /home/ubuntu/apps/Horizon (dirty main baseline preserved; review is read-only on source).

## 1. Independent verification performed (this run, host node v22.22.2)

All commands run foreground, offline, hermetic. No live APIs, no credentials, no DB, no installs, no backgrounding.

1. **SHA-256 binding (3/3 delivered code artifacts match author claims exactly):**
   - `backend/src/features/research/scenarios.js` → `605dd5bba076b11861fac7c9ba9590c9541b333876ee446b4c9577db17235758` MATCH
   - `backend/test/research-scenarios.test.cjs` → `9b3f4604385f019d26581a5f5459ac18da7447c9854d47415dde4d5ad9e02845` MATCH
   - `backend/test/fixtures/research/scenarios-fixtures.json` → `f94b61571b580f1fe3d50610b1b3027e4eb5f6187f9c299b3614932e673d4e26` MATCH
   - Author evidence file `docs/horizon/evidence/h07a-author.md` present (hash `589eee45…` as found on disk).
2. **Named suite rerun:** `node --test backend/test/research-scenarios.test.cjs` → exit 0, **28 pass / 0 fail / 0 skipped** (independently reproduced, not accepted from author self-report).
3. **Independent fixture recomputation in Python (IEEE-754 double, offline, not a JS re-run):** all six fixture cases recomputed bit-for-bit —
   - conditional: `full_three_bound` 90.0 / 102.0 / 114.99999999999999 MATCH; `band_no_central` 75.0 / null / 130.0 MATCH; `fractional_anchor` 40.375 / null / 44.625 MATCH;
   - volatility: `three_month` 90.0 / 110.00000000000001 MATCH; `one_month` 228.34936490538905 / 271.65063509461095 MATCH; `three_month_high_vol` 25.0 / 175.0 MATCH.
   - The disclosed IEEE-754 roundings (114.99999999999999, 110.00000000000001) are the correctly-rounded doubles, absorbed by the tests' 1e-12 relative tolerance.
4. **Regression battery rerun:** research-metrics 24/24, research-contracts 14/14, market-history 12/12, research-evidence 19/19, research-auth 6/6 — all exit 0.
5. **Full backend aggregate rerun:** `node --test backend/test/*.test.cjs` → **357/357 pass, 0 fail, exit 0** (includes the concurrent H09X-owned dirty files; no cross-lane breakage observable).
6. **Wiring scan:** `grep -rn "require.*scenarios"` across `backend/src` and `app` → zero references. `scenarios.js` is unwired, as the author disclosed; integration is H09/H15 ownership.
7. **H07 core non-mutation:** `git diff --stat` on `metrics.js` and `contracts.js` → empty; both are unmodified in the working tree. `git status` shows the three delivery files as untracked-new; no tracked file was modified by this delivery. `git diff --check` → clean.
8. **Contract cross-check:** every field of the object built by `buildProjection` maps 1:1 onto the authoritative `numericProjectionSchema` in `contracts.js` (lines 239–285), and every factory output is re-validated through `safeParse` before return — the downstream optional-renderer contract cannot be violated by a returned object.
9. **Secret scan** on all three delivery files (credential/secret/password/token/api-key patterns) → no matches. Fixture provenance is explicitly synthetic (`fixture_purpose` declares "not observed market data, not user positions, and not calibrated forecasts").
10. **Determinism audit:** no `Math.random`, no `Date.now`, no no-arg `new Date()`, no network/DB/`process.env` in `scenarios.js`. The only `Date` construction is `new Date(Date.UTC(year, month, 0))` days-in-month arithmetic; for years 1–9999 this is leap-correct (1900+year remapping for years 1–99 preserves the `year % 4 == 0` leap test, and year 0 is rejected by the guard).

## 2. SPEC verdict

### Acceptance criterion 1 — "Conditional ranges are not calibrated probabilities or directional volatility forecasts." — VERIFIED

- `calibration` is hard-coded `null` on every produced projection (scenarios.js:250); `numericProjectionSchema` requires `calibration: calibrationEvidence.nullable()`, and `calibrated_forecast` additionally requires calibration evidence at the schema level — but `createProjection('calibrated_forecast')` throws `CALIBRATED_FORECAST_GATE` before any object is built (scenarios.js:303–304), so a calibrated forecast cannot be fabricated through this module at all. Test: 'createProjection rejects calibrated_forecast as gated, not fabricated'.
- `CONDITIONAL_SCENARIO_LIMITATION` (scenarios.js:37) states the bounds "are not calibrated probabilities, not an expected direction, and not a forecast path"; tests assert `/not calibrated probabilities/i` and `/not.*expected direction/i`.
- `VOLATILITY_REFERENCE_LIMITATION` (scenarios.js:38) states "not a directional forecast, not a probability interval, and not the analyst expected path"; `createVolatilityReference` rejects any provided `central` (scenarios.js:287–289) — no expected path is representable. Tests assert both limitation regexes and the central rejection.
- Fixture provenance explicitly separates synthetic arithmetic from observed data; anchors/shifts/volatilities are synthetic samples, satisfying the "observed market data and conditional scenarios remain separate" invariant at the artifact level.

### Acceptance criterion 2 — "Null/insufficient inputs remain explicit; downstream optional renderer contract preserved." — VERIFIED

- `nullScenarioProjection` returns frozen `{numeric_projection: null, data_limitations: [...]}` with a non-empty INSUFFICIENT_INPUTS_LIMITATION — explicit null, never a fabricated number. Tests cover the happy path and the non-array rejection.
- `volatilityReferenceBounds` throws when the band would reach or cross zero (scenarios.js:221–223) rather than clamping — insufficient inputs stay explicit. Test: 'volatilityReferenceBounds never clamps a band to or below zero'.
- Every factory output is validated against `numericProjectionSchema` before return (scenarios.js:267–271), so no produced object can violate the CONTRACTS §7 optional-renderer contract.

### Canonical-step mapping — VERIFIED

- Step 1 (retain H07 requirements/methods/inputs + independently computed fixture arithmetic): `conditionalScenarioBounds` and `volatilityReferenceBounds` are reproducible, separately auditable arithmetic; all six fixtures independently recomputed bit-for-bit (§1.3). H07's `metrics.js` is untouched; its `nullNumericProjection` placeholder and "held for H07A" limitation text remain as-is — the author correctly scopes retiring that text to downstream wiring (H09/H15), not this package.
- Step 2 (optional projection objects only, auditable assumptions, compatible basis, no daily paths): `createConditionalScenario`/`createVolatilityReference`/`createProjection` produce only frozen endpoint/range markers (`lower`/`central`/`upper`); no daily paths, no future candles, no path arrays exist anywhere in the module. Conditional scenarios require ≥1 explicit `assumption_ids` (factory and schema both enforce). `adjustment_basis` is a bounded free-text field left to the caller — compatible-basis binding at production time is wiring's responsibility (see QUALITY Q3).

### SPEC verdict: **SPEC_PASS_SOURCE_ONLY**

All source-inspectable criteria verified by independent inspection and rerun. Explicitly NOT established by this review (DEFERRED_TO_DEV_PC / downstream): any Flutter/frontend rendering of the optional projection, deployment-runtime compatibility (host Node v22.22.2 only), wiring of these factories into any route/service/assessment pipeline, and any runtime/release acceptance. Source-only acceptance is not runtime/release approval.

## 3. QUALITY verdict

Coverage honesty: the 28 tests are substantive, not tautological — fixture-driven arithmetic assertions with real expected values, schema round-trip assertions through the authoritative `numericProjectionSchema`, frozen-immutability assertions, fail-closed guard coverage (malformed timestamps, non-real calendar dates like 2024-02-30, non-ISO currency, non-positive bounds, ordering violations, calibrated-forecast gate), and a determinism deepEqual. No weakened or vacuous assertions found.

Non-blocking findings (logged for the wiring lane H09/H15 and any future targeted author repair; none invalidates source-only acceptance):

- **Q1 — Standalone arithmetic helpers can emit non-finite or zero bounds.** `conditionalScenarioBounds(100, {upper_shift: 1e308})` returns `upper: Infinity`, and `conditionalScenarioBounds(100, {lower_shift: -1 + 5e-324})` returns `lower: 0.0` (the `shift <= -1` guard is bypassed by double rounding of `1 + shift`). This contradicts the module header's "Bounds are finite positive numbers". Verified fail-safe downstream: `buildProjection`'s `assertOptionalBound → assertFinitePositiveNumber` rejects both 0 and Infinity, and `volatilityReferenceBounds` fail-closes on the analogous overflow (`lower <= 0` throws). Contained today because the helpers are unwired, but the wiring lane must route computed bounds through factory validation, and a small overflow guard in `conditionalScenarioBounds` would close the gap at the source.
- **Q2 — Timestamp ordering comparison is format-sensitive.** `valid_until < anchor_time` (scenarios.js:259) is a lexicographic string comparison across two accepted formats (`…:00Z` vs `…:00.000Z`): `Z` (0x5A) sorts after `.` (0x2E), so two equal instants written in different accepted formats would spuriously throw. Fail-closed direction, cosmetic surface, unreachable through current callers that pass a single fixed-format fixture — noted for the wiring lane.
- **Q3 — Object production and bound arithmetic are deliberately disjoint.** `createConditionalScenario` validates that bounds are ordered positive numbers but does not bind them to `conditionalScenarioBounds(shifts)`; auditability of a produced object rests on the caller/wiring passing recomputable bounds. This matches the card's separation of "calculation" and "object production" and the stated H09/H15 ownership; recorded here so the wiring lane inherits the discipline explicitly.
- **Q4 — TDD first-green evidence lost to the infrastructure crash** (prior run 276, gateway session loss ~11:48 UTC; disclosed in h07a-author.md §4). The on-disk green state was independently re-verified this run (28/28 + full aggregate 357/357) and the fixture arithmetic was recomputed independently of both the JS implementation and the author's Python re-check. Honest disclosure; no repair needed.

Quality verdict: **QUALITY_PASS_SOURCE_ONLY** — with Q1–Q4 recorded as non-blocking, and the explicit limitation that quality here covers the unwired pure module plus its tests only; Flutter/runtime criteria remain DEFERRED_TO_DEV_PC and are not passed by this verdict.

## 4. Verdicts

- **SPEC: SPEC_PASS_SOURCE_ONLY** (both acceptance criteria independently verified at source level; all unexecuted PC/runtime criteria explicit above).
- **QUALITY: QUALITY_PASS_SOURCE_ONLY** (0 blocking findings; 4 non-blocking findings recorded).

Historical findings in prior review files are preserved; this review adds only this file. No source files were repaired, no new cards created.
