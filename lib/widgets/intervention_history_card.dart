import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/intervention_config_service.dart';
import '../utils/app_theme.dart';

/// Shows the last N intervention events inline on home/insights screen.
class InterventionHistoryCard extends ConsumerWidget {
  final int maxItems;
  const InterventionHistoryCard({super.key, this.maxItems = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(interventionLogProvider);

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No interventions yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Great scrolling habits! 🎉', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }

    final shown = events.take(maxItems).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text('Recent Interventions',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${events.length} total',
                    style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ...shown.indexed.map((entry) {
            final (i, event) = entry;
            return Column(
              children: [
                _EventRow(event: event),
                if (i < shown.length - 1)
                  Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.08)),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final InterventionEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = InterventionConfig.levelColor(event.level);
    final icon = InterventionConfig.levelIcon(event.level);
    final label = InterventionConfig.levelLabel(event.level);
    final appName = _friendlyName(event.packageName);
    final timeAgo = _timeAgo(event.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (event.wasSkipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('skipped', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$appName • $timeAgo',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Level badge
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'L${event.level}',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _friendlyName(String pkg) {
    const map = {
      'com.instagram.android': 'Instagram',
      'com.tiktok.android': 'TikTok',
      'com.twitter.android': 'Twitter',
      'com.snapchat.android': 'Snapchat',
      'com.reddit.frontpage': 'Reddit',
      'com.facebook.katana': 'Facebook',
      'com.google.android.youtube': 'YouTube',
    };
    return map[pkg] ?? pkg.split('.').last;
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
