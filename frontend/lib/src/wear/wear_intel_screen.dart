import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/briefing/briefing_model.dart';
import 'wear_glass_card.dart';

class WearIntelScreen extends StatelessWidget {
  final BriefingData briefing;
  const WearIntelScreen({super.key, required this.briefing});

  static IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('market') || n.contains('analysis')) return Icons.candlestick_chart_rounded;
    if (n.contains('opportunit') || n.contains('divergent')) return Icons.bolt_rounded;
    if (n.contains('defense') || n.contains('military')) return Icons.shield_outlined;
    if (n.contains('ai') || n.contains('cyber') || n.contains('tech')) return Icons.memory;
    if (n.contains('geo') || n.contains('diplom')) return Icons.public;
    if (n.contains('econom') || n.contains('trade')) return Icons.account_balance_outlined;
    if (n.contains('energy') || n.contains('nuclear')) return Icons.flash_on_rounded;
    return Icons.hub_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final categories = briefing.data.entries.toList();

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x11FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 8,
            ),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8, top: 4),
                  child: Center(
                    child: Text(
                      'INTEL PILLARS',
                      style: TextStyle(
                        color: AppTheme.goldAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              }

              final entry = categories[index - 1];
              final catName = entry.key;
              final catData = entry.value;
              final itemCount = catData.items.length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _WearCategoryDetail(
                        name: catName,
                        category: catData,
                      ),
                    ),
                  ),
                  child: WearGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAmber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _categoryIcon(catName),
                            color: AppTheme.goldAmber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$itemCount items',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white24,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WearCategoryDetail extends StatelessWidget {
  final String name;
  final CategoryData category;

  const _WearCategoryDetail({
    required this.name,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final items = category.items;

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x11FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 8,
            ),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Center(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.goldAmber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final item = items[index - 1];
              final title = item.title ?? item.ticker ?? item.name ?? 'Report';
              final summary = item.takeaway ?? item.explanation ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: WearGlassCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 9,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
