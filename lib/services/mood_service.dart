import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_record.dart';

class MoodService {
  static const _boxName = 'mood_records';

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<void> saveMood(MoodRecord record) async {
    final box = await _openBox();
    await box.put(record.id, jsonEncode(record.toJson()));
  }

  Future<List<MoodRecord>> getHistory({int days = 30}) async {
    final box = await _openBox();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final records = box.values
        .map((v) => MoodRecord.fromJson(jsonDecode(v as String)))
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Future<List<MoodRecord>> getAll() => getHistory(days: 365);

  /// Average mood score (1–5) keyed by hour of day.
  Future<Map<int, double>> getMoodByHour() async {
    final records = await getHistory();
    final buckets = <int, List<int>>{};
    for (final r in records) {
      buckets.putIfAbsent(r.timestamp.hour, () => []).add(r.mood);
    }
    return buckets.map(
      (h, moods) => MapEntry(h, moods.reduce((a, b) => a + b) / moods.length),
    );
  }

  /// Average mood score (1–5) keyed by package name.
  Future<Map<String, double>> getMoodByApp() async {
    final records = await getHistory();
    final buckets = <String, List<int>>{};
    for (final r in records) {
      if (r.sessionApp != null) {
        buckets.putIfAbsent(r.sessionApp!, () => []).add(r.mood);
      }
    }
    return buckets.map(
      (app, moods) => MapEntry(app, moods.reduce((a, b) => a + b) / moods.length),
    );
  }

  /// Rolling 7-day average mood for sparkline.
  Future<List<double>> getWeeklyMoodTrend() async {
    final result = <double>[];
    for (int d = 6; d >= 0; d--) {
      final day = DateTime.now().subtract(Duration(days: d));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final records = (await getHistory()).where(
        (r) => r.timestamp.isAfter(dayStart) && r.timestamp.isBefore(dayEnd),
      );
      if (records.isEmpty) {
        result.add(3.0); // neutral fallback
      } else {
        final avg = records.map((r) => r.mood).reduce((a, b) => a + b) /
            records.length;
        result.add(avg);
      }
    }
    return result;
  }

  Future<void> deleteAll() async {
    final box = await _openBox();
    await box.clear();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final moodServiceProvider = Provider<MoodService>((ref) => MoodService());

final moodHistoryProvider = FutureProvider<List<MoodRecord>>((ref) {
  return ref.read(moodServiceProvider).getHistory();
});

final moodByHourProvider = FutureProvider<Map<int, double>>((ref) {
  return ref.read(moodServiceProvider).getMoodByHour();
});

final moodByAppProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.read(moodServiceProvider).getMoodByApp();
});

final weeklyMoodTrendProvider = FutureProvider<List<double>>((ref) {
  return ref.read(moodServiceProvider).getWeeklyMoodTrend();
});
