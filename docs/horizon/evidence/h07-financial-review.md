# H07 — Focused deterministic financial-calculation review

- Task: t_3861998c (H07 focused financial-calculation gate); parent combined review t_68e6a5b2 (PASSED source-only)
- Reviewer: reviewer (deepseek), author: worker/zai — vendor-disjoint per release note
- Date: 2026-10-31
- Scope: **financial-calculation surfaces only**, as directed by the orchestrator focused-scope comment. This does **not** repeat the full combined review; that verdict (SPEC_PASS_SOURCE_ONLY + QUALITY_PASS_SOURCE_ONLY, F1 resolved) stands and is not re-litigated here.
- Baseline: HEAD `9fbb26b` preserved; no branch/commit/push/cleanup. Existing dirty/untracked baseline untouched. Source allowlist READ-ONLY — no source edits, no repairs, no new cards.

## Verdicts (focused financial scope)

| Verdict | Result |
|---|---|
| **SPEC (financial calc)** | **SPEC_PASS_SOURCE_ONLY** |
| **QUALITY (financial calc)** | **QUALITY_PASS_SOURCE_ONLY** |

## Independent reproduction (this run)

Node host `v22.22.2`, offline, foreground, `/home/ubuntu/apps/Horizon`. No live APIs, credentials, DB, installs.

```
node --test backend/test/research-metrics.test.cjs   -> 24/24 pass (exit 0)
```

All expected values below were recomputed **independently in Python** (IEEE-754 double, with `decimal.Decimal` for exact-money cross-checks) — not by re-running the JS fixtures, and not by trusting the author's self-report.

## 1. profitAndLoss — independent recomputation (all 5 fixture cases)

Exact-decimal cross-check plus double-precision reproduction:

| case | diff (exact) | absolute_pl | percent_pl | verdict |
|---|---|---|---|---|
| matching_currency_and_basis (avg 50.25, cur 60.25, qty 10) | 10.00 | **100.0** ✓ | **0.19900497512437812** ✓ (double; exact = 0.19900497512437810945…) | MATCH |
| zero_pl_same_cost (avg=cur 50.25, qty 10) | 0.00 | **0.0** ✓ | **0.0** ✓ | MATCH |
| fractional_quantity (avg 40, cur 50, qty 12.5) | 10.00 | **125.0** ✓ | **0.25** ✓ | MATCH |
| currency_mismatch (USD vs EUR) | — | n/a | n/a | `{status:'unavailable', reason:'currency_mismatch'}` ✓ — no silent FX (CONTRACTS §2) |
| adjustment_basis_mismatch (split_adjusted vs raw_ohlc_unadjusted) | — | n/a | n/a | `{status:'unavailable', reason:'adjustment_basis_mismatch'}` ✓ — splits must be reconciled |

Ordering note: currency is checked **before** basis in `profitAndLoss` (metrics.js:256–261), so a doubly-mismatched input reports `currency_mismatch`. Deterministic and unambiguous; both block paths return `absolute_pl`/`percent_pl` as `undefined` (no fabricated number).

## 2. Volatility / drawdown / relative returns — independent recomputation

| fixture | independent result | expected | verdict |
|---|---|---|---|
| monotonic simple_returns | [0.05, 0.05] | [0.05, 0.05] | MATCH |
| monotonic mean | 0.05 | 0.05 | MATCH |
| monotonic cumulative | 0.1025 (double 0.10250000000000004) | 0.1025 | MATCH (≤1e-12 tol) |
| with_drawdown simple_returns | [0.2, −0.2, 0.25] | same | MATCH |
| with_drawdown mean | 0.08333333333333333 | same | MATCH |
| with_drawdown sample_variance | 0.060833333333333336 | same | MATCH (n−1 denominator) |
| with_drawdown sample_stddev | 0.24664414311581237 | same | MATCH |
| with_drawdown annualized_vol | 3.915354390090379 | same | MATCH (×√252) |
| with_drawdown cumulative | 0.2 (double 0.19999999999999996) | 0.2 | MATCH (≤1e-12 tol) |
| with_drawdown max_drawdown | −0.2 (double −0.19999999999999996); peak_idx 1, trough_idx 2, peak 120, trough 96 | −0.2 / 1 / 2 / 120 / 96 | MATCH |
| relative per_period_excess | [−0.15, 0.25] | same | MATCH |
| relative cumulative_relative | 0.1484375 | same | MATCH |

Sample variance uses `n−1` (sample, not population) — correct for the stated `sample_volatility_annualized` method. Max drawdown is computed as `close/peak − 1` with a correct running-peak index; the peak/trough indices and values match exactly.

## 3. Decimal-string parsing bounds — DECIMAL_LIMITS reuse

`metrics.js` imports `DECIMAL_LIMITS` from `./contracts` and reuses `maxLength` / `maxIntegerDigits` / `maxFractionDigits` in `parsePositiveDecimalString` (metrics.js:100–105). No reimplementation, no drift — single source of truth. Independent boundary probes:

| probe | result |
|---|---|
| `"50.25"` | ACCEPT |
| `"0"`, `"-50.25"`, `"abc"`, `"1e3"`, `"60.25.1"` | REJECT (not a bounded positive decimal string) |
| `0.` + 12 fraction digits | ACCEPT |
| `0.` + 13 fraction digits | REJECT (fraction bound) |
| 24 integer digits | ACCEPT |
| 25 integer digits | REJECT (integer bound) |

**Reviewer observation (non-blocking):** the orchestrator focused-scope comment refers to a "≤18/≤12" bound. The actual `DECIMAL_LIMITS` in `contracts.js:11` is `{ maxLength: 40, maxIntegerDigits: 24, maxFractionDigits: 12 }` — integer bound **24**, not 18. CONTRACTS v1 §1 prescribes "bounded decimal strings" without a fixed digit count, so the value is an implementation detail; the operative requirement (single source of truth, reused, not drifted) is satisfied. Recording this so the board's mental model of the limit is corrected — not a defect.

## 4. No float-only paths on money inputs

`parseMoney` → `parsePositiveDecimalString` requires `typeof value === 'string'` and a bounded-decimal shape; a numeric `amount` is rejected (`amount: 50.25` (number) → REJECT). Money/quantity inputs cannot enter as raw floats. The only IEEE-754 conversion is the documented one below (derived analytics).

## 5. No nondeterministic sources in calculation paths

Source scan of `metrics.js`: no `Math.random`, no `Date.now`, no no-arg `new Date()`. The only `Date` construction is `new Date(Date.UTC(year, month, 0))` in `isRealCalendarDate` (metrics.js:51) — deterministic days-in-month calendar arithmetic, not a clock read (this is the previously noted Note E: the scan regex would miss a future `new Date(<arg>)`, but the current construction is deterministic and correct). `Math.random`/`Date.now`/`new Date()` occurrences elsewhere in the tree (`briefing.service.js`, `position.service.js`, `market.service.js`, providers) are **outside the H07 scope** and are not part of these metric calculation paths.

## 6. IEEE-754 double conversion — consistent with CONTRACTS v1

`parsePositiveDecimalString` returns `Number(value)`; P&L arithmetic (`difference = current − average`, `quantity * difference`, `difference / average`) runs in double. This matches CONTRACTS v1 §1 exactly: *"Decimal money and quantity inputs use bounded decimal strings; provider OHLC values and derived analytical metrics use finite JSON numbers with explicit basis."* The module header (metrics.js:12–16) discloses this explicitly. Observed double rounding (e.g. cumulative 0.19999999999999996 vs 0.2; percent_pl exact 0.19900497512437810945… stored as 0.19900497512437812) is the disclosed, deterministic behavior; the fixture tolerance (1e-12 relative) absorbs it and every expected value is the correctly-rounded double, reproduced bit-for-bit by my independent Python computation. No NaN/Infinity can reach output (`parsePositiveDecimalString` and every `assertFinite*` guard reject them). No fabricated projection: `NUMERIC_PROJECTION_LIMITATION` + `nullNumericProjection()` keep `numeric_projection` null with an explicit H07A-held limitation.

## Calendar horizons (spot-check, delegated to H01 contracts)

Independent Python re-derivation of `calendarTargetDate` month-end clamping and `evaluationSessionDate` walk-back: all 10 calendar-target cases (leap 2024-02-29, non-leap 2023-02-28, year roll h1/h2/h3, 2024-02-29→2024-03-29, year-10000 overflow rejection) and all 3 holiday/weekend walk-back cases (Easter-Monday/Good-Friday → 2024-03-28; July-1/Sunday → 2024-06-28; May-5/Sunday → 2024-05-03) match. Weekday sanity confirmed against real 2024 calendar (2024-04-01 = Monday, 2024-03-29 = Friday, 2024-02-29 = Thursday). `metrics.js` delegates all of this to the H01-owned `contracts` primitives — correct ownership, no reimplementation.

## Historical findings preserved (from t_68e6a5b2, unchanged)

Non-blocking Notes B–E remain open by explicit author disclosure and are out of this focused financial scope: Note B (`profitAndLoss` result not top-level frozen), Note C (`relativeReturns` guards benchmark `<= −1` but not base), Note D (`isRealCalendarDate` accepts year 0000), Note E (source-scan regex would miss `new Date(<arg>)`). None is a financial-math correctness/safety defect at contract version 1. F1 (frozen-record registry) was resolved and independently verified by the parent review.

## Deferred / unexecuted criteria (explicit, NOT passed)

- All Flutter analysis/generation/tests/device/APK checks — **DEFERRED_TO_DEV_PC**.
- Runtime/release/PC acceptance — NOT covered by this source-only review.
- `numeric_projection` production (H07A conditional-scenario/volatility-reference) — held; must be independently accepted before any numeric projection exists.
- Metrics pipeline wiring into routes/services/assessment composition — downstream (H09/H15 lanes).
- Host Node v22.22.2 does not establish deployment-runtime compatibility.
