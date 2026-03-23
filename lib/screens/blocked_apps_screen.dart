import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/intervention_config_service.dart';
import '../utils/app_theme.dart';

class BlockedAppsScreen extends ConsumerWidget {
  const BlockedAppsScreen({super.key});

  // App catalogue — extend as needed
  static const _catalogue = [
    _AppEntry('com.instagram.android', 'Instagram', '📸', 'Photo & Video'),
    _AppEntry('com.tiktok.android', 'TikTok', '🎵', 'Short Video'),
    _AppEntry('com.google.android.youtube', 'YouTube', '▶️', 'Video'),
    _AppEntry('com.twitter.android', 'Twitter / X', '🐦', 'Social'),
    _AppEntry('com.snapchat.android', 'Snapchat', '👻', 'Messaging'),
    _AppEntry('com.reddit.frontpage', 'Reddit', '🔴', 'Forum'),
    _AppEntry('com.facebook.katana', 'Facebook', '👥', 'Social'),
    _AppEntry('com.zhiliaoapp.musically', 'TikTok (Alt)', '🎵', 'Short Video'),
    _AppEntry('com.pinterest', 'Pinterest', '📌', 'Discovery'),
    _AppEntry('com.linkedin.android', 'LinkedIn', '💼', 'Professional'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(interventionConfigProvider);
    final blocked = config.blockedApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Apps', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${blocked.length} blocked',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Blocked apps are monitored more aggressively. '
                    'Interventions trigger at half the usual threshold.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick-select all social
          _QuickSelectBar(
            onSelectAll: () {
              final all = _catalogue.map((e) => e.pkg).toList();
              ref.read(interventionConfigProvider.notifier).setBlockedApps(all);
            },
            onClearAll: () {
              ref.read(interventionConfigProvider.notifier).setBlockedApps([]);
            },
          ),
          const SizedBox(height: 16),

          // App list
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _catalogue.indexed.map((entry) {
                final (i, app) = entry;
                final isBlocked = blocked.contains(app.pkg);
                return Column(
                  children: [
                    _AppTile(
                      app: app,
                      isBlocked: isBlocked,
                      onToggle: () {
                        ref.read(interventionConfigProvider.notifier).toggleApp(app.pkg);
                      },
                    ),
                    if (i < _catalogue.length - 1)
                      Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.1)),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Custom app note
          Center(
            child: Text(
              'More apps are tracked automatically via the accessibility service.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AppEntry {
  final String pkg;
  final String name;
  final String emoji;
  final String category;
  const _AppEntry(this.pkg, this.name, this.emoji, this.category);
}

class _AppTile extends StatelessWidget {
  final _AppEntry app;
  final bool isBlocked;
  final VoidCallback onToggle;
  const _AppTile({required this.app, required this.isBlocked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isBlocked ? AppTheme.accent.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(app.emoji, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(app.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Switch(
          value: isBlocked,
          onChanged: (_) => onToggle(),
          activeColor: AppTheme.accent,
        ),
      ),
      onTap: onToggle,
    );
  }
}

class _QuickSelectBar extends StatelessWidget {
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  const _QuickSelectBar({required this.onSelectAll, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSelectAll,
            icon: const Icon(Icons.select_all_rounded, size: 16),
            label: const Text('Block all', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: BorderSide(color: AppTheme.accent.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Clear all', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
