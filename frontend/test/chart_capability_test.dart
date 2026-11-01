import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'support/chart_probe.dart';

void main() {
  group('H02: Existing-library chart capability prototype tests', () {
    Widget buildTestHarness({
      List<ProbeMarketBar>? initialBars,
      ProbeNumericProjection? initialProjection,
      ChartStyle initialStyle = ChartStyle.line,
      ChartRange initialRange = ChartRange.r1M,
      bool initialShowOverlay = false,
      bool initialSnapshotMode = false,
      void Function(ProbeMarketBar?, int?)? onSelectionChanged,
    }) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0C0C0C),
        ),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: ChartCapabilityProbe(
              initialBars: initialBars,
              initialProjection: initialProjection,
              initialStyle: initialStyle,
              initialRange: initialRange,
              initialShowOverlay: initialShowOverlay,
              initialSnapshotMode: initialSnapshotMode,
              onSelectionChanged: onSelectionChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('1. renders probe in initial line chart state with default 1M range and theme', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('probe_title')), findsOneWidget);
      expect(find.byKey(const Key('probe_toggle_line')), findsOneWidget);
      expect(find.byKey(const Key('probe_toggle_candles')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(CandlestickChart), findsNothing);

      // Default selection is the last bar in the 4-bar daily fixture (2024-01-05)
      expect(find.byKey(const Key('readout_time')), findsOneWidget);
      expect(find.text('2024-01-05T14:30:00.000Z'), findsOneWidget);
      expect(find.text('Session: 2024-01-05'), findsOneWidget);
      expect(find.text('\$159.91'), findsOneWidget); // Open
      expect(find.text('\$160.55'), findsOneWidget); // High
      expect(find.text('\$158.67'), findsOneWidget); // Low
      expect(find.text('\$159.16'), findsOneWidget); // Close
      expect(find.text('Vol: 4199400'), findsOneWidget);
    });

    testWidgets('2. exact O/H/L/C/V/time matches fixture in line selection', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));

      // Select first bar: 2024-01-02
      state.selectBar(0);
      await tester.pumpAndSettle();

      expect(find.text('2024-01-02T14:30:00.000Z'), findsOneWidget);
      expect(find.text('Session: 2024-01-02'), findsOneWidget);
      expect(find.text('\$162.83'), findsOneWidget); // Open
      expect(find.text('\$163.29'), findsOneWidget); // High
      expect(find.text('\$160.46'), findsOneWidget); // Low
      expect(find.text('\$161.50'), findsOneWidget); // Close
      expect(find.text('Vol: 3825000'), findsOneWidget);

      // Select second bar: 2024-01-03
      state.selectBar(1);
      await tester.pumpAndSettle();

      expect(find.text('2024-01-03T14:30:00.000Z'), findsOneWidget);
      expect(find.text('Session: 2024-01-03'), findsOneWidget);
      expect(find.text('\$161.00'), findsOneWidget); // Open
      expect(find.text('\$161.73'), findsOneWidget); // High
      expect(find.text('\$160.08'), findsOneWidget); // Low
      expect(find.text('\$160.10'), findsOneWidget); // Close
      expect(find.text('Vol: 4086100'), findsOneWidget);
    });

    testWidgets('3. switching between line and candle styles preserves range and selection', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));

      // Select bar 2 (2024-01-04)
      state.selectBar(2);
      await tester.pumpAndSettle();
      expect(state.selectedIndex, 2);
      expect(state.currentRange, ChartRange.r1M);
      expect(find.text('2024-01-04T14:30:00.000Z'), findsOneWidget);

      // Tap Candles toggle
      await tester.tap(find.byKey(const Key('probe_toggle_candles')));
      await tester.pumpAndSettle();

      // Verify Candles chart is displayed, LineChart is removed
      expect(find.byType(CandlestickChart), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(state.currentStyle, ChartStyle.candles);

      // Range and selection must be preserved
      expect(state.currentRange, ChartRange.r1M);
      expect(state.selectedIndex, 2);
      expect(find.text('2024-01-04T14:30:00.000Z'), findsOneWidget);
      expect(find.text('\$160.22'), findsOneWidget); // Open
      expect(find.text('\$161.81'), findsOneWidget); // High
      expect(find.text('\$160.17'), findsOneWidget); // Low
      expect(find.text('\$160.86'), findsOneWidget); // Close
      expect(find.text('Vol: 3212000'), findsOneWidget);

      // Tap Line toggle back
      await tester.tap(find.byKey(const Key('probe_toggle_line')));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(CandlestickChart), findsNothing);
      expect(state.selectedIndex, 2);
      expect(state.currentRange, ChartRange.r1M);
    });

    testWidgets('4. exact O/H/L/C/V/time matches fixture in candle selection', (tester) async {
      await tester.pumpWidget(buildTestHarness(initialStyle: ChartStyle.candles));
      await tester.pumpAndSettle();

      expect(find.byType(CandlestickChart), findsOneWidget);
      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));

      state.selectBar(3);
      await tester.pumpAndSettle();

      expect(find.text('2024-01-05T14:30:00.000Z'), findsOneWidget);
      expect(find.text('\$159.91'), findsOneWidget);
      expect(find.text('\$160.55'), findsOneWidget);
      expect(find.text('\$158.67'), findsOneWidget);
      expect(find.text('\$159.16'), findsOneWidget);
      expect(find.text('Vol: 4199400'), findsOneWidget);
    });

    testWidgets('5. step controls (prev/next) inspect bars without precision gestures', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));
      expect(state.selectedIndex, 3); // Starts at bar 3

      // Tap Prev button
      await tester.tap(find.byKey(const Key('probe_btn_prev')));
      await tester.pumpAndSettle();
      expect(state.selectedIndex, 2);
      expect(find.text('2024-01-04T14:30:00.000Z'), findsOneWidget);

      // Tap Prev button again
      await tester.tap(find.byKey(const Key('probe_btn_prev')));
      await tester.pumpAndSettle();
      expect(state.selectedIndex, 1);
      expect(find.text('2024-01-03T14:30:00.000Z'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.byKey(const Key('probe_btn_next')));
      await tester.pumpAndSettle();
      expect(state.selectedIndex, 2);
      expect(find.text('2024-01-04T14:30:00.000Z'), findsOneWidget);
    });

    testWidgets('6. switching ranges preserves chart style and updates data series', (tester) async {
      await tester.pumpWidget(buildTestHarness(initialStyle: ChartStyle.candles));
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));
      expect(state.currentStyle, ChartStyle.candles);

      // Tap 1D range
      await tester.tap(find.byKey(const Key('probe_range_1D')));
      await tester.pumpAndSettle();

      expect(state.currentRange, ChartRange.r1D);
      expect(state.currentStyle, ChartStyle.candles); // Style preserved
      expect(find.byType(CandlestickChart), findsOneWidget);

      // Active bars should now be synthetic intraday bars (5 bars for 1D range test)
      expect(state.activeBars.length, 5);
      expect(find.text('2024-01-05T14:50:00.000Z'), findsOneWidget);
      expect(find.text('Vol: 490000'), findsOneWidget);
    });

    testWidgets('7. pan and zoom transformation controller updates scale and reset restores identity', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));
      expect(state.currentZoom, 1.0);
      expect(find.text('1.00x'), findsOneWidget);

      // Simulate zoom by setting transformation controller matrix
      state.transformationController.value = Matrix4.diagonal3Values(3.2, 1.0, 1.0);
      await tester.pumpAndSettle();

      expect(find.text('3.20x'), findsOneWidget);

      // Tap Reset View button
      await tester.tap(find.byKey(const Key('probe_btn_reset')));
      await tester.pumpAndSettle();

      expect(state.transformationController.value, Matrix4.identity());
      expect(state.currentZoom, 1.0);
      expect(find.text('1.00x'), findsOneWidget);
    });

    testWidgets('8. scenario overlay: null projection displays "No quantified projection" warning', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        initialProjection: null,
        initialShowOverlay: false,
      ));
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));
      state.setProjection(null);
      await tester.pumpAndSettle();

      // Turn on overlay
      await tester.tap(find.byKey(const Key('probe_toggle_overlay')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_no_projection')), findsOneWidget);
      expect(find.text('No quantified projection for this assessment'), findsOneWidget);
    });

    testWidgets('9. scenario overlay: valid projection renders endpoint markers and banner without future candles', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        initialStyle: ChartStyle.candles,
        initialShowOverlay: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_badge')), findsOneWidget);
      expect(find.textContaining('Conditional scenarios — not observed prices'), findsOneWidget);
      expect(find.textContaining('Target: 2024-02-05'), findsOneWidget);
      expect(find.textContaining('Range: \$150 - \$170'), findsOneWidget);

      // Find the CandlestickChart widget and verify that candlestickSpots contains strictly observed bars
      final chartFinder = find.byType(CandlestickChart);
      expect(chartFinder, findsOneWidget);
      final CandlestickChart chartWidget = tester.widget(chartFinder);

      // EXACTLY 4 spots from observed data — no future candles manufactured!
      expect(chartWidget.data.candlestickSpots.length, 4);

      // Verify that scenario lines are provided via extraLinesData
      expect(chartWidget.data.extraLinesData.horizontalLines.length, 3);
      expect(chartWidget.data.extraLinesData.horizontalLines[0].y, 170.0); // Upper bound
      expect(chartWidget.data.extraLinesData.horizontalLines[1].y, 160.0); // Central target
      expect(chartWidget.data.extraLinesData.horizontalLines[2].y, 150.0); // Lower bound

      // Verify range annotation for scenario corridor
      expect(chartWidget.data.rangeAnnotations.horizontalRangeAnnotations.length, 1);
      expect(chartWidget.data.rangeAnnotations.horizontalRangeAnnotations[0].y1, 150.0);
      expect(chartWidget.data.rangeAnnotations.horizontalRangeAnnotations[0].y2, 170.0);
    });

    testWidgets('10. scenario overlay: stale projection hides overlay and shows stale notice in live view', (tester) async {
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

      await tester.pumpWidget(buildTestHarness(
        initialProjection: staleProj,
        initialShowOverlay: true,
        initialSnapshotMode: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overlay_stale_notice')), findsOneWidget);
      expect(find.text('Projection is stale for live market view'), findsOneWidget);
      expect(find.byKey(const Key('btn_view_snapshot')), findsOneWidget);

      // Verify extra lines are empty in live mode because projection is stale
      final chartFinder = find.byType(LineChart);
      final LineChart chartWidget = tester.widget(chartFinder);
      expect(chartWidget.data.extraLinesData.horizontalLines.isEmpty, isTrue);
    });

    testWidgets('11. scenario overlay: "View assessment snapshot" activates pinned snapshot mode', (tester) async {
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

      await tester.pumpWidget(buildTestHarness(
        initialProjection: staleProj,
        initialShowOverlay: true,
        initialSnapshotMode: false,
      ));
      await tester.pumpAndSettle();

      // Tap "View assessment snapshot" button
      await tester.tap(find.byKey(const Key('btn_view_snapshot')));
      await tester.pumpAndSettle();

      // Notice switches to snapshot badge
      expect(find.byKey(const Key('overlay_badge')), findsOneWidget);
      expect(find.textContaining('[SNAPSHOT MODE]'), findsOneWidget);

      // Now extra lines are enabled because we are pinned to the assessment snapshot
      final chartFinder = find.byType(LineChart);
      final LineChart chartWidget = tester.widget(chartFinder);
      expect(chartWidget.data.extraLinesData.horizontalLines.isNotEmpty, isTrue);
    });

    testWidgets('12. actual and future endpoint ranges never overlap as observed bars', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        initialStyle: ChartStyle.candles,
        initialShowOverlay: true,
      ));
      await tester.pumpAndSettle();

      final state = tester.state<ChartCapabilityProbeState>(find.byType(ChartCapabilityProbe));
      final CandlestickChart chart = tester.widget(find.byType(CandlestickChart));

      // 4 observed bars in fixture
      expect(state.activeBars.length, 4);
      // CandlestickSpots contains strictly 4 spots
      expect(chart.data.candlestickSpots.length, 4);

      // Verify no spot has X coordinate greater than or equal to future projection target
      for (final spot in chart.data.candlestickSpots) {
        expect(spot.x < 4.0, isTrue);
      }
    });

    testWidgets('13. handles null volume and single-point data gracefully without errors', (tester) async {
      final singleBarNoVol = [
        const ProbeMarketBar(
          time: '2024-01-02T14:30:00.000Z',
          sessionDate: '2024-01-02',
          open: 162.83,
          high: 163.29,
          low: 160.46,
          close: 161.50,
          volume: null, // Null volume
        ),
      ];

      await tester.pumpWidget(buildTestHarness(initialBars: singleBarNoVol));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('readout_volume')), findsOneWidget);
      expect(find.text('Vol: N/A'), findsOneWidget);
      expect(find.text('\$161.50'), findsOneWidget);
    });

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
  });
}
