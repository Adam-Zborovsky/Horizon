import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/dashboard/watchlist_provider.dart';

class ManageWatchlistScreen extends ConsumerStatefulWidget {
  const ManageWatchlistScreen({super.key});

  @override
  ConsumerState<ManageWatchlistScreen> createState() => _ManageWatchlistScreenState();
}

class _ManageWatchlistScreenState extends ConsumerState<ManageWatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Simulated available stocks for autocomplete
  final List<Map<String, String>> _allAvailableStocks = [
    {'ticker': 'AAPL', 'name': 'Apple Inc.'},
    {'ticker': 'MSFT', 'name': 'Microsoft Corporation'},
    {'ticker': 'GOOGL', 'name': 'Alphabet Inc.'},
    {'ticker': 'AMZN', 'name': 'Amazon.com, Inc.'},
    {'ticker': 'TSLA', 'name': 'Tesla, Inc.'},
    {'ticker': 'NVDA', 'name': 'NVIDIA Corporation'},
    {'ticker': 'AMD', 'name': 'Advanced Micro Devices, Inc.'},
    {'ticker': 'MU', 'name': 'Micron Technology, Inc.'},
    {'ticker': 'INTC', 'name': 'Intel Corporation'},
    {'ticker': 'TSM', 'name': 'Taiwan Semiconductor Manufacturing'},
    {'ticker': 'META', 'name': 'Meta Platforms, Inc.'},
    {'ticker': 'NFLX', 'name': 'Netflix, Inc.'},
    {'ticker': 'ASML', 'name': 'ASML Holding N.V.'},
    {'ticker': 'AVGO', 'name': 'Broadcom Inc.'},
    {'ticker': 'ARM', 'name': 'Arm Holdings plc'},
    {'ticker': 'PLTR', 'name': 'Palantir Technologies Inc.'},
  ];

  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toUpperCase();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _searchResults = _allAvailableStocks.where((stock) {
        return stock['ticker']!.contains(query) || 
               stock['name']!.toUpperCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          _SliverSearchHeader(
            controller: _searchController,
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                ref.read(watchlistProvider.notifier).add(val);
                _searchController.clear();
              }
            },
          ),
          if (_searchResults.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stock = _searchResults[index];
                    final isAdded = watchlist.contains(stock['ticker']!);
                    
                    return GestureDetector(
                      onTap: () {
                        if (!isAdded) {
                          ref.read(watchlistProvider.notifier).add(stock['ticker']!);
                          _searchController.clear();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isAdded ? AppTheme.goldAmber.withOpacity(0.3) : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock['ticker']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(stock['name']!, style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              color: isAdded ? AppTheme.goldAmber : Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ACTIVE WATCHLIST',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          if (watchlist.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No stocks in watchlist', style: TextStyle(color: Colors.white24)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ticker = watchlist.toList()[index];
                  // Try to find full name from our list or fallback to ticker
                  final stockInfo = _allAvailableStocks.firstWhere(
                    (s) => s['ticker'] == ticker,
                    orElse: () => {'ticker': ticker, 'name': 'Market Asset'},
                  );
                  
                  return _WatchlistItem(
                    ticker: ticker,
                    name: stockInfo['name']!,
                    onRemove: () => ref.read(watchlistProvider.notifier).remove(ticker),
                  );
                },
                childCount: watchlist.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SliverSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const _SliverSearchHeader({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      collapsedHeight: 100,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: GlassCard(
        borderRadius: 0,
        blur: 20,
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 10),
        color: AppTheme.obsidian.withOpacity(0.7),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'SEARCH TICKERS...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14, letterSpacing: 1),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search_rounded, color: AppTheme.goldAmber.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  final String ticker;
  final String name;
  final VoidCallback onRemove;

  const _WatchlistItem({required this.ticker, required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat'),
                ),
                Text(
                  name,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.softCrimson, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
