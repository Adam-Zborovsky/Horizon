import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:horizon/src/features/briefing/briefing_repository.dart';
import 'package:horizon/src/features/briefing/briefing_model.dart';

class AlphaScannerScreen extends ConsumerWidget {
  const AlphaScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0x22FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const _ScannerHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ScannerPulse(),
                    const SizedBox(height: 30),
                    
                    const _ScannerSectionHeader(title: 'Strategic Opportunities'),
                    const SizedBox(height: 8),
                    const Text(
                      'High-conviction ideas scouted from across the market.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        final opportunities = briefing.data['strategic_opportunities']?.items ?? [];
                        if (opportunities.isEmpty) {
                          return const _EmptyScannerState(message: 'No new opportunities scouted.');
                        }
                        return Column(
                          children: opportunities.map((item) => _StrategicOpportunityCard(item: item)).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.goldAmber),
                      error: (e, s) => const _EmptyScannerState(message: 'Opportunity feed offline.'),
                    ),

                    const SizedBox(height: 30),
                    const _ScannerSectionHeader(title: 'High-Signal Divergences'),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Sentiment is high, but price action remains flat/down.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    stocksAsync.when(
                      data: (stocks) {
                        final divergences = stocks.where((s) => s.sentiment > 0.5 && s.changePercent <= 0.5).toList();
                        if (divergences.isEmpty) {
                          return const _EmptyScannerState(message: 'No active divergences detected.');
                        }
                        return Column(
                          children: divergences.map((s) => _DivergenceCard(stock: s)).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.goldAmber),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 30),
                    const _ScannerSectionHeader(title: 'Strategic Catalysts'),
                    const SizedBox(height: 8),
                    const Text(
                      'Deep-intelligence anchors extracted from daily briefing.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        final List<BriefingItem> catalysts = [];
                        briefing.data.forEach((key, cat) {
                          if (key != 'strategic_opportunities') {
                            catalysts.addAll(cat.items.where((i) => i.takeaway != null));
                          }
                        });
                        
                        if (catalysts.isEmpty) {
                          return const _EmptyScannerState(message: 'No catalysts identified.');
                        }
                            
                        return Column(
                          children: catalysts.take(5).map((i) => _CatalystCard(item: i)).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      collapsedHeight: 60,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: Text(
        'Alpha Scanner',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _ScannerPulse extends StatefulWidget {
  const _ScannerPulse({super.key});
  @override
  State<_ScannerPulse> createState() => _ScannerPulseState();
}

class _ScannerPulseState extends State<_ScannerPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.4).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldAmber.withAlpha((255 * _animation.value).toInt())),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.goldAmber.withAlpha((255 * _animation.value).toInt()),
                AppTheme.goldAmber.withAlpha(0),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar_rounded, color: AppTheme.goldAmber.withAlpha((255 * (_animation.value + 0.4)).toInt()), size: 20),
              const SizedBox(width: 12),
              Text(
                'SYSTEM SCANNING LIVE',
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannerSectionHeader extends StatelessWidget {
  final String title;
  const _ScannerSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.goldAmber, shape: BoxShape.circle)),
      ],
    );
  }
}

class _StrategicOpportunityCard extends StatelessWidget {
  final BriefingItem item;

  const _StrategicOpportunityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/stock/${item.ticker}'),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ticker ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Text(
                          item.name?.toUpperCase() ?? 'UNKNOWN ASSET',
                          style: TextStyle(
                            color: Colors.white.withAlpha(96),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                           overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(item.sentiment ?? 0).toStringAsFixed(1)} SNT',
                        style: const TextStyle(
                          color: AppTheme.goldAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.horizon?.toUpperCase() ?? 'MID-TERM',
                        style: TextStyle(color: Colors.white.withAlpha(96), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'SCOUT ANALYSIS',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.explanation ?? 'No analysis provided.',
                style: TextStyle(
                  color: Colors.white.withAlpha(178),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivergenceCard extends StatelessWidget {
  final StockData stock;

  const _DivergenceCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/stock/${stock.ticker}'),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.ticker, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat')),
                  Text(
                    'DIVERGENCE DETECTED',
                    style: TextStyle(color: AppTheme.goldAmber.withAlpha(204), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${stock.sentiment.toStringAsFixed(1)} SNT', style: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${stock.changePercent.toStringAsFixed(2)}% Action', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white10),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalystCard extends StatelessWidget {
  final BriefingItem item;

  const _CatalystCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.go('/vault'),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldAmber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.goldAmber, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title ?? 'Market Event', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)
                    ),
                    const SizedBox(height: 2),
                    Text(item.takeaway?.toUpperCase() ?? 'CATALYST', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.goldAmber.withAlpha(102), fontSize: 9, letterSpacing: 1)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyScannerState extends StatelessWidget {
  final String message;
  const _EmptyScannerState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white24, fontSize: 12)),
      ),
    );
  }
}
