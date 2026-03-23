import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hive_adapters.dart';

/// Manages reading/writing FocusSession records from the 'focus_sessions' Hive box.
class FocusSessionStore {
  static const _boxName = 'focus_sessions';

  Box get _box => Hive.box(_boxName);

  Future<void> save(FocusSession session) async {
    await _box.put(session.id, session);
  }

  List<FocusSession> getAll() {
    return _box.values.cast<FocusSession>().toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<FocusSession> getLast7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getAll().where((s) => s.startTime.isAfter(cutoff)).toList();
  }

  List<FocusSession> getCompleted() =>
      getAll().where((s) => s.completed).toList();

  /// Total completed focus minutes in the last 7 days
  int weeklyFocusMinutes() {
    return getLast7Days()
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Number of completed sessions today
  int todaySessionCount() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return getAll()
        .where((s) => s.completed && s.startTime.isAfter(todayStart))
        .length;
  }

  /// Completed minutes per day for the last 7 days (index 0 = oldest)
  List<double> dailyFocusMinutesLast7() {
    final result = List<double>.filled(7, 0.0);
    final now = DateTime.now();
    for (final s in getLast7Days()) {
      if (!s.completed) continue;
      final daysAgo = now.difference(s.startTime).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        result[6 - daysAgo] += s.durationMinutes;
      }
    }
    return result;
  }

  /// Current focus streak: consecutive days with at least one completed session
  int focusStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int d = 0; d < 60; d++) {
      final day = DateTime(now.year, now.month, now.day - d);
      final dayEnd = day.add(const Duration(days: 1));
      final hasSession = getAll().any(
        (s) => s.completed && s.startTime.isAfter(day) && s.startTime.isBefore(dayEnd),
      );
      if (hasSession) {
        streak++;
      } else if (d > 0) {
        break; // gap — streak ends
      }
    }
    return streak;
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final focusSessionStoreProvider =
    Provider<FocusSessionStore>((ref) => FocusSessionStore());

/// Daily focus minutes for the last 7 days — drives bar charts
final dailyFocusMinutesProvider = Provider<List<double>>((ref) {
  return ref.read(focusSessionStoreProvider).dailyFocusMinutesLast7();
});

/// Weekly total focus minutes
final weeklyFocusMinutesProvider = Provider<int>((ref) {
  return ref.read(focusSessionStoreProvider).weeklyFocusMinutes();
});

/// Current focus streak
final focusStreakProvider = Provider<int>((ref) {
  return ref.read(focusSessionStoreProvider).focusStreak();
});

/// All completed sessions summary for reports
final completedSessionsProvider = Provider<List<FocusSession>>((ref) {
  return ref.read(focusSessionStoreProvider).getCompleted();
});
