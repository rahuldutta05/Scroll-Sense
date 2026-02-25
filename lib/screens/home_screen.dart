import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';
import '../services/usage_stats_service.dart';
import '../services/doom_scroll_detector.dart';
import '../models/hive_adapters.dart';
import '../widgets/score_ring.dart';
import '../widgets/app_usage_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<AppUsageRecord> _usageData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    setState(() => _loading = true);
    final data = await UsageStatsService.getUsageStats();
    setState(() {
      _usageData = data..sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scores = ref.watch(behavioralScoresProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_getGreeting()}',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'ScrollSense',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_rounded, color: AppTheme.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Score Cards
                _buildScoreCards(scores),
                const SizedBox(height: 20),

                // Today's Screen Time
                _buildScreenTimeCard(),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 20),

                // Top Apps
                _buildTopApps(),
                const SizedBox(height: 20),

                // Intervention Levels
                _buildInterventionCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCards(BehavioralScores scores) {
    return Row(
      children: [
        Expanded(child: ScoreCard(
          label: 'Focus Score',
          score: scores.focusScore,
          color: AppTheme.primary,
          icon: Icons.center_focus_strong_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(child: ScoreCard(
          label: 'Addiction',
          score: scores.addictionScore,
          color: AppTheme.accent,
          icon: Icons.warning_rounded,
          isInverse: true,
        )),
        const SizedBox(width: 12),
        Expanded(child: ScoreCard(
          label: 'Productivity',
          score: scores.productivityIndex,
          color: AppTheme.success,
          icon: Icons.trending_up_rounded,
        )),
      ],
    );
  }

  Widget _buildScreenTimeCard() {
    final totalSeconds = _usageData.fold(0, (s, r) => s + r.durationSeconds);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final weeklyData = _buildWeeklyBarData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Screen Time', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'Today • ${hours}h ${minutes}m',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${hours}h ${minutes}m',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          days[value.toInt() % 7],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPair(label: 'Daily Avg', value: '${hours}h ${minutes}m'),
              _StatPair(label: 'Weekly Total', value: '${hours * 7}h'),
              _StatPair(label: 'Longest', value: '${hours + 2}h 30m'),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildWeeklyBarData() {
    final random = [5.5, 7.2, 4.8, 8.1, 6.3, 9.2, 5.5];
    return List.generate(7, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: random[i],
          color: i == 6 ? AppTheme.primary : AppTheme.primary.withOpacity(0.4),
          width: 20,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    ));
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.lock_rounded,
              label: 'Focus Mode',
              color: AppTheme.primary,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.timer_rounded,
              label: 'Pomodoro',
              color: AppTheme.accent,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.block_rounded,
              label: 'Block App',
              color: AppTheme.warning,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.psychology_rounded,
              label: 'Breathe',
              color: AppTheme.success,
              onTap: () => _showBreathingExercise(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopApps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Most Used Today', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          ...(_usageData.take(5).map((app) => AppUsageCard(record: app))),
      ],
    );
  }

  Widget _buildInterventionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intervention Levels',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (i) => _InterventionLevelRow(
            level: i + 1,
            label: ['Gentle Notification', 'Warning Popup', 'Breathing Break',
                    'Temporary Lock', 'HARD LOCK 🔒'][i],
            active: i < 3,
          )),
        ],
      ),
    );
  }

  void _showBreathingExercise() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BreathingExerciseSheet(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _StatPair extends StatelessWidget {
  final String label;
  final String value;
  const _StatPair({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterventionLevelRow extends StatelessWidget {
  final int level;
  final String label;
  final bool active;
  const _InterventionLevelRow({required this.level, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$level', style: TextStyle(
                color: active ? AppTheme.primary : Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white.withOpacity(0.5),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingExerciseSheet extends StatefulWidget {
  const BreathingExerciseSheet({super.key});

  @override
  State<BreathingExerciseSheet> createState() => _BreathingExerciseSheetState();
}

class _BreathingExerciseSheetState extends State<BreathingExerciseSheet>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  String _phase = 'Breathe In';
  int _count = 4;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startBreathing();
  }

  void _startBreathing() async {
    while (mounted) {
      setState(() { _phase = 'Breathe In'; _count = 4; });
      _breathController.forward();
      await Future.delayed(const Duration(seconds: 4));

      setState(() { _phase = 'Hold'; _count = 4; });
      await Future.delayed(const Duration(seconds: 4));

      setState(() { _phase = 'Breathe Out'; _count = 4; });
      _breathController.reverse();
      await Future.delayed(const Duration(seconds: 4));

      setState(() { _phase = 'Hold'; _count = 4; });
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Text('Breathing Exercise', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _breathController,
            builder: (ctx, child) => Container(
              width: 100 + _breathController.value * 80,
              height: 100 + _breathController.value * 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.2),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Text(_phase, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
