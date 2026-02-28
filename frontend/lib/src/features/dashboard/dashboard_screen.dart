import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../briefing/briefing_repository.dart';
import '../stock/stock_repository.dart';
import '../briefing/briefing_model.dart';
import '../onboarding/onboarding_wrapper.dart';
import '../onboarding/tutorial_keys.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return OnboardingWrapper(
      step: OnboardingStep.dashboard,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                Color(0x11FFB800),
                AppTheme.obsidian,
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _WarRoomHeader(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: briefingAsync.when(
                    data: (briefing) => _DailyBriefingSummary(
                      key: TutorialKeys.dashBriefing,
                      briefing: briefing,
                    ),
                    loading: () => const _ShimmerCard(height: 200),
                    error: (err, stack) => _ErrorWidget(error: err.toString()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Intelligence Pillars',
                    onTap: () => context.go('/vault'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              briefingAsync.when(
                data: (briefing) => _IntelPillarsGrid(
                  key: TutorialKeys.dashPillars,
                  briefing: briefing,
                ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Market Nexus',
                    onTap: () => context.go('/nexus'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              stocksAsync.when(
                data: (stocks) => _MarketNexusList(stocks: stocks),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Stock error: $err', style: const TextStyle(color: Colors.white24)))),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.softCrimson, size: 32),
          const SizedBox(height: 12),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.softCrimson),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ProviderScope.containerOf(context).invalidate(briefingRepositoryProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _WarRoomHeader extends StatelessWidget {
  const _WarRoomHeader();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      collapsedHeight: 60,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: Text(
        'War Room',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20, left: 10),
          child: GestureDetector(
            key: TutorialKeys.navProfile,
            onTap: () => context.push('/profile'),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.glassWhite,
              child: Icon(Icons.person_outline_rounded, color: Colors.white70, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyBriefingSummary extends StatelessWidget {
  final BriefingData briefing;
  const _DailyBriefingSummary({super.key, required this.briefing});

  @override
  Widget build(BuildContext context) {
    if (briefing.data.isEmpty) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('No reports available yet.', style: TextStyle(color: Colors.white24)),
          ),
        ),
      );
    }

    String? categoryName;
    CategoryData? category;
    
    for (var entry in briefing.data.entries) {
      if (entry.value.summary.isNotEmpty && entry.value.summary != 'Direct item list' && entry.value.summary != 'Strategic news analysis for ${entry.key}.') {
        categoryName = entry.key;
        category = entry.value;
        break;
      }
    }
    
    categoryName ??= briefing.data.keys.first;
    category ??= briefing.data.values.first;

    final summary = category.summary;
    final score = category.sentimentScore;

    return GestureDetector(
      onTap: () => context.push('/vault?category=${Uri.encodeComponent(categoryName!)}'),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Analysis',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.goldAmber,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryName, 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _SentimentRing(score: (score + 1) / 2),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              summary.isEmpty ? 'Tap to view latest intelligence reports.' : summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Read Full Report',
                  style: TextStyle(
                    color: AppTheme.goldAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.north_east_rounded, size: 14, color: AppTheme.goldAmber),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SentimentRing extends StatelessWidget {
  final double score;
  const _SentimentRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score,
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(AppTheme.goldAmber),
          ),
          Text(
            '${(score * 10).toInt()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldAmber,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelPillarsGrid extends StatelessWidget {
  final BriefingData briefing;
  const _IntelPillarsGrid({super.key, required this.briefing});

  @override
  Widget build(BuildContext context) {
    final categories = briefing.data.keys.toList();
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final catName = categories[index];
            final catData = briefing.data[catName]!;
            return GestureDetector(
              onTap: () => context.go('/vault?category=${Uri.encodeComponent(catName)}'),
              child: _IntelCard(name: catName, score: catData.sentimentScore),
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }
}

class _IntelCard extends StatelessWidget {
  final String name;
  final double score;
  const _IntelCard({required this.name, required this.score});

  static IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('market') || n.contains('analysis')) return Icons.candlestick_chart_rounded;
    if (n.contains('opportunit') || n.contains('divergent')) return Icons.bolt_rounded;
    if (n.contains('defense') || n.contains('military')) return Icons.shield_outlined;
    if (n.contains('ai') || n.contains('cyber') || n.contains('tech')) return Icons.memory;
    if (n.contains('geo') || n.contains('diplom')) return Icons.public;
    if (n.contains('econom') || n.contains('trade') || n.contains('infra')) return Icons.account_balance_outlined;
    if (n.contains('energy') || n.contains('nuclear')) return Icons.flash_on_rounded;
    if (n.contains('health') || n.contains('social') || n.contains('cultur')) return Icons.groups_outlined;
    return Icons.hub_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = score > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(name),
              color: color,
              size: 18,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((score + 1) / 2).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.4), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${score > 0 ? "+" : ""}${score.toStringAsFixed(1)} SNT',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketNexusList extends StatelessWidget {
  final List<StockData> stocks;
  const _MarketNexusList({required this.stocks});

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => context.push('/manage-watchlist'),
            child: GlassCard(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.add_chart_rounded, color: Colors.white10, size: 32),
                  const SizedBox(height: 12),
                  const Text('No stocks added', style: TextStyle(color: Colors.white24)),
                  const SizedBox(height: 8),
                  Text('Tap to add stocks', style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stock = stocks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GestureDetector(
              onTap: () => context.push('/stock/${stock.ticker}'),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.ticker,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            stock.name,
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 30,
                        child: _MiniSparkline(
                          data: stock.history, 
                          color: stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${stock.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: stocks.length,
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _MiniSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final padding = range == 0 ? 1.0 : range * 0.1;

    return LineChart(
      LineChartData(
        minY: minVal - padding,
        maxY: maxVal + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
