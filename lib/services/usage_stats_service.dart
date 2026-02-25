import 'package:flutter/services.dart';
import '../models/hive_adapters.dart';

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('com.scrollsense/usage_stats');

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod('hasUsagePermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {
      // Fallback: open settings manually
    }
  }

  static Future<List<AppUsageRecord>> getUsageStats({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final start = (startTime ?? DateTime.now().subtract(const Duration(days: 1)))
          .millisecondsSinceEpoch;
      final end = (endTime ?? DateTime.now()).millisecondsSinceEpoch;

      final List<dynamic> result = await _channel.invokeMethod('getUsageStats', {
        'startTime': start,
        'endTime': end,
      });

      return result.map((item) => AppUsageRecord(
        packageName: item['packageName'] as String,
        appName: item['appName'] as String,
        durationSeconds: ((item['totalTime'] as int) / 1000).round(),
        date: DateTime.now(),
        openCount: item['launchCount'] as int? ?? 0,
      )).toList();
    } catch (e) {
      return _getMockUsageData();
    }
  }

  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod('getForegroundApp');
    } catch (e) {
      return null;
    }
  }

  // Mock data for testing/demo
  static List<AppUsageRecord> _getMockUsageData() {
    final now = DateTime.now();
    return [
      AppUsageRecord(packageName: 'com.instagram.android', appName: 'Instagram',
          durationSeconds: 4320, date: now, openCount: 18),
      AppUsageRecord(packageName: 'com.google.android.youtube', appName: 'YouTube',
          durationSeconds: 3600, date: now, openCount: 8),
      AppUsageRecord(packageName: 'com.twitter.android', appName: 'Twitter/X',
          durationSeconds: 2700, date: now, openCount: 22),
      AppUsageRecord(packageName: 'com.whatsapp', appName: 'WhatsApp',
          durationSeconds: 1800, date: now, openCount: 35),
      AppUsageRecord(packageName: 'com.tiktok.android', appName: 'TikTok',
          durationSeconds: 5400, date: now, openCount: 12),
      AppUsageRecord(packageName: 'com.snapchat.android', appName: 'Snapchat',
          durationSeconds: 1200, date: now, openCount: 14),
      AppUsageRecord(packageName: 'com.google.android.gm', appName: 'Gmail',
          durationSeconds: 900, date: now, openCount: 6),
      AppUsageRecord(packageName: 'com.spotify.music', appName: 'Spotify',
          durationSeconds: 7200, date: now, openCount: 4),
    ];
  }

  static List<AppUsageRecord> getMockWeeklyData() {
    final data = <AppUsageRecord>[];
    final apps = [
      ('com.instagram.android', 'Instagram'),
      ('com.google.android.youtube', 'YouTube'),
      ('com.twitter.android', 'Twitter'),
      ('com.tiktok.android', 'TikTok'),
    ];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      for (final app in apps) {
        data.add(AppUsageRecord(
          packageName: app.$1,
          appName: app.$2,
          durationSeconds: (1800 + (i * 300) + (app.$2.length * 100)),
          date: date,
          openCount: 5 + i,
        ));
      }
    }
    return data;
  }

  static Map<int, int> getMockHourlyHeatmap() {
    return {
      0: 15, 1: 5, 2: 30, 3: 45, 4: 10, 5: 5,
      6: 20, 7: 60, 8: 45, 9: 30, 10: 40, 11: 55,
      12: 70, 13: 55, 14: 45, 15: 60, 16: 80, 17: 90,
      18: 95, 19: 100, 20: 85, 21: 75, 22: 88, 23: 92,
    };
  }
}
