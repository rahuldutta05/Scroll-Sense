import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'intervention_config_service.dart';
import 'digital_debt_service.dart';
import 'scroll_notification_service.dart';

class StreakData {
  /// Days in a row the user stayed under their daily screen-time goal
  final int budgetStreak;
  /// Days in a row with zero Level 4/5 hard interventions
  final int cleanStreak;
  /// Longest ever budget streak
  final int longestBudgetStreak;
  /// Total intervention-free days ever
  final int totalCleanDays;
  /// Today's date, used to check if streak is still live
  final DateTime lastChecked;

  const StreakData({
    this.budgetStreak = 0,
    this.cleanStreak = 0,
    this.longestBudgetStreak = 0,
    this.totalCleanDays = 0,
    required this.lastChecked,
  });

  StreakData copyWith({
    int? budgetStreak,
    int? cleanStreak,
    int? longestBudgetStreak,
    int? totalCleanDays,
    DateTime? lastChecked,
  }) =>
      StreakData(
        budgetStreak: budgetStreak ?? this.budgetStreak,
        cleanStreak: cleanStreak ?? this.cleanStreak,
        longestBudgetStreak: longestBudgetStreak ?? this.longestBudgetStreak,
        totalCleanDays: totalCleanDays ?? this.totalCleanDays,
        lastChecked: lastChecked ?? this.lastChecked,
      );

  Map<String, dynamic> toMap() => {
        'budgetStreak': budgetStreak,
        'cleanStreak': cleanStreak,
        'longestBudgetStreak': longestBudgetStreak,
        'totalCleanDays': totalCleanDays,
        'lastChecked': lastChecked.toIso8601String(),
      };

  factory StreakData.fromMap(Map<String, dynamic> m) => StreakData(
        budgetStreak: m['budgetStreak'] as int? ?? 0,
        cleanStreak: m['cleanStreak'] as int? ?? 0,
        longestBudgetStreak: m['longestBudgetStreak'] as int? ?? 0,
        totalCleanDays: m['totalCleanDays'] as int? ?? 0,
        lastChecked: DateTime.tryParse(m['lastChecked'] as String? ?? '') ?? DateTime.now(),
      );

  factory StreakData.initial() => StreakData(lastChecked: DateTime.now());
}

class StreakService {
  static const _key = 'streak_data';
  static const _box = 'settings';

  StreakData load() {
    if (!Hive.isBoxOpen(_box)) return StreakData.initial();
    final raw = Hive.box(_box).get(_key);
    if (raw == null) return StreakData.initial();
    try {
      return StreakData.fromMap(Map<String, dynamic>.from(jsonDecode(raw as String)));
    } catch (_) {
      return StreakData.initial();
    }
  }

  void save(StreakData data) {
    if (!Hive.isBoxOpen(_box)) return;
    Hive.box(_box).put(_key, jsonEncode(data.toMap()));
  }

  /// Called once per day (e.g. on app open). Checks yesterday's behaviour
  /// and updates streaks accordingly.
  Future<StreakData> recalculate({
    required List<InterventionEvent> recentEvents,
    required int dailyGoalMinutes,
    required int yesterdayUsageMinutes,
  }) async {
    var data = load();
    final today = DateTime.now();
    final lastDate = data.lastChecked;
    final daysSinceLast = _daysBetween(lastDate, today);

    // Only update once per calendar day
    if (daysSinceLast == 0) return data;

    // If more than 1 day has passed, streaks broke
    if (daysSinceLast > 1) {
      data = data.copyWith(
        budgetStreak: 0,
        cleanStreak: 0,
        lastChecked: today,
      );
      save(data);
      return data;
    }

    // ── Budget streak: was yesterday under the daily goal? ────────────────
    final underBudget = yesterdayUsageMinutes <= dailyGoalMinutes;
    final newBudget = underBudget ? data.budgetStreak + 1 : 0;
    final newLongest = newBudget > data.longestBudgetStreak
        ? newBudget
        : data.longestBudgetStreak;

    // ── Clean streak: no L4/L5 events yesterday ───────────────────────────
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final hadHardIntervention = recentEvents.any((e) =>
        e.level >= 4 &&
        _isSameDay(e.timestamp, yesterday));
    final newClean = hadHardIntervention ? 0 : data.cleanStreak + 1;
    final newCleanTotal = hadHardIntervention
        ? data.totalCleanDays
        : data.totalCleanDays + 1;

    data = data.copyWith(
      budgetStreak: newBudget,
      cleanStreak: newClean,
      longestBudgetStreak: newLongest,
      totalCleanDays: newCleanTotal,
      lastChecked: today,
    );
    save(data);

    // Fire milestone notifications for key streak days
    if (newBudget > 0 && (newBudget == 3 || newBudget == 7 || newBudget % 10 == 0)) {
      await ScrollNotificationService.sendStreakAchievement(days: newBudget);
      await ScrollNotificationService.persistInApp(
        title: '🔥 ${newBudget}-Day Streak!',
        body: '${newBudget} days under your screen time budget. Keep it going!',
        type: 'streak',
      );
    }

    return data;
  }

  static int _daysBetween(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Provider ────────────────────────────────────────────────────────────────

final streakProvider = FutureProvider<StreakData>((ref) async {
  final service = StreakService();
  final events = ref.watch(interventionLogProvider);
  final debtService = ref.read(digitalDebtServiceProvider);
  final debt = await debtService.calculate();

  return service.recalculate(
    recentEvents: events,
    dailyGoalMinutes: debt.dailyGoalMinutes,
    yesterdayUsageMinutes: debt.todayUsageMinutes, // best approximation without daily snapshots
  );
});
