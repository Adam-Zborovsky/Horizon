# Chart Capability Evaluation and Renderer Decision

**Package:** H02 — Existing-library chart capability prototype  
**Date:** 2026-10-31  
**Author:** worker (gemini-3.8-flash)  
**Reviewer:** reviewer (deepseek-v4-pro)  
**Contract Baseline:** docs/horizon/CONTRACTS.md v1, SPEC.md §3, AMENDMENT-2026-10-30.md  

---

## 1. Executive Summary & Renderer Decision

### **Decision: RETAIN `fl_chart: 1.1.1`**
Existing locked library `fl_chart` (version `1.1.1`, lock SHA-256 `7ca9a40f4eb85949190e54087be8b4d6ac09dc4c54238d782a34cf1f7c011de9`) is **retained** as the primary chart renderer for Horizon. Zero new renderer dependencies or commercial licenses are required.

All prototype capabilities required by SPEC.md §3 and CONTRACTS.md §3 & §7 have been evaluated via source and API contract analysis of the locked `fl_chart: 1.1.1` library, native test probe (`frontend/test/support/chart_probe.dart`), and test suite (`frontend/test/chart_capability_test.dart`). In accordance with §5, no Flutter SDK is present on this server and the test suite has not been executed here; all runtime proof and interactive validation remain DEFERRED_TO_DEV_PC.

---

## 2. Requirement-by-Requirement Capability Analysis

| Capability / Requirement | Contract Specification | `fl_chart: 1.1.1` Implementation & Finding | Verdict |
|---|---|---|---|
| **Common X-Axis Mapping** | Shared index/time alignment across Line and Candle modes without spatial drift | Both `LineChartData` and `CandlestickChartData` extend `AxisChartData` and index horizontal space identically via `minX: 0`, `maxX: (bars.length - 1)`. Toggling styles preserves exact X-coordinates. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Exact OHLCV Inspection** | Touch/tap shows date/time, open, high, low, close, volume matching fixture without rounding | Supported via `LineTouchData.touchCallback` and `CandlestickTouchData.touchCallback`. The touched spot index maps directly to the active `ProbeMarketBar` domain object, rendering unrounded O/H/L/C/V values in the readout panel. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Pan, Zoom, and Reset** | Pinch/pan along time axis with visible reset/fit control restoring 1.0x scale | Built-in `FlTransformationConfig(scaleAxis: FlScaleAxis.horizontal, minScale: 1.0, maxScale: 10.0, transformationController: controller)`. Resetting `transformationController.value = Matrix4.identity()` instantly restores base framing. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Style & Range Persistence** | Switching Line ↔ Candles preserves range and active selection | Style and range states are decoupled in the controller. Switching between Line and Candles retains active selected bar index and time range. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Volume Context** | Synchronized volume context or scoped inspected-bar readout | `CandlestickSpot` inherently contains only OHLC (`open`, `high`, `low`, `close`). Volume is rendered via a synchronized volume strip below the price plot sharing the same X indices and displayed in the exact OHLCV readout panel. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Scenario Endpoint Overlays** | Future projection endpoints/ranges without manufacturing future candles | Implemented via `ExtraLinesData.horizontalLines` (upper, central, lower bounds) and `RangeAnnotations.horizontalRangeAnnotations` (shaded target corridor). No future candles or interpolated paths are added to observed bars (`candlestickSpots.length == observedBars.length`). | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Stale & Null Projections** | Explicit "No quantified projection" banner; stale projections hidden in live view with snapshot action | When `projection == null`, displays explicit notice. When projection is stale (`isStale: true`), overlay lines are hidden in live view, displaying a stale notice and "View assessment snapshot" action button. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |
| **Mobile & Touch Semantics** | Touch targets >= 48 logical pixels; accessible step controls (Prev/Next) | All interactive controls (`Key('probe_toggle_line')`, `Key('probe_toggle_candles')`, range selectors, `probe_btn_reset`, step buttons, `Key('btn_view_snapshot')`, and `Key('probe_toggle_overlay')` Switch) enforce >= 48x48 logical pixel minimum touch target constraints. | **SOURCE/API analysis — runtime DEFERRED_TO_DEV_PC** |

---

## 3. Product & Renderer Comparison

As mandated by SPEC.md §3, different charting options were evaluated against Horizon's constraints:

```
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| Option                            | Own Horizon Data   | Horizon Overlays   | Decision & Rationale                      |
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| fl_chart: 1.1.1 (Existing)        | Yes (Direct)       | Yes (ExtraLines /  | RETAINED. Zero new dependency, zero       |
|                                   |                    | RangeAnnotations)  | license cost, native canvas rendering.    |
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| Syncfusion Flutter Charts         | Yes                | Yes                | REJECTED. Requires commercial license or  |
|                                   |                    |                    | strict Community License qualification;   |
|                                   |                    |                    | adds large dependency overhead.           |
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| TradingView Hosted Widget         | No (Hosted feed)   | No                 | REJECTED. Cannot display custom offline   |
|                                   |                    |                    | evidence snapshots, local feeds, or runs. |
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| TradingView Lightweight Charts    | Yes                | Yes (Custom bridge)| OPEN-SOURCE FALLBACK. Retained in reserve |
| (Self-hosted via WebView)         |                    |                    | only if mobile PC testing reveals canvas  |
|                                   |                    |                    | performance bottlenecks.                  |
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
| TradingView Advanced Charts       | Yes (Custom feed)  | Yes                | REJECTED. Excess scope, complex licensing.|
+-----------------------------------+--------------------+--------------------+-------------------------------------------+
```

---

## 4. Upstream / Downstream Interface Contracts

- **Upstream (H01 & H05):**
  Consumes `MarketBar` `{time, session_date, open, high, low, close, volume, adjusted_close, is_final}` from H01 contracts and H05 market service across six semantic ranges: `1D` (5m), `1W` (30m), `1M` (1d), `3M` (1d), `6M` (1d), `1Y` (1d).
- **Downstream (H11 & H13):**
  - H11 owns domain inputs (`MarketBar`, `NumericProjection`).
  - H13 implements production `PriceChart` widget in `frontend/lib/src/features/stock/widgets/price_chart.dart` following the architecture demonstrated by `ChartCapabilityProbe`.

---

## 5. Execution Boundary & Development PC Instructions

In accordance with the **ADAM-AUTHORIZED SPLIT-MACHINE SCOPE** (2026-10-30 Amendment):
- No Flutter SDK or Android tooling is installed on this Linux cloud server.
- Server-side acceptance is strictly **SOURCE_ONLY** (`SPEC_PASS_SOURCE_ONLY` / `QUALITY_PASS_SOURCE_ONLY`).
- Full runtime, device interaction, accessibility gestures, and APK building are **DEFERRED_TO_DEV_PC**.

### Instructions for Dev PC Agent:
1. Navigate to frontend root:
   ```bash
   cd /path/to/Horizon/frontend
   ```
2. Run the 14-test chart capability suite:
   ```bash
   flutter test test/chart_capability_test.dart
   ```
3. Run native probe in interactive runner or web emulator to record interaction proof:
   ```bash
   flutter run -d chrome
   # or on physical / emulated mobile device:
   flutter run -d <device-id>
   ```
4. Verify:
   - Pinch-to-zoom and pan smoothly scale horizontal axis.
   - Tap and drag updates exact OHLCV readout instantaneously.
   - Prev / Next buttons step through bars without precision touch.
   - Toggling between Line and Candles retains framing and selection.
   - Scenario overlay displays bounded horizontal corridors and target lines without drawing future candles.
