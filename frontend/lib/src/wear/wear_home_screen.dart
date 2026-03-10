import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/briefing/briefing_repository.dart';
import '../features/stock/stock_repository.dart';
import 'wear_glass_card.dart';
import 'wear_watchlist_screen.dart';
import 'wear_opportunities_screen.dart';
import 'wear_intel_screen.dart';

class WearHomeScreen extends ConsumerWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.8,
            colors: [
              Color(0x11FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 8,
            ),
            children: [
              // Title
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'HORIZON',
                    style: TextStyle(
                      color: AppTheme.goldAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),

              // Daily Analysis Card
              briefingAsync.when(
                data: (briefing) {
                  if (briefing.data.isEmpty) {
                    return const WearGlassCard(
                      child: Center(
                        child: Text(
                          'No reports yet',
                          style: TextStyle(color: Colors.white24, fontSize: 11),
                        ),
                      ),
                    );
                  }

                  // Find first category with meaningful summary
                  String categoryName = briefing.data.keys.first;
                  final category = briefing.data.values.first;
                  final itemCount = briefing.data.values
                      .fold<int>(0, (sum, c) => sum + c.items.length);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WearIntelScreen(briefing: briefing),
                      ),
                    ),
                    child: WearGlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.goldAmber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Daily Analysis',
                                style: TextStyle(
                                  color: AppTheme.goldAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.summary.isNotEmpty
                                ? category.summary
                                : '$itemCount intelligence items',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const WearGlassCard(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: AppTheme.goldAmber,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const WearGlassCard(
                  child: Center(
                    child: Icon(Icons.error_outline, color: AppTheme.softCrimson, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Quick action row
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.show_chart_rounded,
                      label: 'Watchlist',
                      onTap: () {
                        final stocks = stocksAsync.value ?? [];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WearWatchlistScreen(
                              stocks: stocks
                                  .where((s) => s.source == StockSource.watchlist)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.bolt_rounded,
                      label: 'Alpha',
                      color: AppTheme.goldAmber,
                      onTap: () {
                        final stocks = stocksAsync.value ?? [];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WearOpportunitiesScreen(
                              stocks: stocks
                                  .where((s) => s.source == StockSource.opportunity)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Top movers preview
              stocksAsync.when(
                data: (stocks) {
                  final watchlist = stocks
                      .where((s) => s.source == StockSource.watchlist)
                      .toList();
                  if (watchlist.isEmpty) return const SizedBox.shrink();

                  // Show top 3
                  final top = watchlist.take(3).toList();
                  return WearGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      children: [
                        for (int i = 0; i < top.length; i++) ...[
                          _MiniStockRow(stock: top[i]),
                          if (i < top.length - 1)
                            Divider(
                              color: Colors.white.withOpacity(0.05),
                              height: 8,
                            ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WearGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStockRow extends StatelessWidget {
  final StockData stock;
  const _MiniStockRow({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stock.ticker,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            '\$${stock.currentPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
