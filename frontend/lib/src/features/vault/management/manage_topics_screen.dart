import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/briefing/briefing_config_model.dart';
import 'package:horizon/src/features/briefing/briefing_config_repository.dart';

class ManageTopicsScreen extends ConsumerStatefulWidget {
  const ManageTopicsScreen({super.key});

  static String formatTopic(String key) {
    if (key == 'news_intel') return 'Strategic News Intel';
    if (key == 'market_analyst') return 'Market Analysis';
    if (key == 'opportunity_scout') return 'Alpha Opportunities';
    
    return key.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  @override
  ConsumerState<ManageTopicsScreen> createState() => _ManageTopicsScreenState();
}

class _ManageTopicsScreenState extends ConsumerState<ManageTopicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // These should ideally come from backend config or initial setup
  final List<String> _defaultRecommendedTopics = [
    'Semiconductors', 
    'Geopolitics', 
    'Sovereign AI', 
    'Energy', 
    'Defense Tech', 
    'Cybersecurity', 
    'Macro Crypto'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final briefingConfigAsync = ref.watch(briefingConfigRepositoryProvider);
    final recommendedTopicsAsync = ref.watch(recommendedTopicsProvider);

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          _SliverSearchHeader(
            controller: _searchController, 
            onSubmitted: (val) async {
              if (val.isNotEmpty) {
                // Add the new topic and enable it
                await ref.read(briefingConfigRepositoryProvider.notifier).toggleTopic(val, true);
                _searchController.clear();
              }
            },
          ),
          SliverToBoxAdapter(
            child: briefingConfigAsync.when(
              data: (config) {
                return recommendedTopicsAsync.when(
                  data: (newsRecommended) {
                    // Combine default and news recommendations, prioritizing news
                    final combinedRecommended = <String>{...newsRecommended, ..._defaultRecommendedTopics}.toList();
                    
                    // Filter out topics already in the config to avoid duplicates
                    final filtered = combinedRecommended.where(
                      (recTopic) => !config.topics.any((cfgTopic) => cfgTopic.name == recTopic)
                    ).toList();

                    return _RecommendedSection(
                      recommended: filtered,
                      onTap: (topic) async => await ref.read(briefingConfigRepositoryProvider.notifier).toggleTopic(topic, true),
                      displayNames: filtered.map((e) => ManageTopicsScreen.formatTopic(e)).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
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
          briefingConfigAsync.when(
            data: (config) {
              if (config.topics.isEmpty) {
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
                    final topic = config.topics[index];
                    return _TopicItem(
                      title: ManageTopicsScreen.formatTopic(topic.name),
                      isEnabled: topic.enabled,
                      onToggle: (bool newValue) async {
                        await ref.read(briefingConfigRepositoryProvider.notifier).toggleTopic(topic.name, newValue);
                      },
                      onRemove: () async {
                        // Confirm removal
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.obsidian,
                            title: const Text('REMOVE TOPIC', style: TextStyle(color: AppTheme.goldAmber, letterSpacing: 1)),
                            content: Text('Completely remove "${ManageTopicsScreen.formatTopic(topic.name)}" from your intelligence stream?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref.read(briefingConfigRepositoryProvider.notifier).removeTopic(topic.name);
                        }
                      },
                    );
                  },
                  childCount: config.topics.length,
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
  final List<String> displayNames;
  final Function(String) onTap;

  const _RecommendedSection({
    required this.recommended, 
    required this.onTap,
    required this.displayNames,
  });

  @override
  Widget build(BuildContext context) {
    if (recommended.isEmpty) return const SizedBox.shrink(); // Don't show if no recommendations

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
                  label: Text(displayNames[index]),
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
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;

  const _TopicItem({
    required this.title, 
    required this.isEnabled, 
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Adjusted vertical padding
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
            Switch(
              value: isEnabled,
              onChanged: onToggle,
              activeColor: AppTheme.goldAmber,
              inactiveTrackColor: Colors.white10,
              inactiveThumbColor: Colors.white30,
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
              tooltip: 'Remove topic completely',
            ),
          ],
        ),
      ),
    );
  }
}
