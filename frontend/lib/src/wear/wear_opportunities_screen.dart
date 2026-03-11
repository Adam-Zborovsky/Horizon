import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/stock/stock_repository.dart';
import 'wear_glass_card.dart';
import 'wear_rotary_scroll.dart';

class WearOpportunitiesScreen extends StatefulWidget {
  final List<StockData> stocks;
  const WearOpportunitiesScreen({super.key, required this.stocks});

  @override
  State<WearOpportunitiesScreen> createState() => _WearOpportunitiesScreenState();
}

class _WearOpportunitiesScreenState extends State<WearOpportunitiesScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final stocks = widget.stocks;

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0x11FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: stocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: Colors.white.withOpacity(0.1), size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'No alpha signals',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3), fontSize: 11),
                      ),
                    ],
                  ),
                )
              : WearRotaryScroll(
                  controller: _scrollController,
                  child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: 8,
                  ),
                  itemCount: stocks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8, top: 4),
                        child: Center(
                          child: Text(
                            'ALPHA SIGNALS',
                            style: TextStyle(
                              color: AppTheme.goldAmber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      );
                    }

                    final stock = stocks[index - 1];
                    final isLong = stock.direction?.toLowerCase() == 'long';
                    final directionColor =
                        isLong ? AppTheme.goldAmber : AppTheme.softCrimson;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: WearGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stock.ticker,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: directionColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: directionColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    stock.direction?.toUpperCase() ?? 'ALPHA',
                                    style: TextStyle(
                                      color: directionColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${stock.currentPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (stock.analysis != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                stock.analysis ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 9,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (stock.horizon != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                stock.horizon!,
                                style: TextStyle(
                                  color: AppTheme.goldAmber.withOpacity(0.5),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ),
        ),
      ),
    );
  }
}
