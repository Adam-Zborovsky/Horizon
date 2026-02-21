import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class IntelligenceDetailView extends ConsumerWidget {
  final String category;
  const IntelligenceDetailView({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          category.toUpperCase(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final catData = briefing[category];
          if (catData == null) return const Center(child: Text('Category not found'));
          return RefreshIndicator(
            onRefresh: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
            backgroundColor: AppTheme.cardBg,
            color: AppTheme.neutralBlue,
            child: _CategoryContent(name: category, category: catData),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neutralBlue),
              SizedBox(height: 16),
              Text('GATHERING LOCAL INTELLIGENCE...', style: TextStyle(letterSpacing: 1.5, fontSize: 10, color: AppTheme.textDim)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.negativeRed, size: 48),
              const SizedBox(height: 16),
              Text('INTEL ERROR: $err', style: const TextStyle(color: AppTheme.negativeRed)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBg),
                child: const Text('RETRY UPLINK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryContent extends StatelessWidget {
  final String name;
  final BriefingCategory category;
  const _CategoryContent({required this.name, required this.category});

  @override
  Widget build(BuildContext context) {
    final isGeopolitical = name.toLowerCase().contains('geopolitics');
    final isMarket = name.toLowerCase().contains('market') || name.toLowerCase().contains('nexus');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _KeyMetricsBar(score: category.sentimentScore),
        const SizedBox(height: 20),
        if (isGeopolitical && category.sentimentScore < -0.5)
          const _CriticalAlertBanner(),
        const SizedBox(height: 20),
        _StrategicTakeaways(summary: category.summary, score: category.sentimentScore),
        const SizedBox(height: 32),
        Text(
          isMarket ? 'TOP TICKERS' : 'INTELLIGENCE FEED',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.textDim,
          ),
        ),
        const SizedBox(height: 16),
        ...category.items.map((item) {
          if (item.ticker != null) {
            return _StockItem(item: item);
          } else {
            return _NewsItem(item: item);
          }
        }),
      ],
    );
  }
}

class _KeyMetricsBar extends StatelessWidget {
  final double score;
  const _KeyMetricsBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SENTIMENT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                score.toStringAsFixed(2),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              score > 0.3 ? 'BULLISH' : (score < -0.3 ? 'BEARISH' : 'NEUTRAL'),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalAlertBanner extends StatelessWidget {
  const _CriticalAlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.negativeRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.negativeRed, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.negativeRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CRITICAL INTEL: Regional stability metrics declining.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.negativeRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategicTakeaways extends StatelessWidget {
  final String summary;
  final double score;
  const _StrategicTakeaways({required this.summary, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(score),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STRATEGIC TAKEAWAYS',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.getSentimentColor(score),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _StockItem extends StatelessWidget {
  final BriefingItem item;
  const _StockItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = (item.change ?? 0) >= 0 ? AppTheme.positiveGreen : AppTheme.negativeRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/stock/${item.ticker}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ticker ?? '',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
                      ),
                      Text(item.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.price?.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(item.change ?? 0) >= 0 ? '+' : ''}${item.change}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final BriefingItem item;
  const _NewsItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (item.l != null) {
            await launchUrl(Uri.parse(item.l!));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.img != null && item.img!.isNotEmpty)
              Image.network(
                item.img!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  if (item.takeaway != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.positiveGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.takeaway!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
