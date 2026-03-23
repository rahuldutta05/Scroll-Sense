import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../widgets/score_ring.dart';
import '../services/streak_service.dart';
import '../services/intervention_config_service.dart';
import '../services/focus_session_store.dart';
import '../services/focus_session_store.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            title: const Text('Reports & Progress', style: TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Weekly'), Tab(text: 'Streaks'), Tab(text: 'Achievements')],
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primary,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWeeklyReport(),
            _buildStreaksTab(),
            _buildAchievementsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero summary card
          _buildWeeklySummaryCard(),
          const SizedBox(height: 20),

          // Key metrics
          _buildKeyMetricsGrid(),
          const SizedBox(height: 20),

          // Focus improvement
          _buildFocusImprovement(),
          const SizedBox(height: 20),

          // Distraction triggers
          _buildDistractionTriggers(),
          const SizedBox(height: 20),

          // Productive hours
          _buildProductiveHours(),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    final store = FocusSessionStore();
    final sessionCount = store.getLast7Days().where((s) => s.completed).length;
    final focusMins = store.weeklyFocusMinutes();
    final streak = store.focusStreak();
    final events = ref.read(interventionLogProvider);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weeklyInterventions = events.where((e) => e.timestamp.isAfter(weekStart)).length;

    final now = DateTime.now();
    final weekLabel = '${_monthName(now.month)} ${now.day - 6}–${now.day}';

    String headline;
    String subline;
    if (focusMins >= 120) {
      headline = '📈 Great Progress!';
      subline = 'You completed $sessionCount focus sessions this week with ${focusMins ~/ 60}h ${focusMins % 60}m of deep work.';
    } else if (sessionCount > 0) {
      headline = '🌱 Getting Started';
      subline = '$sessionCount focus session${sessionCount == 1 ? '' : 's'} completed. Build the habit — aim for one session per day.';
    } else {
      headline = '💤 Quiet Week';
      subline = 'No focus sessions logged. Try starting with just 25 minutes using Pomodoro mode.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly Report', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(weekLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(headline, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subline, style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WhiteStat(
                label: 'Focus Time',
                value: '${focusMins ~/ 60}h ${focusMins % 60}m',
                delta: '$sessionCount sessions',
              ),
              _WhiteStat(
                label: 'Focus Streak',
                value: '${streak}d',
                delta: streak > 0 ? '🔥 active' : 'start today',
              ),
              _WhiteStat(
                label: 'Interventions',
                value: '$weeklyInterventions',
                delta: weeklyInterventions == 0 ? '✓ clean' : 'this week',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    final store = FocusSessionStore();
    final streak = store.focusStreak();
    final focusMins = store.weeklyFocusMinutes();
    final avgDaily = focusMins ~/ 7;
    final events = ref.read(interventionLogProvider);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weeklyInterventions = events.where((e) => e.timestamp.isAfter(weekStart)).length;
    final hardLocks = events.where((e) => e.level >= 5 && e.timestamp.isAfter(weekStart)).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _MetricCard(emoji: '🎯', label: 'Focus Streak', value: '$streak day${streak == 1 ? '' : 's'}', color: AppTheme.primary),
        _MetricCard(emoji: '⏱️', label: 'Avg Daily Focus', value: '${avgDaily}m', color: AppTheme.success),
        _MetricCard(emoji: '⚠️', label: 'Total Interventions', value: '$weeklyInterventions', color: AppTheme.warning),
        _MetricCard(emoji: '🔒', label: 'Hard Locks', value: '$hardLocks', color: AppTheme.accent),
      ],
    );
  }

  Widget _buildFocusImprovement() {
    final store = FocusSessionStore();
    final daily = store.dailyFocusMinutesLast7();
    final maxMins = daily.reduce((a, b) => a > b ? a : b);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0=Mon

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Minutes by Day', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Completed focus sessions for this week', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final mins = daily[i];
              final ratio = maxMins > 0 ? (mins / maxMins).clamp(0.05, 1.0) : 0.05;
              final isToday = i == today;
              final label = mins >= 60
                  ? '${mins ~/ 60}h'
                  : mins > 0 ? '${mins.round()}m' : '—';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(
                    fontSize: 9,
                    color: isToday ? AppTheme.primary : Colors.grey,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  )),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 28,
                    height: (80 * ratio).clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primary
                          : mins > 0
                              ? AppTheme.primary.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDistractionTriggers() {
    // Build from real intervention event log
    final events = ref.read(interventionLogProvider);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weekEvents = events.where((e) => e.timestamp.isAfter(weekStart)).toList();

    // Count by app
    final counts = <String, int>{};
    for (final e in weekEvents) {
      counts[e.packageName] = (counts[e.packageName] ?? 0) + 1;
    }

    const appMeta = {
      'com.instagram.android': ('Instagram', '📸'),
      'com.tiktok.android': ('TikTok', '🎵'),
      'com.twitter.android': ('Twitter', '🐦'),
      'com.snapchat.android': ('Snapchat', '👻'),
      'com.reddit.frontpage': ('Reddit', '🔴'),
      'com.facebook.katana': ('Facebook', '👥'),
      'com.google.android.youtube': ('YouTube', '▶️'),
    };

    final triggers = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = triggers.isNotEmpty ? triggers.first.value : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Distraction Triggers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Apps that triggered interventions this week',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (triggers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text('✅', style: TextStyle(fontSize: 22)),
                SizedBox(width: 12),
                Text('No interventions triggered this week!',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          ...triggers.take(5).map((entry) {
            final meta = appMeta[entry.key];
            final name = meta?.$1 ?? entry.key.split('.').last;
            final emoji = meta?.$2 ?? '📱';
            final ratio = entry.value / maxCount;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: AppTheme.accent.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                          borderRadius: BorderRadius.circular(3),
                          minHeight: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${entry.value}',
                          style: const TextStyle(
                              color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('triggers', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProductiveHours() {
    // Derive best focus window from focus sessions (which hours had most sessions)
    final store = FocusSessionStore();
    final sessions = store.getCompleted();
    final hourCounts = List<int>.filled(24, 0);
    for (final s in sessions) {
      hourCounts[s.startTime.hour]++;
    }
    final maxCount = hourCounts.reduce((a, b) => a > b ? a : b);
    String bestWindow = 'No sessions yet';
    String bestEmoji = '💤';
    if (maxCount > 0) {
      final bestHour = hourCounts.indexOf(maxCount);
      final endHour = (bestHour + 3) % 24;
      bestWindow = '${_fmtHour(bestHour)} – ${_fmtHour(endHour)}';
      bestEmoji = bestHour < 12 ? '🌅' : bestHour < 17 ? '☀️' : '🌆';
    }

    // Worst hour = most interventions
    final events = ref.read(interventionLogProvider);
    final worstHourCounts = List<int>.filled(24, 0);
    for (final e in events) {
      worstHourCounts[e.timestamp.hour]++;
    }
    final worstMax = worstHourCounts.reduce((a, b) => a > b ? a : b);
    String worstWindow = 'None detected';
    String worstEmoji = '✅';
    if (worstMax > 0) {
      final worstHour = worstHourCounts.indexOf(worstMax);
      worstWindow = 'Around ${_fmtHour(worstHour)}';
      worstEmoji = worstHour >= 22 || worstHour <= 4 ? '🌙' : '⚠️';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Focus Patterns', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Based on all your logged sessions', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(bestEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Best Focus Window', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(bestWindow, style: const TextStyle(
                        color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${sessions.length} total sessions logged',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text(worstEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('High Risk Zone', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(worstWindow, style: const TextStyle(
                        color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${worstMax > 0 ? worstMax : 0} interventions at peak hour',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current streak
          _buildStreakHero(),
          const SizedBox(height: 20),

          // Calendar-style streak view
          _buildStreakCalendar(),
          const SizedBox(height: 20),

          // Streak goals
          _buildStreakGoals(),
        ],
      ),
    );
  }

  Widget _buildStreakHero() {
    final streakAsync = ref.watch(streakProvider);
    return streakAsync.when(
      loading: () => Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) {
        final events = ref.read(interventionLogProvider);
        final hardCount = events.where((e) => e.level >= 4).length;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    streak.budgetStreak > 0 ? '🔥' : '💤',
                    style: const TextStyle(fontSize: 52),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget Streak', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          '${streak.budgetStreak} Days',
                          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Best: ${streak.longestBudgetStreak} days',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WhiteStatLive(
                    label: 'No-lock streak',
                    value: '${streak.cleanStreak}d',
                  ),
                  _WhiteStatLive(
                    label: 'Clean days ever',
                    value: '${streak.totalCleanDays}',
                  ),
                  _WhiteStatLive(
                    label: 'Hard interventions',
                    value: '$hardCount',
                    danger: hardCount > 5,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    final events = ref.read(interventionLogProvider);
    final monthName = _monthName(today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    // Build set of days that had hard interventions
    final hardDays = events
        .where((e) => e.level >= 4 && e.timestamp.month == today.month)
        .map((e) => e.timestamp.day)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$monthName ${today.year}', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  _CalLegend(color: AppTheme.success, label: 'Clean day'),
                  const SizedBox(width: 12),
                  _CalLegend(color: AppTheme.accent, label: 'Hard lock'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Day-of-week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(fontSize: 10, color: Colors.grey))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: daysInMonth,
            itemBuilder: (ctx, i) {
              final day = i + 1;
              final isToday = day == today.day;
              final isFuture = day > today.day;
              final hasHardLock = hardDays.contains(day);
              final isClean = !isFuture && !hasHardLock && day <= today.day;

              Color? bg;
              Color textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
              if (isToday) {
                bg = AppTheme.primary;
                textColor = Colors.white;
              } else if (hasHardLock) {
                bg = AppTheme.accent.withOpacity(0.2);
                textColor = AppTheme.accent;
              } else if (isClean) {
                bg = AppTheme.success.withOpacity(0.15);
                textColor = AppTheme.success;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$day',
                    style: TextStyle(fontSize: 11, color: textColor,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w400)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m >= 1 && m <= 12 ? names[m] : '';
  }

  static String _fmtHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  Widget _buildStreakGoals() {
    final streakAsync = ref.watch(streakProvider);
    final store = FocusSessionStore();
    final focusMins = store.weeklyFocusMinutes();
    final events = ref.read(interventionLogProvider);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weekLocks = events.where((e) => e.level >= 4 && e.timestamp.isAfter(weekStart)).length;

    return streakAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) {
        // Focus goal: 120 min/week (2h) is baseline; scale to how close they are
        final focusGoalMins = 120;
        final focusProgress = (focusMins / focusGoalMins).clamp(0.0, 1.0);

        // Clean-day goal: 5 clean days in a row
        final cleanProgress = (streak.cleanStreak / 5).clamp(0.0, 1.0);

        // Lock-free week goal
        final lockProgress = weekLocks == 0 ? 1.0 : (1.0 - (weekLocks / 5)).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week\'s Goals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _GoalCard(
              emoji: '🎯',
              title: 'Focus 2h this week',
              progress: focusProgress,
              current: '${focusMins ~/ 60}h ${focusMins % 60}m',
              target: '2h',
            ),
            const SizedBox(height: 8),
            _GoalCard(
              emoji: '🛡️',
              title: '5-day no hard lock streak',
              progress: cleanProgress,
              current: '${streak.cleanStreak} day${streak.cleanStreak == 1 ? '' : 's'}',
              target: '5 days',
            ),
            const SizedBox(height: 8),
            _GoalCard(
              emoji: '🔓',
              title: 'Lock-free week',
              progress: lockProgress,
              current: weekLocks == 0 ? 'Clean ✓' : '$weekLocks locks triggered',
              target: '0 locks',
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    final streakAsync = ref.watch(streakProvider);
    final events = ref.watch(interventionLogProvider);

    return streakAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) {
        final hardCount = events.where((e) => e.level >= 4).length;

        final achievements = [
          _Achievement(
            emoji: '🔥',
            title: 'First Streak',
            desc: 'Get a 1-day budget streak',
            unlocked: streak.budgetStreak >= 1,
          ),
          _Achievement(
            emoji: '⚡',
            title: 'Week Warrior',
            desc: '7-day budget streak',
            unlocked: streak.longestBudgetStreak >= 7,
          ),
          _Achievement(
            emoji: '🏆',
            title: 'Month Master',
            desc: '30-day budget streak',
            unlocked: streak.longestBudgetStreak >= 30,
          ),
          _Achievement(
            emoji: '🛡️',
            title: 'Shield Up',
            desc: 'First clean day (no hard lock)',
            unlocked: streak.totalCleanDays >= 1,
          ),
          _Achievement(
            emoji: '🌙',
            title: 'Night Owl No More',
            desc: '5 clean days in a row',
            unlocked: streak.cleanStreak >= 5,
          ),
          _Achievement(
            emoji: '📵',
            title: 'Social Detox',
            desc: '10 clean days ever',
            unlocked: streak.totalCleanDays >= 10,
          ),
          _Achievement(
            emoji: '🎯',
            title: 'Productivity Pro',
            desc: 'Under 5 total hard interventions',
            unlocked: hardCount < 5 && events.isNotEmpty,
          ),
          _Achievement(
            emoji: '💎',
            title: 'Digital Minimalist',
            desc: '30 total clean days',
            unlocked: streak.totalCleanDays >= 30,
          ),
        ];

        final unlocked = achievements.where((a) => a.unlocked).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('$unlocked / ${achievements.length} unlocked',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  Text(
                    '${(unlocked / achievements.length * 100).round()}% complete',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: achievements.length,
                itemBuilder: (ctx, i) => _AchievementCard(achievement: achievements[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WhiteStat extends StatelessWidget {
  final String label;
  final String value;
  final String delta;

  const _WhiteStat({required this.label, required this.value, required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta.startsWith('-') && !label.contains('Scrolls') ||
        (delta.startsWith('+') && !label.contains('Scrolls'));
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(delta, style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        )),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String emoji;
  final String title;
  final double progress;
  final String current;
  final String target;

  const _GoalCard({required this.emoji, required this.title, required this.progress, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text('$current / $target', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;

  const _Achievement({required this.emoji, required this.title, required this.desc, required this.unlocked});
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? AppTheme.primary.withOpacity(0.08)
            : Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.unlocked ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: achievement.unlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 0.4, 0,
                  ]),
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 8),
          Text(achievement.title, style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: achievement.unlocked ? null : Colors.grey,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(achievement.desc, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          if (achievement.unlocked) ...[
            const SizedBox(height: 6),
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
          ],
        ],
      ),
    );
  }
}

class _WhiteStatLive extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _WhiteStatLive({required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          color: danger ? const Color(0xFFFFD700) : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        )),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _CalLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _CalLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
