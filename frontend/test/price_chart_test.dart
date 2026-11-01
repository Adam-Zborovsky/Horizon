// H13 — widget/controller tests for the interactive observed-data chart.
//
// Fixture provenance: the daily bar values below are the exact observed
// recording from backend/test/fixtures/research/observed-bars.json
// (Yahoo Finance public chart response, content_sha256
// dcf75e1922753be1fc0ced05f47892c6dfbc48b4c52fe5bd2c2e0d9e83923caf,
// retrieved 2026-10-30). Nothing here manufactures candles, sessions, or
// future trajectories; the unavailable/error fixtures contain no bars at all.
//
// EXECUTION STATUS: this suite requires the generated freezed parts for the
// H11 models (dart run build_runner build) and a Flutter SDK. Neither exists
// on the H13 author host, so the suite is authored source-only and its
// execution is DEFERRED_TO_DEV_PC (see docs/horizon/evidence/h13-author.md).
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horizon/src/features/market/market_models.dart';
import 'package:horizon/src/features/positions/position_models.dart';
import 'package:horizon/src/features/research/research_models.dart';
import 'package:horizon/src/features/stock/widgets/chart_controller.dart';
import 'package:horizon/src/features/stock/widgets/price_chart.dart';

// ------------------------------------------------------------- fixtures

/// Exact observed daily bars from backend/test/fixtures/research/
/// observed-bars.json (values byte-for-byte from the fixture recording).
const List<Map<String, dynamic>> kObservedDailyBarsJson = [
  {
    'time': '2024-01-02T14:30:00.000Z',
    'session_date': '2024-01-02',
    'open': 162.8300018310547,
    'high': 163.2899932861328,
    'low': 160.4600067138672,
    'close': 161.5,
    'volume': 3825000,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-03T14:30:00.000Z',
    'session_date': '2024-01-03',
    'open': 161,
    'high': 161.72999572753906,
    'low': 160.0800018310547,
    'close': 160.10000610351562,
    'volume': 4086100,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-04T14:30:00.000Z',
    'session_date': '2024-01-04',
    'open': 160.22000122070312,
    'high': 161.80999755859375,
    'low': 160.1699981689453,
    'close': 160.86000061035156,
    'volume': 3212000,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-05T14:30:00.000Z',
    'session_date': '2024-01-05',
    'open': 159.91000366210938,
    'high': 160.5500030517578,
    'low': 158.6699981689453,
    'close': 159.16000366210938,
    'volume': 4199400,
    'adjusted_close': null,
    'is_final': true,
  },
];

const String kRawBasis =
    'raw provider OHLCV; adjusted close intentionally omitted';

const String kInstrumentId = 'instrument-ibm-xnys-usd';

Map<String, dynamic> historyJson({
  String range = '1M',
  String dataStatus = 'available',
  List<Map<String, dynamic>> bars = kObservedDailyBarsJson,
  String adjustmentBasis = kRawBasis,
  String actualResolution = '1d',
  String asOf = '2024-01-05T21:00:00.000Z',
  String fetchedAt = '2024-01-05T21:05:00.000Z',
  String? unavailableReason,
  bool isStale = false,
  List<Map<String, dynamic>> warnings = const [],
}) {
  return {
    'contract_version': 1,
    'instrument': {
      'instrument_id': kInstrumentId,
      'symbol': 'IBM',
      'exchange': 'XNYS',
      'currency': 'USD',
      'provider_symbol': 'IBM',
    },
    'snapshot_id': null,
    'range': range,
    'requested_resolution': '1d',
    'actual_resolution': actualResolution,
    'exchange_timezone': 'America/New_York',
    'session_mode': 'regular',
    'adjustment_basis': adjustmentBasis,
    'as_of': asOf,
    'fetched_at': fetchedAt,
    'data_status': dataStatus,
    'delay_status': 'unknown',
    'is_stale': isStale,
    'available_ranges': ['1D', '1W', '1M', '3M', '6M', '1Y'],
    'bars': bars,
    'warnings': warnings,
    'next_cursor': null,
    'unavailable_reason': unavailableReason,
  };
}

HistoryResponse availableHistory() =>
    HistoryResponse.fromJson(historyJson());

/// Typed projection anchored after the last displayed observed bar (fresh).
NumericProjection freshProjection({
  String currency = 'USD',
  String adjustmentBasis = 'raw_ohlc_unadjusted',
}) {
  return NumericProjection.fromJson({
    'id': 'projection-1',
    'assessment_id': 'assessment-1',
    'instrument_id': kInstrumentId,
    'evidence_snapshot_id': 'snapshot-1',
    'anchor_time': '2024-01-05T21:00:00.000Z',
    'anchor_price_metric_id': 'metric-close-1',
    'target_session_date': '2024-02-05',
    'kind': 'conditional_scenario',
    'method': 'scenario_envelope',
    'method_version': '1',
    'input_metric_ids': ['metric-close-1'],
    'assumption_ids': ['assumption-1', 'assumption-2'],
    'lower': 150.0,
    'central': 160.0,
    'upper': 170.0,
    'currency': currency,
    'adjustment_basis': adjustmentBasis,
    'calibration': null,
    'valid_until': '2024-02-05T21:00:00.000Z',
    'limitations': ['Synthetic test output.'],
  });
}

/// Typed projection whose anchor precedes the last displayed observed bar —
/// market data has advanced beyond the assessment cutoff (CONTRACTS §7).
NumericProjection staleProjection() {
  return NumericProjection.fromJson({
    'id': 'projection-2',
    'assessment_id': 'assessment-1',
    'instrument_id': kInstrumentId,
    'evidence_snapshot_id': 'snapshot-1',
    'anchor_time': '2024-01-04T00:00:00.000Z',
    'anchor_price_metric_id': 'metric-close-1',
    'target_session_date': '2024-02-05',
    'kind': 'conditional_scenario',
    'method': 'scenario_envelope',
    'method_version': '1',
    'input_metric_ids': ['metric-close-1'],
    'assumption_ids': ['assumption-1'],
    'lower': 150.0,
    'central': null,
    'upper': 170.0,
    'currency': 'USD',
    'adjustment_basis': 'raw_ohlc_unadjusted',
    'calibration': null,
    'valid_until': '2024-01-05T20:00:00.000Z',
    'limitations': ['Synthetic test output.'],
  });
}

Widget harness(ChartController controller) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 650,
          height: 900,
          child: PriceChart(controller: controller),
        ),
      ),
    ),
  );
}

void main() {
  group('H13 controller: ranges, styles, selection', () {
    test('selects all six contract ranges and calls the loader per range', () async {
      final requested = <MarketRange>[];
      final controller = ChartController(
        loadHistory: (range) {
          requested.add(range);
          return Future.value(availableHistory());
        },
        initialRange: MarketRange.oneMonth,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero); // initial load
      expect(requested, [MarketRange.oneMonth]);

      for (final range in MarketRange.values) {
        await controller.selectRange(range);
      }
      expect(requested, [
        MarketRange.oneMonth,
        ...MarketRange.values,
      ]);
      expect(controller.range, MarketRange.oneYear);
      expect(controller.status, ChartLoadState.loaded);
    });

    test('style change preserves range, selection and exact fixture values', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      controller.selectBar(2);
      controller.selectStyle(ChartStyle.candles);

      expect(controller.range, MarketRange.oneMonth);
      expect(controller.selectedIndex, 2);
      final bar = controller.selectedBar!;
      expect(bar.time, '2024-01-04T14:30:00.000Z');
      expect(bar.sessionDate, '2024-01-04');
      expect(bar.open, 160.22000122070312);
      expect(bar.high, 161.80999755859375);
      expect(bar.low, 160.1699981689453);
      expect(bar.close, 160.86000061035156);
      expect(bar.volume, 3212000);
    });

    test('superseded responses are cancelled and never rendered', () async {
      final slow = Completer<HistoryResponse>();
      final fast = Completer<HistoryResponse>();
      final responses = <Completer<HistoryResponse>>[slow, fast];
      var calls = 0;
      final controller = ChartController(
        loadHistory: (range) => responses[calls++].future,
      );
      addTearDown(controller.dispose);

      final switched = controller.selectRange(MarketRange.oneWeek);
      fast.complete(HistoryResponse.fromJson(
          historyJson(range: '1W')));
      await switched;

      // The first request completes late; its response is stale and must be
      // discarded, not rendered.
      slow.complete(availableHistory());
      await Future<void>.delayed(Duration.zero);

      expect(controller.history!.range, MarketRange.oneWeek);
      expect(controller.status, ChartLoadState.loaded);
    });

    test('X mapping is index-based and identical across styles', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(controller.minX, 0);
      expect(controller.maxX, 3); // four observed bars, no future extension.
      controller.selectStyle(ChartStyle.candles);
      expect(controller.minX, 0);
      expect(controller.maxX, 3);
    });
  });

  group('H13 controller: projection and user-cost gates', () {
    test('overlay defaults off and gates fresh projection visibility', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      controller.setProjection(freshProjection());

      expect(controller.projectionGate, ProjectionGateState.toggleOff);
      controller.setOverlayEnabled(true);
      expect(controller.projectionGate, ProjectionGateState.visible);
      expect(controller.projectionBoundsVisible, isTrue);
    });

    test('projection hidden as stale when market advanced beyond cutoff', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      controller.setProjection(staleProjection());
      controller.setOverlayEnabled(true);

      expect(controller.projectionGate, ProjectionGateState.stale);
      controller.enterSnapshotMode();
      expect(controller.projectionGate, ProjectionGateState.visible);
    });

    test('projection suppressed across currency or basis mismatch', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      controller.setProjection(
          freshProjection(currency: 'EUR'));
      controller.setOverlayEnabled(true);
      expect(controller.projectionGate, ProjectionGateState.basisMismatch);

      controller.setProjection(
          freshProjection(adjustmentBasis: 'split_adjusted'));
      expect(controller.projectionGate, ProjectionGateState.basisMismatch);
    });

    test('no projection is a clear state, never an invented target', () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      controller.setOverlayEnabled(true);
      expect(controller.projection, isNull);
      expect(controller.projectionGate, ProjectionGateState.none);
    });

    test('user cost renders only for matching currency and compatible basis',
        () async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      controller.setUserCost(
          MoneyAmount.fromJson({'amount': '155.25', 'currency': 'USD'}));
      // Basis unknown: conservative suppression, line not rendered.
      expect(controller.userCostGate, UserCostGateState.basisMismatch);
      expect(controller.userCostValue, isNull);

      controller.setUserCostBasis('raw_ohlc_unadjusted');
      expect(controller.userCostGate, UserCostGateState.visible);
      expect(controller.userCostValue, 155.25);

      controller.setUserCost(
          MoneyAmount.fromJson({'amount': '150', 'currency': 'EUR'}));
      expect(controller.userCostGate, UserCostGateState.currencyMismatch);
      expect(controller.userCostValue, isNull);
    });
  });

  group('H13 widget: observed rendering and state screens', () {
    testWidgets('renders line chart with exact fixture readout and labels '
        'actual resolution', (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chart_line')), findsOneWidget);
      expect(find.byType(CandlestickChart), findsNothing);
      expect(find.text('2024-01-05T14:30:00.000Z'), findsOneWidget);
      expect(find.text('Session: 2024-01-05'), findsOneWidget);
      expect(find.text(r'$159.91'), findsOneWidget);
      expect(find.text(r'$160.55'), findsOneWidget);
      expect(find.text(r'$158.67'), findsOneWidget);
      expect(find.text(r'$159.16'), findsOneWidget);
      expect(find.text('Vol: 4199400'), findsOneWidget);
      expect(find.textContaining('(1d)'), findsOneWidget);
    });

    testWidgets('exact values, timestamps and selected range survive style '
        'changes', (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      _selectBar(controller, 0);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chart_style_candles')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chart_candles')), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(controller.range, MarketRange.oneMonth);
      expect(controller.selectedIndex, 0);
      expect(find.text('2024-01-02T14:30:00.000Z'), findsOneWidget);
      expect(find.text(r'$162.83'), findsOneWidget);
      expect(find.text(r'$163.29'), findsOneWidget);
      expect(find.text(r'$160.46'), findsOneWidget);
      expect(find.text(r'$161.50'), findsOneWidget);
      expect(find.text('Vol: 3825000'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chart_style_line')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chart_line')), findsOneWidget);
      expect(controller.range, MarketRange.oneMonth);
      expect(controller.selectedIndex, 0);
    });

    testWidgets('line and candle charts share one index-based X axis '
        '(X-axis equivalence)', (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      final lineData =
          tester.widget<LineChart>(find.byKey(const Key('chart_line'))).data;
      expect(lineData.minX, 0);
      expect(lineData.maxX, 3);

      await tester.tap(find.byKey(const Key('chart_style_candles')));
      await tester.pumpAndSettle();

      final candleData = tester
          .widget<CandlestickChart>(find.byKey(const Key('chart_candles')))
          .data;
      // Same mapping: identical bounds, and every candle sits on the bar
      // index it represents.
      expect(candleData.minX, lineData.minX);
      expect(candleData.maxX, lineData.maxX);
      expect(
        candleData.candlestickSpots.map((s) => s.x).toList(),
        [0, 1, 2, 3],
      );
      // No spot beyond the last observed bar: no future candles exist.
      expect(candleData.candlestickSpots.any((s) => s.x > 3), isFalse);
    });

    testWidgets('overlay banner separates scenarios from observed data and '
        'exposes details on tap', (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();
      controller.setProjection(freshProjection());
      await tester.pump();

      // Projection present but the overlay toggle is still off (defaults off,
      // CONTRACTS §7): no scenario banner. The pump above rebuilds the tree
      // with the projection set, so this assertion is non-vacuous — it fails
      // if the toggle-off case ever renders the banner.
      expect(find.byKey(const Key('overlay_badge')), findsNothing);
      expect(
          find.textContaining('Conditional scenarios — not observed prices'),
          findsNothing);

      await tester.tap(find.byKey(const Key('chart_overlay_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_badge')), findsOneWidget);
      expect(
          find.textContaining('Conditional scenarios — not observed prices'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('overlay_badge_tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_details')), findsOneWidget);
      expect(find.text('2024-01-05T21:00:00.000Z'), findsOneWidget);
      expect(find.text('2024-02-05'), findsOneWidget);
      expect(find.text('scenario_envelope v1'), findsOneWidget);
      expect(find.text('raw_ohlc_unadjusted'), findsOneWidget);
      expect(find.text('2 referenced'), findsOneWidget);
      expect(find.text('Synthetic test output.'), findsOneWidget);
    });

    testWidgets('no quantified projection is a clear state', (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chart_overlay_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_no_projection')), findsOneWidget);
      expect(find.text('No quantified projection for this assessment'),
          findsOneWidget);
    });

    testWidgets('stale projection defaults hidden with snapshot action',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();
      controller.setProjection(staleProjection());

      await tester.tap(find.byKey(const Key('chart_overlay_switch')));
      await tester.pumpAndSettle();

      // Hidden by default with the stale notice; no scenario lines rendered.
      expect(find.byKey(const Key('overlay_stale_notice')), findsOneWidget);
      expect(find.byKey(const Key('overlay_badge')), findsNothing);
      expect(find.byKey(const Key('btn_view_snapshot')), findsOneWidget);

      // 48dp-minimum accessible snapshot action enters snapshot mode.
      await tester.tap(find.byKey(const Key('btn_view_snapshot')));
      await tester.pumpAndSettle();

      expect(controller.snapshotMode, isTrue);
      expect(find.byKey(const Key('overlay_badge')), findsOneWidget);
      expect(find.textContaining('[SNAPSHOT MODE]'), findsOneWidget);
    });

    testWidgets('basis-mismatched projection is suppressed with a notice',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();
      controller.setProjection(
          freshProjection(adjustmentBasis: 'split_adjusted'));

      await tester.tap(find.byKey(const Key('chart_overlay_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_basis_notice')), findsOneWidget);
      expect(find.byKey(const Key('overlay_badge')), findsNothing);
    });

    testWidgets('user cost gate states surface honestly in the widget',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(availableHistory()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      // Unknown cost: explicit state, never an invented value.
      expect(find.byKey(const Key('user_cost_unknown')), findsOneWidget);
      expect(find.text('User cost unknown — declared cost is never invented'),
          findsOneWidget);

      controller.setUserCost(
          MoneyAmount.fromJson({'amount': '155.25', 'currency': 'USD'}));
      await tester.pumpAndSettle();
      // Basis unconfirmed: suppressed with a gate notice, not drawn anyway.
      expect(find.byKey(const Key('user_cost_gate')), findsOneWidget);
      expect(controller.userCostValue, isNull);

      controller.setUserCostBasis('raw_ohlc_unadjusted');
      await tester.pumpAndSettle();
      expect(controller.userCostGate, UserCostGateState.visible);
      expect(controller.userCostValue, 155.25);
    });

    testWidgets('unavailable feed renders the reason, never synthetic prices',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.value(
          HistoryResponse.fromJson(
            historyJson(
              dataStatus: 'unavailable',
              bars: const [],
              unavailableReason: 'provider_feed_unavailable',
            ),
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chart_status_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('chart_unavailable_reason')), findsOneWidget);
      expect(find.text('provider_feed_unavailable'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(CandlestickChart), findsNothing);
      expect(find.byKey(const Key('chart_readout_panel')), findsNothing);
    });

    testWidgets('first-load gap shows loading state with no price output',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Completer<HistoryResponse>().future,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pump();

      expect(find.byKey(const Key('chart_loading')), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(CandlestickChart), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('load error renders an explicit error state, no fallback data',
        (tester) async {
      final controller = ChartController(
        loadHistory: (_) => Future.error(const FormatException('bad json')),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chart_status_error')), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(CandlestickChart), findsNothing);
    });

    testWidgets('null volume is labeled N/A, never zero', (tester) async {
      final barsWithNullVolume = [
        Map<String, dynamic>.of(kObservedDailyBarsJson[0])..['volume'] = null,
        ...kObservedDailyBarsJson.sublist(1),
      ];
      final controller = ChartController(
        loadHistory: (_) => Future.value(
          HistoryResponse.fromJson(
              historyJson(bars: barsWithNullVolume)),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();
      controller.selectBar(0);
      await tester.pumpAndSettle();

      expect(find.text('Vol: N/A'), findsOneWidget);
      expect(find.textContaining('Vol: 0'), findsNothing);
      // The strip labels itself as context, not as transform-synchronized.
      expect(find.text('Volume context — inspected bar highlighted'),
          findsOneWidget);
    });
  });
}

void _selectBar(ChartController controller, int index) =>
    controller.selectBar(index);
