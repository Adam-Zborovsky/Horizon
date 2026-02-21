import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class AlphaScannerScreen extends StatelessWidget {
  const AlphaScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _ScannerHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScannerPulse(),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Sentiment Divergences'),
                    const SizedBox(height: 15),
                    _DivergenceCard(ticker: 'ASML', sentiment: 0.85, priceAction: 'Flat'),
                    _DivergenceCard(ticker: 'MU', sentiment: 0.91, priceAction: 'Down 2%'),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Macro Impact Map'),
                    const SizedBox(height: 15),
                    _MacroImpactMap(),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Emerging Catalysts'),
                    const SizedBox(height: 15),
                    _CatalystCard(title: 'Foundry 2.0 Milestone', category: 'Semiconductors'),
                    _CatalystCard(title: 'Ceasefire Progress', category: 'Geopolitics'),
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alpha Scanner', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Finding High-Signal Setups',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.goldAmber.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerPulse extends StatefulWidget {
  @override
  State<_ScannerPulse> createState() => _ScannerPulseState();
}

class _ScannerPulseState extends State<_ScannerPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.goldAmber.withOpacity(_animation.value),
                AppTheme.goldAmber.withOpacity(0),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'SYSTEM SCANNING FOR ALPHA...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 2,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const Icon(Icons.bolt_rounded, color: AppTheme.goldAmber, size: 16),
      ],
    );
  }
}

class _DivergenceCard extends StatelessWidget {
  final String ticker;
  final double sentiment;
  final String priceAction;

  const _DivergenceCard({required this.ticker, required this.sentiment, required this.priceAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  'DIVERGENCE DETECTED',
                  style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Sentiment: +$sentiment', style: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Price Action: $priceAction', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroImpactMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      height: 200,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GeometricMapPainter(),
          ),
          const Center(
            child: Text(
              'STRATEGIC MAP ACTIVE',
              style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 4),
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
      ..color = AppTheme.goldAmber.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = AppTheme.goldAmber.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Abstract connections
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.2), Offset(size.width * 0.8, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.8, size.height * 0.2), Offset(size.width * 0.2, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.1), Offset(size.width * 0.5, size.height * 0.9), paint);

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 4, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 4, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 6, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatalystCard extends StatelessWidget {
  final String title;
  final String category;

  const _CatalystCard({required this.title, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.goldAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.goldAmber, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(category.toUpperCase(), style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.4), fontSize: 10, letterSpacing: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
