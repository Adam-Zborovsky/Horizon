// H14 — multi-horizon outlook panel (CONTRACTS §5, §7).
//
// Standalone presentational widget over the accepted H11 typed domain
// (frontend/lib/src/features/research/research_models.dart). Renders the
// mandatory 1/2/3-month outlooks as three independent tabs, each anchored to
// its own calendar target and evaluation session dates. The horizon selector
// is a research-horizon control and is explicitly labeled as independent of
// the historical chart range controls — the two are never conflated. A
// missing numeric projection renders the contract's explicit message; a
// present one is framed by its kind (conditional scenario / volatility
// reference / calibrated forecast) and never styled as observed data.
//
// The default tab follows the assessment's recommendation horizon so the
// decision-first flow stays coherent; switching tabs never mutates any other
// tab or the chart state.
//
// Flutter checks (analyze/test/a11y) are DEFERRED_TO_DEV_PC per
// AMENDMENT-2026-10-30; widget tests live in test/research_panel_test.dart.
import 'package:flutter/material.dart';

import '../research_models.dart';
import 'evidence_sheet.dart';

/// Palette for the outlook panel, matching the app's Obsidian/gold theme and
/// the other H14 research widgets. Widgets never modify the global theme.
class OutlookPanelTheme {
  const OutlookPanelTheme({
    this.accent = const Color(0xFFFFB800),
    this.surface = const Color(0xFF0C0C0C),
    this.panel = const Color(0xFF161618),
    this.danger = const Color(0xFFFF4B5C),
    this.success = const Color(0xFF57C785),
    this.onSurface = Colors.white,
    this.onSurfaceMuted = Colors.white54,
    this.onSurfaceSubtle = Colors.white38,
  });

  final Color accent;
  final Color surface;
  final Color panel;
  final Color danger;
  final Color success;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceSubtle;
}

/// Three independent research-horizon tabs (1/2/3 months). The initial tab is
/// the assessment's recommendation horizon. Outlooks are contract-mandatory
/// (exactly one per horizon, enforced by the typed model), so the panel never
/// renders a partial set or an invented horizon.
class OutlookPanel extends StatefulWidget {
  const OutlookPanel({
    super.key,
    required this.assessment,
    this.theme = const OutlookPanelTheme(),
    this.onOpenEvidence,
  });

  final ResearchAssessment assessment;
  final OutlookPanelTheme theme;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  State<OutlookPanel> createState() => _OutlookPanelState();
}

class _OutlookPanelState extends State<OutlookPanel>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.assessment);
  }

  @override
  void didUpdateWidget(OutlookPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assessment.id != widget.assessment.id ||
        oldWidget.assessment.recommendation.horizonMonths !=
            widget.assessment.recommendation.horizonMonths) {
      // The H11 typed model validates horizonMonths ∈ {1,2,3}, so the tab
      // length (3) never changes; only the selected index follows the new
      // horizon. The controller is kept alive: disposing it here would
      // dispose a controller still attached to the live TabBar/TabBarView
      // (H14 review finding 3).
      _controller.index = _horizonTabIndex(widget.assessment);
    }
  }

  /// Tab index for a recommendation horizon. horizonMonths is validated by
  /// the H11 typed model to {1,2,3}, so the result is always 0..2.
  /// The num-typed clamp result defect (H14 review finding 1) is fixed by
  /// omission: no clamping is needed, and the expression is plain int.
  int _horizonTabIndex(ResearchAssessment assessment) =>
      assessment.recommendation.horizonMonths - 1;

  TabController _buildController(ResearchAssessment assessment) {
    return TabController(
        length: 3, vsync: this, initialIndex: _horizonTabIndex(assessment));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.onSurfaceSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Multi-horizon outlook',
              style: TextStyle(
                  color: theme.onSurfaceMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            'Research horizon selector — outlook targets below are '
            'independent of the chart history range controls.',
            style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Research horizon selector: 1, 2 or 3 months',
            child: TabBar(
              controller: _controller,
              labelColor: theme.accent,
              unselectedLabelColor: theme.onSurfaceMuted,
              indicatorColor: theme.accent,
              dividerColor: theme.onSurfaceSubtle,
              tabs: const [
                Tab(text: '1 month'),
                Tab(text: '2 months'),
                Tab(text: '3 months'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _controller,
              children: [
                for (final horizon in const [1, 2, 3])
                  _OutlookView(
                    outlook: widget.assessment.outlooks
                        .firstWhere((o) => o.horizonMonths == horizon),
                    theme: theme,
                    onOpenEvidence: widget.onOpenEvidence,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlookView extends StatelessWidget {
  const _OutlookView({
    required this.outlook,
    required this.theme,
    required this.onOpenEvidence,
  });

  final Outlook outlook;
  final OutlookPanelTheme theme;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final directionColor = switch (outlook.direction) {
      OutlookDirection.positive => theme.success,
      OutlookDirection.negative => theme.danger,
      OutlookDirection.mixed => theme.accent,
      OutlookDirection.insufficientEvidence => theme.onSurfaceMuted,
    };
    final directionLabel = switch (outlook.direction) {
      OutlookDirection.positive => 'Positive',
      OutlookDirection.negative => 'Negative',
      OutlookDirection.mixed => 'Mixed',
      OutlookDirection.insufficientEvidence => 'Insufficient evidence',
    };
    return SingleChildScrollView(
      key: ValueKey('outlook-horizon-${outlook.horizonMonths}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: directionColor),
                ),
                child: Semantics(
                  label: 'Outlook direction for ${outlook.horizonMonths} '
                      'months: $directionLabel',
                  child: Text(directionLabel,
                      style: TextStyle(
                          color: directionColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Research horizon: ${outlook.horizonMonths} '
                  'month${outlook.horizonMonths == 1 ? '' : 's'}',
                  style: TextStyle(color: theme.onSurface, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Outlook target date: ${outlook.calendarTargetDate}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
          Text(
              'Evaluated at the last exchange session on or before the '
              'target: ${outlook.evaluationSessionDate}',
              style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12)),
          const SizedBox(height: 10),
          _OutlookSection(
              label: 'Base case',
              claims: outlook.baseCase,
              theme: theme,
              onOpenEvidence: onOpenEvidence),
          _OutlookSection(
              label: 'Upside case',
              claims: outlook.upsideCase,
              theme: theme,
              onOpenEvidence: onOpenEvidence),
          _OutlookSection(
              label: 'Downside case',
              claims: outlook.downsideCase,
              theme: theme,
              onOpenEvidence: onOpenEvidence),
          _OutlookSection(
              label: 'Catalysts',
              claims: outlook.catalysts,
              theme: theme,
              onOpenEvidence: onOpenEvidence),
          _OutlookSection(
              label: 'Invalidators',
              claims: outlook.invalidators,
              theme: theme,
              onOpenEvidence: onOpenEvidence),
          _ProjectionView(projection: outlook.numericProjection, theme: theme),
          if (outlook.dataLimitations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Data limitations',
                style: TextStyle(
                    color: theme.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            for (final limitation in outlook.dataLimitations)
              Text('• $limitation',
                  style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _OutlookSection extends StatelessWidget {
  const _OutlookSection({
    required this.label,
    required this.claims,
    required this.theme,
    required this.onOpenEvidence,
  });

  final String label;
  final List<Claim> claims;
  final OutlookPanelTheme theme;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          ClaimList(
            claims: claims,
            theme: EvidenceSheetTheme(
              accent: theme.accent,
              surface: theme.surface,
              panel: theme.panel,
              danger: theme.danger,
              onSurface: theme.onSurface,
              onSurfaceMuted: theme.onSurfaceMuted,
              onSurfaceSubtle: theme.onSurfaceSubtle,
            ),
            onOpenEvidence: onOpenEvidence,
          ),
        ],
      ),
    );
  }
}

/// Numeric projection display (CONTRACTS §7). The contract message for a
/// missing projection is rendered verbatim; a present projection is framed by
/// its kind with the not-observed-prices boundary, ordered bounds with
/// currency, its method and its limitations. Nothing is extracted from prose.
class _ProjectionView extends StatelessWidget {
  const _ProjectionView({required this.projection, required this.theme});

  final NumericProjection? projection;
  final OutlookPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    final projection = this.projection;
    if (projection == null) {
      return Text('No quantified projection for this assessment',
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13));
    }
    final framing = switch (projection.kind) {
      ProjectionKind.conditionalScenario =>
        'Conditional scenario — not observed prices and not a probability '
            'interval',
      ProjectionKind.volatilityReference =>
        'Volatility reference — not observed prices and not a directional '
            'forecast',
      ProjectionKind.calibratedForecast =>
        'Calibrated forecast — not observed prices; see its calibration '
            'evidence',
    };
    String? bound(double? value) =>
        value == null ? null : value.toStringAsFixed(2);
    final lower = bound(projection.lower);
    final central = bound(projection.central);
    final upper = bound(projection.upper);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.onSurfaceSubtle),
        color: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(framing,
              style: TextStyle(color: theme.accent, fontSize: 12)),
          const SizedBox(height: 4),
          if (lower != null)
            Text('Lower: $lower ${projection.currency}',
                style: TextStyle(color: theme.onSurface, fontSize: 13)),
          if (central != null)
            Text('Central: $central ${projection.currency}',
                style: TextStyle(color: theme.onSurface, fontSize: 13)),
          if (upper != null)
            Text('Upper: $upper ${projection.currency}',
                style: TextStyle(color: theme.onSurface, fontSize: 13)),
          Text('Method: ${projection.method} '
              '(version ${projection.methodVersion})',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
          for (final limitation in projection.limitations)
            Text('• $limitation',
                style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12)),
        ],
      ),
    );
  }
}
