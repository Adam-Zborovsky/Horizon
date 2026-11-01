// H13 — interactive observed-data chart controller.
//
// Owns the state machine for the PriceChart widget: six contract ranges,
// line/candle styles, bar selection, pan/zoom/reset, projection overlay and
// user-cost gates. Consumes H11's typed domain models (HistoryResponse,
// MarketBar, NumericProjection) and never manufactures market data: every
// rendered value originates from a HistoryResponse produced by the typed
// repository. Observed data and conditional scenarios remain separate.
//
// Stale-response cancellation: each range load is stamped with a monotonic
// request token; responses from superseded requests are discarded, never
// rendered. Freshness/basis gates implement CONTRACTS §7: overlays default
// off, stale overlays default hidden with a snapshot action, projections are
// never rendered across an incompatible price basis, and the user-cost line
// renders only for matching currency and compatible corporate-action basis.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../market/market_models.dart';
import '../../positions/position_models.dart';
import '../../research/research_models.dart';

/// Display style for observed prices.
enum ChartStyle { line, candles }

/// Load lifecycle of the currently displayed range.
enum ChartLoadState {
  /// No response accepted yet for the active range (first-load gap).
  loading,

  /// A HistoryResponse with at least one observed bar is displayed.
  loaded,

  /// The feed responded `unavailable`: empty bars, machine-readable reason.
  unavailable,

  /// The request failed (network/auth/parsing). No synthetic fallback.
  error,
}

/// Why the projection overlay is currently not drawn.
enum ProjectionGateState {
  /// Overlay enabled, gate passed, overlay drawn.
  visible,

  /// Overlay toggle is off (contract default).
  toggleOff,

  /// No projection exists for this assessment (numeric_projection == null).
  none,

  /// Projection exists but is stale relative to displayed market data
  /// (market advanced beyond the assessment cutoff or validity elapsed).
  stale,

  /// Projection currency or corporate-action basis is incompatible with the
  /// displayed history. Never render across an incompatible basis.
  basisMismatch,

  /// No history displayed yet, so overlay placement is undefined.
  noHistory,
}

/// Why the user-cost line is currently not drawn.
enum UserCostGateState {
  /// Gate passed: matching currency and compatible basis; line drawn.
  visible,

  /// No user cost declared (candidate position or unknown cost).
  none,

  /// Cost currency differs from the instrument currency.
  currencyMismatch,

  /// Cost basis is not compatible with the displayed price basis.
  basisMismatch,

  /// No history displayed yet, so the reference cannot be placed.
  noHistory,
}

/// Type of loader injected by the host. Resolves against the authenticated
/// H11 MarketRepository in production; tests inject futures directly.
typedef ChartHistoryLoader = Future<HistoryResponse> Function(
  MarketRange range,
);

/// Classification of a price-adjustment basis string for cross-overlay
/// compatibility. The contract requires compatible corporate-action basis;
/// classing is deliberately conservative: unknown wording never counts as
/// compatible, so an unclassifiable basis suppresses overlays (safe
/// direction — a suppressed truthful overlay is recoverable, a mixed-basis
/// overlay is misleading).
enum PriceBasisClass { raw, adjusted, unknown }

PriceBasisClass classifyPriceBasis(String basis) {
  final normalized = basis.toLowerCase();
  final mentionsSplitOrDividend =
      normalized.contains('split') || normalized.contains('dividend');
  final explicitlyUnadjusted =
      normalized.contains('raw') || normalized.contains('unadjusted');
  if (explicitlyUnadjusted && !mentionsSplitOrDividend) {
    return PriceBasisClass.raw;
  }
  if (mentionsSplitOrDividend && !explicitlyUnadjusted) {
    return PriceBasisClass.adjusted;
  }
  if (explicitlyUnadjusted && mentionsSplitOrDividend) {
    // e.g. "split-adjusted" together with "raw" is contradictory; do not
    // guess.
    return PriceBasisClass.unknown;
  }
  return PriceBasisClass.unknown;
}

bool isCompatiblePriceBasis(String a, String b) {
  final classA = classifyPriceBasis(a);
  final classB = classifyPriceBasis(b);
  if (classA == PriceBasisClass.unknown || classB == PriceBasisClass.unknown) {
    return false;
  }
  return classA == classB;
}

/// Controller state for the interactive chart. ChangeNotifier; the widget
/// listens and rebuilds. All state mutations end in [notifyListeners].
class ChartController extends ChangeNotifier {
  ChartController({
    required ChartHistoryLoader loadHistory,
    MarketRange initialRange = MarketRange.oneMonth,
    ChartStyle initialStyle = ChartStyle.line,
  })  : _loadHistory = loadHistory,
        _range = initialRange,
        _style = initialStyle {
    _load(_range);
  }

  final ChartHistoryLoader _loadHistory;

  MarketRange _range;
  ChartStyle _style;
  ChartLoadState _status = ChartLoadState.loading;
  HistoryResponse? _history;
  String? _errorMessage;
  int? _selectedIndex;
  bool _overlayEnabled = false; // CONTRACTS §7: overlay defaults off.
  bool _snapshotMode = false;
  NumericProjection? _projection;
  MoneyAmount? _userCost;
  double _zoom = 1.0;

  final TransformationController transformationController =
      TransformationController();
  int _requestSeq = 0;

  static const double minScale = 1.0;
  static const double maxScale = 10.0;

  // ---------------------------------------------------------------- state

  MarketRange get range => _range;
  ChartStyle get style => _style;
  ChartLoadState get status => _status;
  HistoryResponse? get history => _history;
  String? get errorMessage => _errorMessage;
  int? get selectedIndex => _selectedIndex;
  MarketBar? get selectedBar {
    final bars = barsForDisplay;
    if (_selectedIndex == null || _selectedIndex! >= bars.length) return null;
    return bars[_selectedIndex!];
  }

  bool get overlayEnabled => _overlayEnabled;
  bool get snapshotMode => _snapshotMode;
  NumericProjection? get projection => _projection;
  MoneyAmount? get userCost => _userCost;
  double get zoom => _zoom;

  /// Bars currently displayed. Only bars parsed from the accepted
  /// HistoryResponse are ever returned; there is no filler path.
  List<MarketBar> get barsForDisplay {
    final response = _history;
    if (response == null || response.dataStatus == DataStatus.unavailable) {
      return const [];
    }
    return response.bars;
  }

  /// Shared X mapping: index-based for both line and candle styles, so a bar
  /// index renders at the same X position in either style (X-axis
  /// equivalence is structural, asserted by tests).
  double get minX => 0;
  double get maxX => barsForDisplay.isEmpty ? 0 : (barsForDisplay.length - 1).toDouble();

  /// Machine-readable reason text for the unavailable state (CONTRACTS §3).
  String? get unavailableReason {
    final response = _history;
    if (response == null || response.dataStatus != DataStatus.unavailable) {
      return null;
    }
    return response.unavailableReason;
  }

  // -------------------------------------------------------- overlay gates

  /// Effective projection gate for the current state.
  ProjectionGateState get projectionGate {
    if (!_overlayEnabled) return ProjectionGateState.toggleOff;
    if (_projection == null) return ProjectionGateState.none;
    final response = _history;
    if (response == null || response.dataStatus == DataStatus.unavailable) {
      return ProjectionGateState.noHistory;
    }
    if (_projection!.currency != response.instrument.currency) {
      return ProjectionGateState.basisMismatch;
    }
    if (!isCompatiblePriceBasis(
        _projection!.adjustmentBasis, response.adjustmentBasis)) {
      return ProjectionGateState.basisMismatch;
    }
    if (!snapshotMode && _isProjectionStale(response)) {
      return ProjectionGateState.stale;
    }
    return ProjectionGateState.visible;
  }

  /// Staleness per CONTRACTS §7: displayed market data has advanced beyond
  /// the assessment cutoff (projection anchor), or the projection validity
  /// elapsed relative to the displayed data's fetch time. Never derived from
  /// prose; only from typed timestamps.
  bool _isProjectionStale(HistoryResponse response) {
    final projection = _projection!;
    final lastBarTime =
        response.bars.isEmpty ? null : response.bars.last.time;
    final displayedTime = lastBarTime ?? response.asOf;
    if (displayedTime != null &&
        displayedTime.compareTo(projection.anchorTime) > 0) {
      return true;
    }
    final validUntil = projection.validUntil;
    if (validUntil != null && response.fetchedAt.compareTo(validUntil) > 0) {
      return true;
    }
    return false;
  }

  bool get projectionBoundsVisible =>
      projectionGate == ProjectionGateState.visible;

  /// Effective user-cost gate for the current state.
  UserCostGateState get userCostGate {
    final response = _history;
    if (response == null || response.dataStatus == DataStatus.unavailable) {
      // Only gate on basis/currency once something is displayed; absent
      // history still reports missing cost first.
      if (_userCost == null) return UserCostGateState.none;
      return UserCostGateState.noHistory;
    }
    final cost = _userCost;
    if (cost == null) return UserCostGateState.none;
    if (cost.currency != response.instrument.currency) {
      return UserCostGateState.currencyMismatch;
    }
    if (!isCompatiblePriceBasis(response.adjustmentBasis,
        _costBasisHint(response))) {
      return UserCostGateState.basisMismatch;
    }
    return UserCostGateState.visible;
  }

  /// The position model carries no corporate-action basis of its own; the
  /// compatible-basis comparison therefore uses the displayed history's basis
  /// against itself, which always passes, UNLESS the host supplies an
  /// explicit basis via [setUserCostBasis]. The conservative default is that
  /// an unknown cost basis is NOT compatible.
  String _costBasisHint(HistoryResponse response) => _userCostBasis ?? '';

  String? _userCostBasis;

  /// Optional explicit corporate-action basis of the stored average cost.
  /// Hosts that know the basis (e.g. from position metadata) pass it here;
  /// unknown/null means the gate cannot confirm compatibility and the line
  /// is suppressed.
  void setUserCostBasis(String? basis) {
    _userCostBasis = (basis == null || basis.isEmpty) ? null : basis;
    notifyListeners();
  }

  /// Decimal value of the user cost, or null when not renderable.
  double? get userCostValue {
    final gate = userCostGate;
    if (gate != UserCostGateState.visible) return null;
    return double.tryParse(_userCost!.amount);
  }

  // -------------------------------------------------------------- actions

  /// Loads the initial range. Called from the constructor; failures surface
  /// through [status] rather than construction.

  /// Selects a contract range. Cached responses render immediately while a
  /// fresh load runs; only the newest response is ever accepted.
  Future<void> selectRange(MarketRange range) async {
    if (range == _range) return;
    _range = range;
    final cached = _cache[range];
    if (cached != null) {
      _history = cached;
      _status = cached.dataStatus == DataStatus.unavailable
          ? ChartLoadState.unavailable
          : ChartLoadState.loaded;
      _errorMessage = null;
      _clampSelection();
    } else {
      _history = null;
      _status = ChartLoadState.loading;
      _selectedIndex = null;
    }
    notifyListeners();
    await _load(range);
  }

  final Map<MarketRange, HistoryResponse> _cache = {};

  Future<void> _load(MarketRange range) async {
    final token = ++_requestSeq;
    try {
      final response = await _loadHistory(range);
      if (token != _requestSeq || range != _range) return; // superseded
      _cache[range] = response;
      _history = response;
      _errorMessage = null;
      _status = response.dataStatus == DataStatus.unavailable
          ? ChartLoadState.unavailable
          : ChartLoadState.loaded;
      _clampSelection();
      notifyListeners();
    } catch (error) {
      if (token != _requestSeq || range != _range) return; // superseded
      _status = ChartLoadState.error;
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _clampSelection() {
    final bars = barsForDisplay;
    if (bars.isEmpty) {
      _selectedIndex = null;
      return;
    }
    final index = _selectedIndex;
    if (index == null || index >= bars.length) {
      _selectedIndex = bars.length - 1;
    }
  }

  /// Switches line/candle display. Style changes never touch loaded data,
  /// the selected range, or the selection index (acceptance: fixture values,
  /// timestamps and selected range survive style changes).
  void selectStyle(ChartStyle style) {
    if (style == _style) return;
    _style = style;
    notifyListeners();
  }

  void selectBar(int index) {
    final bars = barsForDisplay;
    if (index < 0 || index >= bars.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void stepPrev() {
    final index = _selectedIndex;
    if (index != null && index > 0) selectBar(index - 1);
  }

  void stepNext() {
    final index = _selectedIndex;
    if (index != null && index < barsForDisplay.length - 1) {
      selectBar(index + 1);
    }
  }

  void setOverlayEnabled(bool enabled) {
    if (enabled == _overlayEnabled) return;
    _overlayEnabled = enabled;
    notifyListeners();
  }

  /// Snapshot action from the stale notice: pins the view to the immutable
  /// assessment evidence. The host re-loads history through the snapshot
  /// loader (snapshotId from the accepted response/projection context) and
  /// then calls [exitSnapshotMode] to return to the live view.
  void enterSnapshotMode() {
    if (_snapshotMode) return;
    _snapshotMode = true;
    notifyListeners();
  }

  void exitSnapshotMode() {
    if (!_snapshotMode) return;
    _snapshotMode = false;
    notifyListeners();
  }

  /// Supplies the assessment's typed projection (null: none exists — a
  /// qualitative outlook is valid without a numeric projection).
  void setProjection(NumericProjection? projection) {
    _projection = projection;
    notifyListeners();
  }

  /// Supplies the position's average cost when known (CONTRACTS §2: owned
  /// records may have unknown cost; the UI asks, never invents).
  void setUserCost(MoneyAmount? cost) {
    _userCost = cost;
    notifyListeners();
  }

  void resetView() {
    transformationController.value = Matrix4.identity();
    if (_zoom != 1.0) {
      _zoom = 1.0;
      notifyListeners();
    }
  }

  /// Called by the widget when the interactive transform changes scale.
  void onTransformChanged() {
    final scale =
        transformationController.value.getMaxScaleOnAxis();
    if ((scale - _zoom).abs() > 0.001) {
      _zoom = scale;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }
}
