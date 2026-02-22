import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../briefing/briefing_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      Color(0x22FFB800),
                      AppTheme.obsidian,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldAmber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldAmber.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Adam Zborovsky',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.goldAmber.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'ALPHA TIER',
                        style: TextStyle(
                          color: AppTheme.goldAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const _StatsRow(),
                  const SizedBox(height: 30),
                  _SettingsGroup(
                    title: 'ACCOUNT',
                    items: [
                      _SettingsItem(icon: Icons.person_outline_rounded, title: 'Personal Information'),
                      _SettingsItem(icon: Icons.lock_outline_rounded, title: 'Security & Privacy'),
                      _SettingsItem(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric Auth',
                        trailing: Switch(
                          value: true,
                          onChanged: (v) {},
                          activeColor: AppTheme.goldAmber,
                          activeTrackColor: AppTheme.goldAmber.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsGroup(
                    title: 'PREFERENCES',
                    items: [
                      _SettingsItem(icon: Icons.notifications_outlined, title: 'Notifications'),
                      _SettingsItem(icon: Icons.palette_outlined, title: 'Appearance', trailing: const Text('Dark', style: TextStyle(color: Colors.white38))),
                      _SettingsItem(icon: Icons.language_outlined, title: 'Language', trailing: const Text('English', style: TextStyle(color: Colors.white38))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsGroup(
                    title: 'ALPHA HORIZON CONFIG',
                    items: [
                      _SettingsItem(
                        icon: Icons.refresh_rounded, 
                        title: 'Manual Intelligence Refresh',
                        onTap: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Triggering Alpha Intelligence...'), backgroundColor: AppTheme.obsidian),
                            );
                            await ref.read(briefingRepositoryProvider.notifier).triggerBriefing();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Intelligence workflow started. Check back soon.'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Trigger failed: $e'), backgroundColor: AppTheme.softCrimson),
                            );
                          }
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.topic_rounded, 
                        title: 'Manage Intelligence Topics',
                        onTap: () => context.push('/manage-topics'),
                      ),
                      _SettingsItem(
                        icon: Icons.list_alt_rounded, 
                        title: 'Manage Global Watchlist',
                        onTap: () => context.push('/manage-watchlist'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.softCrimson),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: AppTheme.softCrimson,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Stocks Watched', value: '12')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Alpha Score', value: '94')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Signals Caught', value: '8')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.goldAmber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({required this.icon, required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
