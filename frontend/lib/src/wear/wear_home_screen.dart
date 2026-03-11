import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../core/theme/app_theme.dart';
import '../features/briefing/briefing_repository.dart';
import '../features/stock/stock_repository.dart';
import 'wear_glass_card.dart';
import 'wear_rotary_scroll.dart';
import 'wear_watchlist_screen.dart';
import 'wear_opportunities_screen.dart';
import 'wear_intel_screen.dart';
import 'wear_refresh_bottom.dart';

class WearHomeScreen extends ConsumerStatefulWidget {
  const WearHomeScreen({super.key});

  @override
  ConsumerState<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends ConsumerState<WearHomeScreen> {
  final _scrollController = ScrollController();
  
  Completer<void>? _refreshCompleter;
  bool _isActuallyRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted && !_isActuallyRefreshing) {
      final pos = _scrollController.position;
      if (pos.pixels < pos.maxScrollExtent - 10) {
        _refreshCompleter?.complete();
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _onPullToLock() async {
    _refreshCompleter = Completer<void>();
    HapticFeedback.lightImpact();
    return _refreshCompleter!.future;
  }

  /// Trigger the entire backend AI workflow and poll for completion
  Future<void> _performManualRefresh() async {
    if (_isActuallyRefreshing) return;
    
    setState(() => _isActuallyRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      final briefingRepo = ref.read(briefingRepositoryProvider.notifier);
      
      // 1. Trigger the actual AI Agents workflow on the backend
      await briefingRepo.triggerBriefing();
      
      // 2. Poll for completion (Wait for agents to save new data)
      // We check every 5 seconds for up to 2 minutes
      bool completed = false;
      int attempts = 0;
      final startTime = DateTime.now();

      while (!completed && attempts < 24) {
        await Future.delayed(const Duration(seconds: 5));
        attempts++;

        // Fetch latest data to see if timestamp updated
        final briefing = await ref.refresh(briefingRepositoryProvider.future);
        
        if (briefing.createdAt != null && briefing.createdAt!.isAfter(startTime)) {
          completed = true;
        }
      }

      if (completed) {
        // 3. Refresh the stock repository once briefing is done
        ref.invalidate(stockRepositoryProvider);
        await ref.read(stockRepositoryProvider.future);
        
        if (mounted) {
          HapticFeedback.heavyImpact(); // Success signal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Intelligence Updated'), duration: Duration(seconds: 2)),
          );
        }
      } else {
        throw Exception('Timed out waiting for agents');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow failed'), duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter?.complete();
      }
      _refreshCompleter = null;
      if (mounted) setState(() => _isActuallyRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);
    final size = MediaQuery.of(context).size;
    final pad = size.width * 0.08;
    const double indicatorHeight = 85.0;

    return Scaffold(
      backgroundColor: AppTheme.charcoalBlack,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1C),
              Color(0xFF080808),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.4,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 1.2,
                height: size.height * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.goldAmber.withOpacity(0.08),
                      AppTheme.goldAmber.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: stocksAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppTheme.goldAmber, strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.softCrimson, size: 20),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(stockRepositoryProvider);
                          ref.invalidate(briefingRepositoryProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldAmber.withOpacity(0.1),
                        ),
                        child: const Text('RETRY', style: TextStyle(color: AppTheme.goldAmber, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                data: (allStocks) {
                  final watchlist = allStocks.where((s) => s.source == StockSource.watchlist).toList();
                  final opportunities = allStocks.where((s) => s.source == StockSource.opportunity).toList();

                  return CustomRefreshIndicator(
                    onRefresh: _onPullToLock,
                    trigger: IndicatorTrigger.trailingEdge,
                    offsetToArmed: 30.0,
                    builder: (context, child, controller) {
                      return AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) {
                          final bool isTrailing = controller.side == IndicatorSide.bottom;
                          final dy = isTrailing ? (controller.value * -indicatorHeight) : 0.0;

                          return Stack(
                            children: [
                              if (isTrailing)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: indicatorHeight,
                                  child: WearRefreshIndicator(
                                    controller: controller,
                                    height: indicatorHeight,
                                    onTap: _performManualRefresh,
                                    isActuallyLoading: _isActuallyRefreshing,
                                  ),
                                ),
                              Transform.translate(
                                offset: Offset(0, dy),
                                child: Container(
                                  color: Colors.transparent,
                                  child: child,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: WearRotaryScroll(
                      controller: _scrollController,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(pad, 10, pad, 14),
                              child: const Center(
                                child: Text(
                                  'HORIZON',
                                  style: TextStyle(
                                    color: AppTheme.goldAmber,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              child: briefingAsync.when(
                                data: (briefing) {
                                  if (briefing.data.isEmpty) return const SizedBox.shrink();
                                  final categories = briefing.data.entries.toList();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _SectionLabel(label: 'INTEL', icon: Icons.hub_outlined),
                                      const SizedBox(height: 8),
                                      ...categories.take(2).map((entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => WearIntelScreen(briefing: briefing)),
                                          ),
                                          child: WearGlassCard(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              children: [
                                                Icon(WearIntelScreen.categoryIcon(entry.key), color: AppTheme.goldAmber, size: 14),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    entry.key.toUpperCase(),
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text('${entry.value.items.length}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              child: _SectionLabel(
                                label: 'WATCHLIST',
                                icon: Icons.show_chart_rounded,
                                onTap: watchlist.isEmpty ? null : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => WearWatchlistScreen(stocks: watchlist)),
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          if (watchlist.isEmpty)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverToBoxAdapter(
                                child: WearGlassCard(
                                  child: Center(child: Text('No tracks', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _DetailedStockCard(stock: watchlist[index]),
                                  ),
                                  childCount: watchlist.take(3).length,
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              child: _SectionLabel(
                                label: 'SIGNALS',
                                icon: Icons.bolt_rounded,
                                color: AppTheme.goldAmber,
                                onTap: opportunities.isEmpty ? null : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => WearOpportunitiesScreen(stocks: opportunities)),
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          if (opportunities.isEmpty)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverToBoxAdapter(
                                child: WearGlassCard(
                                  child: Center(child: Text('Scanning...', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _OpportunityCard(stock: opportunities[index]),
                                  ),
                                  childCount: opportunities.take(3).length,
                                ),
                              ),
                            ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _SectionLabel({required this.label, required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white38, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}

class _DetailedStockCard extends StatelessWidget {
  final StockData stock;
  const _DetailedStockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _WearStockDetail(stock: stock)),
      ),
      child: WearGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.ticker, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(stock.name, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${stock.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WearStockDetail extends StatefulWidget {
  final StockData stock;
  const _WearStockDetail({required this.stock});

  @override
  State<_WearStockDetail> createState() => _WearStockDetailState();
}

class _WearStockDetailState extends State<_WearStockDetail> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final size = MediaQuery.of(context).size;
    final color = stock.changePercent >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

    return Scaffold(
      backgroundColor: AppTheme.charcoalBlack,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1C), AppTheme.charcoalBlack],
          ),
        ),
        child: SafeArea(
          child: WearRotaryScroll(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: 12),
              children: [
                Center(child: Text(stock.ticker, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Center(child: Text(stock.name, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10), textAlign: TextAlign.center)),
                const SizedBox(height: 12),
                
                WearGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${stock.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text('${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                if (stock.direction != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (stock.direction!.toLowerCase() == 'long' ? AppTheme.goldAmber : AppTheme.softCrimson).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (stock.direction!.toLowerCase() == 'long' ? AppTheme.goldAmber : AppTheme.softCrimson).withOpacity(0.3)),
                      ),
                      child: Text(stock.direction!.toUpperCase(), style: TextStyle(color: stock.direction!.toLowerCase() == 'long' ? AppTheme.goldAmber : AppTheme.softCrimson, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],

                if (stock.analysis != null && stock.analysis!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('ANALYSIS', style: TextStyle(color: AppTheme.goldAmber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  WearGlassCard(child: Text(stock.analysis!, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4))),
                ],

                if (stock.catalysts != null && stock.catalysts!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('CATALYSTS', style: TextStyle(color: AppTheme.goldAmber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  WearGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stock.catalysts!.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.goldAmber, fontSize: 11)),
                            Expanded(child: Text(c, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],

                if (stock.risks != null && stock.risks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('RISKS', style: TextStyle(color: AppTheme.softCrimson, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  WearGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stock.risks!.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.softCrimson, fontSize: 11)),
                            Expanded(child: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],

                if (stock.horizon != null || stock.potentialPriceAction != null) ...[
                  const SizedBox(height: 12),
                  const Text('PROJECTION', style: TextStyle(color: AppTheme.goldAmber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  WearGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stock.horizon != null)
                          Text('Horizon: ${stock.horizon}', style: const TextStyle(color: AppTheme.goldAmber, fontSize: 10, fontWeight: FontWeight.bold)),
                        if (stock.potentialPriceAction != null) ...[
                          const SizedBox(height: 4),
                          Text(stock.potentialPriceAction!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final StockData stock;
  const _OpportunityCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isLong = stock.direction?.toLowerCase() == 'long';
    final dirColor = isLong ? AppTheme.goldAmber : AppTheme.softCrimson;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _WearStockDetail(stock: stock)),
      ),
      child: WearGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.ticker, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: dirColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: dirColor.withOpacity(0.2), width: 0.5)),
                    child: Text(stock.direction?.toUpperCase() ?? 'ALPHA', style: TextStyle(color: dirColor, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Text('\$${stock.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
