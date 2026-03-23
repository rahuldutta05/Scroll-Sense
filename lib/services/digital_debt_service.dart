import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'usage_stats_service.dart';

class DigitalDebtData {
  final int dailyGoalMinutes;
  final int todayUsageMinutes;
  final int weeklyUsageMinutes;
  final int baselineWeeklyMinutes;

  const DigitalDebtData({
    required this.dailyGoalMinutes,
    required this.todayUsageMinutes,
    required this.weeklyUsageMinutes,
    required this.baselineWeeklyMinutes,
  });

  // Positive = over budget, negative = under budget
  int get debtMinutes => todayUsageMinutes - dailyGoalMinutes;

  // Positive = improved vs baseline
  int get weeklyTimeSavedMinutes => baselineWeeklyMinutes - weeklyUsageMinutes;

  bool get isOverBudget => debtMinutes > 0;

  // 0.0 = no usage, 1.0 = hit goal, 2.0 = double the goal
  double get debtProgress =>
      dailyGoalMinutes > 0 ? (todayUsageMinutes / dailyGoalMinutes).clamp(0.0, 2.0) : 0.0;

  String get debtLabel {
    final abs = debtMinutes.abs();
    final formatted = _fmtMins(abs);
    return isOverBudget ? '$formatted over budget' : '$formatted remaining';
  }

  String get savedLabel {
    if (weeklyTimeSavedMinutes <= 0) return 'Set a goal to track savings';
    return '${_fmtMins(weeklyTimeSavedMinutes)} reclaimed this week';
  }

  String get todayLabel => _fmtMins(todayUsageMinutes);
  String get goalLabel => _fmtMins(dailyGoalMinutes);

  static String _fmtMins(int minutes) {
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '${minutes}m';
  }
}

class DigitalDebtService {
  static const _box = 'settings';
  static const _goalKey = 'daily_goal_minutes';
  static const _baselineKey = 'baseline_weekly_minutes';
  static const _defaultGoal = 120; // 2 hours

  int getDailyGoal() {
    if (!Hive.isBoxOpen(_box)) return _defaultGoal;
    return Hive.box(_box).get(_goalKey, defaultValue: _defaultGoal) as int;
  }

  void setDailyGoal(int minutes) {
    if (Hive.isBoxOpen(_box)) {
      Hive.box(_box).put(_goalKey, minutes);
    }
  }

  void _setBaseline(int weeklyMinutes) {
    if (Hive.isBoxOpen(_box)) {
      Hive.box(_box).put(_baselineKey, weeklyMinutes);
    }
  }

  Future<DigitalDebtData> calculate() async {
    final goal = getDailyGoal();

    // Today
    final todayRecords = await UsageStatsService.getUsageStats();
    final todaySeconds = todayRecords.fold(0, (s, r) => s + r.durationSeconds);
    final todayMinutes = todaySeconds ~/ 60;

    // Weekly
    final weeklyRecords = await UsageStatsService.getWeeklyData();
    final weeklySeconds = weeklyRecords.fold(0, (s, r) => s + r.durationSeconds);
    final weeklyMinutes = weeklySeconds ~/ 60;

    // Baseline: stored on first run; auto-refreshes if no baseline yet
    int baseline;
    if (Hive.isBoxOpen(_box)) {
      final stored = Hive.box(_box).get(_baselineKey);
      if (stored == null) {
        // First run – treat this week as 110% of current (so savings appear later)
        baseline = (weeklyMinutes * 1.1).round();
        _setBaseline(baseline);
      } else {
        baseline = stored as int;
      }
    } else {
      baseline = (weeklyMinutes * 1.1).round();
    }

    return DigitalDebtData(
      dailyGoalMinutes: goal,
      todayUsageMinutes: todayMinutes,
      weeklyUsageMinutes: weeklyMinutes,
      baselineWeeklyMinutes: baseline,
    );
  }

  /// Call this to reset the baseline (e.g. on a new month).
  Future<void> resetBaseline() async {
    final weeklyRecords = await UsageStatsService.getWeeklyData();
    final weeklySeconds = weeklyRecords.fold(0, (s, r) => s + r.durationSeconds);
    _setBaseline(weeklySeconds ~/ 60);
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final digitalDebtServiceProvider =
    Provider<DigitalDebtService>((ref) => DigitalDebtService());

final digitalDebtProvider = FutureProvider<DigitalDebtData>((ref) {
  return ref.read(digitalDebtServiceProvider).calculate();
});

final dailyGoalProvider = StateProvider<int>((ref) {
  return ref.read(digitalDebtServiceProvider).getDailyGoal();
});
