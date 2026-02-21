import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../stock/stock_repository.dart';

class MarketNexusScreen extends ConsumerWidget {
  const MarketNexusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x11FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _NexusHeader(),
            _NexusToolbar(),
            stocksAsync.when(
              data: (stocks) => _NexusList(stocks: stocks),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _NexusHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Market Nexus',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/manage-watchlist'),
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.goldAmber),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _NexusToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 15,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Search Assets...',
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GlassCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 15,
              child: const Icon(Icons.filter_list_rounded, color: AppTheme.goldAmber, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _NexusList extends StatelessWidget {
  final List<StockData> stocks;
  const _NexusList({required this.stocks});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stock = stocks[index];
          return _NexusCard(stock: stock);
        },
        childCount: stocks.length,
      ),
    );
  }
}

class _NexusCard extends StatelessWidget {
  final StockData stock;
  const _NexusCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock.changePercent > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/stock/${stock.ticker}'),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.ticker,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        stock.name,
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${stock.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${stock.changePercent > 0 ? "+" : ""}${stock.changePercent}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: _NexusSparkline(data: stock.history, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NexusSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _NexusSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    
    // Add 10% padding to the range to make the chart look tactical and not hit the edges
    final padding = range == 0 ? 1.0 : range * 0.1;

    return LineChart(
      LineChartData(
        minY: minVal - padding,
        maxY: maxVal + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.1),
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
