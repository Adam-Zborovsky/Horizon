# H13 — Author delivery: interactive observed-data chart and projection display

- Task: t_76ee4e19 (H13), role flutter-chart-worker, phase core_source
- Date: 2026-10-31
- Workspace: /home/ubuntu/apps/Horizon, branch main, baseline HEAD 9fbb26b5519889e0816720530dd60c204dda2bf2, dirty baseline preserved (no commit, no push, no branch change, no cleanup).
- Author profile: worker (zai/glm-5.3-flash). This is an AUTHOR DELIVERY ONLY — not independent acceptance. Controller verifies delivery; reviewer inspects artifacts independently.

## 1. Changed files (exact paths, SHA-256)

| Path | Lines | SHA-256 |
|---|---|---|
| frontend/lib/src/features/stock/widgets/chart_controller.dart | 445 | 3ae015790af36256fbfdf05c64738a0284e63b71bfb627cf0bbff6cf02d8737a |
| frontend/lib/src/features/stock/widgets/price_chart.dart | 1128 | 7faa125b31b1b0c675d44538d8d858dd5cedc086ce9527823d2014899c2025f1 |
| frontend/test/price_chart_test.dart | 653 | b55cacb0d263a84a53dfbcfeba94f8b00e7dbfcc6c60818d332e633d100e0b9f |

Machine-readable copy: docs/horizon/evidence/h13/sha256sums.txt (sha256sum output over the same three files).

`git status --porcelain` shows exactly these three new paths under `frontend/lib/src/features/stock/widgets/` and `frontend/test/price_chart_test.dart` (plus pre-existing dirty baseline lanes untouched). No existing file was edited. `git diff --check` clean.

## 2. Commands run and results (actual output)

All checks executable on this host (no Dart/Flutter SDK — probed: `which dart flutter` → not found, exit 1):

1. `git status --porcelain | grep -E "stock/widgets|price_chart|h13"` → exit 0; output listed in §1 (only allowed new files).
2. `git diff --check` → exit 0, "diff --check clean" (no whitespace errors).
3. Balanced-delimiter static scan (Python) over the three Dart files after stripping comments/string literals → braces 0, parens 0, brackets 0 for all three (log: docs/horizon/evidence/h13/static-scan.log).
4. `which dart flutter` → exit 1 (SDK absent; corroborates H02 review's probe).

No Flutter/Dart command was executed, so no analyze/test/build output exists and none is claimed. All Dart execution is DEFERRED_TO_DEV_PC.

## 3. Component interface (for H15 — the only lane that edits stock_detail_screen.dart)

```dart
// Controller: drive from a riverpod provider or the screen's state.
final ChartController controller = ChartController(
  loadHistory: (MarketRange range) => ref
      .read(marketRepositoryProvider)
      .getHistory(instrumentId: instrumentId, range: range),
  initialRange: MarketRange.oneMonth,   // any of the six contract ranges
  initialStyle: ChartStyle.line,        // or ChartStyle.candles
);

// Optional typed inputs (all nullable, all re-settable):
controller.setProjection(NumericProjection?);   // H11 research model or null
controller.setUserCost(MoneyAmount?);           // H11/positions model or null
controller.setUserCostBasis(String?);           // optional explicit cost basis;
                                                // null = unknown = suppressed

// Snapshot flow: when PriceChart.onViewSnapshot fires, the host pins the
// view to the assessment snapshot (history/metrics from the snapshot id)
// and re-feeds the controller; controller.enterSnapshotMode() is already
// invoked by the widget's btn_view_snapshot handler.

// Widget:
PriceChart(
  controller: controller,
  theme: const PriceChartTheme(),       // optional palette override
  onViewSnapshot: () { ... },           // optional host hook
)
// Controller is a ChangeNotifier: dispose it with the screen.
// PriceChart registers/unregisters its own transform listener; no extra wiring.
```

Interaction surface delivered (widget keys): chart_style_line / chart_style_candles, chart_range_1D…chart_range_1Y, chart_prev / chart_next / chart_reset, chart_overlay_switch, chart_zoom_readout, chart_loading / chart_status_unavailable (+ chart_unavailable_reason) / chart_status_error / chart_empty_state, overlay_badge (+ overlay_badge_tap → overlay_details with issued/target/kind/method/basis/assumptions/limitations), overlay_no_projection, overlay_stale_notice + btn_view_snapshot (48dp minimum), overlay_basis_notice, user_cost_unknown / user_cost_gate, chart_volume_strip (+ label "Volume context — inspected bar highlighted"), chart_readout_panel with readout_time / readout_session_date / readout_open / readout_high / readout_low / readout_close / readout_volume.

## 4. Contract mapping (CONTRACTS.md v1)

| Requirement | Implementation |
|---|---|
| §3 six ranges/resolutions | `MarketRange` (H11 typed enum) drives the range selector; actual resolution labeled in the readout (`actualResolution`), never relabeled |
| §3 no manufactured candles / no filled sessions | Widget renders only `HistoryResponse.bars` from the typed repository response; unavailable → empty-bar state screen with machine-readable `unavailable_reason`; error/loading show state screens, never prices |
| §3 volume null vs zero | Null volume → explicit N/A marker in strip and readout (`Vol: N/A`); zero renders as zero |
| §3 stale/delay labeling | `is_stale` → cache-stale banner; `delay_status` delayed/unknown → "not real-time" banners; stale never claims realtime (enforced upstream by H11 parse too) |
| §3 bar identity on axes | Bottom titles use `session_date` (daily) or UTC bucket time (intraday), verbatim from typed bars |
| §7 overlay defaults off | `_overlayEnabled = false` initial state (test asserts) |
| §7 "Conditional scenarios — not observed prices" | Banner text verbatim, includes target session and bound range; details (issued date, target date, method+version, adjustment basis, assumptions count, limitations) accessible on banner tap |
| §7 dashed boundaries, endpoint ranges, no future path | Projection drawn as dashed horizontal lines (lower/central/upper) + low-opacity band annotation; X axis structurally ends at the last observed bar (`maxX = len-1`), so no future candles or trajectory points can exist |
| §7 no quantitative projection | "No quantified projection for this assessment" state (typed model null) |
| §7 stale overlay default hidden + snapshot action | Freshness gate: displayed last-bar time / as_of beyond projection `anchor_time`, or `fetched_at` past `valid_until` → hidden with stale notice + 48dp "View assessment snapshot" button; snapshot mode restores the overlay with `[SNAPSHOT MODE]` label |
| §7 user cost separate, matching currency + compatible basis | Separate dotted "User cost" line gated by `UserCostGateState` (currency mismatch, unknown/incompatible basis → suppressed with honest notices); unknown cost → explicit "declared cost is never invented" state |
| No scenario styling certainty | Dashed 0.6-opacity accent lines, 0.06-opacity band — visually subordinate to solid observed data |

## 5. Test coverage authored (frontend/test/price_chart_test.dart, 21 cases)

Controller group: (1) all six ranges select + per-range loader calls; (2) style change preserves range/selection/exact fixture values; (3) superseded-response cancellation (late-arriving stale response discarded, never rendered); (4) index-based X mapping identical across styles.

Gates group: (5) overlay defaults off, fresh typed projection visible when enabled; (6) market advanced beyond cutoff → stale gate, snapshot mode restores; (7) currency and basis mismatch suppression; (8) null projection → clear none state; (9) user cost currency/basis/cost-known gate matrix with conservative unknown-basis suppression.

Widget group: (10) line chart exact fixture readout (time, session, O/H/L/C, volume, actual resolution label); (11) exact values/timestamps/range survive line↔candle toggles; (12) X-axis equivalence (H02 review note): identical minX/maxX across styles, candle spots exactly at indices 0–3, no spot beyond the last observed bar; (13) overlay banner separation + details-on-tap; (14) "No quantified projection" state; (15) stale notice + btn_view_snapshot flow into snapshot mode; (16) basis-mismatch notice; (17) user-cost widget gate states; (18) unavailable feed renders reason with zero chart widgets; (19) first-load gap shows loading, no `$` text anywhere; (20) load error state, no fallback data; (21) null volume labeled N/A, strip wording de-synchronized ("Volume context — inspected bar highlighted", per H02 review note).

Fixture provenance: daily bars are the exact observed recording from backend/test/fixtures/research/observed-bars.json (content_sha256 dcf75e1922753be1fc0ced05f47892c6dfbc48b4c52fe5bd2c2e0d9e83923caf); projections are synthetic typed-model instances labeled as such; unavailable/error fixtures contain no bars. No intraday fixture was needed (X-axis and range behavior are resolution-independent).

## 6. Limitations — explicit DEFERRED_TO_DEV_PC (never PASS from this delivery)

- The 21-case suite above was NOT executed: no Flutter SDK on this host, and the H11 typed models require `dart run build_runner build --delete-conflicting-outputs` (freezed parts for market_models/position_models/research_models) before any compilation. Suite correctness is judged by source inspection only.
- `flutter analyze`, `flutter test`, `flutter build web`, Android/APK, and device gesture capture: not run, DEFERRED_TO_DEV_PC.
- fl_chart 1.1.1 API usage mirrors the H02-accepted probe (FlTransformationConfig, CandlestickChart/CandlestickChartData.candlestickSpots, CandlestickTouchData, ExtraLinesData, RangeAnnotations, SideTitleWidget(meta:...)); a compile against the resolved dependency has not been produced — residual symbol mismatches are Dev-PC compile checks.
- Pan/zoom/reset, touch inspection and volume-context behavior are implemented (shared TransformationController, 48dp targets, Semantics) but verified as source structure only; no rendered/visual proof exists.
- Test imports use the actual package name `horizon` (matching frontend/test/research_models_test.dart convention).
- User-cost basis: the H11 position model carries no corporate-action basis, so compatibility requires the host to pass `setUserCostBasis`; unknown basis conservatively suppresses the line (safe direction, documented in source).
- Deliberately NOT done (ownership): no edit to stock_detail_screen.dart (H15 alone), no riverpod provider for the controller (H15 wires it), no new dependency (fl_chart ^1.1.1 only), no pubspec/lockfile change, no generated files authored.
