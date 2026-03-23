import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return [];
    }
  }

  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod('getForegroundApp');
    } catch (e) {
      return null;
    }
  }

  static Future<List<AppUsageRecord>> getWeeklyData() async {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return getUsageStats(startTime: start);
  }

  static Future<Map<int, int>> getHourlyHeatmap() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getHourlyHeatmap');
      if (result == null) return {};
      // Keys are strings from Android
      return result.map((key, value) => MapEntry(int.parse(key as String), value as int));
    } catch (e) {
      return {};
    }
  }
}
// ─── Providers ──────────────────────────────────────────────────────────────
final usageStatsServiceProvider = Provider<UsageStatsService>((ref) => UsageStatsService());

/// Today's device usage in seconds (aggregated)
final dailyDeviceUsageProvider = FutureProvider<int>((ref) async {
  final records = await UsageStatsService.getUsageStats();
  int total = 0;
  for (var record in records) {
    total += record.durationSeconds;
  }
  return total;
});

