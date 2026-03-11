import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/stock/stock_repository.dart';
import 'wear_glass_card.dart';
import 'wear_rotary_scroll.dart';

class WearWatchlistScreen extends StatefulWidget {
  final List<StockData> stocks;
  const WearWatchlistScreen({super.key, required this.stocks});

  @override
  State<WearWatchlistScreen> createState() => _WearWatchlistScreenState();
}

class _WearWatchlistScreenState extends State<WearWatchlistScreen> {
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x11FFB800), AppTheme.obsidian],
          ),
        ),
        child: SafeArea(
          child: stocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart_rounded,
                          color: Colors.white.withOpacity(0.1), size: 28),
                      const SizedBox(height: 8),
                      Text('No stocks in watchlist',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    ],
                  ),
                )
              : WearRotaryScroll(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.08, vertical: 8),
                    itemCount: stocks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 8, top: 4),
                          child: Center(
                            child: Text('WATCHLIST',
                                style: TextStyle(color: AppTheme.goldAmber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ),
                        );
                      }

                      final stock = stocks[index - 1];
                      final color = stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: WearGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stock.ticker,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    Text(stock.name,
                                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${stock.currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(1)}%',
                                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
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
