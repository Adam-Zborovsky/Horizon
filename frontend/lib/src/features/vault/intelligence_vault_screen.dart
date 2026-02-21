import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_model.dart';

class IntelligenceVaultScreen extends ConsumerWidget {
  const IntelligenceVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _VaultHeader(),
            _CategoryPills(),
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
    );
  }
}

class _CategoryPills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Semiconductors', 'Geopolitics', 'Sovereign AI'];
    return SliverToBoxAdapter(
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 20, top: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final isActive = index == 0;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.goldAmber : AppTheme.glassWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppTheme.goldAmber : Colors.white10),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  final BriefingData briefing;
  const _NewsList({required this.briefing});

  @override
  Widget build(BuildContext context) {
    // Collect all items from all categories
    final List<BriefingItem> allItems = [];
    briefing.data.forEach((catName, catData) {
      allItems.addAll(catData.items);
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = allItems[index];
          // Skip items that are just tickers (dealt with in Nexus/Detail)
          if (item.title == null) return const SizedBox.shrink();
          
          return _NewsCard(item: item);
        },
        childCount: allItems.length,
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final BriefingItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = (item.sentiment ?? 0) > 0 ? AppTheme.goldAmber : AppTheme.softCrimson;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.img != null)
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
                      const Icon(Icons.bookmark_outline_rounded, color: Colors.white24, size: 20),
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
