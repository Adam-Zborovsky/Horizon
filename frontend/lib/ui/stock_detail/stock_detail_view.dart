import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';

class StockDetailView extends ConsumerWidget {
  final String ticker;
  const StockDetailView({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          ticker.toUpperCase(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded, color: Colors.amber),
            onPressed: () {},
          ),
        ],
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final stock = briefing.values
              .expand((cat) => cat.items)
              .firstWhere((item) => item.ticker == ticker, orElse: () => const BriefingItem());
          if (stock.ticker == null) return const Center(child: Text('Stock not found'));
          return RefreshIndicator(
            onRefresh: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
            backgroundColor: AppTheme.cardBg,
            color: AppTheme.neutralBlue,
            child: _StockDetailContent(stock: stock),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neutralBlue),
              SizedBox(height: 16),
              Text('PROBING TICKER DATA...', style: TextStyle(letterSpacing: 1.5, fontSize: 10, color: AppTheme.textDim)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.negativeRed, size: 48),
              const SizedBox(height: 16),
              Text('COMMUNICATION ERROR: $err', style: const TextStyle(color: AppTheme.negativeRed)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBg),
                child: const Text('RETRY UPLINK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockDetailContent extends StatelessWidget {
  final BriefingItem stock;
  const _StockDetailContent({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isPositive = (stock.change ?? 0) >= 0;
    final color = isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _PriceHeader(stock: stock, color: color),
        const SizedBox(height: 24),
        _AIIntelligenceCard(stock: stock, color: color),
        const SizedBox(height: 24),
        const _KeyStatisticsGrid(),
        const SizedBox(height: 32),
        _SentimentChartSection(color: color),
        const SizedBox(height: 32),
        _RelatedIntelligenceFeed(ticker: stock.ticker!),
      ],
    );
  }
}

class _PriceHeader extends StatelessWidget {
  final BriefingItem stock;
  final Color color;
  const _PriceHeader({required this.stock, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          stock.name ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textDim),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$${stock.price?.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(stock.change ?? 0) >= 0 ? '+' : ''}${stock.change}%',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AIIntelligenceCard extends StatelessWidget {
  final BriefingItem stock;
  final Color color;
  const _AIIntelligenceCard({required this.stock, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(stock.sentiment ?? 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI SIGNAL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.neutralBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  'SENTIMENT: ${stock.sentiment ?? 0.0}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stock.analysis ?? 'AI is currently processing latest market signals for this asset. No critical deviations detected from baseline trend.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _KeyStatisticsGrid extends StatelessWidget {
  const _KeyStatisticsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: const [
        _StatItem(label: 'MARKET CAP', value: '\$1.22T'),
        _StatItem(label: 'P/E RATIO', value: '32.4'),
        _StatItem(label: '52W HIGH', value: '\$823.10'),
        _StatItem(label: 'DIV YIELD', value: '1.2%'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SentimentChartSection extends StatelessWidget {
  final Color color;
  const _SentimentChartSection({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SENTIMENT TREND (30D)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textDim),
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 0.5),
                    FlSpot(5, 0.6),
                    FlSpot(10, 0.55),
                    FlSpot(15, 0.8),
                    FlSpot(20, 0.75),
                    FlSpot(25, 0.9),
                    FlSpot(30, 0.85),
                  ],
                  isCurved: true,
                  color: color,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedIntelligenceFeed extends StatelessWidget {
  final String ticker;
  const _RelatedIntelligenceFeed({required this.ticker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATED INTELLIGENCE',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textDim),
        ),
        const SizedBox(height: 16),
        _NewsListItem(title: 'Blackwell chip demand spikes', source: 'Bloomberg', time: '2h ago', sentiment: AppTheme.positiveGreen),
        _NewsListItem(title: 'NVDA leads semiconductor surge', source: 'Reuters', time: '4h ago', sentiment: AppTheme.positiveGreen),
        _NewsListItem(title: 'Analysts revise targets upward', source: 'FT', time: '6h ago', sentiment: AppTheme.neutralBlue),
      ],
    );
  }
}

class _NewsListItem extends StatelessWidget {
  final String title;
  final String source;
  final String time;
  final Color sentiment;
  const _NewsListItem({required this.title, required this.source, required this.time, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/intelligence-feed'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: sentiment, shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$source • $time', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
