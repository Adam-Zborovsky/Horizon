import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'HORIZON',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 28,
            letterSpacing: 2,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Colors.white, AppTheme.neutralBlue],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () => context.go('/watchlist'),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: briefingAsync.when(
        data: (briefing) => RefreshIndicator(
          onRefresh: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
          backgroundColor: AppTheme.cardBg,
          color: AppTheme.neutralBlue,
          child: _DashboardContent(briefing: briefing),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neutralBlue),
              SizedBox(height: 16),
              Text('SCANNING GLOBAL FREQUENCIES...', style: TextStyle(letterSpacing: 1.5, fontSize: 10, color: AppTheme.textDim)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off_rounded, color: AppTheme.negativeRed, size: 48),
              const SizedBox(height: 16),
              Text('COMMUNICATION ERROR: $err', style: const TextStyle(color: AppTheme.negativeRed)),
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

class _DashboardContent extends StatelessWidget {
  final Map<String, BriefingCategory> briefing;
  const _DashboardContent({required this.briefing});

  @override
  Widget build(BuildContext context) {
    final firstCategory = briefing.values.firstOrNull;
    final globalSummary = firstCategory?.summary ?? 'Scanning for latest global intelligence updates...';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _DailyBriefingCard(summary: globalSummary),
        const SizedBox(height: 24),
        ...briefing.entries.map((entry) {
          return _CategoryCard(name: entry.key, category: entry.value);
        }),
      ],
    );
  }
}

class _DailyBriefingCard extends StatelessWidget {
  final String summary;
  const _DailyBriefingCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neutralBlue.withOpacity(0.2),
            AppTheme.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutralBlue.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/intelligence-feed'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.neutralBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY BRIEFING',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.neutralBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final BriefingCategory category;
  const _CategoryCard({required this.name, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.glassCardDecoration(category.sentimentScore),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/intelligence/$name'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    _SentimentBadge(score: category.sentimentScore),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  category.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMain.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      size: 14,
                      color: AppTheme.getSentimentColor(category.sentimentScore),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.items.length} Intelligence Items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppTheme.getSentimentColor(category.sentimentScore),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SentimentBadge extends StatelessWidget {
  final double score;
  const _SentimentBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        score.toStringAsFixed(2),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
