import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_model.dart';
import 'saved_articles_provider.dart';

class IntelligenceVaultScreen extends ConsumerStatefulWidget {
  const IntelligenceVaultScreen({super.key});

  @override
  ConsumerState<IntelligenceVaultScreen> createState() => _IntelligenceVaultScreenState();
}

class _IntelligenceVaultScreenState extends ConsumerState<IntelligenceVaultScreen> {
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
              data: (briefing) => _NewsList(briefing: briefing),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
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
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Intelligence Vault',
          style: Theme.of(context).textTheme.displayMedium,
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

class _NewsList extends StatelessWidget {
  final BriefingData briefing;

  const _NewsList({required this.briefing});

  @override
  Widget build(BuildContext context) {
    // Flatten all items into a single unified intelligence feed
    final List<MapEntry<String, BriefingItem>> itemsWithCategories = [];
    
    briefing.data.forEach((catName, catData) {
      for (var item in catData.items) {
        // Skip items that don't have a title (e.g. pure stock data)
        if (item.title != null) {
          itemsWithCategories.add(MapEntry(catName, item));
        }
      }
    });

    if (itemsWithCategories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No intelligence found.', style: TextStyle(color: Colors.white24))),
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
    final color = (item.sentiment ?? 0) > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;
    final savedArticles = ref.watch(savedArticlesProvider);
    final isSaved = savedArticles.contains(item.title ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.img != null && item.img!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  item.img!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 180,
                    color: AppTheme.glassWhite,
                    child: const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            Padding(
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
                              '${(item.sentiment ?? 0).toStringAsFixed(1)} SNT',
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
                          if (item.title != null) {
                            ref.read(savedArticlesProvider.notifier).toggle(item.title!);
                          }
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
                  Text(
                    item.title ?? "Untitled Intelligence",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.takeaway != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: AppTheme.goldAmber,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'TAKEAWAY',
                          style: TextStyle(
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
                      item.takeaway!,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
