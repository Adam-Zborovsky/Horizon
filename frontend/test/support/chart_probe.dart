import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Observed market bar conforming to Contract v1 section 3.
class ProbeMarketBar {
  final String time;
  final String sessionDate;
  final double open;
  final double high;
  final double low;
  final double close;
  final int? volume;
  final double? adjustedClose;
  final bool isFinal;

  const ProbeMarketBar({
    required this.time,
    required this.sessionDate,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
    this.adjustedClose,
    this.isFinal = true,
  });

  factory ProbeMarketBar.fromJson(Map<String, dynamic> json) {
    return ProbeMarketBar(
      time: json['time'] as String,
      sessionDate: json['session_date'] as String,
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: json['volume'] != null ? (json['volume'] as num).toInt() : null,
      adjustedClose: json['adjusted_close'] != null
          ? (json['adjusted_close'] as num).toDouble()
          : null,
      isFinal: json['is_final'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'session_date': sessionDate,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
        'adjusted_close': adjustedClose,
        'is_final': isFinal,
      };
}

/// Scenario projection conforming to Contract v1 section 7.
class ProbeNumericProjection {
  final String id;
  final String assessmentId;
  final String instrumentId;
  final String anchorTime;
  final String targetSessionDate;
  final String kind;
  final double? lower;
  final double? central;
  final double? upper;
  final String currency;
  final String validUntil;
  final List<String> limitations;
  final bool isStale;

  const ProbeNumericProjection({
    required this.id,
    required this.assessmentId,
    required this.instrumentId,
    required this.anchorTime,
    required this.targetSessionDate,
    required this.kind,
    this.lower,
    this.central,
    this.upper,
    this.currency = 'USD',
    required this.validUntil,
    this.limitations = const [],
    this.isStale = false,
  });

  factory ProbeNumericProjection.fromJson(Map<String, dynamic> json) {
    return ProbeNumericProjection(
      id: json['id'] as String,
      assessmentId: json['assessment_id'] as String,
      instrumentId: json['instrument_id'] as String,
      anchorTime: json['anchor_time'] as String,
      targetSessionDate: json['target_session_date'] as String,
      kind: json['kind'] as String,
      lower: json['lower'] != null ? (json['lower'] as num).toDouble() : null,
      central:
          json['central'] != null ? (json['central'] as num).toDouble() : null,
      upper: json['upper'] != null ? (json['upper'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'USD',
      validUntil: json['valid_until'] as String,
      limitations: (json['limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isStale: json['is_stale'] as bool? ?? false,
    );
  }
}

/// Display style for price data.
enum ChartStyle { line, candles }

/// Contract-defined UI ranges.
enum ChartRange {
  r1D('1D', '5m'),
  r1W('1W', '30m'),
  r1M('1M', '1d'),
  r3M('3M', '1d'),
  r6M('6M', '1d'),
  r1Y('1Y', '1d');

  final String label;
  final String preferredResolution;
  const ChartRange(this.label, this.preferredResolution);
}

/// Offline observed fixture data matching backend/test/fixtures/research/observed-bars.json.
final List<ProbeMarketBar> kFixtureObservedDailyBars = const [
  ProbeMarketBar(
    time: '2024-01-02T14:30:00.000Z',
    sessionDate: '2024-01-02',
    open: 162.8300018310547,
    high: 163.2899932861328,
    low: 160.4600067138672,
    close: 161.5,
    volume: 3825000,
    adjustedClose: null,
    isFinal: true,
  ),
  const ProbeMarketBar(
    time: '2024-01-03T14:30:00.000Z',
    sessionDate: '2024-01-03',
    open: 161.0,
    high: 161.72999572753906,
    low: 160.0800018310547,
    close: 160.10000610351562,
    volume: 4086100,
    adjustedClose: null,
    isFinal: true,
  ),
  const ProbeMarketBar(
    time: '2024-01-04T14:30:00.000Z',
    sessionDate: '2024-01-04',
    open: 160.22000122070312,
    high: 161.80999755859375,
    low: 160.1699981689453,
    close: 160.86000061035156,
    volume: 3212000,
    adjustedClose: null,
    isFinal: true,
  ),
  const ProbeMarketBar(
    time: '2024-01-05T14:30:00.000Z',
    sessionDate: '2024-01-05',
    open: 159.91000366210938,
    high: 160.5500030517578,
    low: 158.6699981689453,
    close: 159.16000366210938,
    volume: 4199400,
    adjustedClose: null,
    isFinal: true,
  ),
]);

/// Synthetic intraday 5m values for 1D range layout testing — NOT observed market data.
/// Provenance note: These 5 bars (2024-01-05 14:30 - 14:50) are explicit synthetic test
/// values constructed for UI/layout and range-switch validation. No real market recording
/// or external provider backs these intraday values.
final List<ProbeMarketBar> kFixtureSyntheticIntradayBars = [
  const ProbeMarketBar(
    time: '2024-01-05T14:30:00.000Z',
    sessionDate: '2024-01-05',
    open: 159.91,
    high: 160.10,
    low: 159.70,
    close: 159.85,
    volume: 250000,
  ),
  const ProbeMarketBar(
    time: '2024-01-05T14:35:00.000Z',
    sessionDate: '2024-01-05',
    open: 159.85,
    high: 160.30,
    low: 159.80,
    close: 160.20,
    volume: 310000,
  ),
  const ProbeMarketBar(
    time: '2024-01-05T14:40:00.000Z',
    sessionDate: '2024-01-05',
    open: 160.20,
    high: 160.55,
    low: 160.05,
    close: 160.40,
    volume: 280000,
  ),
  const ProbeMarketBar(
    time: '2024-01-05T14:45:00.000Z',
    sessionDate: '2024-01-05',
    open: 160.40,
    high: 160.50,
    low: 158.90,
    close: 159.00,
    volume: 520000,
  ),
  const ProbeMarketBar(
    time: '2024-01-05T14:50:00.000Z',
    sessionDate: '2024-01-05',
    open: 159.00,
    high: 159.35,
    low: 158.67,
    close: 159.16,
    volume: 490000,
  ),
];

/// Sample projection matching backend/test/fixtures/research/contract-cases.json.
const ProbeNumericProjection kFixtureScenarioProjection =
    ProbeNumericProjection(
  id: 'projection-1',
  assessmentId: 'assessment-1',
  instrumentId: 'instrument-ibm-xnys-usd',
  anchorTime: '2024-01-05T21:00:00.000Z',
  targetSessionDate: '2024-02-05',
  kind: 'conditional_scenario',
  lower: 150.0,
  central: 160.0,
  upper: 170.0,
  currency: 'USD',
  validUntil: '2024-02-05T21:00:00.000Z',
  limitations: ['Synthetic test output.'],
  isStale: false,
);

/// Interactive test-only chart probe exercising fl_chart: 1.1.1 capabilities.
class ChartCapabilityProbe extends StatefulWidget {
  final List<ProbeMarketBar>? initialBars;
  final ProbeNumericProjection? initialProjection;
  final ChartStyle initialStyle;
  final ChartRange initialRange;
  final bool initialShowOverlay;
  final bool initialSnapshotMode;
  final void Function(ProbeMarketBar? bar, int? index)? onSelectionChanged;
  final void Function(ChartStyle style)? onStyleChanged;
  final void Function(ChartRange range)? onRangeChanged;

  const ChartCapabilityProbe({
    super.key,
    this.initialBars,
    this.initialProjection,
    this.initialStyle = ChartStyle.line,
    this.initialRange = ChartRange.r1M,
    this.initialShowOverlay = false,
    this.initialSnapshotMode = false,
    this.onSelectionChanged,
    this.onStyleChanged,
    this.onRangeChanged,
  });

  @override
  State<ChartCapabilityProbe> createState() => ChartCapabilityProbeState();
}

class ChartCapabilityProbeState extends State<ChartCapabilityProbe> {
  late ChartStyle _currentStyle;
  late ChartRange _currentRange;
  late bool _showOverlay;
  late bool _isSnapshotMode;
  late TransformationController _transformationController;

  ProbeMarketBar? _selectedBar;
  int? _selectedIndex;
  double _currentZoom = 1.0;

  ProbeNumericProjection? _projection;
  Map<ChartRange, List<ProbeMarketBar>> _rangeData = {};

  @override
  void initState() {
    super.initState();
    _currentStyle = widget.initialStyle;
    _currentRange = widget.initialRange;
    _showOverlay = widget.initialShowOverlay;
    _isSnapshotMode = widget.initialSnapshotMode;
    _projection = widget.initialProjection ?? kFixtureScenarioProjection;

    _rangeData = {
      ChartRange.r1D: kFixtureSyntheticIntradayBars,
      ChartRange.r1W: kFixtureObservedDailyBars,
      ChartRange.r1M: widget.initialBars ?? kFixtureObservedDailyBars,
      ChartRange.r3M: widget.initialBars ?? kFixtureObservedDailyBars,
      ChartRange.r6M: widget.initialBars ?? kFixtureObservedDailyBars,
      ChartRange.r1Y: widget.initialBars ?? kFixtureObservedDailyBars,
    };

    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    // Initial default selection if bars available
    final bars = activeBars;
    if (bars.isNotEmpty) {
      _selectedIndex = bars.length - 1;
      _selectedBar = bars.last;
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    setState(() {
      _currentZoom = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  List<ProbeMarketBar> get activeBars =>
      _rangeData[_currentRange] ?? kFixtureObservedDailyBars;

  ChartStyle get currentStyle => _currentStyle;
  ChartRange get currentRange => _currentRange;
  ProbeMarketBar? get selectedBar => _selectedBar;
  int? get selectedIndex => _selectedIndex;
  double get currentZoom => _currentZoom;
  bool get showOverlay => _showOverlay;
  bool get isSnapshotMode => _isSnapshotMode;
  TransformationController get transformationController =>
      _transformationController;

  void selectBar(int index) {
    final bars = activeBars;
    if (index >= 0 && index < bars.length) {
      setState(() {
        _selectedIndex = index;
        _selectedBar = bars[index];
      });
      widget.onSelectionChanged?.call(_selectedBar, _selectedIndex);
    }
  }

  void stepPrev() {
    if (_selectedIndex != null && _selectedIndex! > 0) {
      selectBar(_selectedIndex! - 1);
    }
  }

  void stepNext() {
    final bars = activeBars;
    if (_selectedIndex != null && _selectedIndex! < bars.length - 1) {
      selectBar(_selectedIndex! + 1);
    }
  }

  void toggleStyle(ChartStyle style) {
    if (_currentStyle != style) {
      setState(() {
        _currentStyle = style;
      });
      widget.onStyleChanged?.call(_currentStyle);
    }
  }

  void selectRange(ChartRange range) {
    if (_currentRange != range) {
      setState(() {
        _currentRange = range;
        final bars = activeBars;
        if (_selectedIndex != null && _selectedIndex! >= bars.length) {
          _selectedIndex = bars.isNotEmpty ? bars.length - 1 : null;
          _selectedBar = _selectedIndex != null ? bars[_selectedIndex!] : null;
        } else if (_selectedIndex != null && bars.isNotEmpty) {
          _selectedBar = bars[_selectedIndex!];
        }
      });
      widget.onRangeChanged?.call(_currentRange);
    }
  }

  void toggleOverlay(bool value) {
    setState(() {
      _showOverlay = value;
    });
  }

  void enterSnapshotMode() {
    setState(() {
      _isSnapshotMode = true;
    });
  }

  void resetView() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentZoom = 1.0;
    });
  }

  void setProjection(ProbeNumericProjection? proj) {
    setState(() {
      _projection = proj;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bars = activeBars;

    return Container(
      color: const Color(0xFF0C0C0C), // Obsidian
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Style Toggles
          _buildHeader(),
          const SizedBox(height: 8),

          // Range Selector Controls
          _buildRangeSelector(),
          const SizedBox(height: 8),

          // Pan / Zoom Controls & Status
          _buildInteractionBar(),
          const SizedBox(height: 8),

          // Scenario Overlay Notice / Banner
          if (_showOverlay) _buildOverlayBanner(),

          // Chart Display Area
          Expanded(
            child: bars.isEmpty
                ? const Center(
                    child: Text(
                      'No market data available',
                      key: Key('chart_empty_state'),
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : _currentStyle == ChartStyle.line
                    ? _buildLineChart(bars)
                    : _buildCandlestickChart(bars),
          ),
          const SizedBox(height: 8),

          // Volume Context Strip
          _buildVolumeStrip(bars),
          const SizedBox(height: 8),

          // Exact Readout Panel
          _buildReadoutPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'HORIZON CHART PROBE',
          key: Key('probe_title'),
          style: TextStyle(
            color: Color(0xFFFFB800), // Gold Amber
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Row(
          children: [
            _buildTouchableButton(
              key: const Key('probe_toggle_line'),
              label: 'Line',
              isSelected: _currentStyle == ChartStyle.line,
              onTap: () => toggleStyle(ChartStyle.line),
            ),
            const SizedBox(width: 6),
            _buildTouchableButton(
              key: const Key('probe_toggle_candles'),
              label: 'Candles',
              isSelected: _currentStyle == ChartStyle.candles,
              onTap: () => toggleStyle(ChartStyle.candles),
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
        children: ChartRange.values.map((range) {
          final isSelected = _currentRange == range;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildTouchableButton(
              key: Key('probe_range_${range.label}'),
              label: range.label,
              isSelected: isSelected,
              onTap: () => selectRange(range),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        _buildTouchableButton(
          key: const Key('probe_btn_reset'),
          label: 'Reset View',
          icon: Icons.refresh,
          onTap: resetView,
        ),
        const SizedBox(width: 8),
        _buildTouchableButton(
          key: const Key('probe_btn_prev'),
          label: 'Prev',
          icon: Icons.chevron_left,
          onTap: stepPrev,
        ),
        const SizedBox(width: 6),
        _buildTouchableButton(
          key: const Key('probe_btn_next'),
          label: 'Next',
          icon: Icons.chevron_right,
          onTap: stepNext,
        ),
        const Spacer(),
        // Scenario Overlay Toggle
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Overlay',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Switch(
                key: const Key('probe_toggle_overlay'),
                value: _showOverlay,
                activeColor: const Color(0xFFFFB800),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onChanged: toggleOverlay,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_currentZoom.toStringAsFixed(2)}x',
          key: const Key('probe_zoom_readout'),
          style: const TextStyle(
            color: Color(0xFFFFB800),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayBanner() {
    if (_projection == null) {
      return Container(
        key: const Key('overlay_no_projection'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text(
          'No quantified projection for this assessment',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    if (_projection!.isStale && !_isSnapshotMode) {
      return Container(
        key: const Key('overlay_stale_notice'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4B5C).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF4B5C).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Projection is stale for live market view',
                style: TextStyle(color: Color(0xFFFF4B5C), fontSize: 12),
              ),
            ),
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
          ],
        ),
      );
    }

    // Active scenario overlay notice
    return Container(
      key: const Key('overlay_badge'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
      ),
      child: Text(
        'Conditional scenarios — not observed prices (Target: ${_projection!.targetSessionDate}, '
        'Range: \$${_projection!.lower?.toStringAsFixed(0)} - \$${_projection!.upper?.toStringAsFixed(0)})'
        '${_isSnapshotMode ? ' [SNAPSHOT MODE]' : ''}',
        style: const TextStyle(
          color: Color(0xFFFFB800),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLineChart(List<ProbeMarketBar> bars) {
    final spots = bars
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.close))
        .toList();

    final minY = _calculateMinY(bars);
    final maxY = _calculateMaxY(bars);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (bars.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: _buildTitlesData(bars),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              selectBar(response.lineBarSpots!.first.spotIndex);
            }
          },
        ),
        extraLinesData: _buildExtraLinesData(),
        rangeAnnotations: _buildRangeAnnotations(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Straight segments per Spec section 3
            color: const Color(0xFFFFB800),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == _selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 5.0 : 2.5,
                  color: isSelected ? Colors.white : const Color(0xFFFFB800),
                  strokeWidth: isSelected ? 2 : 1,
                  strokeColor: const Color(0xFFFFB800),
                );
              },
            ),
          ),
        ],
      ),
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.horizontal,
        minScale: 1.0,
        maxScale: 10.0,
        panEnabled: true,
        scaleEnabled: true,
        transformationController: _transformationController,
      ),
    );
  }

  Widget _buildCandlestickChart(List<ProbeMarketBar> bars) {
    final spots = bars
        .asMap()
        .entries
        .map((e) => CandlestickSpot(
              x: e.key.toDouble(),
              open: e.value.open,
              high: e.value.high,
              low: e.value.low,
              close: e.value.close,
            ))
        .toList();

    final minY = _calculateMinY(bars);
    final maxY = _calculateMaxY(bars);

    return CandlestickChart(
      CandlestickChartData(
        minX: 0,
        maxX: (bars.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
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
            if (response?.touchedSpot != null) {
              selectBar(response!.touchedSpot!.spotIndex);
            }
          },
        ),
        extraLinesData: _buildExtraLinesData(),
        rangeAnnotations: _buildRangeAnnotations(),
      ),
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.horizontal,
        minScale: 1.0,
        maxScale: 10.0,
        panEnabled: true,
        scaleEnabled: true,
        transformationController: _transformationController,
      ),
    );
  }

  double _calculateMinY(List<ProbeMarketBar> bars) {
    if (bars.isEmpty) return 0.0;
    double minVal = bars.first.low;
    for (final b in bars) {
      if (b.low < minVal) minVal = b.low;
    }
    if (_showOverlay && _projection != null && _shouldShowScenarioLines) {
      if (_projection!.lower != null && _projection!.lower! < minVal) {
        minVal = _projection!.lower!;
      }
    }
    return (minVal * 0.98).floorToDouble();
  }

  double _calculateMaxY(List<ProbeMarketBar> bars) {
    if (bars.isEmpty) return 100.0;
    double maxVal = bars.first.high;
    for (final b in bars) {
      if (b.high > maxVal) maxVal = b.high;
    }
    if (_showOverlay && _projection != null && _shouldShowScenarioLines) {
      if (_projection!.upper != null && _projection!.upper! > maxVal) {
        maxVal = _projection!.upper!;
      }
    }
    return (maxVal * 1.02).ceilToDouble();
  }

  bool get _shouldShowScenarioLines =>
      _showOverlay &&
      _projection != null &&
      (!_projection!.isStale || _isSnapshotMode);

  ExtraLinesData _buildExtraLinesData() {
    if (!_shouldShowScenarioLines) {
      return const ExtraLinesData();
    }

    final hLines = <HorizontalLine>[];
    if (_projection!.upper != null) {
      hLines.add(HorizontalLine(
        y: _projection!.upper!,
        color: const Color(0xFFFFB800).withOpacity(0.6),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: const TextStyle(
            color: Color(0xFFFFB800),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          labelResolver: (_) =>
              'Scenario High: \$${_projection!.upper!.toStringAsFixed(0)}',
        ),
      ));
    }
    if (_projection!.central != null) {
      hLines.add(HorizontalLine(
        y: _projection!.central!,
        color: const Color(0xFFFFB800).withOpacity(0.9),
        strokeWidth: 1.5,
        dashArray: [4, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: const TextStyle(
            color: Color(0xFFFFB800),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          labelResolver: (_) =>
              'Target Central: \$${_projection!.central!.toStringAsFixed(0)}',
        ),
      ));
    }
    if (_projection!.lower != null) {
      hLines.add(HorizontalLine(
        y: _projection!.lower!,
        color: const Color(0xFFFFB800).withOpacity(0.6),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.bottomRight,
          style: const TextStyle(
            color: Color(0xFFFFB800),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          labelResolver: (_) =>
              'Scenario Low: \$${_projection!.lower!.toStringAsFixed(0)}',
        ),
      ));
    }

    return ExtraLinesData(horizontalLines: hLines);
  }

  RangeAnnotations _buildRangeAnnotations() {
    if (!_shouldShowScenarioLines ||
        _projection!.lower == null ||
        _projection!.upper == null) {
      return const RangeAnnotations();
    }

    return RangeAnnotations(
      horizontalRangeAnnotations: [
        HorizontalRangeAnnotation(
          y1: _projection!.lower!,
          y2: _projection!.upper!,
          color: const Color(0xFFFFB800).withOpacity(0.06),
        ),
      ],
    );
  }

  FlTitlesData _buildTitlesData(List<ProbeMarketBar> bars) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              meta: meta,
              child: Text(
                '\$${value.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx >= 0 && idx < bars.length) {
              final label = bars[idx].sessionDate.substring(5); // MM-DD
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildVolumeStrip(List<ProbeMarketBar> bars) {
    if (bars.isEmpty) return const SizedBox.shrink();

    int maxVolume = 1;
    for (final b in bars) {
      if (b.volume != null && b.volume! > maxVolume) {
        maxVolume = b.volume!;
      }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.asMap().entries.map((e) {
          final idx = e.key;
          final bar = e.value;
          final isSelected = idx == _selectedIndex;
          final vol = bar.volume ?? 0;
          final fraction = vol / maxVolume;
          final height = (fraction * 32).clamp(4.0, 32.0);

          return Expanded(
            child: GestureDetector(
              onTap: () => selectBar(idx),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFB800)
                        : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReadoutPanel() {
    if (_selectedBar == null) {
      return Container(
        key: const Key('readout_empty'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text(
            'Tap bar to inspect OHLCV',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    final bar = _selectedBar!;
    return Container(
      key: const Key('probe_readout_panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bar.time,
                key: const Key('readout_time'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Session: ${bar.sessionDate}',
                key: const Key('readout_session_date'),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReadoutItem('Open', bar.open, const Key('readout_open')),
              _buildReadoutItem('High', bar.high, const Key('readout_high')),
              _buildReadoutItem('Low', bar.low, const Key('readout_low')),
              _buildReadoutItem('Close', bar.close, const Key('readout_close')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vol: ${bar.volume != null ? bar.volume.toString() : 'N/A'}',
                key: const Key('readout_volume'),
                style: const TextStyle(
                  color: Color(0xFFFFB800),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Bar: ${(_selectedIndex ?? 0) + 1} of ${activeBars.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutItem(String label, double value, Key key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          key: key,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTouchableButton({
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
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFB800).withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFB800)
                      : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFFFFB800)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFFB800)
                          : Colors.white70,
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
