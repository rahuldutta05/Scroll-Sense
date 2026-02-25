import 'package:flutter/material.dart';
import '../models/hive_adapters.dart';
import '../utils/app_theme.dart';
import 'score_ring.dart';
// Score Card with ring visualization
class ScoreCard extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;
  final bool isInverse;

  const ScoreCard({
    super.key,
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    this.isInverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayScore = score.round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ScoreRing(score: score / 100, color: color, size: 56),
          const SizedBox(height: 8),
          Text(
            '$displayScore',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// App Usage Card
class AppUsageCard extends StatelessWidget {
  final AppUsageRecord record;

  const AppUsageCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final hours = record.durationSeconds ~/ 3600;
    final minutes = (record.durationSeconds % 3600) ~/ 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    final appColor = _getAppColor(record.packageName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: appColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_getAppEmoji(record.packageName), style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.appName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(
                  '${record.openCount} opens',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: appColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                height: 4,
                child: LinearProgressIndicator(
                  value: record.durationSeconds / (8 * 3600),
                  backgroundColor: appColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(appColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAppColor(String packageName) {
    final colors = {
      'com.instagram.android': const Color(0xFFE1306C),
      'com.tiktok.android': const Color(0xFF69C9D0),
      'com.twitter.android': const Color(0xFF1DA1F2),
      'com.google.android.youtube': const Color(0xFFFF0000),
      'com.whatsapp': const Color(0xFF25D366),
      'com.snapchat.android': const Color(0xFFFFFC00),
      'com.spotify.music': const Color(0xFF1DB954),
    };
    return colors[packageName] ?? AppTheme.primary;
  }

  String _getAppEmoji(String packageName) {
    final emojis = {
      'com.instagram.android': '📸',
      'com.tiktok.android': '🎵',
      'com.twitter.android': '🐦',
      'com.google.android.youtube': '▶️',
      'com.whatsapp': '💬',
      'com.snapchat.android': '👻',
      'com.spotify.music': '🎧',
      'com.reddit.frontpage': '🔴',
    };
    return emojis[packageName] ?? '📱';
  }
}
