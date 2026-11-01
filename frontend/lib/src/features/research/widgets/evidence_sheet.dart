// H14 — evidence sheet: source links, freshness and snapshot metadata
// (CONTRACTS §4), plus the shared claim renderer used by the research and
// outlook panels.
//
// Standalone presentational widgets over the accepted H11 typed domain
// (frontend/lib/src/features/research/research_models.dart). Freshness is
// shown with distinct labeled fields — publication, retrieval, availability
// and reporting period are separate concepts and are never conflated.
// Headline-only news stays explicitly headline-only: it is never presented as
// a verified article or proof of a cause. URLs are vetted source links from
// the backend; the widget renders them as selectable text and, when a
// callback is provided, delegates opening to the host application instead of
// fetching anything itself.
//
// Flutter checks (analyze/test/a11y) are DEFERRED_TO_DEV_PC per
// AMENDMENT-2026-10-30; widget tests live in test/research_panel_test.dart.
import 'package:flutter/material.dart';

import '../research_models.dart';

/// Palette for the evidence sheet, matching the app's Obsidian/gold theme and
/// the other H14 research widgets. Widgets never modify the global theme.
class EvidenceSheetTheme {
  const EvidenceSheetTheme({
    this.accent = const Color(0xFFFFB800),
    this.surface = const Color(0xFF0C0C0C),
    this.panel = const Color(0xFF161618),
    this.danger = const Color(0xFFFF4B5C),
    this.onSurface = Colors.white,
    this.onSurfaceMuted = Colors.white54,
    this.onSurfaceSubtle = Colors.white38,
  });

  final Color accent;
  final Color surface;
  final Color panel;
  final Color danger;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceSubtle;
}

String evidenceKindLabel(EvidenceKind kind) => switch (kind) {
      EvidenceKind.filing => 'Filing',
      EvidenceKind.earningsRelease => 'Earnings release',
      EvidenceKind.transcript => 'Transcript',
      EvidenceKind.companyIr => 'Company IR',
      EvidenceKind.news => 'News',
      EvidenceKind.marketData => 'Market data',
      EvidenceKind.corporateAction => 'Corporate action',
      EvidenceKind.eventCalendar => 'Event calendar',
    };

/// Coverage status labels. headline_only is spelled out: a headline alone is
/// not a read article, not a verified cause, and must read that way.
String coverageStatusLabel(CoverageStatus status) => switch (status) {
      CoverageStatus.available => 'Full source available',
      CoverageStatus.partial => 'Partially available',
      CoverageStatus.unavailable => 'Unavailable',
      CoverageStatus.headlineOnly => 'Headline only — not a verified article',
    };

String claimTypeLabel(ClaimType type) => switch (type) {
      ClaimType.observed => 'Observed',
      ClaimType.interpretation => 'Interpretation',
      ClaimType.assumption => 'Assumption',
    };

/// Renders a list of claims with their claim type and evidence/metric
/// references. The references are shown as tappable chips delegating to the
/// host application ([onOpenEvidence]); without a callback they remain plain
/// text. An empty list renders [emptyText] — silence is never substituted
/// for missing support.
class ClaimList extends StatelessWidget {
  const ClaimList({
    super.key,
    required this.claims,
    this.theme = const EvidenceSheetTheme(),
    this.onOpenEvidence,
    this.emptyText = 'None recorded',
  });

  final List<Claim> claims;
  final EvidenceSheetTheme theme;
  final void Function(String evidenceId)? onOpenEvidence;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return Text(emptyText,
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final claim in claims)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: claim.claimType == ClaimType.observed
                                ? theme.accent
                                : theme.onSurfaceSubtle),
                      ),
                      child: Text(
                        claimTypeLabel(claim.claimType),
                        style: TextStyle(
                            color: claim.claimType == ClaimType.observed
                                ? theme.accent
                                : theme.onSurfaceMuted,
                            fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(claim.text,
                          style: TextStyle(
                              color: theme.onSurface, fontSize: 13)),
                    ),
                  ],
                ),
                if (claim.evidenceIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final evidenceId in claim.evidenceIds)
                          _ReferenceChip(
                            label: evidenceId,
                            theme: theme,
                            onTap: onOpenEvidence == null
                                ? null
                                : () => onOpenEvidence!(evidenceId),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final EvidenceSheetTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: theme.surface,
        border: Border.all(color: theme.onSurfaceSubtle),
      ),
      child: Text(label,
          style: TextStyle(
              color: onTap == null ? theme.onSurfaceMuted : theme.accent,
              fontSize: 11)),
    );
    if (onTap == null) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: text,
    );
  }
}

/// Source-linked evidence items with freshness, coverage and facts. The sheet
/// renders what the backend validated; it never fetches, re-requests or
/// fabricates source content.
class EvidenceSheet extends StatelessWidget {
  const EvidenceSheet({
    super.key,
    required this.items,
    this.theme = const EvidenceSheetTheme(),
    this.onOpenSource,
    this.onOpenEvidence,
  });

  final List<EvidenceItem> items;
  final EvidenceSheetTheme theme;

  /// Invoked with the vetted source URL when the reader opens a source link.
  /// The host application decides how to open it (browser, in-app view).
  final void Function(Uri url)? onOpenSource;

  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No evidence items were recorded for this report.',
          style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          _EvidenceCard(
            item: item,
            theme: theme,
            onOpenSource: onOpenSource,
            onOpenEvidence: onOpenEvidence,
          ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.item,
    required this.theme,
    required this.onOpenSource,
    required this.onOpenEvidence,
  });

  final EvidenceItem item;
  final EvidenceSheetTheme theme;
  final void Function(Uri url)? onOpenSource;
  final void Function(String evidenceId)? onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final url = Uri.tryParse(item.sourceUrl);
    final openSource = onOpenSource;
    final headlineOnly = item.coverageStatus == CoverageStatus.headlineOnly;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: headlineOnly ? theme.danger.withAlpha(0x66) : theme.onSurfaceSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(evidenceKindLabel(item.kind),
                  style: TextStyle(
                      color: theme.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(coverageStatusLabel(item.coverageStatus),
                  style: TextStyle(
                      color: headlineOnly ? theme.danger : theme.onSurfaceMuted,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.title,
              style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Source: ${item.sourceName}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 13)),
          if (url != null)
            _SourceLink(url: url, theme: theme, onOpenSource: openSource),
          const SizedBox(height: 6),
          _FreshnessRows(item: item, theme: theme),
          if (item.excerpt != null) ...[
            const SizedBox(height: 6),
            Text('Excerpt: ${item.excerpt}',
                style: TextStyle(color: theme.onSurface, fontSize: 13)),
          ],
          if (item.sourceLocator != null) ...[
            const SizedBox(height: 4),
            Text('Locator: ${item.sourceLocator}',
                style: TextStyle(color: theme.onSurfaceSubtle, fontSize: 12)),
          ],
          for (final fact in item.facts) _FactRow(fact: fact, theme: theme),
        ],
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({
    required this.url,
    required this.theme,
    required this.onOpenSource,
  });

  final Uri url;
  final EvidenceSheetTheme theme;
  final void Function(Uri url)? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final callback = onOpenSource;
    final text = Text(url.toString(),
        style: TextStyle(
            color: callback == null ? theme.onSurfaceMuted : theme.accent,
            fontSize: 12,
            decoration: callback == null
                ? TextDecoration.none
                : TextDecoration.underline));
    if (callback == null) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => callback(url),
      child: text,
    );
  }
}

/// Freshness fields with explicit labels. Publication, retrieval,
/// availability and the reporting period are separate concepts (CONTRACTS
/// §4); a missing value is labeled as missing, never backfilled.
class _FreshnessRows extends StatelessWidget {
  const _FreshnessRows({required this.item, required this.theme});

  final EvidenceItem item;
  final EvidenceSheetTheme theme;

  @override
  Widget build(BuildContext context) {
    final period = item.reportingPeriod;
    final periodText = period == null
        ? null
        : period.label ?? '${period.start} to ${period.end}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            item.publishedAt == null
                ? 'Published: not provided by the source'
                : 'Published: ${item.publishedAt}',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
        Text('Retrieved: ${item.retrievedAt}',
            style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
        if (item.availableAt != null)
          Text('Available: ${item.availableAt}',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
        if (periodText != null)
          Text('Reporting period: $periodText',
              style: TextStyle(color: theme.onSurfaceMuted, fontSize: 12)),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, required this.theme});

  final EvidenceFact fact;
  final EvidenceSheetTheme theme;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      '${fact.label}: ${fact.value}',
      if (fact.unit != null) fact.unit!,
      if (fact.currency != null) fact.currency!,
      if (fact.basis != null) '(${fact.basis})',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(parts.join(' '),
          style: TextStyle(color: theme.onSurface, fontSize: 13)),
    );
  }
}
