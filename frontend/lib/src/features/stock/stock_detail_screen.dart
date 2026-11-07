import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/auth_repository.dart';
import '../briefing/briefing_config_repository.dart';
import '../market/market_repository.dart';
import '../positions/position_models.dart';
import '../positions/position_repository.dart';
import '../positions/widgets/position_badge.dart';
import '../positions/widgets/position_editor.dart';
import '../research/research_models.dart';
import '../research/widgets/research_panel.dart';
import '../stock/stock_repository.dart';
import '../stock/opportunity_stats_provider.dart';
import '../stock/widgets/chart_controller.dart';
import '../stock/widgets/price_chart.dart';
import '../dashboard/watchlist_provider.dart';

class StockDetailScreen extends ConsumerWidget {
  final String ticker;
  final bool autoOpenPositionEditor;

  const StockDetailScreen({
    super.key,
    required this.ticker,
    this.autoOpenPositionEditor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stockRepositoryProvider);
    final watchlist = ref.watch(watchlistProvider);
    final upperTicker = ticker.toUpperCase();

    return Scaffold(
      body: stocksAsync.when(
        data: (stocks) {
          final stock =
              stocks
                  .where((s) => s.ticker.toUpperCase() == upperTicker)
                  .firstOrNull ??
              (autoOpenPositionEditor || watchlist.contains(upperTicker)
                  ? StockData(
                      ticker: upperTicker,
                      name: upperTicker,
                      currentPrice: 0.0,
                      changePercent: 0.0,
                      history: const <double>[],
                      sentiment: 0.0,
                      source: StockSource.watchlist,
                    )
                  : null);
          if (stock == null) {
            return Center(
              child: Text(
                'Stock $ticker not found',
                style: const TextStyle(color: Colors.white38),
              ),
            );
          }
          return _DetailContent(
            stock: stock,
            autoOpenPositionEditor: autoOpenPositionEditor,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final StockData stock;
  final bool autoOpenPositionEditor;

  const _DetailContent({
    required this.stock,
    this.autoOpenPositionEditor = false,
  });

  String? _getDisplayString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value.values.whereType<String>().join('\n');
    return value.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = stock.changePercent > 0
        ? AppTheme.goldAmber
        : AppTheme.softCrimson;

    return CustomScrollView(
      slivers: [
        _DetailHeader(ticker: stock.ticker),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stock.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _SourceBadge(source: stock.source),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // H15: 0.0 means "unavailable" (no structured model price
                    // and no model-reported history). The heading never
                    // fabricates "$0.00" — it states the unavailability.
                    if (stock.currentPrice > 0)
                      Text(
                        '\$${stock.currentPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 42,
                          letterSpacing: -2,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '—',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 42,
                              letterSpacing: -2,
                              color: Colors.white24,
                            ),
                          ),
                          const Text(
                            'PRICE UNAVAILABLE',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 16),
                    if (stock.currentPrice > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${stock.changePercent > 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                // The legacy briefing list has neither identity nor OHLCV
                // metadata. This slot resolves the matching tracked
                // instrument and only then loads typed observed bars through
                // the authenticated MarketRepository.
                _ObservedPriceSection(ticker: stock.ticker),
                const SizedBox(height: 30),
                // A tracked position is a decision surface, so its validated
                // research belongs ahead of the briefing-derived context.
                _PositionResearchSection(
                  stock: stock,
                  autoOpenEditor: autoOpenPositionEditor,
                ),
                const SizedBox(height: 40),
                if (stock.horizon != null || stock.direction != null) ...[
                  Row(
                    children: [
                      if (stock.direction != null) ...[
                        _DirectionBadge(direction: stock.direction!),
                        if (stock.horizon != null) const SizedBox(width: 16),
                      ],
                      if (stock.horizon != null) ...[
                        const Icon(
                          Icons.timer_outlined,
                          color: AppTheme.goldAmber,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stock.horizon!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
                Text(
                  'HISTORIC / SECONDARY CONTEXT',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Legacy briefing context',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          _SentimentPill(score: stock.sentiment),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getDisplayString(stock.analysis) ??
                            // H15B: truthful unavailable copy — no synthetic
                            // analysis is fabricated when the model sent none.
                            'No analysis was provided for this ticker yet.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/vault?category=${Uri.encodeComponent(stock.source == StockSource.opportunity ? 'Opportunities' : 'Market Analysis')}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.goldAmber,
                          side: BorderSide(
                            color: AppTheme.goldAmber.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: Text(
                          stock.source == StockSource.opportunity
                              ? 'VIEW HISTORIC OPPORTUNITIES'
                              : 'VIEW HISTORIC MARKET ANALYSIS',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (stock.potentialPriceAction != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'LEGACY EXPECTATION',
                          style: TextStyle(
                            color: AppTheme.goldAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDisplayString(stock.potentialPriceAction)!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (stock.catalysts != null && stock.catalysts!.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text(
                    'GROWTH CATALYSTS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.goldAmber,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stock.catalysts!.map(
                    (c) => _MacroItem(
                      title: 'Bullish Driver',
                      description: c,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
                if (stock.risks != null && stock.risks!.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text(
                    'CRITICAL RISKS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.softCrimson,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stock.risks!.map(
                    (r) => _MacroItem(
                      title: 'Risk Factor',
                      description: r,
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.softCrimson,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                _OpportunityScoutStats(ticker: stock.ticker),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hosts the existing interactive [PriceChart] in the detail hierarchy.
///
/// A ticker alone is not a market-instrument identity. This resolves the
/// owner's matching non-archived position first, then supplies its canonical
/// instrument id to the authenticated [MarketRepository].
class _ObservedPriceSection extends ConsumerStatefulWidget {
  const _ObservedPriceSection({required this.ticker});

  final String ticker;

  @override
  ConsumerState<_ObservedPriceSection> createState() =>
      _ObservedPriceSectionState();
}

class _ObservedPriceSectionState extends ConsumerState<_ObservedPriceSection> {
  ChartController? _controller;
  String? _error;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolveInstrument();
  }

  Future<void> _resolveInstrument() async {
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _resolving = true;
        _error = null;
      });
    }
    try {
      final positions = await ref.read(positionRepositoryProvider).getPositions();
      final ticker = widget.ticker.toUpperCase();
      final matches = positions
          .where((candidate) =>
              !candidate.archived &&
              candidate.instrument.symbol.toUpperCase() == ticker)
          .toList(growable: false);
      if (!mounted) return;
      if (matches.isEmpty) {
        setState(() {
          _resolving = false;
          _error = 'Observed market history is unavailable: no resolved '
              'tracked instrument for $ticker.';
        });
        return;
      }
      if (matches.length != 1) {
        setState(() {
          _resolving = false;
          _error = 'Observed market history is unavailable: $ticker matches '
              'multiple tracked instruments. Resolve the duplicate positions '
              'before viewing a chart.';
        });
        return;
      }
      final resolvedPosition = matches.single;
      final controller = ChartController(
        loadHistory: (range) => ref.read(marketRepositoryProvider).getHistory(
              instrumentId: resolvedPosition.instrument.instrumentId,
              range: range,
            ),
      );
      if (resolvedPosition.averageCost != null) {
        controller.setUserCost(resolvedPosition.averageCost);
      }
      setState(() {
        _controller = controller;
        _resolving = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to resolve chart instrument: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = 'Observed market history could not be prepared. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBSERVED MARKET DATA',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.goldAmber,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 510,
            width: double.infinity,
            child: _resolving
                ? const Center(
                    child: CircularProgressIndicator(
                      key: Key('detail_chart_resolving'),
                    ),
                  )
                : controller != null
                    ? PriceChart(controller: controller)
                    : _ChartIdentityError(
                        message: _error!,
                        onRetry: _resolveInstrument,
                      ),
          ),
        ),
      ],
    );
  }
}

class _ChartIdentityError extends StatelessWidget {
  const _ChartIdentityError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 28),
            const SizedBox(height: 8),
            Text(
              message,
              key: const Key('detail_chart_identity_error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            TextButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends ConsumerWidget {
  final String ticker;
  const _DetailHeader({required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final isInWatchlist = watchlist.contains(ticker.toUpperCase());

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(ticker, style: Theme.of(context).textTheme.displaySmall),
      actions: [
        IconButton(
          icon: Icon(
            isInWatchlist ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isInWatchlist ? AppTheme.goldAmber : Colors.white38,
          ),
          onPressed: () async {
            try {
              if (isInWatchlist) {
                await ref.read(watchlistProvider.notifier).remove(ticker);
              } else {
                await ref.read(watchlistProvider.notifier).add(ticker);
              }
            } on PositionTickerConflictException catch (conflict) {
              // H15: a star removal refused by the backend (409
              // POSITION_TICKER_CONFLICT — the ticker backs an active
              // position) is surfaced bounded and explicitly, never
              // silently swallowed into the generic failure copy.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(conflict.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not update watchlist'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class _SentimentPill extends StatelessWidget {
  final double score;
  const _SentimentPill({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${score > 0 ? "+" : ""}${score.toStringAsFixed(1)} SNT',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OpportunityScoutStats extends ConsumerWidget {
  final String ticker;
  const _OpportunityScoutStats({required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(opportunityStatsProvider(ticker));

    return statsAsync.when(
      data: (stats) {
        if (stats.totalLast30Days == 0) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPPORTUNITY SCOUT',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.goldAmber,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _ScoutStatTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.consecutiveTradingDays}',
                      label: stats.consecutiveTradingDays == 1
                          ? 'day streak'
                          : 'days in a row',
                      color: stats.consecutiveTradingDays >= 3
                          ? AppTheme.goldAmber
                          : Colors.white70,
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.white10),
                  Expanded(
                    child: _ScoutStatTile(
                      icon: Icons.calendar_month_rounded,
                      value: '${stats.totalLast30Days}',
                      label: 'times / 30 days',
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ScoutStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ScoutStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _MacroItem({
    required this.title,
    required this.description,
    this.icon = Icons.hub_outlined,
    this.color = AppTheme.goldAmber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final String direction;
  const _DirectionBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final isLong = direction.toLowerCase() == 'long';
    final color = isLong ? AppTheme.goldAmber : AppTheme.softCrimson;
    final icon = isLong
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final label = isLong ? 'LONG' : 'SHORT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final StockSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isOpp = source == StockSource.opportunity;
    final color = isOpp ? AppTheme.goldAmber : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isOpp ? 'ALPHA' : 'WATCHLIST',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// H15B — owner-scoped position + grounded research wiring.
// ---------------------------------------------------------------------------

/// Owner-safe run-state projections from
/// `GET /research/positions/:id/latest` (research.routes.js:61-80 /
/// research.service.js getPositionResearchState). These are NOT full
/// [ResearchRun] objects: last_success and latest_attempt arrive as separate
/// narrow projections, so they are rendered as their own truthful rows
/// instead of being reassembled into a run model that would invent fields.
class RunSuccessView {
  const RunSuccessView({
    required this.runId,
    required this.status,
    this.assessmentId,
    this.finishedAt,
  });

  final String runId;
  final String status;
  final String? assessmentId;
  final String? finishedAt;

  static RunSuccessView? fromWire(Object? wire) {
    if (wire == null) return null;
    if (wire is! Map<String, dynamic>) {
      throw const FormatException('run_state.last_success: expected an '
          'object or null');
    }
    return RunSuccessView(
      runId: wire['run_id'] as String,
      status: wire['status'] as String,
      assessmentId: wire['assessment_id'] as String?,
      finishedAt: wire['finished_at'] as String?,
    );
  }
}

class RunAttemptView {
  const RunAttemptView({
    required this.runId,
    required this.status,
    required this.stage,
    this.startedAt,
    this.finishedAt,
    this.errorCode,
    this.deadlineAt,
  });

  final String runId;
  final String status;
  final String stage;
  final String? startedAt;
  final String? finishedAt;
  final String? errorCode;
  final String? deadlineAt;

  static RunAttemptView? fromWire(Object? wire) {
    if (wire == null) return null;
    if (wire is! Map<String, dynamic>) {
      throw const FormatException('run_state.latest_attempt: expected an '
          'object or null');
    }
    return RunAttemptView(
      runId: wire['run_id'] as String,
      status: wire['status'] as String,
      stage: wire['stage'] as String,
      startedAt: wire['started_at'] as String?,
      finishedAt: wire['finished_at'] as String?,
      errorCode: wire['error_code'] as String?,
      deadlineAt: wire['deadline_at'] as String?,
    );
  }
}

/// Unwrapped research state for one position. The backend nests the contract
/// assessment object flatly under `latest_assessment` (owner_id_internal
/// stripped by toPublicAssessmentView); run state arrives as the narrow
/// projections above.
class PositionResearchState {
  const PositionResearchState({
    required this.positionId,
    this.assessment,
    this.lastSuccess,
    this.latestAttempt,
  });

  final String positionId;
  final ResearchAssessment? assessment;
  final RunSuccessView? lastSuccess;
  final RunAttemptView? latestAttempt;
}

/// H15B wire adapter for the owner-scoped research endpoints.
///
/// Wire reconciliation (parent-card constraint, traced against the actual
/// backend — never assumed):
/// - `GET /research/positions/:id/latest` answers
///   `{position_id, latest_assessment, run_state: {last_success,
///   latest_attempt}}`. H11's ResearchLatest historically expects a different
///   shape and that file is read-only for this lane, so the unwrap happens
///   HERE and the drift is reported for a scoped H11 repair instead of being
///   silently repaired.
/// - `POST /research/positions/:id/runs` answers `{run, idempotent_replay}`
///   where the run wire RETAINS owner_id_internal (toPublicRunView strips
///   only lease_nonce) — exactly what H11's strict ResearchRun.fromJson
///   requires, so the full run parse reconciles with the real wire.
/// - The evidence detail endpoint is not part of the mounted route surface,
///   so evidence chips intentionally stay non-interactive plain text rather
///   than a dead affordance.
class ResearchWire {
  ResearchWire({http.Client? client, AuthTokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider() => AuthRepository().getToken();

  Future<dynamic> _sendJson(
    String method,
    String path, {
    Map<String, String> extraHeaders = const {},
  }) async {
    final token = await _tokenProvider();
    final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'));
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    extraHeaders.forEach((key, value) => request.headers[key] = value);
    final response =
        await http.Response.fromStream(await _client.send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  /// Latest validated assessment plus owner-safe run-state projections;
  /// null assessment when no run has produced one yet.
  Future<PositionResearchState> latestState(String positionId) async {
    final decoded = await _sendJson(
      'GET',
      '/research/positions/$positionId/latest',
    );
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'research latest: expected an object response');
    }
    ResearchAssessment? assessment;
    final assessmentJson = decoded['latest_assessment'];
    if (assessmentJson != null) {
      if (assessmentJson is! Map<String, dynamic>) {
        throw const FormatException(
            'research latest.latest_assessment: expected an object or null');
      }
      try {
        final payload = assessmentJson['assessment'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(assessmentJson['assessment'] as Map)
            : assessmentJson;
        assessment = ResearchAssessment.fromJson(payload);
      } catch (e1) {
        assessment = ResearchAssessment.fromJson(assessmentJson);
      }
    }
    final runState = decoded['run_state'];
    RunSuccessView? lastSuccess;
    RunAttemptView? latestAttempt;
    if (runState != null) {
      if (runState is! Map<String, dynamic>) {
        throw const FormatException(
            'research latest.run_state: expected an object or null');
      }
      lastSuccess = RunSuccessView.fromWire(runState['last_success']);
      latestAttempt = RunAttemptView.fromWire(runState['latest_attempt']);
    }
    return PositionResearchState(
      positionId: positionId,
      assessment: assessment,
      lastSuccess: lastSuccess,
      latestAttempt: latestAttempt,
    );
  }

  /// Queues a manual research run. The idempotency key is contract-required;
  /// duplicate keys return the persisted run, conflicting payloads a 409.
  Future<ResearchRun> queueRun(
    String positionId, {
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty || idempotencyKey.length > 255) {
      throw ArgumentError.value(
          idempotencyKey, 'idempotencyKey', 'must be 1-255 characters');
    }
    final decoded = await _sendJson(
      'POST',
      '/research/positions/$positionId/runs',
      extraHeaders: {'Idempotency-Key': idempotencyKey},
    );
    if (decoded is! Map<String, dynamic> ||
        decoded['run'] is! Map<String, dynamic>) {
      throw const FormatException(
          'research run queue: expected a {run: ...} response');
    }
    return ResearchRun.fromJson(decoded['run'] as Map<String, dynamic>);
  }

  /// Reads the authoritative current state for a queued run. A 202 queue
  /// response only confirms acceptance; it is not a completed report.
  Future<ResearchRun> getRun(String runId) async {
    final decoded = await _sendJson('GET', '/research/runs/$runId');
    if (decoded is! Map<String, dynamic> ||
        decoded['run'] is! Map<String, dynamic>) {
      throw const FormatException(
          'research run status: expected a {run: ...} response');
    }
    return ResearchRun.fromJson(decoded['run'] as Map<String, dynamic>);
  }

  /// Cancels in-flight requests and releases the client.
  void close() => _client.close();
}

/// Hand-written provider (no codegen — this file is a shared screen file, not
/// a generated-part owner) for the research wire adapter. Overridable in
/// integration tests with an injectable http.Client.
final researchWireProvider = Provider<ResearchWire>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ResearchWire(tokenProvider: auth.getToken);
});

/// H15B: connects the tracked position (H12 editor, H11 repository) and the
/// grounded research panels (H14) into the stock detail flow. The chart slot
/// above is preserved and stays independent — panels render with or without
/// any chart data, never waiting for chart completion.
class _PositionResearchSection extends ConsumerStatefulWidget {
  final StockData stock;
  final bool autoOpenEditor;

  const _PositionResearchSection({
    required this.stock,
    this.autoOpenEditor = false,
  });

  @override
  ConsumerState<_PositionResearchSection> createState() =>
      _PositionResearchSectionState();
}

class _PositionResearchSectionState
    extends ConsumerState<_PositionResearchSection> {
  static final Random _random = Random.secure();
  static const Duration _runPollInterval = Duration(seconds: 3);
  static const int _maxConsecutivePollFailures = 3;

  Position? _position;
  PositionResearchState? _research;
  ResearchRun? _queuedRun;
  bool _loading = true;
  bool _queueing = false;
  bool _autoOpened = false;
  String? _error;
  String? _queueError;
  Timer? _runPollTimer;
  String? _pollingRunId;
  bool _pollInFlight = false;
  int _consecutivePollFailures = 0;
  bool _pollingPaused = false;
  String? _pausedPollingRunId;

  bool get _hasActiveLocalRun =>
      _queuedRun?.status == RunStatus.queued || _queuedRun?.status == RunStatus.running;

  bool get _hasActiveRemoteRun {
    final status = _research?.latestAttempt?.status;
    return status == 'queued' || status == 'running';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(positionRepositoryProvider);
    final researchWire = ref.read(researchWireProvider);
    try {
      final positions = await repository.getPositions();
      final ticker = widget.stock.ticker.toUpperCase();
      final matches = positions
          .where((position) =>
              !position.archived &&
              position.instrument.symbol.toUpperCase() == ticker)
          .toList(growable: false);
      if (matches.length > 1) {
        if (!mounted) return;
        _stopRunPolling();
        setState(() {
          _position = null;
          _research = null;
          _error = 'Position and research state are unavailable: $ticker '
              'matches multiple tracked instruments. Resolve the duplicate '
              'positions before continuing.';
          _loading = false;
        });
        return;
      }
      final match = matches.isEmpty ? null : matches.single;
      PositionResearchState? research;
      if (match != null && mounted) {
        research = await researchWire.latestState(match.id);
      }
      if (!mounted) return;
      setState(() {
        _position = match;
        _research = research;
        _loading = false;
      });
      // A reload can discover a run that this widget did not queue (for
      // example after navigating back to this screen). Poll the authoritative
      // run endpoint so the disabled action is released when it terminates.
      final activeAttempt = research?.latestAttempt;
      if (activeAttempt != null &&
          (activeAttempt.status == 'queued' ||
              activeAttempt.status == 'running')) {
        _startRunPolling(activeAttempt.runId);
      } else if (!_hasActiveLocalRun) {
        _stopRunPolling();
      }
      _maybeAutoOpenEditor();
    } on Object catch (e, st) {
      debugPrint('Failed to load position & research state: $e\n$st');
      if (!mounted) return;
      final String message;
      if (e is ApiException) {
        if (e.statusCode == 401) {
          message = 'Session expired (401). Please log out and back in.';
        } else {
          message = 'Server returned HTTP ${e.statusCode}: ${e.message ?? e.code}';
        }
      } else if (e is FormatException) {
        message = 'Format error: ${e.message}';
      } else {
        message = 'Position and research state could not be loaded ($e)';
      }
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  void _maybeAutoOpenEditor() {
    if (!widget.autoOpenEditor || _autoOpened) return;
    _autoOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      } catch (_) {}
      if (!mounted) return;
      await _openEditor();
    });
  }

  Future<void> _openEditor() async {
    final position = _position;
    final repository = ref.read(positionRepositoryProvider);
    final upperTicker = widget.stock.ticker.toUpperCase();
    final fallbackInstrument = PositionInstrument(
      instrumentId: 'legacy-ticker-$upperTicker',
      symbol: upperTicker,
      exchange: null,
      currency: null,
      providerSymbol: upperTicker,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: AppTheme.obsidian,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: position != null
                        ? PositionEditor.edit(
                            initial: position,
                            // H12 accepted wiring: the editor saves through the real
                            // PositionRepository; it builds {expected_revision, changes}
                            // itself from initial.revision and surfaces 409
                            // REVISION_CONFLICT internally without silent retries.
                            onSave: (write) =>
                                repository.patchPosition(position.id, write),
                            onConflict: () {
                              Navigator.of(sheetContext).pop();
                              if (mounted) _load();
                            },
                            onSaved: (saved) {
                              Navigator.of(sheetContext).pop();
                              if (!mounted) return;
                              setState(() => _position = saved);
                              _load();
                            },
                          )
                        : PositionEditor.create(
                            instrument: fallbackInstrument,
                            onSave: (write) => repository.addPosition(write),
                            onSaved: (saved) {
                              Navigator.of(sheetContext).pop();
                              if (!mounted) return;
                              setState(() => _position = saved);
                              _load();
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _queueRun() async {
    final position = _position;
    if (_queueing || _hasActiveLocalRun || _hasActiveRemoteRun || position == null) {
      return;
    }
    setState(() {
      _queueing = true;
      _queueError = null;
    });
    // One idempotency key per user intent (CONTRACTS §8); locally generated,
    // no shared secret involved.
    final key = 'manual-${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${_randomHex(8)}';
    final researchWire = ref.read(researchWireProvider);
    try {
      final run = await researchWire.queueRun(
        position.id,
        idempotencyKey: key,
      );
      if (!mounted) return;
      setState(() {
        _queuedRun = run;
        _queueing = false;
      });
      _startRunPolling(run.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'RUN_ALREADY_ACTIVE' =>
          'Research is already in progress. The current status is shown below.',
        'IDEMPOTENCY_CONFLICT' =>
          'This research request conflicts with an earlier request. Refresh and try again.',
        _ => 'Research run could not be queued (${error.code}).',
      };
      setState(() {
        _queueError = message;
        _queueing = false;
      });
      if (error.code == 'RUN_ALREADY_ACTIVE') {
        _load();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _queueError = 'Research run could not be queued.';
        _queueing = false;
      });
    }
  }

  void _startRunPolling(String runId, {bool resetFailures = true}) {
    // Do not create a second timer when a reload repeats the same active run.
    if (_pollingRunId == runId &&
        (_runPollTimer?.isActive == true || _pollInFlight)) {
      return;
    }
    _stopRunPolling(clearPausedRun: false);
    _pollingRunId = runId;
    if (resetFailures) {
      _consecutivePollFailures = 0;
      _pollingPaused = false;
      _pausedPollingRunId = null;
    }
    _scheduleRunPoll(runId, _runPollInterval);
  }

  void _scheduleRunPoll(String runId, Duration delay) {
    _runPollTimer?.cancel();
    _runPollTimer = Timer(delay, () => _pollRun(runId));
  }

  void _stopRunPolling({bool clearPausedRun = true}) {
    _runPollTimer?.cancel();
    _runPollTimer = null;
    _pollingRunId = null;
    if (clearPausedRun) {
      _pollingPaused = false;
      _pausedPollingRunId = null;
    }
  }

  Duration _pollBackoffDelay(int consecutiveFailures) {
    // The first retry waits 3s, then 6s, then 12s. The failure cap below
    // prevents a permanently failing endpoint from polling indefinitely.
    return switch (consecutiveFailures) {
      1 => _runPollInterval,
      2 => const Duration(seconds: 6),
      _ => const Duration(seconds: 12),
    };
  }

  void _pausePolling(String runId, String message) {
    _stopRunPolling(clearPausedRun: false);
    _pollingPaused = true;
    _pausedPollingRunId = runId;
    if (mounted) {
      setState(() => _queueError = message);
    }
  }

  void _retryRunPolling() {
    final runId = _pausedPollingRunId ??
        _queuedRun?.id ??
        _research?.latestAttempt?.runId;
    if (runId == null) return;
    setState(() => _queueError = null);
    _startRunPolling(runId);
  }

  Future<void> _pollRun(String runId) async {
    // A slow request cannot overlap with a scheduled retry for the same run.
    if (_pollInFlight || _pollingRunId != runId) return;
    _pollInFlight = true;
    try {
      final run = await ref.read(researchWireProvider).getRun(runId);
      // A reload may have switched to a newer active run while this request
      // was in flight. Ignore the superseded answer instead of letting it
      // cancel or overwrite the newer poller's state.
      if (!mounted || _pollingRunId != runId) return;
      setState(() => _queuedRun = run);
      if (run.status == RunStatus.queued || run.status == RunStatus.running) {
        _consecutivePollFailures = 0;
        _scheduleRunPoll(runId, _runPollInterval);
        return;
      }
      _stopRunPolling();
      await _load();
      // Retain the terminal local run until the next user request. This keeps a
      // failure visible even if the latest-state projection has not caught up
      // to the just-polled terminal status yet.
    } on ApiException catch (error) {
      if (!mounted || _pollingRunId != runId) return;
      switch (error.statusCode) {
        case 401:
          _pausePolling(
            runId,
            'Polling stopped: your session expired (401). Sign in again, then reload.',
          );
          break;
        case 403:
          _pausePolling(
            runId,
            'Polling stopped: access was denied (403). Reload after your permissions are restored.',
          );
          break;
        case 404:
          _pausePolling(
            runId,
            'Polling stopped: this research run was not found (404). Reload to reconcile its status.',
          );
          break;
        default:
          _consecutivePollFailures += 1;
          if (_consecutivePollFailures >= _maxConsecutivePollFailures) {
            _pausePolling(
              runId,
              'Polling stopped after $_maxConsecutivePollFailures failed status checks. Retry status or reload.',
            );
          } else {
            final retryDelay = _pollBackoffDelay(_consecutivePollFailures);
            setState(() {
              _queueError = 'Could not refresh research status (${error.code}). '
                  'Retrying in ${retryDelay.inSeconds}s.';
            });
            _scheduleRunPoll(runId, retryDelay);
          }
          break;
      }
    } on Object {
      if (!mounted || _pollingRunId != runId) return;
      _consecutivePollFailures += 1;
      if (_consecutivePollFailures >= _maxConsecutivePollFailures) {
        _pausePolling(
          runId,
          'Polling stopped after $_maxConsecutivePollFailures failed status checks. Retry status or reload.',
        );
      } else {
        final retryDelay = _pollBackoffDelay(_consecutivePollFailures);
        setState(() {
          _queueError = 'Could not refresh research status. '
              'Retrying in ${retryDelay.inSeconds}s.';
        });
        _scheduleRunPoll(runId, retryDelay);
      }
    } finally {
      _pollInFlight = false;
    }
  }

  @override
  void dispose() {
    _stopRunPolling();
    super.dispose();
  }

  String _randomHex(int bytes) => List.generate(bytes, (_) => _random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POSITION & RESEARCH',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.goldAmber,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          TextButton(
            onPressed: _load,
            child: const Text('RETRY'),
          ),
        ],
      );
    }
    final position = _position;
    if (position == null) {
      // Truthful: a bare ticker is not a resolved instrument identity, so no
      // position is invented here (CONTRACTS §1 — identity comes from a
      // vetted provider resolution).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No tracked position for ${widget.stock.ticker}. Tracked positions '
            'with a resolved instrument identity appear here.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.54)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _openEditor,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.goldAmber,
                side: BorderSide(
                  color: AppTheme.goldAmber.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit position'),
            ),
          ),
        ],
      );
    }
    final research = _research;
    final queueActionBlocked =
        _queueing || _hasActiveLocalRun || _hasActiveRemoteRun;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PositionStateBadge(
          state: position.state,
          archived: position.archived,
        ),
        const SizedBox(height: 8),
        PositionEconomicsLine(position: position),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _openEditor,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.goldAmber,
              side: BorderSide(
                color: AppTheme.goldAmber.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit position'),
          ),
        ),
        const SizedBox(height: 16),
        ResearchPanel(
          assessment: research?.assessment,
          // A queued/running run surfaced honestly; evidence/snapshot views
          // stay plain text (no dead affordances).
          run: _queuedRun,
        ),
        const SizedBox(height: 16),
        ..._runStateRows(research),
        if (_queueError != null) ...[
          const SizedBox(height: 8),
          Text(
            _queueError!,
            style: const TextStyle(color: AppTheme.softCrimson, fontSize: 13),
          ),
          if (_pollingPaused &&
              (_hasActiveLocalRun || _hasActiveRemoteRun))
            TextButton(
              onPressed: _retryRunPolling,
              child: const Text('RETRY STATUS'),
            ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: queueActionBlocked ? null : _queueRun,
            child: _queueing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text((_hasActiveLocalRun || _hasActiveRemoteRun)
                    ? 'RESEARCH IN PROGRESS'
                    : 'RUN RESEARCH'),
          ),
        ),
      ],
    );
  }

  /// Latest attempt versus last success, reported separately (CONTRACTS §8):
  /// an existing success is never rewritten by a later failure, and a failed
  /// attempt never hides the prior report.
  List<Widget> _runStateRows(PositionResearchState? research) {
    const mutedStyle = TextStyle(color: Colors.white54, fontSize: 13);
    const baseStyle = TextStyle(color: Colors.white70, fontSize: 13);
    final success = research?.lastSuccess;
    final attempt = research?.latestAttempt;
    if (success == null && attempt == null) {
      return const [
        Text('No successful research runs yet.', style: mutedStyle),
        SizedBox(height: 4),
        Text('No research attempts recorded yet.', style: mutedStyle),
      ];
    }
    final rows = <Widget>[
      if (success != null)
        Text(
          'Last successful report: ${success.status}'
          '${success.finishedAt == null ? '' : ' · finished ${success.finishedAt}'}',
          style: baseStyle,
        )
      else
        const Text('No successful research runs yet.', style: mutedStyle),
      const SizedBox(height: 4),
      if (attempt != null)
        Text(
          'Latest attempt: ${attempt.status} · stage ${attempt.stage}',
          style: baseStyle,
        )
      else
        const Text('No research attempts recorded yet.', style: mutedStyle),
      if (attempt?.errorCode != null)
        Text(
          'Error: ${attempt!.errorCode}',
          style: const TextStyle(
              color: AppTheme.softCrimson, fontSize: 13),
        ),
    ];
    return rows;
  }
}
