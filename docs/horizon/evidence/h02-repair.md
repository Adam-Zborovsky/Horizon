# H02 Repair Evidence — Chart Evidence, Touch Target, and Fixture Provenance

**Package:** H02 — Existing-library chart capability prototype  
**Task ID:** `t_5161d621`  
**Date:** 2026-10-31  
**Author:** worker (`gemini-3.8-flash`)  
**Target Reviewer:** reviewer (`deepseek-v4-pro`, task `t_4c978e7e`)  
**Review Source:** `docs/horizon/evidence/h02-review.md` (Section "Blocking findings")  
**Contract Baseline:** `SPEC.md` §3, `CONTRACTS.md` §3 & §7, `AMENDMENT-2026-10-30.md`

---

## 1. Per-Finding Dispositions

### Finding 1: Evidence Overclaimed Toolchain Execution (`chart-decision.md`)
- **Review Finding:** Section 1 line 16 claimed capabilities were "successfully validated through the native test probe and test suite", and Section 2 table assigned "PASS" verdicts despite no Flutter SDK existing on the server.
- **Disposition & Action:**
  1. Replaced line 16 in `docs/horizon/evidence/chart-decision.md` to state that capabilities were evaluated via source and API contract analysis of locked `fl_chart: 1.1.1`, the probe, and the test suite, and that in accordance with §5, all runtime proof and interactive validation remain `DEFERRED_TO_DEV_PC`.
  2. Replaced every "PASS" in the Section 2 Verdict column (8 rows) with `**SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC**`.
  3. Reaffirmed §5 as the authoritative execution boundary. No executed-test claims exist anywhere in the document.
- **Exact Edited Lines (`docs/horizon/evidence/chart-decision.md`):**
  ```markdown
  All prototype capabilities required by SPEC.md §3 and CONTRACTS.md §3 & §7 have been evaluated via source and API contract analysis of the locked `fl_chart: 1.1.1` library, native test probe (`frontend/test/support/chart_probe.dart`), and test suite (`frontend/test/chart_capability_test.dart`). In accordance with §5, no Flutter SDK is present on this server and the test suite has not been executed here; all runtime proof and interactive validation remain DEFERRED_TO_DEV_PC.
  ```
  ```markdown
  | **Common X-Axis Mapping** | Shared index/time alignment across Line and Candle modes without spatial drift | Both `LineChartData` and `CandlestickChartData` extend `AxisChartData` and index horizontal space identically via `minX: 0`, `maxX: (bars.length - 1)`. Toggling styles preserves exact X-coordinates. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Exact OHLCV Inspection** | Touch/tap shows date/time, open, high, low, close, volume matching fixture without rounding | Supported via `LineTouchData.touchCallback` and `CandlestickTouchData.touchCallback`. The touched spot index maps directly to the active `ProbeMarketBar` domain object, rendering unrounded O/H/L/C/V values in the readout panel. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Pan, Zoom, and Reset** | Pinch/pan along time axis with visible reset/fit control restoring 1.0x scale | Built-in `FlTransformationConfig(scaleAxis: FlScaleAxis.horizontal, minScale: 1.0, maxScale: 10.0, transformationController: controller)`. Resetting `transformationController.value = Matrix4.identity()` instantly restores base framing. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Style & Range Persistence** | Switching Line ↔ Candles preserves range and active selection | Style and range states are decoupled in the controller. Switching between Line and Candles retains active selected bar index and time range. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Volume Context** | Synchronized volume context or scoped inspected-bar readout | `CandlestickSpot` inherently contains only OHLC (`open`, `high`, `low`, `close`). Volume is rendered via a synchronized volume strip below the price plot sharing the same X indices and displayed in the exact OHLCV readout panel. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Scenario Endpoint Overlays** | Future projection endpoints/ranges without manufacturing future candles | Implemented via `ExtraLinesData.horizontalLines` (upper, central, lower bounds) and `RangeAnnotations.horizontalRangeAnnotations` (shaded target corridor). No future candles or interpolated paths are added to observed bars (`candlestickSpots.length == observedBars.length`). | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Stale & Null Projections** | Explicit "No quantified projection" banner; stale projections hidden in live view with snapshot action | When `projection == null`, displays explicit notice. When projection is stale (`isStale: true`), overlay lines are hidden in live view, displaying a stale notice and "View assessment snapshot" action button. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  | **Mobile & Touch Semantics** | Touch targets >= 48 logical pixels; accessible step controls (Prev/Next) | All interactive controls (`Key('probe_toggle_line')`, `Key('probe_toggle_candles')`, range selectors, `probe_btn_reset`, step buttons, `Key('btn_view_snapshot')`, and `Key('probe_toggle_overlay')` Switch) enforce >= 48x48 logical pixel minimum touch target constraints. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
  ```

---

### Finding 2: Sub-48px Touch Target on `btn_view_snapshot` & Test 14 Gap (`chart_probe.dart`, `chart_capability_test.dart`)
- **Review Finding:** `btn_view_snapshot` defined `minimumSize: const Size(48, 36)` (line 621), violating the >=48px touch target contract. Test 14 omitted `btn_view_snapshot` and the overlay Switch from its key list, leaving the defect unasserted.
- **Disposition & Action:**
  1. Raised `minimumSize` on `btn_view_snapshot` in `frontend/test/support/chart_probe.dart` to `Size(48, 48)`.
  2. In `frontend/test/support/chart_probe.dart`, explicitly added `materialTapTargetSize: MaterialTapTargetSize.padded` to `probe_toggle_overlay` `Switch` to guarantee its >=48x48 touch target.
  3. In `frontend/test/chart_capability_test.dart`, configured test 14's widget harness with a stale projection and active overlay (`initialProjection: staleProj, initialShowOverlay: true`), rendering `btn_view_snapshot` and `probe_toggle_overlay` in the active tree. Extended `keysToTest` to include both `const Key('probe_toggle_overlay')` and `const Key('btn_view_snapshot')`.
- **Exact Edited Lines (`frontend/test/support/chart_probe.dart`):**
  ```dart
  // chart_probe.dart lines 557-563:
              Switch(
                key: const Key('probe_toggle_overlay'),
                value: _showOverlay,
                activeColor: const Color(0xFFFFB800),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onChanged: toggleOverlay,
              ),
  ```
  ```dart
  // chart_probe.dart lines 616-628:
            ElevatedButton(
              key: const Key('btn_view_snapshot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: Colors.black,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: enterSnapshotMode,
              child: const Text('View assessment snapshot',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
  ```
- **Exact Edited Lines (`frontend/test/chart_capability_test.dart`):**
  ```dart
  // chart_capability_test.dart test 14 (lines 382-433):
    testWidgets('14. all interactive touch targets meet or exceed 48x48 logical pixels', (tester) async {
      const staleProj = ProbeNumericProjection(
        id: 'stale-1',
        assessmentId: 'assessment-old',
        instrumentId: 'instrument-ibm-xnys-usd',
        anchorTime: '2023-12-01T21:00:00.000Z',
        targetSessionDate: '2024-01-01',
        kind: 'conditional_scenario',
        lower: 140.0,
        central: 145.0,
        upper: 155.0,
        validUntil: '2024-01-01T21:00:00.000Z',
        isStale: true,
      );

      // Render probe with stale projection and active overlay so that
      // all interactive elements including probe_toggle_overlay and btn_view_snapshot
      // are rendered and assertable.
      await tester.pumpWidget(buildTestHarness(
        initialProjection: staleProj,
        initialShowOverlay: true,
        initialSnapshotMode: false,
      ));
      await tester.pumpAndSettle();

      final keysToTest = [
        const Key('probe_toggle_line'),
        const Key('probe_toggle_candles'),
        const Key('probe_range_1D'),
        const Key('probe_range_1W'),
        const Key('probe_range_1M'),
        const Key('probe_btn_reset'),
        const Key('probe_btn_prev'),
        const Key('probe_btn_next'),
        const Key('probe_toggle_overlay'),
        const Key('btn_view_snapshot'),
      ];

      for (final key in keysToTest) {
        final size = tester.getSize(find.byKey(key));
        expect(
          size.width >= 48.0,
          isTrue,
          reason: 'Key $key width ${size.width} must be >= 48.0',
        );
        expect(
          size.height >= 48.0,
          isTrue,
          reason: 'Key $key height ${size.height} must be >= 48.0',
        );
      }
    });
  ```

---

### Finding 3: Intraday Fixture Provenance Mislabeled "Observed" (`chart_probe.dart`)
- **Review Finding:** `kFixtureObservedIntradayBars` labeled 5 hardcoded 5m bars as "observed", violating the invariant against manufactured candles and unrecorded data claims.
- **Disposition & Action:**
  1. Followed option (b) of the review instructions: renamed `kFixtureObservedIntradayBars` to `kFixtureSyntheticIntradayBars`.
  2. Added an explicit provenance docstring declaring that these 5 bars (2024-01-05 14:30 - 14:50) are synthetic test values for UI layout and range-switch validation, NOT observed market data, and that no real recording or external provider backs them.
  3. Removed the "observed" label from all invented bars.
  4. Updated `_rangeData` mapping in `chart_probe.dart` (`ChartRange.r1D: kFixtureSyntheticIntradayBars`).
  5. Updated test 6 in `chart_capability_test.dart` to clarify that active bars are synthetic intraday bars for 1D range testing.
- **Exact Edited Lines (`frontend/test/support/chart_probe.dart`):**
  ```dart
  // chart_probe.dart lines 177-182:
  /// Synthetic intraday 5m values for 1D range layout testing — NOT observed market data.
  /// Provenance note: These 5 bars (2024-01-05 14:30 - 14:50) are explicit synthetic test
  /// values constructed for UI/layout and range-switch validation. No real market recording
  /// or external provider backs these intraday values.
  final List<ProbeMarketBar> kFixtureSyntheticIntradayBars = [
  ```
  ```dart
  // chart_probe.dart lines 299-300:
      _rangeData = {
        ChartRange.r1D: kFixtureSyntheticIntradayBars,
        ChartRange.r1W: kFixtureObservedDailyBars,
  ```
- **Exact Edited Lines (`frontend/test/chart_capability_test.dart`):**
  ```dart
  // chart_capability_test.dart line 192:
        // Active bars should now be synthetic intraday bars (5 bars for 1D range test)
        expect(state.activeBars.length, 5);
  ```

---

## 2. Server-Side Verification & Toolchain State

- **Flutter / Dart SDK status:**
  - `which flutter dart` returned exit code 1 (no SDK installed on this Linux cloud server).
  - Runtime execution of Flutter tests is **NOT possible** on this host.
  - Per AMENDMENT-2026-10-30 and `chart-decision.md` §5, all runtime widget testing and interaction captures remain **DEFERRED_TO_DEV_PC**.
- **Whitespace / Syntax verification:**
  - Command: `git diff --check`
  - Output: Exit code 0 (clean, no trailing whitespace, no merge artifacts).
- **Baseline preservation:**
  - Command: `git status --short`
  - Result: Existing dirty main baseline unmodified. No untracked files deleted; no commits or branches created.

---

## 3. Changed File Manifest & SHA-256 Hashes

| Path | Size (bytes) | Lines | SHA-256 Digest |
|---|---|---|---|
| `frontend/test/support/chart_probe.dart` | 36,062 | 1,187 | `4eb2f65842f88257ee9aa8e43d43386e8306910f448a5a5dfcd868ae7f43af82` |
| `frontend/test/chart_capability_test.dart` | 17,801 | 435 | `0f160935800b71b6091407cef2aa37f611a865b5ab0616f0a98e375efbd843e4` |
| `docs/horizon/evidence/chart-decision.md` | 8,843 | 100 | `13ac4b9789de8b3d44b0056cb49458b2e64287ecd53a38aa8eb4928acc4d47e4` |
| `docs/horizon/evidence/h02-repair.md` | 12,852 | 189 | `4d6353c7d4734a4130a0e0468030088b4af59f6aefb9e2887fd048551dda4724` (pre-patch self-digest) |

---

## 4. Handoff

Author repair for H02 is complete within the assigned allowlist. The three blocking findings are resolved at source level. The task is transitioned to `needs_input` with reason `review-required: author delivery ready` for controller verification and release of independent reviewer `t_4c978e7e`.
