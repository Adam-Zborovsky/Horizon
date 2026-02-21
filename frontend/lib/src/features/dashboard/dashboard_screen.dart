import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../briefing/briefing_repository.dart';
import '../stock/stock_repository.dart';
import '../briefing/briefing_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
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
            _WarRoomHeader(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: briefingAsync.when(
                  data: (briefing) => _DailyBriefingSummary(briefing: briefing),
                  loading: () => const _ShimmerCard(height: 200),
                  error: (err, stack) => Center(child: Text('Error loading briefing: $err')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            _SectionHeader(title: 'Intelligence Pillars'),
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            briefingAsync.when(
              data: (briefing) => _IntelPillarsGrid(briefing: briefing),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            _SectionHeader(title: 'Market Nexus'),
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            stocksAsync.when(
              data: (stocks) => _MarketNexusList(stocks: stocks),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }
}

class _WarRoomHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'War Room',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 20, left: 10),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.glassWhite,
            child: Icon(Icons.person_outline_rounded, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.goldAmber.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _DailyBriefingSummary extends StatelessWidget {
  final BriefingData briefing;
  const _DailyBriefingSummary({required this.briefing});

  @override
  Widget build(BuildContext context) {
    final summary = briefing.data.values.first.summary;
    final score = briefing.data.values.first.sentimentScore;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  Text('Tactical Overview', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              _SentimentRing(score: (score + 1) / 2),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.goldAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAmber.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Full Intelligence Report',
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
          ),
        ],
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
  const _IntelPillarsGrid({required this.briefing});

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
            return _IntelCard(name: catName, score: catData.sentimentScore);
          },
          childCount: categories.length > 4 ? 4 : categories.length,
        ),
      ),
    );
  }
}

class _IntelCard extends StatelessWidget {
  final String name;
  final double score;
  const _IntelCard({required this.name, required this.score});

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
              name.contains('Semi') ? Icons.memory : Icons.public,
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
                  widthFactor: (score + 1) / 2,
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
                    Column(
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
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      width: 70,
                      child: _MiniSparkline(
                        data: stock.history, 
                        color: stock.changePercent > 0 ? AppTheme.goldAmber : AppTheme.softCrimson
                      ),
                    ),
                    const SizedBox(width: 20),
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
                          '${stock.changePercent > 0 ? "+" : ""}${stock.changePercent}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: stock.changePercent > 0 ? AppTheme.goldAmber : AppTheme.softCrimson,
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
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
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
