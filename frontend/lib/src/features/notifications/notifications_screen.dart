import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Notifications',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const _NotificationItem(
                type: NotificationType.marketAlert,
                title: 'MU Breakout',
                message: 'Micron broke major resistance at \$105. High volume detected.',
                time: '2m ago',
              ),
              const _NotificationItem(
                type: NotificationType.intelUpdate,
                title: 'Daily Briefing Ready',
                message: 'Your tactical intelligence report for Feb 21 is now available.',
                time: '1h ago',
              ),
              const _NotificationItem(
                type: NotificationType.system,
                title: 'Watchlist Synced',
                message: 'Your watchlist has been successfully synced with the backend.',
                time: '3h ago',
              ),
              const _NotificationItem(
                type: NotificationType.marketAlert,
                title: 'NVDA Pullback',
                message: 'NVIDIA is testing the 50-day moving average support level.',
                time: '5h ago',
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

enum NotificationType { marketAlert, intelUpdate, system }

class _NotificationItem extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String message;
  final String time;

  const _NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case NotificationType.marketAlert:
        iconColor = AppTheme.goldAmber;
        iconData = Icons.bolt_rounded;
        break;
      case NotificationType.intelUpdate:
        iconColor = Colors.blueAccent;
        iconData = Icons.article_rounded;
        break;
      case NotificationType.system:
        iconColor = Colors.white38;
        iconData = Icons.sync_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
