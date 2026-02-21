import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/briefing/briefing_repository.dart';
import 'package:horizon/src/features/dashboard/watchlist_provider.dart';

class ManageTopicsScreen extends ConsumerStatefulWidget {
  const ManageTopicsScreen({super.key});

  @override
  ConsumerState<ManageTopicsScreen> createState() => _ManageTopicsScreenState();
}

class _ManageTopicsScreenState extends ConsumerState<ManageTopicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recommended = ['Semiconductors', 'Geopolitics', 'Sovereign AI', 'Energy', 'Defense Tech', 'Cybersecurity', 'Macro Crypto'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followed = ref.watch(followedTopicsProvider);
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          _SliverSearchHeader(
            controller: _searchController, 
            onSubmitted: (val) async {
              if (val.isNotEmpty) {
                await ref.read(followedTopicsProvider.notifier).toggle(val);
                _searchController.clear();
              }
            },
          ),
          SliverToBoxAdapter(
            child: _RecommendedSection(
              recommended: _recommended,
              onTap: (topic) async => await ref.read(followedTopicsProvider.notifier).toggle(topic),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'FOLLOWED INTELLIGENCE',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          briefingAsync.when(
            data: (briefing) {
              final categories = briefing.data.keys.toList();
              // Combine actual categories from backend with any custom followed ones
              final allVisible = {...categories, ...followed}.toList();
              
              if (allVisible.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No topics followed', style: TextStyle(color: Colors.white24)),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final topic = allVisible[index];
                    final isFollowing = followed.contains(topic);
                    return _TopicItem(
                      title: topic,
                      isFollowing: isFollowing,
                      onToggle: () async => await ref.read(followedTopicsProvider.notifier).toggle(topic),
                    );
                  },
                  childCount: allVisible.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SliverSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const _SliverSearchHeader({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: GlassCard(
        borderRadius: 0,
        blur: 20,
        padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 10),
        color: AppTheme.obsidian.withOpacity(0.7),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: onSubmitted,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'SEARCH TOPICS...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14, letterSpacing: 1),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search_rounded, color: AppTheme.goldAmber.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  final List<String> recommended;
  final Function(String) onTap;

  const _RecommendedSection({required this.recommended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24, top: 30, bottom: 12),
          child: Text(
            'TRENDING PILLARS',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  label: Text(recommended[index]),
                  onPressed: () => onTap(recommended[index]),
                  backgroundColor: AppTheme.glassWhite,
                  side: BorderSide(color: AppTheme.goldAmber.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopicItem extends StatelessWidget {
  final String title;
  final bool isFollowing;
  final VoidCallback onToggle;

  const _TopicItem({required this.title, required this.isFollowing, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.goldAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hub_outlined, color: AppTheme.goldAmber, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                backgroundColor: isFollowing ? Colors.transparent : AppTheme.goldAmber.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isFollowing ? Colors.white10 : AppTheme.goldAmber.withOpacity(0.3)),
                ),
              ),
              child: Text(
                isFollowing ? 'UNFOLLOW' : 'FOLLOW',
                style: TextStyle(
                  color: isFollowing ? Colors.white38 : AppTheme.goldAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
