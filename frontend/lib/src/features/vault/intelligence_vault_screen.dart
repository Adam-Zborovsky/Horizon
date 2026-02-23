import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_model.dart';
import 'saved_articles_provider.dart';

class IntelligenceVaultScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const IntelligenceVaultScreen({super.key, this.initialCategory});

  @override
  ConsumerState<IntelligenceVaultScreen> createState() => _IntelligenceVaultScreenState();
}

class _IntelligenceVaultScreenState extends ConsumerState<IntelligenceVaultScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void didUpdateWidget(IntelligenceVaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory && widget.initialCategory != null) {
      setState(() {
        _selectedCategory = widget.initialCategory!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      body: Container(
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const _VaultHeader(),
            briefingAsync.when(
              data: (briefing) {
                // Filter categories: only show those with >= 1 items (either title or ticker), plus 'All'
                final validCategories = briefing.data.entries
                    .where((e) => e.value.items.where((i) => i.title != null || i.ticker != null).isNotEmpty)
                    .map((e) => e.key)
                    .toList();
                
                final categories = ['All', ...validCategories];
                
                // If our selected category is not in the list (but exists in data), we should still show it if it was explicitly selected
                if (_selectedCategory != 'All' && !validCategories.contains(_selectedCategory) && briefing.data.containsKey(_selectedCategory)) {
                  categories.add(_selectedCategory);
                }

                if (categories.length <= 1) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: _CategoryPills(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            briefingAsync.when(
              data: (briefing) => _NewsList(
                briefing: briefing,
                selectedCategory: _selectedCategory,
              ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
                        const SizedBox(height: 16),
                        Text('Intel feed offline', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 12)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(briefingRepositoryProvider),
                          child: const Text('Reconnect'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _VaultHeader extends StatelessWidget {
  const _VaultHeader();

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
        'Intelligence Vault',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/manage-topics'),
          icon: const Icon(Icons.search_rounded, color: AppTheme.goldAmber),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _CategoryPills extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoryPills({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == selectedCategory;
          
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.goldAmber : AppTheme.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppTheme.goldAmber : Colors.white10),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  final BriefingData briefing;
  final String selectedCategory;

  const _NewsList({
    required this.briefing,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, BriefingItem>> itemsWithCategories = [];
    
    if (selectedCategory == 'All') {
      briefing.data.forEach((catName, catData) {
        for (var item in catData.items) {
          if (item.title != null || item.ticker != null) {
            itemsWithCategories.add(MapEntry(catName, item));
          }
        }
      });
    } else {
      final catData = briefing.data[selectedCategory];
      if (catData != null) {
        for (var item in catData.items) {
          if (item.title != null || item.ticker != null) {
            itemsWithCategories.add(MapEntry(selectedCategory, item));
          }
        }
      }
    }

    if (itemsWithCategories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_mosaic_outlined, color: Colors.white10, size: 48),
              SizedBox(height: 16),
              Text('The vault is currently empty.', style: TextStyle(color: Colors.white24)),
              Text('Awaiting next briefing cycles...', style: TextStyle(color: Colors.white12, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = itemsWithCategories[index];
          return _NewsCard(categoryName: entry.key, item: entry.value);
        },
        childCount: itemsWithCategories.length,
      ),
    );
  }
}

class _NewsCard extends ConsumerWidget {
  final String categoryName;
  final BriefingItem item;
  const _NewsCard({required this.categoryName, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle sentiment as dynamic (double score or String description)
    double sentimentVal = 0.0;
    String sentimentText = '0.0 SNT';
    
    if (item.sentimentScore != null) {
       sentimentVal = item.sentimentScore!;
       sentimentText = '${sentimentVal > 0 ? "+" : ""}${sentimentVal.toStringAsFixed(1)} SNT';
    } else if (item.sentiment is double) {
      sentimentVal = item.sentiment as double;
      sentimentText = '${sentimentVal > 0 ? "+" : ""}${sentimentVal.toStringAsFixed(1)} SNT';
    } else if (item.sentiment is String) {
      sentimentText = item.sentiment as String;
      // Heuristic for color if it's a string
      final s = (item.sentiment as String).toLowerCase();
      if (s.contains('bullish') || s.contains('high') || s.contains('positive')) sentimentVal = 1.0;
      if (s.contains('bearish') || s.contains('low') || s.contains('negative')) sentimentVal = -1.0;
    }

    final color = sentimentVal >= 0 ? AppTheme.goldAmber : AppTheme.softCrimson;
    final savedArticles = ref.watch(savedArticlesProvider);
    final title = item.title ?? item.name ?? item.ticker ?? "Untitled Intelligence";
    final isSaved = savedArticles.contains(title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        sentimentText,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryName.toUpperCase(),
                      style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(savedArticlesProvider.notifier).toggle(title);
                  },
                  child: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isSaved ? AppTheme.goldAmber : Colors.white24,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.ticker != null) 
              Text(
                item.ticker!,
                style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.takeaway != null || item.analysis != null || item.explanation != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 2,
                    height: 30,
                    color: AppTheme.goldAmber,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.analysis != null ? 'ANALYSIS' : item.explanation != null ? 'EXPLANATION' : 'TAKEAWAY',
                    style: const TextStyle(
                      color: AppTheme.goldAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.analysis ?? item.explanation ?? item.takeaway ?? "",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.catalysts != null && item.catalysts!.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text('CATALYSTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 5),
              ...item.catalysts!.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.goldAmber)),
                    Expanded(child: Text(c, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
