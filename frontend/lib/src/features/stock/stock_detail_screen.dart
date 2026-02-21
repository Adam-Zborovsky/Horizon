import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../stock/stock_repository.dart';

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

class _DetailContent extends StatelessWidget {
  final StockData stock;
  const _DetailContent({required this.stock});

  @override
  Widget build(BuildContext context) {
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
                        '${stock.changePercent > 0 ? "+" : ""}${stock.changePercent}%',
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
                        stock.analysis ?? "No AI analysis available for this ticker today.",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'MACRO DRIVERS',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.goldAmber,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _MacroItem(title: 'Memory Wall Bottleneck', description: 'Primary bottleneck for AI scaling.'),
                _MacroItem(title: 'Sovereign AI Pivot', description: 'Nations prioritizing hardware ownership.'),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final String ticker;
  const _DetailHeader({required this.ticker});

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.star_outline_rounded, color: Colors.white38),
          onPressed: () {},
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
        '${score > 0 ? "+" : ""}$score SNT',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String title;
  final String description;
  const _MacroItem({required this.title, required this.description});

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
                color: AppTheme.goldAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_outlined, color: AppTheme.goldAmber, size: 18),
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
