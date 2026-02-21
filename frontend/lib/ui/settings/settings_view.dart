import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/core/theme/app_theme.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('SYSTEM SETTINGS', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsSection(
            title: 'AI CONFIGURATION',
            items: [
              _SettingsItem(label: 'Analysis Depth', value: 'High Fidelity', icon: Icons.psychology),
              _SettingsItem(label: 'Real-time Ticker Feed', value: 'Enabled', icon: Icons.bolt),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'ACCOUNT',
            items: [
              _SettingsItem(label: 'Subscription', value: 'Alpha Pro', icon: Icons.verified_user),
              _SettingsItem(label: 'Notifications', value: 'Critical Only', icon: Icons.notifications),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SettingsItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.neutralBlue),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textDim)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textDim),
        ],
      ),
    );
  }
}
