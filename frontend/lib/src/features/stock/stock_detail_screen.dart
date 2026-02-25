import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../stock/stock_repository.dart';
import '../dashboard/watchlist_provider.dart';

class StockDetailScreen extends ConsumerWidget {
  final String ticker;
  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      body: stocksAsync.when(
        data: (stocks) {
          final stock = stocks.firstWhere((s) => s.ticker == ticker);
          return _DetailContent(stock: stock);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final StockData stock;
  const _DetailContent({required this.stock});

  String? _getDisplayString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value.values.where((v) => v is String).join('\n');
    return value.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = stock.changePercent > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

    return CustomScrollView(
      slivers: [
        _DetailHeader(ticker: stock.ticker),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${stock.currentPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.2)),
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
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: _MainChart(data: stock.history, color: color),
                ),
                const SizedBox(height: 40),
                Text(
                  'AI STRATEGIC SIGNAL',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.goldAmber,
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
                            'Strategic Position',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          _SentimentPill(score: stock.sentiment),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getDisplayString(stock.analysis) ?? "No AI analysis available for this ticker today.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/vault?category=${Uri.encodeComponent('Market Analysis')}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.goldAmber,
                          side: BorderSide(color: AppTheme.goldAmber.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('VIEW MARKET ANALYSIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      if (stock.potentialPriceAction != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'EXPECTED ACTION',
                          style: TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDisplayString(stock.potentialPriceAction)!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
                  ...stock.catalysts!.map((c) => _MacroItem(title: 'Bullish Driver', description: c, icon: Icons.trending_up_rounded)),
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
                  ...stock.risks!.map((r) => _MacroItem(title: 'Risk Factor', description: r, icon: Icons.warning_amber_rounded, color: AppTheme.softCrimson)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
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
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(ticker, style: Theme.of(context).textTheme.displaySmall),
      actions: [
        IconButton(
          icon: Icon(
            isInWatchlist ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isInWatchlist ? AppTheme.goldAmber : Colors.white38,
          ),
          onPressed: () {
            if (isInWatchlist) {
              ref.read(watchlistProvider.notifier).remove(ticker);
            } else {
              ref.read(watchlistProvider.notifier).add(ticker);
            }
          },
        ),
      ],
    );
  }
}

class _MainChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _MainChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    
    // Add 15% padding to the range to make the chart look tactical and not hit the edges
    final padding = range == 0 ? 1.0 : range * 0.15;

    return LineChart(
      LineChartData(
        minY: minVal - padding,
        maxY: maxVal + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '\$${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '${score > 0 ? "+" : ""}${score.toStringAsFixed(1)} SNT',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
