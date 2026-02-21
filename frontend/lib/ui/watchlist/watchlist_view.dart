import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';

class WatchlistView extends ConsumerWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'WATCHLIST',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final stocks = briefing.values
              .expand((cat) => cat.items)
              .where((item) => item.ticker != null)
              .toList();
          final topics = briefing.keys.toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
            backgroundColor: AppTheme.cardBg,
            color: AppTheme.neutralBlue,
            child: _WatchlistContent(stocks: stocks, topics: topics),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neutralBlue),
              SizedBox(height: 16),
              Text('MONITORING PULSE...', style: TextStyle(letterSpacing: 1.5, fontSize: 10, color: AppTheme.textDim)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off_rounded, color: AppTheme.negativeRed, size: 48),
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

class _WatchlistContent extends StatelessWidget {
  final List<BriefingItem> stocks;
  final List<String> topics;
  const _WatchlistContent({required this.stocks, required this.topics});

  @override
  Widget build(BuildContext context) {
    final avgSentiment = stocks.isEmpty 
        ? 0.0 
        : stocks.fold(0.0, (sum, item) => sum + (item.sentiment ?? 0.0)) / stocks.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _SentimentPulseHeader(avgSentiment: avgSentiment),
        const SizedBox(height: 32),
        Text(
          'TICKERS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.textDim,
          ),
        ),
        const SizedBox(height: 16),
        ...stocks.map((stock) => _StockListItem(stock: stock)),
        const SizedBox(height: 32),
        Text(
          'INTELLIGENCE TOPICS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.textDim,
          ),
        ),
        const SizedBox(height: 16),
        ...topics.map((topic) => _TopicListItem(topic: topic)),
      ],
    );
  }
}

class _SentimentPulseHeader extends StatelessWidget {
  final double avgSentiment;
  const _SentimentPulseHeader({required this.avgSentiment});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(avgSentiment);
    final sentimentText = avgSentiment > 0.3 ? 'Bullish' : (avgSentiment < -0.3 ? 'Bearish' : 'Neutral');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            AppTheme.neutralBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SENTIMENT PULSE',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
              Icon(Icons.show_chart_rounded, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Overall watchlist sentiment is $sentimentText (${avgSentiment.toStringAsFixed(2)}). Major drivers are currently identified within technical sectors and geopolitical shifts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StockListItem extends StatelessWidget {
  final BriefingItem stock;
  const _StockListItem({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isPositive = (stock.change ?? 0) >= 0;
    final color = isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/stock/${stock.ticker}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.ticker ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(stock.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 25,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 1),
                            FlSpot(1, 1.2),
                            FlSpot(2, 1.1),
                            FlSpot(3, 1.8),
                            FlSpot(4, 1.6),
                            FlSpot(5, 2.0),
                          ],
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${stock.price?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${isPositive ? '+' : ''}${stock.change}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicListItem extends StatelessWidget {
  final String topic;
  const _TopicListItem({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/intelligence/$topic'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.topic_rounded, color: AppTheme.neutralBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Last update: 12m ago', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
