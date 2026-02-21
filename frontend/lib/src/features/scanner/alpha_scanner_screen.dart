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
                    const _ScannerSectionHeader(title: 'High-Signal Divergences'),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Sentiment is high, but price action remains flat/down.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    stocksAsync.when(
                      data: (stocks) {
                        final divergences = stocks.where((s) => s.sentiment > 0.6 && s.changePercent <= 0).toList();
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
                      'High-impact events identified from daily briefing.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        final List<BriefingItem> catalysts = [];
                        briefing.data.values.forEach((cat) {
                          catalysts.addAll(cat.items.where((i) => i.takeaway != null));
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
                    const SizedBox(height: 30),
                    const _ScannerSectionHeader(title: 'System Analysis Map'),
                    const SizedBox(height: 15),
                    const _MacroImpactMap(),
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
  const _ScannerHeader();
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Alpha Scanner',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _ScannerPulse extends StatefulWidget {
  const _ScannerPulse();
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
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.goldAmber.withOpacity(_animation.value)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.goldAmber.withOpacity(_animation.value),
                AppTheme.goldAmber.withOpacity(0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, color: AppTheme.goldAmber.withOpacity(_animation.value + 0.4), size: 24),
                const SizedBox(height: 8),
                Text(
                  'ENGINE ACTIVE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScannerSectionHeader extends StatelessWidget {
  final String title;
  const _ScannerSectionHeader({required this.title});

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

class _DivergenceCard extends StatelessWidget {
  final StockData stock;

  const _DivergenceCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/stock/${stock.ticker}'),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.ticker, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat')),
                  Text(
                    'DIVERGENCE DETECTED',
                    style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${stock.sentiment} SNT', style: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${stock.changePercent}% Action', style: const TextStyle(color: Colors.white38, fontSize: 11)),
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

class _EmptyScannerState extends StatelessWidget {
  final String message;
  const _EmptyScannerState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white24, fontSize: 12)),
      ),
    );
  }
}

class _MacroImpactMap extends StatelessWidget {
  const _MacroImpactMap();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      height: 150,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GeometricMapPainter(),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'CORRELATION ACTIVE',
              style: TextStyle(color: Colors.white10, fontSize: 7, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.goldAmber.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = AppTheme.goldAmber.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final nodes = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.7),
    ];

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(nodes[i], nodes[j], paint);
      }
      canvas.drawCircle(nodes[i], 2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatalystCard extends StatelessWidget {
  final BriefingItem item;

  const _CatalystCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.goldAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.goldAmber, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title ?? 'Market Event', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(item.takeaway?.toUpperCase() ?? 'CATALYST', 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.4), fontSize: 9, letterSpacing: 1)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
