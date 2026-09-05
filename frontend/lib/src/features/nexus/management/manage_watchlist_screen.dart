import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/dashboard/watchlist_provider.dart';
import 'package:horizon/src/features/stock/stock_search_provider.dart';

class ManageWatchlistScreen extends ConsumerStatefulWidget {
  const ManageWatchlistScreen({super.key});

  @override
  ConsumerState<ManageWatchlistScreen> createState() =>
      _ManageWatchlistScreenState();
}

class _ManageWatchlistScreenState extends ConsumerState<ManageWatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.toUpperCase();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(stockSearchProvider.notifier).search(query);
      }
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
            onSubmitted: (val) async {
              if (val.isNotEmpty) {
                await ref.read(watchlistProvider.notifier).add(val);
                _searchController.clear();
              }
            },
          ),

          // Search Suggestions (Autocomplete)
          if (_searchQuery.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'RECOMMENDATIONS',
                  style: TextStyle(
                    color: AppTheme.goldAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                final searchResults = ref.watch(stockSearchProvider);

                return searchResults.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(watchlistProvider.notifier)
                                  .add(_searchQuery);
                              _searchController.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.glassWhite.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.goldAmber.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _searchQuery,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'No matches found. Tap to add anyway.',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppTheme.goldAmber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final result = results[index];
                        final isAdded = watchlist.contains(result.symbol);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          child: GestureDetector(
                            onTap: isAdded
                                ? null
                                : () async {
                                    await ref
                                        .read(watchlistProvider.notifier)
                                        .add(result.symbol);
                                    _searchController.clear();
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.glassWhite.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.symbol,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          result.name,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAdded)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  else
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: AppTheme.goldAmber,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: results.length),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.goldAmber,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: AppTheme.softCrimson),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: Divider(
                color: Colors.white10,
                indent: 24,
                endIndent: 24,
                height: 40,
              ),
            ),
          ],

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
                child: Text(
                  'No stocks in watchlist',
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final ticker = watchlist.toList()[index];

                return _WatchlistItem(
                  ticker: ticker,
                  name: ticker,
                  onRemove: () async =>
                      await ref.read(watchlistProvider.notifier).remove(ticker),
                );
              }, childCount: watchlist.length),
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

  const _SliverSearchHeader({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100, // Reduced from 140
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: GlassCard(
        borderRadius: 0,
        blur: 20,
        padding: const EdgeInsets.only(
          top: 40,
          left: 24,
          right: 24,
          bottom: 10,
        ),
        color: AppTheme.obsidian.withValues(alpha: 0.7),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
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
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  border: InputBorder.none,
                  suffixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.goldAmber.withValues(alpha: 0.5),
                  ),
                ),
              ),
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

  const _WatchlistItem({
    required this.ticker,
    required this.name,
    required this.onRemove,
  });

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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppTheme.softCrimson,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
