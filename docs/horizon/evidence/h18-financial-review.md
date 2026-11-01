# H18 — Focused final-readiness and financial-UX review (cross-package financial chain)

**Reviewer:** reviewer / zai-glm-5.3-flash (distinct profile/model from author worker/gpt-5.6-terra; vendor disclosure per contract)
**Date:** 2026-11-01
**Scope:** the orchestrator's focused-release comment only — the CROSS-PACKAGE financial chain. Per-package verdicts (H07/H07A, H04, H11, H14, H15, H16) stand and are not re-litigated.
**Baseline:** main @ `a9d2600c789a6d7b564fc3f0068eac1f91924a94`, 29 dirty/untracked entries preserved untouched (delta over the accepted 27-entry baseline is exactly the H18/H16/H09X/H10X/H07A evidence files). Reviewer wrote only `docs/horizon/evidence/h18-financial-review.md` + sanitized logs under `docs/horizon/evidence/h18/`. No source edits, no commits.

## Verdicts

| Verdict | Result |
|---|---|
| Specification (financial chain) | **SPEC_PASS_SOURCE_ONLY** |
| Quality (financial chain) | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts are **source-level**. They are not runtime, deployment, or full-release approval, and they do not lift any operator gate from `h18-review.md` §6. H19 remains Adam's decision alone.

---

## 1. Independent recomputation (real modules, committed fixtures)

Node v22.22.2, offline, foreground, repo root. Logs: `h18/reviewer-financial-recompute.log` (full run) and `h18/reviewer-financial-recompute-part2.log` (corrected §3/§4 rerun). **Honesty note on the logs:** run 1 had two script-side bugs of mine (fixture `absolute_pl` shape, H04's numeric-quote signature); run 3 had 6 FAILs that were also script-side (I passed numeric money amounts where `composeEconomics` requires bounded decimal **strings** — the H07 contract working as intended) and one wrong `outlookHorizons` key. All corrected in the part-2 rerun; logs are preserved as-is, unedited. **52/52 checks pass** across the corrected runs (11 fixture + 14 H04 + 7 composeEconomics/seam + 14 scorecard + 6 calendar).

| Chain link | Recomputed result |
|---|---|
| **H07 `profitAndLoss`** — every committed `pnl_cases` fixture | 11/11. `matching_currency_and_basis` percent_pl 0.19900497512437812, absolute 100; zero and fractional-quantity cases exact; both mismatch cases return `{status:'unavailable'}` with **no number fields emitted at all** |
| **H04 `computeProfitLoss`** (BigInt scale-12, round-8) | 14/14. available 19.90049751% / 100 USD; zero exact; fractional 12.5 qty → 125 / 25%; loss → −100 / −16.59751037%; currency/basis/unknown-cost/not-owned all block with **no numeric fields**; fees/dividends explicitly excluded; label "user cost reference, not market support or fair value" |
| **H04 ↔ H07 agreement** | H04 percent/100 vs H07 percent_pl agree within 1e-8 on the same economics (two independent implementations — BigInt fixed-point vs IEEE-754 double — same verdicts, same magnitudes) |
| **`composeEconomics`** (H07 path into assessments) | bit-identical percent_pl to the direct H07 call; every unavailable path (`missing_average_cost`, `missing_current_price`, `state_without_executed_economics`, `currency_mismatch`, `adjustment_basis_mismatch`, invalid input → `economics_input_invalid`) returns a typed reason and never a number, never a throw |
| **H16 `computeScorecard`** | hit_rate is `null` below `MIN_MATURE_OBSERVATIONS`=10 with status `insufficient_observations`; at 9 hits/10 it is exactly 0.9 with `is_calibrated_probability:false`, `edge_claim:null`; `insufficient_evidence` entries go to an unscored bucket and never enter the denominator; quality dimensions count only explicit pass/fail — `unknown` values are excluded from totals **and declared** per-assessment; never-observed dimensions stay 0/0 (no average invented, no rate field on aggregates) |
| **Calendar horizons** (feeding H14 panel dates) | month-end clamping exact: 2026-01-31→2026-02-28, 2024-01-31→2024-02-29 (leap), +3mo→2026-04-30, 2026-11-30+3→2027-02-28; `outlookHorizons` returns exactly 1/2/3 with clamped targets |

## 2. Financial-UX honesty (H14/H15/H11 rendering chain) — VERIFIED by source read

- **H14 `outlook_panel.dart`:** a null `numeric_projection` renders the explicit "No quantified projection for this assessment" message; a present one is framed by its kind verbatim ("Conditional scenario — not observed prices and not a probability interval", etc.), renders bounds only when non-null, always with currency, method, version and the projection's own limitations. `dataLimitations` are rendered whenever present. `insufficient_evidence` direction is labeled and styled muted, never as a neutral-positive.
- **H11 `research_models.dart` enforces what the panel relies on:** exactly one 1/2/3-month outlook (panel's `firstWhere` can never hit a missing horizon); the model **re-derives** month-end clamping client-side and rejects mismatched targets; evaluation session cannot predate `session_as_of` or postdate the target; projection identity must match assessment/snapshot/instrument/evaluation session; bounds are nullable finite **positive** numbers with pairwise ordering enforced and at least one bound required. Fabricated projections cannot parse.
- **Position economics UI:** `PositionEconomicsLine` renders explicit unavailability ("Cost unknown — enter your average cost and quantity to enable profit/loss"), never zero, never invented; the editor's currency-mismatch banner states nothing is converted silently. **No client-side P&L computation exists anywhere in the Flutter tree** — the only numeric formatters are display formatters over server-provided fields (`currentPrice`, `changePercent`, sentiment/score), and `changePercent` defaults to the disclosed 0.0 sentinel rendered as `—`.
- **Wear (H15):** `wear_opportunities_screen.dart` renders `—` for the unavailable-price sentinel ("no fabricated $0.00 on the watch", disclosed in-source) and an explicit "No alpha signals" empty state.
- **No prose-price scraping anywhere in the chain:** `yahoo.js` parses structured chart JSON arrays; research providers parse structured feed tags only (title/link/date/description); `result_validator.js` flags any numeral in an observed claim without a metric reference (`UNREGISTERED_NUMBER`); the numeric-integrity quality dimension exists precisely to catch fabricated numerals.

## 3. Finding F1 (non-blocking; explicit operator-activation gate): adjustment-basis vocabulary seam

Three basis vocabularies coexist with no mapper anywhere in the tree:

- Position cost basis: `raw_purchase` | `split_reconciled` (`position.model.js` `COST_BASES`, H04 amendment, default `raw_purchase`);
- Market provider price basis: `raw_ohlc_unadjusted` (`yahoo.js:149`), `unavailable` fallback (`market.service.js:150`);
- H04 `computeProfitLoss`'s price-side mapper expects `raw` | `split_adjusted` (it maps `raw_purchase`→`raw`, `split_reconciled`→`split_adjusted`).

`metrics.profitAndLoss` compares basis strings for **equality** (opaque strings, H07A review Q3 already assigns compatible-basis binding to wiring). My seam probe recomputed the natural naive wiring — operator `inputProvider` passes the market snapshot's basis verbatim against a default-basis position:

```
composeEconomics(raw_purchase vs raw_ohlc_unadjusted) → {status:'unavailable', reason:'adjustment_basis_mismatch'}
computeProfitLoss (H04) same inputs                  → {status:'unavailable', reason:'split_basis_unreconciled'}
```

**Classification: fail-closed, honesty invariants hold (a typed reason, no fabricated number), and the surface is currently unwired (`inputProvider` is operator-provisioned; the automation surface is unmounted), so this cannot mislead anyone today.** But unremediated it makes economics systematically unavailable for *every* default-basis position at activation. No test spans the real strings from both schemas (positions tests use synthetic `raw`/`split_adjusted`; agent-runtime tests use `raw_purchase` on both sides — the seam itself is untested). **Required at activation (operator, add to the §6 gate list of h18-review.md):** the `inputProvider` must map the market basis onto the comparison vocabulary (or normalize both sides), and a test must pin the seam using `position.model.COST_BASES` values against the actual provider emission (`raw_ohlc_unadjusted`). This review does not repair source; the owning lane applies the fix when wiring is scoped.

## 4. Other observations (non-blocking, no action required for this verdict)

1. **H04 `computeProfitLoss` is unwired** — unit-tested (positions.test.cjs:464–512) but exposed through no route; the Flutter UI computes and displays no P&L number at all. Consistent with the H04 route scope (GET/POST/PATCH only) and with CONTRACTS §2's ask-in-UI posture; recorded so the release picture is explicit: no user-facing computed P&L exists in this delivery.
2. **Two P&L implementations coexist** (H04 BigInt fixed-point, H07 IEEE-754 double) with different input conventions (numeric quote vs decimal-string money). Both independently verified consistent within 1e-8 on identical economics; each is internally coherent; noted as deliberate duplication to keep an eye on, not a defect.
3. H16's `generated_at` uses the wall clock — correct for a report timestamp, not a calculation input.

## 5. Unexecuted criteria (explicit, NOT passed)

- All Flutter analyze/test/device/APK execution — **DEFERRED_TO_DEV_PC**; runtime proof on record remains the operator-executed Dev-PC gate, which this review did not re-run.
- No live models, MongoDB, n8n, market APIs or production systems were executed in this review. Host Node v22.22.2 does not establish deployment-runtime compatibility.
- The `inputProvider` basis mapping (§3) and all other operator gates from `h18-review.md` §6 remain open; this focused review adds to, and does not narrow, that list.
- Full-release acceptance is NOT granted from source; H19 is Adam's decision alone.

## 6. Verdict basis

SPEC_PASS_SOURCE_ONLY: every focused-scope requirement — deterministic recomputation across the full chain, UX honesty (unavailable states never render fabricated numbers, no prose-price scraping, typed truthful error surfaces), and H16 scorecard missing-data declaration — is verified in §1–§2 from real modules and committed fixtures, or is an explicit item in §3/§5. QUALITY_PASS_SOURCE_ONLY: the chain composes coherently and fails closed at every seam probed; the one defect class found (F1) is a fail-closed vocabulary seam with a concrete, actionable wiring requirement, disclosed here rather than silently waived.

— reviewer, 2026-11-01
