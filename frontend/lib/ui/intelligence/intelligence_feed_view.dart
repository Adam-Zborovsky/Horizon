import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/models/briefing.dart';
import 'package:horizon/repositories/briefing_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class IntelligenceFeedView extends ConsumerWidget {
  const IntelligenceFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'GLOBAL INTELLIGENCE',
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
            icon: const Icon(Icons.search_rounded, color: AppTheme.neutralBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: briefingAsync.when(
        data: (briefing) {
          final newsItems = briefing.values
              .expand((cat) => cat.items)
              .where((item) => item.title != null)
              .toList();
          
          return RefreshIndicator(
            onRefresh: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
            backgroundColor: AppTheme.cardBg,
            color: AppTheme.neutralBlue,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                return _NewsFeedItem(item: newsItems[index]);
              },
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neutralBlue),
              SizedBox(height: 16),
              Text('DECODING GLOBAL SIGNALS...', style: TextStyle(letterSpacing: 1.5, fontSize: 10, color: AppTheme.textDim)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.negativeRed, size: 48),
              const SizedBox(height: 16),
              Text('INTEL LOSS: $err', style: const TextStyle(color: AppTheme.negativeRed)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(briefingRepositoryProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBg),
                child: const Text('REESTABLISH CONNECTION'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsFeedItem extends StatelessWidget {
  final BriefingItem item;
  const _NewsFeedItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.getSentimentColor(item.sentiment ?? 0.0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.source ?? "Intelligence Source"} • ${item.timestamp ?? "12m ago"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.5),
                        ),
                        const Spacer(),
                        const Icon(Icons.more_horiz_rounded, size: 16, color: AppTheme.textDim),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    if (item.takeaway != null) ...[
                      const SizedBox(height: 16),
                      _StrategicTakeawaySnippet(text: item.takeaway!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategicTakeawaySnippet extends StatelessWidget {
  final String text;
  const _StrategicTakeawaySnippet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralBlue.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.neutralBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
