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
  String selectedTimeframe = '1M';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.neutralBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final categories = briefing.entries.toList();
          final totalItems = categories.fold(0, (sum, entry) => sum + entry.value.items.length);
          final avgSentiment = categories.isEmpty 
              ? 0.0 
              : categories.fold(0.0, (sum, entry) => sum + entry.value.sentimentScore) / categories.length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _TimeframeSelector(
                selected: selectedTimeframe,
                onChanged: (val) => setState(() => selectedTimeframe = val),
              ),
              const SizedBox(height: 24),
              const _AnalysisSectionHeader(title: 'GLOBAL SENTIMENT PULSE'),
              _MainSentimentChart(timeframe: selectedTimeframe, avgSentiment: avgSentiment),
              const SizedBox(height: 32),
              const _AnalysisSectionHeader(title: 'SECTOR CORRELATION'),
              _SectorPerformanceChart(
                categories: categories,
                onTouch: (index) => setState(() => touchedIndex = index),
              ),
              const SizedBox(height: 32),
              const _AnalysisSectionHeader(title: 'INTELLIGENCE DENSITY'),
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
        return GestureDetector(
          onTap: () => onChanged(tf),
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
                color: isSelected ? AppTheme.neutralBlue : AppTheme.textDim,
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
  const _AnalysisSectionHeader({required this.title});

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
          const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textDim),
        ],
      ),
    );
  }
}

class _MainSentimentChart extends StatelessWidget {
  final String timeframe;
  final double avgSentiment;
  const _MainSentimentChart({required this.timeframe, required this.avgSentiment});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSentimentColor(avgSentiment);
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(avgSentiment),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 0.4),
                const FlSpot(2, 0.45),
                const FlSpot(4, 0.42),
                FlSpot(6, avgSentiment > 0 ? 0.6 : 0.3),
                const FlSpot(8, 0.58),
                FlSpot(10, avgSentiment + 0.1),
                const FlSpot(12, 0.72),
                FlSpot(14, avgSentiment),
              ],
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
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
    );
  }
}

class _SectorPerformanceChart extends StatelessWidget {
  final List<MapEntry<String, BriefingCategory>> categories;
  final ValueChanged<int> onTouch;
  const _SectorPerformanceChart({required this.categories, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              if (response != null && response.spot != null) {
                onTouch(response.spot!.touchedBarGroupIndex);
              }
            },
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < categories.length) {
                    final title = categories[value.toInt()].key;
                    final initials = title.split(' ').map((e) => e[0]).join();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        initials,
                        style: const TextStyle(color: AppTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: categories.asMap().entries.map((e) {
            final index = e.key;
            final category = e.value.value;
            final sentiment = category.sentimentScore;
            return _makeGroupData(index, sentiment.abs(), AppTheme.getSentimentColor(sentiment));
          }).toList(),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 1,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ],
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
              _DensityMetric(label: 'SENTIMENT', value: avgSentiment > 0.3 ? 'High' : (avgSentiment < -0.3 ? 'Low' : 'Med'), color: AppTheme.getSentimentColor(avgSentiment)),
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
