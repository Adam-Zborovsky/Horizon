import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';

class AnalysisView extends ConsumerStatefulWidget {
  const AnalysisView({super.key});

  @override
  ConsumerState<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends ConsumerState<AnalysisView> {
  String selectedTimeframe = '1D';
  Set<String> excludedSectors = {};
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'STRATEGIC HUB',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final allCategories = briefing.entries.toList();
          final visibleCategories = allCategories
              .where((e) => !excludedSectors.contains(e.key))
              .toList();

          final totalItems = visibleCategories.fold(
              0, (sum, entry) => sum + entry.value.items.length);
          final avgSentiment = visibleCategories.isEmpty
              ? 0.0
              : visibleCategories.fold(
                      0.0, (sum, entry) => sum + entry.value.sentimentScore) /
                  visibleCategories.length;

          // Extract top signals (high/low sentiment)
          final allItems = visibleCategories.expand((e) => e.value.items).toList();
          allItems.sort((a, b) => (b.sentiment ?? 0).abs().compareTo((a.sentiment ?? 0).abs()));
          final topSignals = allItems.take(5).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _TimeframeSelector(
                selected: selectedTimeframe,
                onChanged: (val) => setState(() => selectedTimeframe = val),
              ),
              const SizedBox(height: 24),
              const _AnalysisSectionHeader(title: 'GLOBAL SENTIMENT RADAR'),
              _MainSentimentChart(
                avgSentiment: avgSentiment,
                categories: visibleCategories,
              ),
              const SizedBox(height: 24),
              _AICommentaryCard(avgSentiment: avgSentiment, categoryCount: visibleCategories.length),
              const SizedBox(height: 32),
              _AnalysisSectionHeader(
                title: 'INTELLIGENCE PILLARS',
                action: Text(
                  '${visibleCategories.length}/${allCategories.length} ACTIVE',
                  style: const TextStyle(color: AppTheme.neutralBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              _SectorGrid(
                allCategories: allCategories,
                excludedSectors: excludedSectors,
                onToggle: (sector) {
                  setState(() {
                    if (excludedSectors.contains(sector)) {
                      excludedSectors.remove(sector);
                    } else {
                      excludedSectors.add(sector);
                    }
                  });
                },
              ),
              const SizedBox(height: 32),
              const _AnalysisSectionHeader(title: 'TACTICAL ALERTS'),
              _TacticalAlertsList(topSignals: topSignals),
              const SizedBox(height: 32),
              const _AnalysisSectionHeader(title: 'DENSITY METRICS'),
              _IntelligenceDensityCard(totalItems: totalItems, avgSentiment: avgSentiment),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.neutralBlue)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.negativeRed))),
      ),
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TimeframeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final timeframes = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: timeframes.map((tf) {
        final isSelected = selected == tf;
        final isDisabled = tf != '1D'; // Currently only 1D is "functional"
        return GestureDetector(
          onTap: isDisabled ? null : () => onChanged(tf),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.neutralBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.neutralBlue : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Text(
              tf,
              style: TextStyle(
                color: isSelected ? AppTheme.neutralBlue : (isDisabled ? AppTheme.textDim.withOpacity(0.3) : AppTheme.textDim),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AnalysisSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _AnalysisSectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.neutralBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.textDim,
                ),
          ),
          const Spacer(),
          action ?? const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textDim),
        ],
      ),
    );
  }
}

class _MainSentimentChart extends StatelessWidget {
  final double avgSentiment;
  final List<MapEntry<String, BriefingCategory>> categories;
  const _MainSentimentChart({required this.avgSentiment, required this.categories});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(avgSentiment);
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(avgSentiment),
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: categories.isEmpty
                      ? [const FlSpot(0, 0.5)]
                      : categories.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value.value.sentimentScore + 1) / 2);
                        }).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CORE PULSE',
                  style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  '${(avgSentiment * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectorGrid extends StatelessWidget {
  final List<MapEntry<String, BriefingCategory>> allCategories;
  final Set<String> excludedSectors;
  final Function(String) onToggle;

  const _SectorGrid({
    required this.allCategories,
    required this.excludedSectors,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final entry = allCategories[index];
        final name = entry.key;
        final category = entry.value;
        final isExcluded = excludedSectors.contains(name);
        final color = AppTheme.getSentimentColor(category.sentimentScore);

        return GestureDetector(
          onTap: () => onToggle(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isExcluded ? AppTheme.cardBg.withOpacity(0.3) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExcluded ? Colors.white.withOpacity(0.05) : color.withOpacity(0.3),
                width: isExcluded ? 1 : 2,
              ),
              boxShadow: isExcluded
                  ? []
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Icon(
                  isExcluded ? Icons.visibility_off_outlined : Icons.radar,
                  size: 16,
                  color: isExcluded ? AppTheme.textDim : color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.split(' ').first.toUpperCase(),
                        style: TextStyle(
                          color: isExcluded ? AppTheme.textDim : AppTheme.textMain,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isExcluded)
                        Text(
                          '${(category.sentimentScore * 100).toStringAsFixed(0)}% SNT',
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                    ],
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

class _TacticalAlertsList extends StatelessWidget {
  final List<BriefingItem> topSignals;
  const _TacticalAlertsList({required this.topSignals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: topSignals.map((item) {
        final sentiment = item.sentiment ?? 0;
        final color = AppTheme.getSentimentColor(sentiment);
        final isPositive = sentiment > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ticker ?? item.title ?? 'Unknown Signal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.takeaway ?? item.analysis ?? 'Critical intelligence signal detected.',
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(sentiment * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    isPositive ? 'ALPHA' : 'RISK',
                    style: TextStyle(color: color.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IntelligenceDensityCard extends StatelessWidget {
  final int totalItems;
  final double avgSentiment;
  const _IntelligenceDensityCard({required this.totalItems, required this.avgSentiment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(avgSentiment),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DensityMetric(label: 'SIGNALS', value: totalItems.toString(), color: AppTheme.neutralBlue),
              _DensityMetric(
                  label: 'SENTIMENT',
                  value: avgSentiment > 0.3 ? 'High' : (avgSentiment < -0.3 ? 'Low' : 'Med'),
                  color: AppTheme.getSentimentColor(avgSentiment)),
              const _DensityMetric(label: 'STATUS', value: 'ACTIVE', color: AppTheme.positiveGreen),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Analysis reflects $totalItems intelligence signals processed across multiple global categories. Sentiment is trending ${avgSentiment > 0 ? "positively" : "negatively"} at ${avgSentiment.toStringAsFixed(2)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DensityMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DensityMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}

class _AICommentaryCard extends StatelessWidget {
  final double avgSentiment;
  final int categoryCount;

  const _AICommentaryCard({required this.avgSentiment, required this.categoryCount});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(avgSentiment);
    String title = '';
    String insight = '';

    if (categoryCount == 0) {
      title = 'NO DATA';
      insight = 'Select at least one intelligence pillar to generate strategic commentary.';
    } else if (avgSentiment > 0.4) {
      title = 'OPTIMISTIC MOMENTUM';
      insight = 'The aggregate sentiment across active sectors indicates strong upward pressure. Opportunities in AI and tech are offsetting macro risks.';
    } else if (avgSentiment < -0.4) {
      title = 'HEIGHTENED VOLATILITY';
      insight = 'Negative geopolitical signals are dominating the radar. Tactical defensive positions are recommended until correlation stabilizes.';
    } else {
      title = 'NEUTRAL EQUILIBRIUM';
      insight = 'The market is exhibiting a balanced posture. Mixed signals across sectors suggest a period of consolidation before the next directional break.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: const TextStyle(color: AppTheme.textMain, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

