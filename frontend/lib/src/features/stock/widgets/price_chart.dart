// H13 — reusable interactive observed-data price chart (production widget).
//
// Promotes the accepted H02 probe architecture into a themed component that
// consumes the controller in chart_controller.dart and H11's typed domain
// models. Contract rules enforced here (CONTRACTS §3/§7):
//  - only bars parsed from a typed HistoryResponse are rendered; unavailable
//    feeds, first-load gaps and errors render state screens, never synthetic
//    prices or filled sessions;
//  - observations use solid line/candles; projections are dashed horizontal
//    bounds plus a band — endpoint ranges, never a future path, and no
//    future candles exist structurally (X axis ends at the last observed bar);
//  - overlay defaults off; the stale notice offers a 48dp "View assessment
//    snapshot" action; projection details (issued/target/method/assumptions/
//    limitations) are accessible on tap;
//  - the user-cost reference is a separate dotted line labeled "User cost",
//    gated on matching currency and compatible basis by the controller;
//  - the volume strip is index-aligned context for the inspected bar (it is
//    NOT transform-synchronized wording); null volume renders as an explicit
//    N/A marker, never zero.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../market/market_models.dart';
import 'chart_controller.dart';

/// Palette for the chart. Defaults match the Horizon dark surface; hosts may
/// override for alternate themes.
@immutable
class PriceChartTheme {
  const PriceChartTheme({
    this.accent = const Color(0xFFFFB800),
    this.surface = const Color(0xFF0C0C0C),
    this.panel = const Color(0xFF161618),
    this.danger = const Color(0xFFFF4B5C),
    this.onSurfaceMuted = Colors.white54,
    this.onSurfaceSubtle = Colors.white38,
  });

  final Color accent;
  final Color surface;
  final Color panel;
  final Color danger;
  final Color onSurfaceMuted;
  final Color onSurfaceSubtle;
}

/// Interactive observed-data chart with optional typed projection overlay
/// and user-cost reference. Reads all state from [controller]; this widget
/// holds no data of its own.
class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.controller,
    this.theme = const PriceChartTheme(),
    this.onViewSnapshot,
  });

  final ChartController controller;
  final PriceChartTheme theme;

  /// Invoked when the user asks to view the assessment snapshot (stale
  /// overlay notice). The host pins history/metrics to the snapshot and
  /// re-feeds the controller.
  final VoidCallback? onViewSnapshot;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  bool _projectionDetailsOpen = false;

  ChartController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.transformationController
        .addListener(_controller.onTransformChanged);
  }

  @override
  void dispose() {
    _controller.transformationController
        .removeListener(_controller.onTransformChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.theme.surface,
      padding: const EdgeInsets.all(12),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStyleHeader(),
            const SizedBox(height: 8),
            _buildRangeSelector(),
            const SizedBox(height: 8),
            _buildInteractionBar(),
            const SizedBox(height: 8),
            _buildOverlayArea(),
            Expanded(child: _buildChartArea()),
            const SizedBox(height: 8),
            _buildVolumeStrip(),
            const SizedBox(height: 8),
            _buildReadoutPanel(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- controls

  Widget _buildStyleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'OBSERVED PRICE',
          key: const Key('chart_title'),
          style: TextStyle(
            color: widget.theme.accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        Row(
          children: [
            _touchable(
              key: const Key('chart_style_line'),
              label: 'Line',
              isSelected: _controller.style == ChartStyle.line,
              onTap: () => _controller.selectStyle(ChartStyle.line),
            ),
            const SizedBox(width: 6),
            _touchable(
              key: const Key('chart_style_candles'),
              label: 'Candles',
              isSelected: _controller.style == ChartStyle.candles,
              onTap: () => _controller.selectStyle(ChartStyle.candles),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MarketRange.values.map((range) {
          final isSelected = _controller.range == range;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _touchable(
              key: Key('chart_range_${range.wireValue}'),
              label: range.wireValue,
              isSelected: isSelected,
              onTap: () => _controller.selectRange(range),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        _touchable(
          key: const Key('chart_reset'),
          label: 'Reset view',
          icon: Icons.refresh,
          onTap: _controller.resetView,
        ),
        const SizedBox(width: 4),
        _touchable(
          key: const Key('chart_prev'),
          label: 'Prev',
          icon: Icons.chevron_left,
          onTap: _controller.stepPrev,
        ),
        const SizedBox(width: 4),
        _touchable(
          key: const Key('chart_next'),
          label: 'Next',
          icon: Icons.chevron_right,
          onTap: _controller.stepNext,
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Overlay', style: TextStyle(color: widget.theme.onSurfaceMuted, fontSize: 12)),
              Switch(
                key: const Key('chart_overlay_switch'),
                value: _controller.overlayEnabled,
                activeColor: widget.theme.accent,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onChanged: _controller.setOverlayEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${_controller.zoom.toStringAsFixed(2)}x',
          key: const Key('chart_zoom_readout'),
          style: TextStyle(
            color: widget.theme.accent,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------- overlay / banners

  Widget _buildOverlayArea() {
    return Column(
      children: [
        _buildProjectionBanner(),
        _buildUserCostNotice(),
        if (_controller.history?.isStale ?? false) _buildStaleCacheNotice(),
        if (_controller.history?.delayStatus == DelayStatus.delayed ||
            (_controller.history?.delayStatus == DelayStatus.unknown &&
                _controller.history != null))
          _buildDelayNotice(),
        if (_controller.history?.warnings.isNotEmpty ?? false)
          _buildWarningsNotice(),
      ],
    );
  }

  Widget _buildProjectionBanner() {
    switch (_controller.projectionGate) {
      case ProjectionGateState.toggleOff:
        // Overlay toggle is off: no scenario banner, no projection UI, even
        // when a projection is present (CONTRACTS §7 overlay defaults off).
        return const SizedBox.shrink();
      case ProjectionGateState.visible:
        break;
      case ProjectionGateState.none:
        return _banner(
          key: const Key('overlay_no_projection'),
          text: 'No quantified projection for this assessment',
          accent: widget.theme.onSurfaceMuted,
          borderOpacity: 0.24,
          fillOpacity: 0.08,
        );
      case ProjectionGateState.stale:
        return Container(
          key: const Key('overlay_stale_notice'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.danger.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.theme.danger.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Market data advanced beyond this assessment; overlay hidden',
                  style: TextStyle(color: widget.theme.danger, fontSize: 12),
                ),
              ),
              ElevatedButton(
                key: const Key('btn_view_snapshot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  _controller.enterSnapshotMode();
                  widget.onViewSnapshot?.call();
                },
                child: const Text(
                  'View assessment snapshot',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      case ProjectionGateState.basisMismatch:
        return _banner(
          key: const Key('overlay_basis_notice'),
          text: 'Projection not shown: price basis or currency differs from '
              'the displayed data',
          accent: widget.theme.danger,
          borderOpacity: 0.4,
          fillOpacity: 0.12,
        );
      case ProjectionGateState.noHistory:
        return _banner(
          key: const Key('overlay_no_history'),
          text: 'No observed data displayed; overlay unavailable',
          accent: widget.theme.onSurfaceMuted,
          borderOpacity: 0.24,
          fillOpacity: 0.08,
        );
    }

    // Gate is visible — the overlay toggle is on. Render the scenario banner.
    final projection = _controller.projection;
    if (projection == null) return const SizedBox.shrink();

    final bounds = [
      projection.lower,
      projection.central,
      projection.upper,
    ].whereType<double>().toList();
    final rangeText = bounds.isEmpty
        ? ''
        : ' (\$${bounds.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}'
            '–\$${bounds.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)})';

    return Column(
      key: const Key('overlay_badge'),
      children: [
        InkWell(
          key: const Key('overlay_badge_tap'),
          onTap: () => setState(
              () => _projectionDetailsOpen = !_projectionDetailsOpen),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.theme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: widget.theme.accent.withOpacity(0.3)),
            ),
            child: Text(
              'Conditional scenarios — not observed prices '
              '(target ${projection.targetSessionDate})$rangeText'
              '${_controller.snapshotMode ? ' [SNAPSHOT MODE]' : ''}',
              style: TextStyle(
                color: widget.theme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_projectionDetailsOpen)
          Container(
            key: const Key('overlay_details'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.theme.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.theme.accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailLine('Issued', projection.anchorTime),
                _detailLine('Target session', projection.targetSessionDate),
                _detailLine('Kind', projection.kind.wireValue),
                _detailLine(
                    'Method', '${projection.method} v${projection.methodVersion}'),
                _detailLine('Adjustment basis', projection.adjustmentBasis),
                _detailLine('Assumptions',
                    '${projection.assumptionIds.length} referenced'),
                if (projection.limitations.isNotEmpty)
                  _detailLine('Limitations', projection.limitations.join('; ')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: widget.theme.onSurfaceMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                key: Key('detail_${label.toLowerCase().replaceAll(' ', '_')}'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCostNotice() {
    switch (_controller.userCostGate) {
      case UserCostGateState.visible:
        return const SizedBox.shrink();
      case UserCostGateState.none:
        return _banner(
          key: const Key('user_cost_unknown'),
          text: 'User cost unknown — declared cost is never invented',
          accent: widget.theme.onSurfaceMuted,
          borderOpacity: 0.18,
          fillOpacity: 0.05,
        );
      case UserCostGateState.currencyMismatch:
        return _banner(
          key: const Key('user_cost_gate'),
          text: 'User cost not shown: currency differs from market data',
          accent: widget.theme.danger,
          borderOpacity: 0.4,
          fillOpacity: 0.12,
        );
      case UserCostGateState.basisMismatch:
        return _banner(
          key: const Key('user_cost_gate'),
          text: 'User cost not shown: price basis differs or could not be '
              'confirmed compatible with market data',
          accent: widget.theme.danger,
          borderOpacity: 0.4,
          fillOpacity: 0.12,
        );
      case UserCostGateState.noHistory:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStaleCacheNotice() {
    return _banner(
      key: const Key('chart_cache_stale'),
      text: 'Cached history is marked stale and cannot claim real-time '
          'delivery',
      accent: widget.theme.onSurfaceMuted,
      borderOpacity: 0.24,
      fillOpacity: 0.08,
    );
  }

  Widget _buildDelayNotice() {
    final delay = _controller.history!.delayStatus;
    return _banner(
      key: const Key('chart_delay_notice'),
      text: delay == DelayStatus.delayed
          ? 'Market data is delayed (not real-time)'
          : 'Market data delivery timing unknown (not real-time)',
      accent: widget.theme.onSurfaceMuted,
      borderOpacity: 0.18,
      fillOpacity: 0.05,
    );
  }

  Widget _buildWarningsNotice() {
    final codes = _controller.history!.warnings.map((w) => w.code).join(', ');
    return _banner(
      key: const Key('chart_warnings'),
      text: 'Data warnings: $codes',
      accent: widget.theme.onSurfaceMuted,
      borderOpacity: 0.18,
      fillOpacity: 0.05,
    );
  }

  Widget _banner({
    required Key key,
    required String text,
    required Color accent,
    required double borderOpacity,
    required double fillOpacity,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(fillOpacity),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(borderOpacity)),
      ),
      child: Text(text, style: TextStyle(color: accent, fontSize: 12)),
    );
  }

  // ---------------------------------------------------------- chart area

  Widget _buildChartArea() {
    switch (_controller.status) {
      case ChartLoadState.loading:
        return const Center(
          key: Key('chart_loading'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading observed market data…',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      case ChartLoadState.error:
        return Center(
          key: const Key('chart_status_error'),
          child: Text(
            'Market data could not be loaded. No substitute data is shown.',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.theme.danger, fontSize: 12),
          ),
        );
      case ChartLoadState.unavailable:
        return Center(
          key: const Key('chart_status_unavailable'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white38, size: 28),
              const SizedBox(height: 8),
              Text(
                _controller.unavailableReason ?? 'Market data unavailable',
                key: const Key('chart_unavailable_reason'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      case ChartLoadState.loaded:
        final bars = _controller.barsForDisplay;
        if (bars.isEmpty) {
          return const Center(
            key: Key('chart_empty_state'),
            child: Text('No observed bars in this range',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          );
        }
        return _buildChart(bars);
    }
  }

  List<double> get _displayBounds {
    final bars = _controller.barsForDisplay;
    if (bars.isEmpty) return const [];
    double minVal = bars.first.low;
    double maxVal = bars.first.high;
    for (final bar in bars) {
      if (bar.low < minVal) minVal = bar.low;
      if (bar.high > maxVal) maxVal = bar.high;
    }
    if (_controller.userCostValue != null) {
      final cost = _controller.userCostValue!;
      if (cost < minVal) minVal = cost;
      if (cost > maxVal) maxVal = cost;
    }
    if (_controller.projectionBoundsVisible) {
      final projection = _controller.projection!;
      for (final bound in [projection.lower, projection.central, projection.upper]) {
        if (bound != null && bound < minVal) minVal = bound;
        if (bound != null && bound > maxVal) maxVal = bound;
      }
    }
    return [minVal * 0.98, maxVal * 1.02];
  }

  Widget _buildChart(List<MarketBar> bars) {
    final bounds = _displayBounds;
    final minY = bounds.first;
    final maxY = bounds.last;

    return _controller.style == ChartStyle.line
        ? _buildLineChart(bars, minY, maxY)
        : _buildCandlestickChart(bars, minY, maxY);
  }

  FlTitlesData _buildTitlesData(List<MarketBar> bars) {
    final intraday =
        _controller.history?.actualResolution != '1d';
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text('\$${value.toStringAsFixed(0)}',
                style: TextStyle(
                    color: widget.theme.onSurfaceMuted, fontSize: 10)),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= bars.length) {
              return const SizedBox.shrink();
            }
            final bar = bars[index];
            // Labels come verbatim from typed bar identity — session_date
            // for daily bars, the UTC bucket time for intraday resolutions.
            final label = intraday
                ? bar.time.substring(11, 16)
                : bar.sessionDate.substring(5);
            return SideTitleWidget(
              meta: meta,
              child: Text(label,
                  style: TextStyle(
                      color: widget.theme.onSurfaceMuted, fontSize: 9)),
            );
          },
        ),
      ),
    );
  }

  ExtraLinesData _buildExtraLinesData() {
    final horizontalLines = <HorizontalLine>[];

    if (_controller.projectionBoundsVisible) {
      final projection = _controller.projection!;
      if (projection.upper != null) {
        horizontalLines.add(HorizontalLine(
          y: projection.upper!,
          color: widget.theme.accent.withOpacity(0.6),
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: TextStyle(
                color: widget.theme.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold),
            labelResolver: (_) =>
                'Scenario high \$${projection.upper!.toStringAsFixed(0)}',
          ),
        ));
      }
      if (projection.central != null) {
        horizontalLines.add(HorizontalLine(
          y: projection.central!,
          color: widget.theme.accent.withOpacity(0.9),
          strokeWidth: 1.5,
          dashArray: const [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: TextStyle(
                color: widget.theme.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold),
            labelResolver: (_) =>
                'Central \$${projection.central!.toStringAsFixed(0)}',
          ),
        ));
      }
      if (projection.lower != null) {
        horizontalLines.add(HorizontalLine(
          y: projection.lower!,
          color: widget.theme.accent.withOpacity(0.6),
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            style: TextStyle(
                color: widget.theme.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold),
            labelResolver: (_) =>
                'Scenario low \$${projection.lower!.toStringAsFixed(0)}',
          ),
        ));
      }
    }

    final cost = _controller.userCostValue;
    if (cost != null) {
      horizontalLines.add(HorizontalLine(
        y: cost,
        color: Colors.white70,
        strokeWidth: 1,
        dashArray: const [2, 3],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topLeft,
          style: TextStyle(
              color: widget.theme.onSurfaceMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600),
          labelResolver: (_) => 'User cost \$${cost.toStringAsFixed(2)}',
        ),
      ));
    }

    return ExtraLinesData(horizontalLines: horizontalLines);
  }

  RangeAnnotations _buildRangeAnnotations() {
    if (!_controller.projectionBoundsVisible) {
      return const RangeAnnotations();
    }
    final projection = _controller.projection!;
    if (projection.lower == null || projection.upper == null) {
      return const RangeAnnotations();
    }
    return RangeAnnotations(
      horizontalRangeAnnotations: [
        HorizontalRangeAnnotation(
          y1: projection.lower!,
          y2: projection.upper!,
          color: widget.theme.accent.withOpacity(0.06),
        ),
      ],
    );
  }

  FlGridData _gridData() => FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withOpacity(0.06),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: Colors.white.withOpacity(0.06),
          strokeWidth: 1,
        ),
      );

  Widget _buildLineChart(List<MarketBar> bars, double minY, double maxY) {
    final spots = bars
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.close))
        .toList();

    return LineChart(
      key: const Key('chart_line'),
      LineChartData(
        minX: _controller.minX,
        maxX: _controller.maxX,
        minY: minY,
        maxY: maxY,
        gridData: _gridData(),
        titlesData: _buildTitlesData(bars),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            final spots = response?.lineBarSpots;
            if (spots != null && spots.isNotEmpty) {
              _controller.selectBar(spots.first.spotIndex);
            }
          },
        ),
        extraLinesData: _buildExtraLinesData(),
        rangeAnnotations: _buildRangeAnnotations(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: widget.theme.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == _controller.selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 5.0 : 2.5,
                  color: isSelected ? Colors.white : widget.theme.accent,
                  strokeWidth: isSelected ? 2 : 1,
                  strokeColor: widget.theme.accent,
                );
              },
            ),
          ),
        ],
      ),
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.horizontal,
        minScale: ChartController.minScale,
        maxScale: ChartController.maxScale,
        panEnabled: true,
        scaleEnabled: true,
        transformationController: _controller.transformationController,
      ),
    );
  }

  Widget _buildCandlestickChart(
      List<MarketBar> bars, double minY, double maxY) {
    final spots = bars
        .asMap()
        .entries
        .map((entry) => CandlestickSpot(
              x: entry.key.toDouble(),
              open: entry.value.open,
              high: entry.value.high,
              low: entry.value.low,
              close: entry.value.close,
            ))
        .toList();

    return CandlestickChart(
      key: const Key('chart_candles'),
      CandlestickChartData(
        minX: _controller.minX,
        maxX: _controller.maxX,
        minY: minY,
        maxY: maxY,
        gridData: _gridData(),
        titlesData: _buildTitlesData(bars),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        candlestickSpots: spots,
        candlestickTouchData: CandlestickTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            final touched = response?.touchedSpot;
            if (touched != null) {
              _controller.selectBar(touched.spotIndex);
            }
          },
        ),
        rangeAnnotations: _buildRangeAnnotations(),
      ),
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.horizontal,
        minScale: ChartController.minScale,
        maxScale: ChartController.maxScale,
        panEnabled: true,
        scaleEnabled: true,
        transformationController: _controller.transformationController,
      ),
    );
  }

  // -------------------------------------------------------- volume strip

  /// Index-aligned volume context for the inspected bar. Deliberately not
  /// transform-synchronized (H02 review note): the strip shows the full
  /// range's volumes; the inspected bar is highlighted and its exact volume
  /// is in the readout. Null volume renders an explicit N/A marker, never 0.
  Widget _buildVolumeStrip() {
    final bars = _controller.barsForDisplay;
    if (bars.isEmpty) return const SizedBox.shrink();

    int maxVolume = 1;
    for (final bar in bars) {
      final volume = bar.volume;
      if (volume != null && volume > maxVolume) maxVolume = volume;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Text('Volume context — inspected bar highlighted',
              key: const Key('chart_volume_strip_label'),
              style: TextStyle(
                  color: widget.theme.onSurfaceSubtle, fontSize: 9)),
        ),
        Container(
          key: const Key('chart_volume_strip'),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.asMap().entries.map((entry) {
              final index = entry.key;
              final bar = entry.value;
              final isSelected = index == _controller.selectedIndex;
              final volume = bar.volume;
              final Widget fill;
              if (volume == null) {
                // Unavailable volume: explicit dashed placeholder, not zero.
                fill = Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? widget.theme.accent
                          : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              } else {
                final height =
                    ((volume / maxVolume) * 32).clamp(4.0, 32.0).toDouble();
                fill = Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.theme.accent
                        : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _controller.selectBar(index),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: fill,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------- readout panel

  Widget _buildReadoutPanel() {
    final bar = _controller.selectedBar;
    if (bar == null) {
      return Container(
        key: const Key('readout_empty'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.theme.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            _controller.status == ChartLoadState.loaded
                ? 'Tap a bar to inspect OHLCV'
                : 'No observed bar selected',
            style: TextStyle(
                color: widget.theme.onSurfaceMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      key: const Key('chart_readout_panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bar.time,
                  key: const Key('readout_time'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'monospace')),
              Text('Session: ${bar.sessionDate}',
                  key: const Key('readout_session_date'),
                  style: TextStyle(
                      color: widget.theme.onSurfaceMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _readoutItem('Open', bar.open, const Key('readout_open')),
              _readoutItem('High', bar.high, const Key('readout_high')),
              _readoutItem('Low', bar.low, const Key('readout_low')),
              _readoutItem('Close', bar.close, const Key('readout_close')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vol: ${bar.volume?.toString() ?? 'N/A'}',
                key: const Key('readout_volume'),
                style: TextStyle(
                  color: widget.theme.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Bar: ${(_controller.selectedIndex ?? 0) + 1} of '
                '${_controller.barsForDisplay.length} '
                '(${_controller.history?.actualResolution ?? ''})',
                style: TextStyle(
                    color: widget.theme.onSurfaceSubtle, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readoutItem(String label, double value, Key key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: widget.theme.onSurfaceMuted, fontSize: 10)),
        Text('\$${value.toStringAsFixed(2)}',
            key: key,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'monospace')),
      ],
    );
  }

  Widget _touchable({
    required Key key,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool isSelected = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.theme.accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? widget.theme.accent
                      : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 16,
                        color: isSelected
                            ? widget.theme.accent
                            : widget.theme.onSurfaceMuted),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? widget.theme.accent
                          : widget.theme.onSurfaceMuted,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
