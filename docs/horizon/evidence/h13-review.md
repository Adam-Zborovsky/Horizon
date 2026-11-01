# H13 — Combined independent specification and quality review

**Package:** H13 — Interactive observed-data chart and projection display
**Date:** 2026-10-31
**Reviewer:** reviewer (deepseek-v4-pro)
**Author:** worker (zai) — author delivery t_76ee4e19
**Contract baseline:** CONTRACTS.md v1 §3/§7, SPEC.md §3, AMENDMENT-2026-10-30.md
**Scope:** core_source, source-only. No Dart/Flutter SDK on this host — every
runtime/PC criterion is DEFERRED_TO_DEV_PC and listed in §Limitations.

## Verdict summary

| Verdict | Result |
|---|---|
| Specification | **SPEC_FAIL_SOURCE** |
| Quality | **QUALITY_FAIL_SOURCE** |

Both verdicts fail at source-only scope. Two blocking findings (F1 compile error,
F2 overlay-defaults-off violation) require one targeted author repair before
re-review. This is not runtime or release approval under any circumstance.

---

## Scope and method

Independently inspected (read in full):

- `frontend/lib/src/features/stock/widgets/chart_controller.dart` (445 lines)
- `frontend/lib/src/features/stock/widgets/price_chart.dart` (1,128 lines)
- `frontend/test/price_chart_test.dart` (653 lines)
- `frontend/lib/src/features/market/market_models.dart` (H11, 363 lines)
- `frontend/lib/src/features/positions/position_models.dart` (H11, 597 lines)
- `frontend/lib/src/features/research/research_models.dart` (H11, 1,490 lines)
- `frontend/test/chart_capability_test.dart` (H02 accepted probe)
- `docs/horizon/evidence/h02-review.md` (accepted probe architecture + non-blocking notes)
- `docs/horizon/evidence/h13-author.md`, `docs/horizon/evidence/h13/sha256sums.txt`,
  `docs/horizon/evidence/h13/static-scan.log`
- `docs/horizon/CONTRACTS.md`, `docs/horizon/SPEC.md`
- `backend/test/fixtures/research/observed-bars.json`

Independently reproduced / verified:

- SHA-256 of all three deliverables (3/3 match author claims).
- `git diff --check` (clean, exit 0); `git status --porcelain` (only the three new
  H13 paths; no existing file, shared glue, or pubspec/lock modified).
- Secret/credential scan over the three files (clean).
- Daily-bar fixture values vs `observed-bars.json` (all four bars match exactly;
  provenance `content_sha256` `dcf75e…` matches the fixture's `source` block).
- fl_chart 1.1.1 API surface consistency against the accepted H02 probe.

No Flutter SDK exists on this server (`dart`/`flutter` absent). The 21-case widget/
controller suite was **not executed**; it is DEFERRED_TO_DEV_PC. This review judges
source correctness, contract fidelity, and test-assertion correctness, not runtime
behavior.

---

## Positive findings (verified)

1. **Hash integrity.** All three files re-hash to the author's declared SHA-256
   (`3ae01579…`, `7faa125b…`, `b55cacb0…`). No drift since delivery.
2. **Baseline preserved.** The three deliverables are new/untracked files; no
   existing file, shared glue, or `pubspec.yaml`/`pubspec.lock` was edited. `git
   diff --check` clean. No commits/pushes/branch changes.
3. **No secrets/confidential data.** The only `token` matches are the request-token
   cancellation variable, not credentials. No `.env`, API keys, or business data.
4. **Fixture provenance is honest.** The four daily bars in `price_chart_test.dart`
   match `backend/test/fixtures/research/observed-bars.json` bar-for-bar (time,
   session_date, O/H/L/C, volume); the fixture carries a Yahoo-chart provenance
   record with `content_sha256` `dcf75e…`, and the test comment cites that digest
   correctly. Projection fixtures are synthetic typed-model instances labeled as
   such. No manufactured candles or future daily trajectories.
5. **H02 review non-blocking notes honored.** (a) The volume strip is de-synchronized
   and relabeled "Volume context — inspected bar highlighted" (price_chart.dart:891);
   (b) the controller consumes H11's full `NumericProjection`/`MoneyAmount`/`MarketBar`
   models rather than the probe's rendering subset; (c) an explicit X-axis-equivalence
   assertion was added (test "line and candle charts share one index-based X axis").
6. **No future candles structurally.** `maxX = bars.length - 1`; candle spots are
   built from `entry.key` (bar index) only, so `candlestickSpots` count equals the
   observed bar count and no spot exceeds the last index. Projections render only as
   dashed horizontal lines (`ExtraLinesData`) plus a low-opacity band
   (`RangeAnnotations`), never as future spots.
7. **Stale/null projection states are typed, not prose-derived.** `projectionGate`
   computes `toggleOff/none/stale/basisMismatch/noHistory/visible` from typed
   timestamps (`anchorTime`, `validUntil`, bar `time`, `fetchedAt`) and typed
   currency/basis fields. The snapshot action (`btn_view_snapshot`) enters snapshot
   mode and restores the overlay with a `[SNAPSHOT MODE]` label.
8. **User-cost gate is conservative.** Currency + basis + cost-known matrix; unknown
   basis suppresses the line ("declared cost is never invented"), matching §7's
   "known matching currency and compatible corporate-action basis" rule.
9. **H15 interface handoff is complete.** `h13-author.md` §3 documents the controller
   constructor, `setProjection`/`setUserCost`/`setUserCostBasis`, the snapshot flow,
   `PriceChart` params (`controller`/`theme`/`onViewSnapshot`), dispose ownership, and
   the full widget-key inventory.

---

## SPECIFICATION VERDICT — SPEC_FAIL_SOURCE

Acceptance criteria vs SPEC.md §3 and CONTRACTS.md §3/§7:

- "Exact fixture values/timestamps and selected range survive style changes; no
  manufactured candles or future daily trajectories" — **Passing (source-only).**
  Test 2/3/10/11 assert exact O/H/L/C/V/time; style toggle preserves range/selection;
  X-axis equivalence test confirms index-based mapping and no candle beyond the last
  observed bar.
- "Null/stale forecasts produce clear state and snapshot action" — **Passing
  (source-only).** `overlay_no_projection`, `overlay_stale_notice` +
  `btn_view_snapshot` → snapshot mode; tests 7/9/14/15 encode these.
- "Unavailable feed and first-load data gaps never render synthetic prices" —
  **Passing (source-only).** Unavailable → reason + no chart widgets; first-load gap
  → loading with zero `$` text; error → no fallback data (tests 17–19).
- **CONTRACTS §7 "Overlay toggle defaults off"** — **FAILING (Finding F2).**

Failing on:

**F2 — the projection scenario banner renders when the overlay toggle is OFF.**
`_buildProjectionBanner` (price_chart.dart:246–320) has `case
ProjectionGateState.toggleOff: … break;`, then falls through to the common render
path that emits the `overlay_badge` Column whenever `_controller.projection != null`.
The dashed lines and band are correctly gated off via `projectionBoundsVisible`
(`projectionGate == visible`), but the "Conditional scenarios — not observed prices
(target …) ($$min–$$max)" banner is emitted regardless of toggle state. This violates
§7 "Overlay toggle defaults off" — a user who turns the overlay off still sees the
scenario target date and price range. The in-file comment ("Render the scenario
banner only when the overlay is actually on", line 316–317) contradicts the code.

---

## QUALITY VERDICT — QUALITY_FAIL_SOURCE

Quality dimensions: contract fidelity, compile-correctness, test fidelity, evidence
honesty, maintainability, baseline preservation, security/privacy.

Passing:

- **Baseline preserved / no secrets / no new dependency / no prod ops** — confirmed
  (see Positive findings 1–3).
- **Maintainability.** Clean controller/widget split; all state mutation ends in
  `notifyListeners`; single `ChangeNotifier` + `TransformationController`; typed
  domain consumption without filler paths.

Failing:

**F1 — compile error in `_buildVolumeStrip` (price_chart.dart:928).**
`final height = ((volume / maxVolume) * 32).clamp(4.0, 32.0);` — in Dart,
`num.clamp(num, num)` returns `num`, not `double`, and `double` does not override it.
`height` therefore has static type `num`, and it is passed to
`Container(height: …)`, whose `height` parameter is `double?`. This is a hard
argument-type error ("The argument type 'num' can't be assigned to the parameter
type 'double?'") and will fail `flutter analyze` / `flutter test` on the Dev PC. The
line needs `.toDouble()` (or `height` cast to `double`). The author honestly noted
"residual symbol mismatches are Dev-PC compile checks," but this one is deterministic
and must be fixed before source acceptance.

**Test-fidelity gap (aggravates F2).** The "overlay banner separates scenarios"
test (price_chart_test.dart:453–484) asserts `overlay_badge` is absent "off by
default" *before* any pump following `setProjection`, so the tree it inspects still
has a null projection — the assertion is vacuous and would pass even with F2 present.
The suite never exercises "projection present + toggle off," which is exactly why F2
is invisible.

---

## Blocking findings (one targeted author repair)

1. **price_chart.dart:928 — fix the `num`→`double` type error.** Append `.toDouble()`
   to the clamp expression so the volume-bar height is a `double` (or otherwise make
   the value assignable to `Container.height`). This is a deterministic compile error.
2. **price_chart.dart:246–320 — honor "overlay defaults off."** `case
   ProjectionGateState.toggleOff:` must not render the scenario banner; return
   `const SizedBox.shrink()` (or gate the banner on `overlayEnabled`) so a projection
   present with the toggle off shows no "Conditional scenarios" banner. Then
   strengthen the "overlay banner separates scenarios" test to set the projection,
   `pump`, and assert `overlay_badge` is absent while the toggle is still off, before
   enabling it.

---

## Non-blocking notes (do not gate)

- **N1 — no 48px touch-target assertion in the H13 suite.** The implementation is
  source-correct (`btn_view_snapshot` `minimumSize: Size(48, 48)`; `_touchable`
  `minWidth/minHeight: 48`; overlay `Switch` padded + `ConstrainedBox(minHeight: 48)`),
  but unlike the H02 probe's test 14, `price_chart_test.dart` never asserts the 48×48
  minimum. Worth adding so the SPEC §3 target guarantee stays covered.
- **N2 — no in-widget exit from snapshot mode.** `exitSnapshotMode()` exists on the
  controller but no UI control calls it; returning to the live view is a host (H15)
  responsibility. Document that H15 must provide a "return to live" affordance.
- **N3 — error state is not machine-readable.** The unavailable state surfaces
  `unavailableReason` (as §3 requires), but the error state shows a fixed generic
  message while `_errorMessage` stays unsurfaced. Acceptable/safer (avoids leaking raw
  exception text), but note the machine-readable-reason guarantee applies to the
  `unavailable` state only.

---

## Checks run / regression evidence

- Independent SHA-256 recomputation of all three deliverables — 3/3 match.
- `git diff --check` → exit 0 (clean); `git status --porcelain` → only the three new
  H13 paths (baseline preserved).
- Secret/credential grep over the three files → no matches (only the cancellation
  token variable).
- Programmatic bar-for-bar diff of the test daily fixture vs `observed-bars.json` →
  all four bars match; provenance `content_sha256` `dcf75e…` matches.
- fl_chart API usage cross-checked against the accepted H02 probe (`FlTransformationConfig`,
  `CandlestickSpot`, `CandlestickTouchData`, `ExtraLinesData`, `RangeAnnotations`,
  `SideTitleWidget(meta:)`) — consistent, no new dependency introduced.
- `classifyPriceBasis`/`isCompatiblePriceBasis` traced against the test basis strings
  (`kRawBasis`→raw, `raw_ohlc_unadjusted`→raw, `split_adjusted`→adjusted) — consistent
  and conservative (unknown → incompatible → suppressed).

## Limitations (explicit unexecuted criteria — DEFERRED_TO_DEV_PC)

- The 21-case suite (`frontend/test/price_chart_test.dart`) was **not executed**; its
  green/red status is unknown and remains a Dev-PC check.
- `flutter analyze`, `dart run build_runner build`, `flutter test`, `flutter build web`,
  Android/APK builds, and device-gesture capture are all DEFERRED_TO_DEV_PC.
- Pan/zoom/reset, touch inspection, volume-context behavior, and 48px target
  dimensions are verified as source structure only; no rendered/visual proof exists.
- fl_chart API claims are consistent with the H02-accepted probe, but a compile
  against the resolved dependency has not been produced; residual version-specific
  symbol mismatches remain Dev-PC compile checks.
- Runtime/release readiness is NOT established by this review under any circumstance.

## Conclusion

The architecture is sound: correct fixture provenance, honest separation of observed
data and conditional scenarios, no future candles, typed stale/null gates, and the
H02 non-blocking notes were all honored. The gate is held on two correctable defects:
(1) a deterministic `num`→`double` compile error in the volume strip, and (2) a
CONTRACTS §7 violation where the scenario banner renders while the overlay toggle is
off. Author to apply the two fixes in §Blocking findings, then return for a targeted
independent re-review.

---

## RE-REVIEW — 2026-10-31 (targeted: F1 + F2 + test fidelity)

**Trigger:** scoped repair t_1fc3c09e delivered and controller-verified. This
section supersedes the FAIL verdicts above for the two findings and the test-fidelity
gap only; every other finding and limitation in this document stands unchanged.

**Independently re-verified (not author self-report):**

- SHA-256 recomputation — 3/3 match the after-repair claims:
  - `price_chart.dart` = `8f1055b8…` (1128→1131 lines, +3)
  - `chart_controller.dart` = `3ae01579…` (445 lines, byte-identical to the prior
    delivery — untouched by the repair)
  - `price_chart_test.dart` = `2f835d04…` (653→660 lines, +7)
- `git diff --check` clean (exit 0); the three H13 deliverables remain untracked
  new files on the shared dirty baseline.

**F1 — RESOLVED (source-only).** The only `.clamp(` site in the entire deliverable
set is `price_chart.dart:931`:

```dart
final height = ((volume / maxVolume) * 32).clamp(4.0, 32.0).toDouble();
```

`.toDouble()` widens the `num` result to `double`; `height` is `double` and is passed
to `Container(height: height)` (line 933), whose `height` parameter is `double?`.
`grep "\.clamp("` over `chart_controller.dart` and `price_chart_test.dart` returns
zero matches, confirming this was the single clamp site. The compile-error class is
closed at source scope; the actual `flutter analyze`/`flutter test` run remains
DEFERRED_TO_DEV_PC.

**F2 — RESOLVED (source-only).** `_buildProjectionBanner` now short-circuits the
toggle-off state (price_chart.dart:248–251):

```dart
case ProjectionGateState.toggleOff:
  // Overlay toggle is off: no scenario banner, no projection UI, even
  // when a projection is present (CONTRACTS §7 overlay defaults off).
  return const SizedBox.shrink();
```

`overlay_badge` (line 334) is reachable only through the `visible` case → `break` →
line 319+, which is itself guarded by `if (projection == null) return const
SizedBox.shrink();`. The controller's `projectionGate` (chart_controller.dart:208)
returns `toggleOff` whenever `!_overlayEnabled`. The scenario banner can no longer
render while the overlay toggle is off, satisfying CONTRACTS §7 "overlay defaults off."

**Test fidelity — RESOLVED (source-only).** The "overlay banner separates scenarios"
test (price_chart_test.dart:453–491) is no longer vacuous:

1. `setProjection(freshProjection())` (461) then `await tester.pump()` (462) — the
   tree is rebuilt with the projection present.
2. Assert `overlay_badge` `findsNothing` (468) **and**
   `textContaining('Conditional scenarios — not observed prices')` `findsNothing`
   (469–471) while the toggle is still off.
3. Tap `chart_overlay_switch` (473) → `onChanged: setOverlayEnabled` (price_chart.dart:209)
   → `notifyListeners` (chart_controller.dart:386–390); assert `overlay_badge`
   `findsOneWidget` (476) and the scenario text `findsOneWidget` (478–479).

The in-test comment (464–467) documents the non-vacuous reasoning, and a separate
controller unit test (285–295) pins `setProjection → toggleOff → setOverlayEnabled(true)
→ visible`.

**Revised verdicts:**

| Verdict | Result |
|---|---|
| Specification | **SPEC_PASS_SOURCE_ONLY** |
| Quality | **QUALITY_PASS_SOURCE_ONLY** |

Non-blocking notes N1/N2/N3 from the original review stand unchanged. All runtime/PC
criteria remain DEFERRED_TO_DEV_PC; this re-review does not establish runtime or
release approval under any circumstance.
