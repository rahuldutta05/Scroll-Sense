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

      final List<dynamic>? result = await _channel.invokeMethod('getUsageStats', {
        'startTime': start,
        'endTime': end,
      });

      if (result == null) return [];

      return result.map<AppUsageRecord>((item) {
        final map = item as Map<dynamic, dynamic>;
        return AppUsageRecord(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          durationSeconds: ((map['totalTime'] as int) / 1000).round(),
          date: DateTime.now(),
          openCount: 0, // open count not tracked per user preference
        );
      }).toList();
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

// Basic app categorization for stacked charts
enum AppCategory { social, entertainment, productive, other }

AppCategory categorizeApp(String packageName) {
  final p = packageName.toLowerCase();
  if (p.contains('instagram') || p.contains('facebook') || p.contains('twitter') || 
      p.contains('tiktok') || p.contains('snapchat') || p.contains('reddit') || p.contains('discord') || p.contains('whatsapp')) {
    return AppCategory.social;
  }
  if (p.contains('youtube') || p.contains('netflix') || p.contains('spotify') || 
      p.contains('twitch') || p.contains('prime') || p.contains('hulu')) {
    return AppCategory.entertainment;
  }
  if (p.contains('docs') || p.contains('mail') || p.contains('slack') || 
      p.contains('notion') || p.contains('calendar') || p.contains('teams') || p.contains('chrome') || p.contains('zoom')) {
    return AppCategory.productive;
  }
  return AppCategory.other;
}

class DailyCategorizedUsage {
  final double socialHours;
  final double entertainmentHours;
  final double productiveHours;
  final double otherHours;
  
  DailyCategorizedUsage(this.socialHours, this.entertainmentHours, this.productiveHours, this.otherHours);
  
  double get totalHours => socialHours + entertainmentHours + productiveHours + otherHours;
}

/// Fetches categorized daily usage for the last 7 days
final weeklyCategorizedUsageProvider = FutureProvider<List<DailyCategorizedUsage>>((ref) async {
  List<DailyCategorizedUsage> weeklyData = [];
  final now = DateTime.now();
  
  for (int i = 0; i < 7; i++) {
    // 0 is 6 days ago, 6 is today
    final dayStart = DateTime(now.year, now.month, now.day - (6 - i));
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    final stats = await UsageStatsService.getUsageStats(startTime: dayStart, endTime: dayEnd);
    
    double social = 0;
    double entertainment = 0;
    double productive = 0;
    double other = 0;
    
    for (var record in stats) {
      final hours = record.durationSeconds / 3600.0;
      switch (categorizeApp(record.packageName)) {
        case AppCategory.social:
          social += hours;
          break;
        case AppCategory.entertainment:
          entertainment += hours;
          break;
        case AppCategory.productive:
          productive += hours;
          break;
        case AppCategory.other:
          other += hours;
          break;
      }
    }
    
    weeklyData.add(DailyCategorizedUsage(social, entertainment, productive, other));
  }
  
  return weeklyData;
});
