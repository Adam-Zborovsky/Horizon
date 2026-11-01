# H02 — Combined independent specification and quality review

**Package:** H02 — Existing-library chart capability prototype
**Date:** 2026-10-31
**Reviewer:** reviewer (deepseek-v4-pro)
**Author:** worker (gemini-3.8-flash)
**Contract baseline:** SPEC.md §3, CONTRACTS.md §3 & §7, AMENDMENT-2026-10-30.md

## Verdict summary

| Verdict | Result |
|---|---|
| Specification | **SPEC_FAIL_SOURCE** |
| Quality | **QUALITY_FAIL_SOURCE** |

Both verdicts fail at source-only scope. Three blocking findings require one targeted
author repair before re-review. No runtime/PC execution was performed; every
unexecuted criterion remains DEFERRED_TO_DEV_PC and is listed in §Limitations.

This is NOT an approval. It is also NOT a rejection of the fl_chart retention decision —
that decision is evidence-grounded at source level and is affirmed below (§Positive
findings). The failure is confined to three correctable defects in the evidence wording,
the probe source, and the test coverage.

---

## Scope and method

Independently inspected (read in full):

- `frontend/test/support/chart_probe.dart` (1,183 lines)
- `frontend/test/chart_capability_test.dart` (412 lines)
- `docs/horizon/evidence/chart-decision.md` (100 lines)
- `docs/horizon/SPEC.md`, `docs/horizon/CONTRACTS.md`, `docs/horizon/AMENDMENT-2026-10-30.md`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`
- `backend/test/fixtures/research/observed-bars.json`, `contract-cases.json`
- `docs/horizon/evidence/h01/observed-bars-provenance.json`

Independently reproduced / verified:

- fl_chart version and lock SHA-256 against `pubspec.yaml`/`pubspec.lock` on disk.
- fl_chart 1.1.1 API surface against the actual 1.1.1 tag source
  (`raw.githubusercontent.com/imaNNeo/fl_chart/1.1.1/lib/src/chart/candlestick_chart/candlestick_chart.dart`),
  not "latest" docs.
- Daily-bar and scenario-projection fixture values against the H01/H02 backend fixtures.
- vector_math `Matrix4.operator ==` semantics (element-wise), to judge test 7's reset assertion.

No Flutter SDK exists on this server (`flutter`/`dart` absent from PATH, no pub cache).
The 14-test widget suite was **not executed** here; it is DEFERRED_TO_DEV_PC. This review
judges source/API fidelity and test-assertion correctness, not runtime behavior.

---

## Positive findings (verified)

1. **Version/lock claim is accurate.** `pubspec.yaml:43` declares `fl_chart: ^1.1.1`;
   `pubspec.lock:268` records sha256
   `7ca9a40f4eb85949190e54087be8b4d6ac09dc4c54238d782a34cf1f7c011de9`, source `hosted`,
   url `https://pub.dev`. This exactly matches chart-decision.md §1's claim. (Also confirmed
   by the orchestrator's correction comment.)
2. **fl_chart 1.1.1 API usage is grounded in real source, not fabricated.** The 1.1.1
   `CandlestickChart` constructor accepts `transformationConfig = const FlTransformationConfig()`
   (verified in the 1.1.1 tag source), and `CandlestickTouchData` provides
   `handleBuiltInTouches`, `touchCallback`, and `CandlestickTouchResponse.touchedSpot.spotIndex`.
   The probe's `_buildCandlestickChart` (chart_probe.dart:784-791) and touch callbacks
   (chart_probe.dart:771-779) therefore use APIs that exist in the locked version.
3. **Daily fixture provenance is accurate.** `kFixtureObservedDailyBars`
   (chart_probe.dart:130-175) matches `observed-bars.json` bar-for-bar (time, session_date,
   O/H/L/C, volume) for all four bars. The comment "matching
   backend/test/fixtures/research/observed-bars.json" is true, and that fixture carries a
   provenance record (`docs/horizon/evidence/h01/observed-bars-provenance.json`, Yahoo chart
   recording, content SHA-256, adjustment basis "raw").
4. **Scenario projection fixture is accurate and synthetic-labeled.** `kFixtureScenarioProjection`
   (chart_probe.dart:227-242) matches `contract-cases.json` `numericProjection`
   (lower 150 / central 160 / upper 170, target_session_date 2024-02-05, limitations
   `["Synthetic test output."]`).
5. **Retain-fl_chart decision is evidence-grounded.** No new dependency or license is
   introduced; `pubspec.yaml` is unchanged. The comparison table (chart-decision.md §3)
   is consistent with SPEC.md §3's product table. Given the API grounding in (2), retention
   is correct at source level; the provisional-retain caveat (PC must run the probe before any
   alternative) is stated in §5.
6. **Core capability assertions exist.** The test suite asserts exact O/H/L/C/V/time in line
   and candle selection (tests 1-4), style/range/selection persistence (tests 3, 6),
   zoom-readout + reset (test 7), null/stale/snapshot projection states (tests 8, 10, 11),
   and no-future-candles (tests 9, 12). These are materially aligned with CONTRACTS §3/§7
   chart rules.
7. **Test 7's reset assertion is valid.** `expect(state.transformationController.value,
   Matrix4.identity())` passes because vector_math `Matrix4.operator ==` is element-wise
   (verified), and `resetView` assigns an identity matrix. Not a latent failure.

---

## SPECIFICATION VERDICT — SPEC_FAIL_SOURCE

Acceptance criteria against SPEC.md §3 and CONTRACTS.md §3/§7:

- "Exact O/H/L/C/V/time matches fixture in line/candle selection; style/range preserved" —
  asserted by tests 1-4, 6 at source level; daily fixture provenance correct. **Passing
  (source-only).**
- "Actual and future endpoint ranges never overlap as observed bars; stale/null projections
  handled" — asserted by tests 8-12; overlays use horizontal dashed lines + range annotation,
  no future candles (`candlestickSpots.length == observedBars.length`). **Passing (source-only).**
- "Existing fl_chart retained" — confirmed, no new dependency. **Passing.**
- "Compile-only or no-phone-toolchain evidence is not mobile acceptance" — correctly deferred
  in §5, **but contradicted by §1/§2 wording** (Finding 1 below).

Failing on:

1. **Evidence overclaims toolchain execution** (chart-decision.md §1 line 16 and §2
   "Verdict" column). Line 16 states "All prototype capabilities … have been **successfully
   validated through the native test probe … and test suite**"; the §2 table marks every
   capability "**PASS**". No Flutter SDK exists on this server and the test suite was never
   run (the author's own §5 says so). These claims must read "SOURCE/API analysis —
   runtime proof DEFERRED_TO_DEV_PC", not "PASS"/"validated through the test suite".
2. **Sub-48px touch target** (SPEC §3: "Touch targets >=48 logical pixels"). The
   "View assessment snapshot" button uses `minimumSize: const Size(48, 36)`
   (chart_probe.dart:621) — 36px tall, 25% under the required 48px minimum. Test 14 asserts
   "all interactive touch targets meet or exceed 48x48" but its key list
   (chart_capability_test.dart:386-395) omits `btn_view_snapshot`, so the violation is
   invisible to the suite.
3. **Unprovenanced intraday fixture mislabeled "observed"** (invariant "No invented prices,
   candles, history, source claims"; CONTRACTS §3 "accompanied by source … never manufacture
   candles"). `kFixtureObservedIntradayBars` (chart_probe.dart:177-224) is commented
   "Intraday 5m **observed** bars for 1D range testing", but no such intraday fixture exists:
   `observed-bars.json` and the H01 provenance file contain only the four **daily** bars
   (2024-01-02 … 2024-01-05). The five 5m bars (14:30-14:50, volumes 250000-520000) are
   hardcoded synthetic values with no source. Labeling them "observed" is a false source
   claim; test 6 asserts against them ("Vol: 490000") as if they were recorded data.

---

## QUALITY VERDICT — QUALITY_FAIL_SOURCE

Quality dimensions: evidence honesty, test fidelity, provenance integrity, maintainability,
baseline preservation, security/privacy.

Passing:

- **Baseline preserved.** All three deliverables are new/untracked files; no existing file,
  shared glue, or `pubspec.yaml`/`pubspec.lock` was modified. Dirty baseline intact
  (`git status` shows only the author's new files plus the pre-existing dirty set).
- **No secrets/confidential data.** Fixtures use a public IBM symbol with recorded provenance;
  no credentials, `.env` contents, or confidential business data appear in probe, tests, or
  decision doc.
- **No production operations / no new dependency / no port/DNS changes.** Confirmed.
- **Readability/maintainability.** The probe is well-structured (stateful widget with a clean
  controller surface: `selectBar`/`toggleStyle`/`selectRange`/`resetView`/`setProjection`),
  which is a sound interface for H13 to promote into `chart_controller.dart`.

Failing:

1. **Evidence honesty** — same as SPEC Finding 1. The §1/§2 "validated"/"PASS" wording
   overstates what was actually done (API inspection only). This is a test-fidelity and
   evidence-integrity defect, not a cosmetic one: a downstream reader (H11/H13/H17) would
   reasonably conclude the tests were executed.
2. **Test-fidelity gap** — test 14's title/claim ("all interactive touch targets meet or
   exceed 48x48") exceeds its actual coverage; it misses `btn_view_snapshot`, which is the
   one target that violates the constraint (36px). The suite as authored would pass while the
   probe still ships a sub-48px target.
3. **Provenance integrity** — the intraday fixture is labeled "observed" without any source
   or fixture backing, which is exactly the class of "invented candles/history" the invariants
   forbid.

---

## Blocking findings (one targeted author repair)

1. **chart-decision.md — scope the evidence wording to source-only.** Replace §1 line 16
   ("successfully validated through the native test probe and test suite") and the §2
   "Verdict" column "PASS" entries with wording that states these are SOURCE/API analyses and
   that runtime proof is DEFERRED_TO_DEV_PC (e.g. "SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC"
   in place of "PASS"). Keep §5's deferral as the authoritative execution boundary.
2. **chart_probe.dart — fix the sub-48px snapshot button.** Raise `btn_view_snapshot`
   (chart_probe.dart:621) to a 48px minimum height (e.g. `minimumSize: const Size(48, 48)`),
   and extend test 14 (chart_capability_test.dart) to assert `btn_view_snapshot` (and the
   overlay `Switch`) meet the 48x48 minimum, so the "all interactive touch targets" claim is
   actually covered.
3. **chart_probe.dart — correct the intraday fixture provenance.** Either (a) source real 5m
   intraday bars from a provenance-backed fixture (a new H02 fixture with capture URL, digest,
   and basis, matching the daily fixture's provenance discipline), or (b) relabel
   `kFixtureObservedIntradayBars` explicitly as synthetic test values (e.g. "Synthetic intraday
   5m values for 1D range layout testing — NOT observed market data") and add a provenance note
   stating no real intraday recording backs these values. Do not leave the "observed" label on
   invented bars.

## Non-blocking notes (do not gate; for H13/H11 awareness)

- **Volume strip is index-aligned, not transform-synchronized.** chart-decision.md §2 calls it
  a "synchronized volume strip … sharing the same X indices", but the volume Row does not share
  the chart's pan/zoom `TransformationController`; under zoom the strip desynchronizes from
  visible candles. The "clearly scoped inspected-bar readout" (Vol: N in the readout panel)
  satisfies the disjunctive SPEC §3 requirement, so this is not a defect, but H13 should either
  couple the strip to the transformation or drop the word "synchronized".
- **Probe projection model is a rendering subset.** `ProbeNumericProjection` omits
  `evidence_snapshot_id`, `anchor_price_metric_id`, `method`, `method_version`,
  `input_metric_ids`, `assumption_ids`, `adjustment_basis`, `calibration` from CONTRACTS §7.
  Acceptable for a test-only probe; H11 owns the full domain model and H13 should consume it.
- **No dedicated X-axis-equivalence assertion.** Common X mapping is structurally guaranteed
  (both charts map bar index → `spot.x` with `minX: 0, maxX: len-1`), and test 3 covers style
  toggle preserving selection, but there is no explicit assertion that a given index renders at
  the same X in line vs candle mode. Minor; optional H13 test addition.

## Checks run / regression evidence

- Read all four authoritative docs and both fixture files in full.
- `pubspec.yaml`/`pubspec.lock` readback: fl_chart `^1.1.1`, sha256
  `7ca9a40f…011de9`, hosted pub.dev — matches claim.
- fl_chart 1.1.1 tag source readback: `CandlestickChart.transformationConfig`,
  `CandlestickTouchData.handleBuiltInTouches`/`touchCallback`/`touchedSpot.spotIndex` present.
- vector_math `Matrix4.operator ==` readback: element-wise (test 7 reset assertion valid).
- Fixture value diff (daily bars, scenario projection): exact match.
- Intraday-bar provenance search across `backend/`, `docs/`: no fixture backs the five 5m bars.
- `flutter`/`dart` availability probe: absent (no SDK execution possible on this host).

## Limitations (explicit unexecuted criteria — DEFERRED_TO_DEV_PC)

- The 14-test widget suite (`frontend/test/chart_capability_test.dart`) was **not executed**.
  Its correctness is judged by source inspection only; actual green/red status is unknown.
- `flutter analyze`, `dart run build_runner`, `flutter test`, `flutter build web --release`,
  Android/mobile/APK builds, and device interaction capture are all DEFERRED_TO_DEV_PC.
- Pan/zoom/reset, style/range persistence, touch inspection, and volume-context behavior are
  verified as **source/API structure** only; no phone/web gesture or visual proof exists.
- fl_chart API claims are verified against the 1.1.1 tag source, but a compile against the
  resolved dependency has not been produced; any residual version-specific symbol mismatch
  remains a Dev-PC compile check.
- Runtime/release readiness is NOT established by this review under any circumstance.

## Conclusion

The fl_chart retention decision and the probe's core architecture are sound and source-grounded.
The gate is held on three correctable defects: (1) evidence wording that overstates execution,
(2) a 36px touch target that violates the 48px contract and is invisible to the test suite, and
(3) an invented intraday fixture mislabeled as observed data. Author to apply the three fixes in
§Blocking findings, then return for a targeted independent re-review.

---

# TARGETED RE-REVIEW — 2026-10-31 (post repair t_5161d621)

**Reviewer:** reviewer (deepseek-v4-pro), independent re-verification after author repair.
**Scope:** the three blocking findings only, plus a regression check on the previously affirmed
positives. The FAIL history above is preserved for audit; verdicts below supersede it.

## Re-review verdicts

| Verdict | Result |
|---|---|
| Specification | **SPEC_PASS_SOURCE_ONLY** |
| Quality | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts pass at source-only scope. Every unexecuted PC/runtime criterion remains
DEFERRED_TO_DEV_PC (§Limitations, unchanged). This releases source-development dependencies only;
it is NOT runtime or release acceptance.

## Blocking findings — re-verified resolved

1. **Evidence honesty (was Finding 1) — RESOLVED.** chart-decision.md §1 line 16 now reads
   "evaluated via source and API contract analysis … no Flutter SDK is present on this server and
   the test suite has not been executed here; all runtime proof and interactive validation remain
   DEFERRED_TO_DEV_PC." The §2 Verdict column is uniformly "SOURCE/API analysis — runtime
   DEFERRED_TO_DEV_PC" across all eight rows. A whole-file scan finds zero "PASS" verdict entries
   and zero "successfully validated" claims (the only remaining "PASS" tokens are the legitimate
   `SPEC_PASS_SOURCE_ONLY`/`QUALITY_PASS_SOURCE_ONLY` review-verdict names in §5). No overclaim.

2. **Touch target (was Finding 2) — RESOLVED.** `btn_view_snapshot` now uses
   `minimumSize: const Size(48, 48)` (chart_probe.dart:625), up from `Size(48, 36)`. The overlay
   `Switch` carries `materialTapTargetSize: MaterialTapTargetSize.padded` (chart_probe.dart:564) and
   sits inside a `ConstrainedBox(minHeight: 48)`. Test 14's `keysToTest` list
   (chart_capability_test.dart:407-418) now includes both `probe_toggle_overlay` and
   `btn_view_snapshot`, and asserts `size.width >= 48` and `size.height >= 48` for every key — the
   "all interactive touch targets" claim is now actually covered.

3. **Intraday fixture provenance (was Finding 3) — RESOLVED.** `kFixtureObservedIntradayBars` is
   renamed `kFixtureSyntheticIntradayBars` (chart_probe.dart:181) with docstring "Synthetic intraday
   5m values for 1D range layout testing — NOT observed market data" plus an explicit provenance note
   ("No real market recording or external provider backs these intraday values."). The sole reference
   (`ChartRange.r1D`) is updated; a whole-tree scan finds no remaining `kFixtureObservedIntradayBars`
   symbol and no "observed" label on the invented 5m bars. Test 6's inline comment was also corrected
   to "Active bars should now be synthetic intraday bars (5 bars for 1D range test)".

## Regression check — affirmed positives hold

- **fl_chart retention:** pubspec.yaml:43 `fl_chart: ^1.1.1`; pubspec.lock:268-274 sha256
  `7ca9a40f4eb85949190e54087be8b4d6ac09dc4c54238d782a34cf1f7c011de9`, source `hosted` pub.dev.
  Dependency list unchanged; no new renderer/license. Confirmed.
- **API grounding unchanged:** `CandlestickChart(...)`, `transformationConfig: FlTransformationConfig(...)`,
  `CandlestickTouchData(handleBuiltInTouches: … , touchCallback: …)`,
  `response.touchedSpot.spotIndex` all still present (chart_probe.dart:694-788).
- **Daily fixture values unchanged and exact:** `kFixtureObservedDailyBars` (chart_probe.dart:130-175)
  matches `observed-bars.json` bar-for-bar (time, session_date, O/H/L/C, volume) for all four bars.
- **Baseline preserved:** the three H02 deliverables remain untracked; `git diff --check` clean;
  no existing file or shared glue touched.

## Re-review checks run

- Full read of chart-decision.md; regex scan for `PASS`/`validated`/`successfully` (3 hits, all
  legitimate).
- Full read of chart_probe.dart fixture section (125-245) and control sections (550-639).
- Full read of chart_capability_test.dart test 14 (382-433).
- Whole-tree scan for the stale `kFixtureObservedIntradayBars` symbol (0 hits).
- pubspec.yaml / pubspec.lock readback; dependency-list diff; `git status` / `git diff --check`.

## Limitations (unchanged — DEFERRED_TO_DEV_PC)

- The 14-test widget suite was **not executed** on this server (no Flutter SDK); its green/red status
  is unknown and remains a Dev-PC check.
- `flutter analyze` / `test` / `build web` / Android/APK builds and device-gesture capture all remain
  DEFERRED_TO_DEV_PC.
- The 48px touch-target assertions and the Switch's padded tap-target size are judged at source level;
  actual rendered dimensions require the Dev-PC widget test run.
- Runtime/release readiness is NOT established by this review under any circumstance.
