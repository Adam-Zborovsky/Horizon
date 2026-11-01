// H14 — decision-first research panel (CONTRACTS §5).
//
// Standalone presentational widgets over the accepted H11 typed domain
// (frontend/lib/src/features/research/research_models.dart). They render the
// evidence-backed recommendation — action, headline, rationale, countercase,
// invalidation conditions — with an explicit business-versus-price thesis
// distinction, honest run state when no assessment exists, and the evidence
// snapshot link. They never invent economics: position_context inputs are
// shown as recorded user data, never as comparable profit/loss.
//
// H09 review N1 constraint (controller addendum 2026-11-01): the additive
// position_context.economics_status field is hasCost&&hasQuantity-derived on
// the backend and is NOT authoritative for comparable P/L (the authoritative
// additive `economics.status` object is not yet in the typed model). This
// renderer therefore never presents a comparable profit/loss figure at all;
// comparable P/L presentation belongs to the lane that extends the typed
// model with the `economics` object. agent_runtime.js itself is untouched.
//
// Flutter checks (analyze/test/a11y) are DEFERRED_TO_DEV_PC per
// AMENDMENT-2026-10-30; widget tests live in test/research_panel_test.dart.
import 'package:flutter/material.dart';

import '../../positions/position_models.dart';
import '../research_models.dart';
import 'evidence_sheet.dart';
import 'outlook_panel.dart';

/// Palette for the research widgets, matching the app's Obsidian/gold theme
/// (core/theme/app_theme.dart) and the H13 chart theme. Widgets never modify
/// the global theme; callers may pass an adjusted instance.
class ResearchPanelTheme {
  const ResearchPanelTheme({
    this.accent = const Color(0xFFFFB800),
    this.surface = const Color(0xFF0C0C0C),
    this.panel = const Color(0xFF161618),
    this.danger = const Color(0xFFFF4B5C),
    this.success = const Color(0xFF57C785),
    this.info = const Color(0xFF9FC4E8),
    this.onSurface = Colors.white,
    this.onSurfaceMuted = Colors.white54,
    this.onSurfaceSubtle = Colors.white38,
  });

  final Color accent;
  final Color surface;
  final Color panel;
  final Color danger;
  final Color success;
  final Color info;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceSubtle;
}

/// Human-readable recommendation action labels (CONTRACTS §5). Candidate
/// actions (buy/wait/avoid), owned actions (hold/hold_no_add/add/reduce/
/// exit) and the explicit insufficient_evidence conclusion share one label
/// map; state compatibility is already enforced by the typed model.
String recommendationActionLabel(RecommendationAction action) =>
    switch (action) {
      RecommendationAction.buy => 'Buy',
      RecommendationAction.wait => 'Wait',
      RecommendationAction.avoid => 'Avoid',
      RecommendationAction.hold => 'Hold',
      RecommendationAction.holdNoAdd => 'Hold — do not add',
      RecommendationAction.add => 'Add',
      RecommendationAction.reduce => 'Reduce',
      RecommendationAction.exit => 'Exit',
      RecommendationAction.insufficientEvidence => 'Insufficient evidence',
    };

/// Run lifecycle labels (CONTRACTS §8). A limited result may refer to a
/// validated limited assessment; no result means failed/unavailable.
String runStatusLabel(RunStatus status) => switch (status) {
      RunStatus.queued => 'Queued',
      RunStatus.running => 'Running',
      RunStatus.succeeded => 'Succeeded',
      RunStatus.limited => 'Limited',
      RunStatus.failed => 'Failed',
      RunStatus.stalled => 'Stalled',
      RunStatus.superseded => 'Superseded',
    };

Color _actionColor(ResearchPanelTheme theme, RecommendationAction action) =>
    switch (action) {
      RecommendationAction.buy ||
      RecommendationAction.add ||
      RecommendationAction.hold ||
      RecommendationAction.wait =>
        theme.accent,
      RecommendationAction.holdNoAdd ||
      RecommendationAction.reduce ||
      RecommendationAction.exit =>
        theme.info,
      RecommendationAction.avoid =>
        theme.danger,
      RecommendationAction.insufficientEvidence =>
        theme.onSurfaceMuted,
    };

/// Maps the panel palette onto the claim renderer's palette; the two theme
/// classes stay decoupled so each widget file remains standalone.
extension _ResearchPanelThemeX on ResearchPanelTheme {
  EvidenceSheetTheme get evidenceTheme => EvidenceSheetTheme(
        accent: accent,
        surface: surface,
        panel: panel,
        danger: danger,
        onSurface: onSurface,
        onSurfaceMuted: onSurfaceMuted,
        onSurfaceSubtle: onSurfaceSubtle,
      );
}

/// Decision-first research panel: the evidence-backed recommendation and its
/// reasoning first, thesis sections, recorded position inputs, continuity,
/// then the multi-horizon outlook panel. Null [assessment] with a [run]
/// renders the honest run state instead of any invented report content.
class ResearchPanel extends StatelessWidget {
  const ResearchPanel({
    super.key,
    required this.assessment,
    this.run,
    this.theme = const ResearchPanelTheme(),
    this.onViewSnapshot,
    this.onOpenEvidence,
  });

  /// Latest validated assessment, or null when no run has produced one.
  final ResearchAssessment? assessment;

  /// Latest run detail (GET /research/runs/:runId), when the caller has one.
  final ResearchRun? run;

  final ResearchPanelTheme theme;

  /// Invoked when the reader opens the immutable evidence snapshot view.
  final void Function(String snapshotId)? onViewSnapshot;

  /// Invoked when the reader opens an evidence item referenced by a claim.
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final assessment = this.assessment;
    if (assessment == null) {
      return _NoAssessmentView(run: run, theme: theme);
    }
    return _AssessmentView(
      assessment: assessment,
      theme: theme,
      onViewSnapshot: onViewSnapshot,
      onOpenEvidence: onOpenEvidence,
    );
  }
}

class _NoAssessmentView extends StatelessWidget {
  const _NoAssessmentView({required this.run, required this.theme});

  final ResearchRun? run;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    final run = this.run;
    return _PanelCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No research report yet',
              style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'No validated assessment exists for this position. Nothing is '
            'invented here; queue a research run to produce one.',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 14),
          ),
          if (run != null) ...[
            const SizedBox(height: 12),
            Text('Run status: ${runStatusLabel(run.status)}',
                style: TextStyle(color: theme.onSurface, fontSize: 14)),
            Text('Stage: ${run.stage}',
                style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
            if (run.errorCode != null)
              Text('Error: ${run.errorCode}',
                  style: TextStyle(color: theme.danger, fontSize: 13)),
            Text('Deadline: ${run.deadlineAt}',
                style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _AssessmentView extends StatelessWidget {
  const _AssessmentView({
    required this.assessment,
    required this.theme,
    required this.onViewSnapshot,
    required this.onOpenEvidence,
  });

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;
  final void Function(String snapshotId)? onViewSnapshot;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final recommendation = assessment.recommendation;
    final limited = assessment.status == AssessmentStatus.limited;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (limited)
          _PanelCard(
            theme: theme,
            borderColor: theme.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Limited report',
                    style: TextStyle(
                        color: theme.danger,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Evidence coverage was incomplete for this session; the '
                  'conclusions below are bounded by what was available.',
                  style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        _RecommendationCard(
          assessment: assessment,
          theme: theme,
          onOpenEvidence: onOpenEvidence,
        ),
        _ThesisCard(assessment: assessment, theme: theme),
        _EconomicsCard(assessment: assessment, theme: theme),
        _ContinuityCard(assessment: assessment, theme: theme),
        if (assessment.missingData.isNotEmpty)
          _MissingDataCard(assessment: assessment, theme: theme),
        OutlookPanel(assessment: assessment, onOpenEvidence: onOpenEvidence),
        _SnapshotLink(
          snapshotId: assessment.evidenceSnapshotId,
          theme: theme,
          onViewSnapshot: onViewSnapshot,
        ),
        Text(
          'Report generated ${assessment.generatedAt} · session as of '
          '${assessment.sessionAsOf}',
          style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.assessment,
    required this.theme,
    required this.onOpenEvidence,
  });

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final recommendation = assessment.recommendation;
    final actionColor = _actionColor(theme, recommendation.action);
    return _PanelCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommendation',
              style: TextStyle(
                  color: theme.onSurfaceMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Semantics(
            label: 'Recommended action: '
                '${recommendationActionLabel(recommendation.action)}',
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color.alphaBlend(actionColor.withAlpha(0x2E), theme.panel),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: actionColor),
              ),
              child: Text(
                recommendationActionLabel(recommendation.action),
                style: TextStyle(
                    color: actionColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Research horizon: ${recommendation.horizonMonths} '
              'month${recommendation.horizonMonths == 1 ? '' : 's'}',
              style: TextStyle(color: theme.onSurface, fontSize: 14)),
          const SizedBox(height: 8),
          Text(recommendation.headline,
              style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _LabeledSection(
            label: 'Why',
            theme: theme,
            child: ClaimList(
              claims: recommendation.rationale,
              theme: theme.evidenceTheme,
              onOpenEvidence: onOpenEvidence,
            ),
          ),
          _LabeledSection(
            label: 'Countercase',
            theme: theme,
            child: ClaimList(
              claims: recommendation.countercase,
              theme: theme.evidenceTheme,
              onOpenEvidence: onOpenEvidence,
            ),
          ),
          _LabeledSection(
            label: 'Invalidates the conclusion if',
            theme: theme,
            child: ClaimList(
              claims: recommendation.invalidationConditions,
              theme: theme.evidenceTheme,
              onOpenEvidence: onOpenEvidence,
            ),
          ),
          const SizedBox(height: 4),
          Text('Evidence quality: ${recommendation.evidenceQuality}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
              'Predictive uncertainty: ${recommendation.predictiveUncertainty}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Business versus price distinction (CONTRACTS §5): the market thesis is
/// produced before personal cost is injected, and its three sections are
/// shown separately so a business conclusion never masquerades as a price
/// observation.
class _ThesisCard extends StatelessWidget {
  const _ThesisCard({required this.assessment, required this.theme});

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    final thesis = assessment.marketThesis;
    return _PanelCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market thesis',
              style: TextStyle(
                  color: theme.onSurfaceMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _ThesisSection(
              title: 'Business assessment',
              section: thesis.businessAssessment,
              theme: theme),
          _ThesisSection(
              title: 'Price and technical assessment',
              section: thesis.priceTechnicalAssessment,
              theme: theme),
          _ThesisSection(
              title: 'Valuation assessment',
              section: thesis.valuationAssessment,
              theme: theme),
          _LabeledSection(
            label: 'Counterevidence',
            theme: theme,
            child: ClaimList(
              claims: thesis.counterevidence,
              theme: theme.evidenceTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThesisSection extends StatelessWidget {
  const _ThesisSection({
    required this.title,
    required this.section,
    required this.theme,
  });

  final String title;
  final ThesisSection section;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(section.summary,
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
          // Section claims carry the evidence-backed detail; summaries alone
          // are never a substitute for the sourced content.
          ClaimList(claims: section.claims, theme: theme.evidenceTheme),
        ],
      ),
    );
  }
}

/// Recorded position inputs, plainly labeled as user data. No value is
/// invented for missing inputs, no comparable P/L is derived here, and a
/// legacy position is asked to classify rather than silently analyzed.
class _EconomicsCard extends StatelessWidget {
  const _EconomicsCard({required this.assessment, required this.theme});

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    final context_ = assessment.positionContext;
    final children = <Widget>[];
    switch (context_.state) {
      case PositionState.owned:
        children.add(Text('Your recorded inputs (not advice)',
            style: TextStyle(
                color: theme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)));
        if (context_.averageCost != null) {
          children.add(Text(
              'Average cost: ${context_.averageCost!.amount} '
              '${context_.averageCost!.currency}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
        } else {
          children.add(Text('Average cost: unknown',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
        }
        children.add(Text(
            context_.quantity == null
                ? 'Quantity: unknown'
                : 'Quantity: ${context_.quantity}',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
        if (context_.openedOn != null) {
          children.add(Text('Opened on: ${context_.openedOn}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
        }
        children.add(const SizedBox(height: 4));
        children.add(Text(
          'Comparable profit and loss is not shown from these inputs alone; '
          'it requires matching currency and a compatible price basis, and '
          'is added by the app when that is validated.',
          style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12),
        ));
      case PositionState.candidate:
        children.add(Text('No recorded purchase',
            style: TextStyle(
                color: theme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)));
        children.add(Text(
          'Candidate position — the analysis above is market-level research; '
          'a desired entry condition belongs in your review conditions.',
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13),
        ));
      case PositionState.legacyUnclassified:
        children.add(Text('Position not yet classified',
            style: TextStyle(
                color: theme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)));
        children.add(Text(
          'This imported ticker must be classified as candidate or owned '
          'before a position-specific recommendation; generic market '
          'research remains available.',
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13),
        ));
    }
    return _PanelCard(theme: theme, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}

/// Continuity (CONTRACTS §6): what changed since the previous report, from
/// the assessment's own changes_since_previous block. Prior generated
/// judgments are not source evidence and are never presented as such.
class _ContinuityCard extends StatelessWidget {
  const _ContinuityCard({required this.assessment, required this.theme});

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    final changes = assessment.changesSincePrevious;
    final children = <Widget>[
      Text('What changed since the previous report',
          style: TextStyle(
              color: theme.onSurfaceMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    ];
    if (changes == null) {
      children.add(Text('First report for this position.',
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
    } else {
      if (changes.previousSessionAsOf != null) {
        children.add(Text(
            'Previous report session: ${changes.previousSessionAsOf}',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
      }
      if (changes.missingReportSessions.isNotEmpty) {
        children.add(Text(
            'Missing report sessions: '
                '${changes.missingReportSessions.join(', ')}',
            style: TextStyle(color: theme.danger, fontSize: 13)));
      }
      for (final change in changes.thesisChanges) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${change.component} — ${change.status}',
                  style: TextStyle(color: theme.onSurface, fontSize: 13)),
              Text(change.reason,
                  style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
            ],
          ),
        ));
      }
      if (changes.thesisChanges.isEmpty) {
        children.add(Text('No thesis component changes were recorded.',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)));
      }
    }
    return _PanelCard(theme: theme, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}

class _MissingDataCard extends StatelessWidget {
  const _MissingDataCard({required this.assessment, required this.theme});

  final ResearchAssessment assessment;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      theme: theme,
      borderColor: theme.danger.withAlpha(0x66),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Missing data',
              style: TextStyle(
                  color: theme.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          for (final item in assessment.missingData)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item,
                  style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _SnapshotLink extends StatelessWidget {
  const _SnapshotLink({
    required this.snapshotId,
    required this.theme,
    required this.onViewSnapshot,
  });

  final String snapshotId;
  final ResearchPanelTheme theme;
  final void Function(String snapshotId)? onViewSnapshot;

  @override
  Widget build(BuildContext context) {
    final callback = onViewSnapshot;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fact_check_outlined,
            size: 16, color: theme.accent),
        const SizedBox(width: 6),
        Text('Evidence snapshot: $snapshotId',
            style: TextStyle(
                color: callback == null ? theme.onSurfaceMuted : theme.accent,
                fontSize: 13,
                decoration: callback == null
                    ? TextDecoration.none
                    : TextDecoration.underline)),
      ],
    );
    if (callback == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => callback(snapshotId),
      child: row,
    );
  }
}

/// Shared card container for the research widgets.
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    required this.theme,
    this.borderColor,
  });

  final Widget child;
  final ResearchPanelTheme theme;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? theme.onSurfaceSubtle),
      ),
      child: child,
    );
  }
}

class _LabeledSection extends StatelessWidget {
  const _LabeledSection({
    required this.label,
    required this.child,
    required this.theme,
  });

  final String label;
  final Widget child;
  final ResearchPanelTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}
