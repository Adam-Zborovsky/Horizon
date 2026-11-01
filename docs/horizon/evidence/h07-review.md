# H07 — Combined independent specification and quality review

- Task: t_68e6a5b2 (H07 review); author delivery t_0b20800d
- Reviewer: reviewer (deepseek), author: worker/zai — vendor-disjoint per release note
- Date: 2026-10-31
- Scope: source-only. Flutter/runtime/PC checks are DEFERRED_TO_DEV_PC and are **not** covered by either verdict.
- Baseline: HEAD `9fbb26b` preserved; no branch/commit/push/cleanup. Existing dirty/untracked baseline untouched.

## Verdicts

| Verdict | Result |
|---|---|
| **SPEC** | **SPEC_PASS_SOURCE_ONLY** |
| **QUALITY** | **QUALITY_FAIL_SOURCE** — one blocking finding F1 |

## Independent reproduction (this run, host node v22.22.2, hermetic offline)

All commands run foreground in `/home/ubuntu/apps/Horizon`. No live APIs, credentials, DB, installs.

```
node --version                                                   -> v22.22.2
sha256sum (3 delivered files)                                    -> all 3 match author-declared hashes exactly
git diff --check                                                 -> clean (exit 0)
node --test backend/test/research-metrics.test.cjs               -> 23/23 pass
node --test backend/test/*.test.cjs                              -> 125/125 pass (all 7 suites)
git log --oneline -1                                             -> 9fbb26b (no commit introduced)
```

Hash verification (matches `docs/horizon/evidence/h07/verification.log` and `h07-author.md` §1):

```
afbe204983180bf1dbe442e57a7ef8f36fedb7444cef1512e9c6f4e808b3710d  backend/src/features/research/metrics.js
1b7ff4b3a3823d7127ba7e164c4ec578fdf1bd97ee22fcbd2e4fce1ee7c49349  backend/test/research-metrics.test.cjs
9206f594052a0326d0ae20295d334f7fac70aade3550d92b05b259ca1eb7127e  backend/test/fixtures/research/metrics-fixtures.json
```

Author self-reports are corroborated, not relied on: I independently recomputed every fixture expected value in offline Python (double-precision). Returns, mean, sample variance/stddev, annualized volatility, max drawdown (peak/trough indices and values), relative-return excess and cumulative-relative, and all P&L cases (absolute/percent, same-cost zero, fractional quantity, currency/basis mismatch) all match the fixture. Calendar facts independently verified: 2024-02-29 leap clamp, 2023-02-28 non-leap clamp, year roll 2024-12-31 h1/h2/h3, 2024-02-29→2024-03-29, Easter-Monday/Good-Friday walk-back to 2024-03-28, Sunday/July-1 holiday walk-backs, year-10000 overflow rejection. Fixture provenance is correctly labeled synthetic — `fixture_kind: "deterministic_metric_reference"` and `fixture_purpose` asserting "not observed market data, not user positions, and not projections" (satisfies the "no invented prices/history" invariant).

## SPEC analysis

**AC1 — "Money/quantity handling is deterministic; same-cost/split/currency assumptions tested."** PASS.
`profitAndLoss` (metrics.js:246–274) takes bounded decimal-string economics via `parsePositiveDecimalString`, reusing `DECIMAL_LIMITS` from `./contracts` (no reimplementation). Determinism proven by repeated-call `deepEqual` and by a source scan asserting absence of `Math.random`/`Date.now`/`new Date()`. Same-cost → zero P&L tested; currency mismatch → `{status:'unavailable', reason:'currency_mismatch'}` (no silent FX, CONTRACTS §2); basis mismatch → `adjustment_basis_mismatch` (splits must be reconciled); fees/dividends labeled excluded. Note A (non-blocking): decimal strings are converted to IEEE-754 doubles for arithmetic; results are deterministic finite JSON numbers, consistent with CONTRACTS §1 (inputs are decimal strings; derived analytics are finite JSON numbers). No decimal-rounding policy is applied — none is specified at contract version 1; the author discloses this in `h07-author.md` §6. This is a disclosed limitation, not a contract violation.

**AC2 — "Calendar target/evaluation sessions correct at month ends, holidays and leap years."** PASS.
`outlookHorizons` (metrics.js:280–297) delegates all calendar arithmetic to H01-owned `contracts.calendarTargetDate`/`evaluationSessionDate` — correct ownership, no reimplementation, no session-date-by-UTC-truncation. Fixture cases cover leap/non-leap clamp, year roll, holiday + weekend walk-backs, and year-10000 overflow. Evaluation session is asserted to never predate `sessionAsOf` and never exceed the calendar target. The corrected Easter-Monday fixture (2024-04-01 declared a holiday) is present and correct.

**AC3 — "Metric references remain reproducible and code-calculated; no fabricated projection."** PASS.
`createMetric` produces the exact CONTRACTS §4 Metric shape; registry `list()` is sorted/reproducible; volatility metric labels are asserted to exclude expected/probability/direction/forecast vocabulary (CONTRACTS §7: volatility references are never directional forecasts); `NUMERIC_PROJECTION_LIMITATION` + `nullNumericProjection()` keep `numeric_projection` null with an explicit limitation, with no scenario engine and no projection values anywhere (H07A held).

**Invariants** — secrets: none (files read in full; no credentials/`.env`); no ports/DNS/tunnel; no shell backgrounding; no commit/push/history rewrite; no live ops; observed-vs-synthetic separation honored (fixtures explicitly non-observed). All satisfied.

## QUALITY analysis

**F1 (blocking) — metric registry stores the mutable original, discarding the frozen validated record.**

`createMetricRegistry().register` (metrics.js:350–357) validates via `createMetric` — which returns a frozen, sanitized record — then stores and returns the **original input object**, discarding the frozen copy:

```js
register(metric) {
  const validated = createMetric(metric);      // frozen, sanitized — then thrown away
  if (metricsById.has(validated.id)) { throw ... }
  metricsById.set(validated.id, metric);       // stores the mutable ORIGINAL
  return metric;                               // returns the mutable ORIGINAL
}
```

Independently reproduced:

```
stored === raw: true          # registry holds the caller's raw object, not the frozen record
stored frozen: false
after mutating raw, registry value: 999   # post-registration mutation leaks into the registry
register returns frozen?: false
```

This violates the "freeze evidence snapshot and derived metrics" requirement (SPEC step 4; CONTRACTS §4 immutable `EvidenceSnapshot`/derived metrics). `get`/`list` hand out live mutable references, so a downstream consumer (H09 composition) can silently mutate a "frozen" metric. The author clearly intends immutability — `createMetric` freezes and the test asserts `Object.isFrozen(metric) === true` — but the registry wiring drops it. The test does not expose the gap because it registers pre-`createMetric`-ed (already frozen) objects and asserts identity, not immutability-of-stored-value.

Fix is small and localized: store and return the validated record (`metricsById.set(validated.id, validated); return validated;`), and adjust the registry test's identity assertion (`registry.get('metric-a') === first`) to assert field equality or add a mutation test proving the stored value cannot be changed post-registration.

**Non-blocking observations (no action required for this verdict, noted for the record):**

- Note B — `profitAndLoss` freezes only the inner `excluded_adjustments` array, not the returned object; harmless (a fresh object is produced per call, no shared state) but inconsistent with `createMetric`/`nullNumericProjection` which freeze their results.
- Note C — `relativeReturns` (metrics.js:212–233) guards `benchmarkReturns[i] <= -1` (division-by-zero/negative-growth) but not `returns[i] <= -1`; safe for returns derived from positive-price `simpleReturns` (never `< -1`), but asymmetric if the function is ever fed arbitrary values.
- Note D — `isRealCalendarDate` (metrics.js:44–53) accepts year `0000`, which `contracts.isValidDateParts` rejects (`year >= 1`); no product impact (the delegated `calendarTargetDate` rejects year 0 downstream), but the two date validators differ at the boundary.
- Note E — the "no nondeterministic clock" source scan regex `/new Date\(\)/` would not catch a future `new Date(<arg>)`; `isRealCalendarDate` legitimately uses `new Date(Date.UTC(...))` which is deterministic, so the current claim holds.

## Deferred / unexecuted criteria (explicit, NOT passed)

- All Flutter analysis/generation/tests/device/APK checks — DEFERRED_TO_DEV_PC.
- Runtime/release/PC acceptance — NOT covered by this source-only review.
- `numeric_projection` production (H07A conditional-scenario/volatility-reference) — held; must be independently accepted before any numeric projection exists.
- Metrics pipeline wiring into routes/services/assessment composition — downstream (H09/H15 lanes).
- Host Node v22.22.2 does not establish deployment-runtime compatibility.

---

# Re-review — 2026-10-31 (targeted: F1 only)

Scope: author repair t_56142c25 addresses **F1** (metric registry frozen-record storage). Non-blocking notes B–E remain open by explicit author disclosure and are out of scope. SPEC verdict is **unchanged** (fixture byte-identical; no behavioral change to the already-passed computation/calendar surfaces). This section augments — does not replace — the findings above.

## Verdicts (updated)

| Verdict | Result |
|---|---|
| **SPEC** | **SPEC_PASS_SOURCE_ONLY** (unchanged from initial review) |
| **QUALITY** | **QUALITY_PASS_SOURCE_ONLY** — F1 resolved |

## Independent re-verification of F1

Source inspected at `backend/src/features/research/metrics.js:350–357`: `register` now stores and returns the frozen validated record:

```js
register(metric) {
  const validated = createMetric(metric);
  if (metricsById.has(validated.id)) { throw new RangeError(...); }
  metricsById.set(validated.id, validated);   // was: metric
  return validated;                           // was: metric
},
```

`has`/`get`/`list`/`size` are unchanged and read from the same `Map`, so they now hand out the frozen record. The new regression test (`research-metrics.test.cjs:280–309`, *"metric registry stores and returns the frozen validated record, never the caller mutable original"*) registers a raw (non-frozen) object, mutates the original post-registration, and asserts no leakage. The existing identity assertion was correctly downgraded from `===` to `deepEqual` + `Object.isFrozen` (lines 272–273) to match the prescribed behavior change.

Independent host reproduction (node v22.22.2, strict mode, foreground):

```
returned is frozen:     true
stored is frozen:       true
returned === stored:    true      # registry stores and returns the SAME frozen record
stored === raw:         false     # NOT the caller's raw object
after mutating raw -> registry value: 0.3   (raw.value=999 did not leak)
registry currency:      USD       (raw.currency=EUR did not leak)
registry ids:           ["e1"]    (raw push did not leak)
list() all frozen:      true
frozen write throws:    TypeError (strict mode)
get('missing') ->       null
```

The mutation-leakage symptom that defined F1 (mutating the raw object changed the registry value to 999) is gone: the registry holds the frozen validated record, mutation of the original does not propagate, and `get`/`list` return frozen records.

## Independent test reproduction

```
node --test backend/test/research-metrics.test.cjs   -> 24/24 pass (was 23/23 + 1 regression)
node --test backend/test/*.test.cjs                  -> 126/126 pass (all 7 suites)
git diff --check                                      -> clean, exit 0
git log --oneline -1                                  -> 9fbb26b (no commit introduced)
```

SHA-256 (recomputed this run, match `h07-repair.md` §SHA-256 exactly; fixture byte-identical to the reviewed delivery):

```
2730600850491270f878703c0f65c06d1d1424fc8377ebad7981f17d44cb3d1b  backend/src/features/research/metrics.js
bf411b7bf09f927b52792e2140954b66f3727ae674e7326c26c5582e6682b347  backend/test/research-metrics.test.cjs
9206f594052a0326d0ae20295d334f7fac70aade3550d92b05b259ca1eb7127e  backend/test/fixtures/research/metrics-fixtures.json  (UNTOUCHED)
```

Only the two allowlisted files changed; no other files touched. Red run is real (`h07-repair.md` §RED run: 23 pass / 1 fail on `Object.isFrozen(returned) === true` at line 299 before the fix), not a setup failure.

## Non-blocking observations B–E — status

Unchanged and still open (author explicitly scoped them out of this repair): Note B (`profitAndLoss` result not top-level frozen), Note C (`relativeReturns` guards benchmark `<= -1` but not base), Note D (`isRealCalendarDate` accepts year 0000), Note E (source-scan regex `/new Date\(\)/` would miss `new Date(<arg>)`). None is a correctness/safety defect at contract version 1; recorded for the record, no action required for this verdict.

## Deferred / unexecuted criteria (unchanged, NOT passed)

- All Flutter analysis/generation/tests/device/APK checks — DEFERRED_TO_DEV_PC.
- Runtime/release/PC acceptance — NOT covered by this source-only review.
- `numeric_projection` production (H07A) — still held.
- Metrics pipeline wiring (H09/H15) — downstream.
