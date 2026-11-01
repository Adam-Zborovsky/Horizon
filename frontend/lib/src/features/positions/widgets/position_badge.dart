// H12 — position state badge and honest economics summary.
//
// Reusable, dependency-free presentational widgets for the position lists and
// the position editor (CONTRACTS §2). They render the typed H11 domain
// (frontend/src/features/positions/position_models.dart) in the existing
// Obsidian/gold theme and never invent economics: an unknown value is labeled
// "unknown", never zero, never a fabricated default.
//
// Flutter checks (analyze/test/a11y audit) are DEFERRED_TO_DEV_PC per
// AMENDMENT-2026-10-30; widget tests live in test/position_editor_test.dart.
import 'package:flutter/material.dart';

import '../position_models.dart';

/// Colors for the position lifecycle states, taken from the app theme
/// palette (core/theme/app_theme.dart): gold for owned, muted grey-blue for
/// candidate, neutral outline for legacy/unclassified.
(Color, Color) _stateStyle(PositionState state, bool archived) {
  if (archived) return (const Color(0xFF6E6E6E), const Color(0x22FFFFFF));
  return switch (state) {
    PositionState.owned => (const Color(0xFFFFB800), const Color(0x1AFFB800)),
    PositionState.candidate => (
        const Color(0xFF9FC4E8),
        const Color(0x1A9FC4E8),
      ),
    PositionState.legacyUnclassified => (
        const Color(0xFFD8C9A3),
        const Color(0x14FFFFFF),
      ),
  };
}

String _stateLabel(PositionState state) => switch (state) {
      PositionState.owned => 'Owned',
      PositionState.candidate => 'Candidate',
      PositionState.legacyUnclassified => 'Legacy · unclassified',
    };

String _stateSemanticDescription(PositionState state) => switch (state) {
      PositionState.owned => 'Owned position',
      PositionState.candidate =>
        'Candidate position: a watchlist idea, no executed purchase',
      PositionState.legacyUnclassified =>
        'Legacy imported ticker, not yet classified as candidate or owned',
    };

/// Pill badge for a position lifecycle state, with an optional Archived
/// marker. Non-interactive; state is also exposed through Semantics so screen
/// readers never depend on color alone.
class PositionStateBadge extends StatelessWidget {
  const PositionStateBadge({
    super.key,
    required this.state,
    this.archived = false,
    this.compact = false,
  });

  final PositionState state;

  /// Archival is reversible removal from active coverage, not deletion; the
  /// badge always distinguishes it from the lifecycle state.
  final bool archived;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = _stateStyle(state, archived);
    final label = _stateLabel(state);
    final semanticLabel = archived
        ? '${_stateSemanticDescription(state)}, archived'
        : _stateSemanticDescription(state);

    return Semantics(
      excludeSemantics: true,
      label: semanticLabel,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: foreground.withValues(alpha: 0.5)),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (archived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF6E6E6E)),
              ),
              child: Text(
                'Archived',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFB5B5B5),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One-line honest economics summary for a position.
///
/// Contract rules rendered here (CONTRACTS §2):
/// - candidate: no executed cost/quantity exists, so none is shown;
/// - owned with null cost/quantity: explicitly "unknown" with the reason it
///   matters (P/L needs it), never zero, never invented;
/// - legacy_unclassified: classification is required before any economics.
class PositionEconomicsLine extends StatelessWidget {
  const PositionEconomicsLine({super.key, required this.position});

  final Position position;

  String _text() {
    switch (position.state) {
      case PositionState.candidate:
        return 'No executed purchase — entry ideas live in review conditions.';
      case PositionState.legacyUnclassified:
        return 'Unclassified legacy ticker — classify before position analysis.';
      case PositionState.owned:
        final cost = position.averageCost;
        final quantity = position.quantity;
        if (cost == null && quantity == null) {
          return 'Cost unknown — enter your average cost and quantity to '
              'enable profit/loss.';
        }
        final parts = <String>[
          if (cost != null) 'Cost ${cost.amount} ${cost.currency}',
          if (quantity == null && cost != null) 'Quantity unknown',
          if (quantity != null) 'Quantity $quantity',
          if (cost == null) 'Cost unknown',
        ];
        return parts.join(' · ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Text(_text(), style: style, maxLines: 3, overflow: TextOverflow.fade);
  }
}
