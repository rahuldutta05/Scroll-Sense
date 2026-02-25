import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/score_ring.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _achievements = [
    _Achievement(emoji: '🔥', title: 'First Focus', desc: 'Complete your first focus session', unlocked: true),
    _Achievement(emoji: '⚡', title: 'Speed Reducer', desc: 'Cut screen time by 20%', unlocked: true),
    _Achievement(emoji: '🏆', title: 'Week Warrior', desc: '7-day focus streak', unlocked: true),
    _Achievement(emoji: '🧠', title: 'Deep Focus', desc: 'Focus for 2+ hours straight', unlocked: false),
    _Achievement(emoji: '🌙', title: 'Night Owl No More', desc: 'No late night usage for 5 days', unlocked: false),
    _Achievement(emoji: '📵', title: 'Social Detox', desc: 'No social media for 24h', unlocked: false),
    _Achievement(emoji: '🎯', title: 'Productivity Pro', desc: 'Score 90+ on productivity', unlocked: false),
    _Achievement(emoji: '💎', title: 'Digital Minimalist', desc: 'Under 2h screen time for a week', unlocked: false),
  ];

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
                child: const Text('Feb 17-23', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '📈 Great Progress!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'You reduced screen time by 18% compared to last week. Focus score improved by 12 points.',
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WhiteStat(label: 'Screen Time', value: '48h 20m', delta: '-18%'),
              _WhiteStat(label: 'Focus Score', value: '72', delta: '+12'),
              _WhiteStat(label: 'Doom Scrolls', value: '23', delta: '-8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _MetricCard(emoji: '🎯', label: 'Focus Streak', value: '5 days', color: AppTheme.primary),
        _MetricCard(emoji: '📉', label: 'Screen Reduction', value: '-18%', color: AppTheme.success),
        _MetricCard(emoji: '⏱️', label: 'Avg Daily Time', value: '6h 54m', color: AppTheme.warning),
        _MetricCard(emoji: '🔒', label: 'Interventions', value: '23 blocked', color: AppTheme.accent),
      ],
    );
  }

  Widget _buildFocusImprovement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Improvement Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final heights = [0.55, 0.62, 0.48, 0.70, 0.65, 0.78, 0.72];
              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Column(
                children: [
                  Text('${(heights[i] * 100).round()}', style: TextStyle(
                    fontSize: 10,
                    color: i == 6 ? AppTheme.primary : Colors.grey,
                    fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w400,
                  )),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 80 * heights[i],
                    decoration: BoxDecoration(
                      color: i == 6 ? AppTheme.primary : AppTheme.primary.withOpacity(0.3),
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
    final triggers = [
      ('TikTok', '🎵', 0.85),
      ('Instagram', '📸', 0.72),
      ('YouTube', '▶️', 0.60),
      ('Twitter', '🐦', 0.45),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Distraction Triggers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...triggers.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(t.$2, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: t.$3,
                      backgroundColor: AppTheme.accent.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${(t.$3 * 100).round()}%', style: const TextStyle(
                color: AppTheme.accent, fontWeight: FontWeight.w700,
              )),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildProductiveHours() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Productive Hours', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Based on this week\'s usage patterns', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('🌅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Best Focus Window', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Text('9:00 AM – 12:00 PM', style: TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('72% productive on average', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('High Risk Zone', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Text('8:00 PM – 11:00 PM', style: TextStyle(color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('88% doom scroll likelihood', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 56)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Streak', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const Text('5 Days', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const Text('Best: 12 days', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('February 2025', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 28,
            itemBuilder: (ctx, i) {
              final day = i + 1;
              final isStreak = day >= 18 && day <= today.day;
              final isToday = day == today.day;
              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.primary
                      : isStreak
                          ? AppTheme.success.withOpacity(0.2)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday ? null : Border.all(
                    color: isStreak ? AppTheme.success.withOpacity(0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : isStreak
                              ? AppTheme.success
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStreakGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Goals', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _GoalCard(emoji: '⏱️', title: 'Reduce to 6h/day', progress: 0.7, current: '6h 54m', target: '6h'),
        const SizedBox(height: 8),
        _GoalCard(emoji: '🌙', title: 'No phone after 11pm', progress: 0.6, current: '3/5 days', target: '5 days'),
        const SizedBox(height: 8),
        _GoalCard(emoji: '🎯', title: 'Focus score 80+', progress: 0.72, current: '72', target: '80'),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _achievements.length,
      itemBuilder: (ctx, i) => _AchievementCard(achievement: _achievements[i]),
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
