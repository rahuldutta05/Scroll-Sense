import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';
import '../services/usage_stats_service.dart';
import '../models/hive_adapters.dart';
import '../widgets/app_usage_card.dart';
import '../widgets/score_ring.dart';
import '../services/doom_scroll_detector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, int>? _heatmapData;
  List<AppUsageRecord>? _weeklyData;
  BehavioralScores? _scores;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final heatmap = await UsageStatsService.getHourlyHeatmap();
    final weekly = await UsageStatsService.getWeeklyData();
    final scores = DoomScrollDetector.calculateScores(weekly);
    
    if (mounted) {
      setState(() {
        _heatmapData = heatmap;
        _weeklyData = weekly;
        _scores = scores;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_heatmapData == null || _weeklyData == null || _scores == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Heatmap'),
                Tab(text: 'Apps'),
              ],
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primary,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildHeatmapTab(),
            _buildAppsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Behavioral Score Cards
          _buildScoresSection(),
          const SizedBox(height: 20),

          // Focus Trend Graph
          _buildFocusTrend(),
          const SizedBox(height: 20),

          // Key Stats
          _buildKeyStats(),
          const SizedBox(height: 20),

          // Weekly Comparison
          _buildWeeklyComparison(),
        ],
      ),
    );
  }

  Widget _buildScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Behavioral Scores', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _ScoreGridItem(label: 'Focus', score: _scores!.focusScore, color: AppTheme.primary),
            _ScoreGridItem(label: 'Addiction', score: _scores!.addictionScore, color: AppTheme.accent, isWarning: true),
            _ScoreGridItem(label: 'Productivity', score: _scores!.productivityIndex, color: AppTheme.success),
            _ScoreGridItem(label: 'Distraction', score: _scores!.distractionScore, color: AppTheme.warning, isWarning: true),
            _ScoreGridItem(label: 'Night Usage', score: _scores!.nightUsageRatio * 100, color: const Color(0xFF8B5CF6)),
            _ScoreGridItem(label: 'Social Dep.', score: _scores!.socialMediaDependency, color: const Color(0xFF06B6D4), isWarning: true),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusTrend() {
    final spots = [
      FlSpot(0, 55), FlSpot(1, 62), FlSpot(2, 48), FlSpot(3, 70),
      FlSpot(4, 65), FlSpot(5, 78), FlSpot(6, 72),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Last 7 days', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStats() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Most Distracting',
          value: 'TikTok',
          emoji: '🎵',
          color: const Color(0xFF69C9D0),
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Peak Distraction',
          value: '9 PM',
          emoji: '⏰',
          color: AppTheme.accent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Longest Session',
          value: '1h 34m',
          emoji: '📱',
          color: AppTheme.warning,
        )),
      ],
    );
  }

  Widget _buildWeeklyComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Week Comparison', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _ComparisonRow(label: 'Screen Time', thisWeek: '48h 20m', lastWeek: '52h 10m', improved: true),
          _ComparisonRow(label: 'Focus Sessions', thisWeek: '12', lastWeek: '8', improved: true),
          _ComparisonRow(label: 'Doom Scrolls', thisWeek: '23', lastWeek: '18', improved: false),
          _ComparisonRow(label: 'Focus Score', thisWeek: '72', lastWeek: '65', improved: true),
        ],
      ),
    );
  }

  Widget _buildHeatmapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hourly Distraction Heatmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Darker = more distracted', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          _buildHeatmapGrid(),
          const SizedBox(height: 24),
          _buildTimeZones(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1.2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 24,
        itemBuilder: (ctx, hour) {
          final intensity = _heatmapData![hour] ?? 0;
          final opacity = intensity / 100;
          return Tooltip(
            message: '${hour == 0 ? 12 : hour > 12 ? hour - 12 : hour}${hour < 12 ? 'am' : 'pm'}: $intensity%',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1 + opacity * 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${hour}h',
                  style: TextStyle(
                    fontSize: 9,
                    color: opacity > 0.5 ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeZones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Addiction Zones', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _ZoneCard(icon: '🌅', label: 'Morning Risk', time: '6am - 9am', intensity: 0.3, color: AppTheme.warning),
        const SizedBox(height: 8),
        _ZoneCard(icon: '☀️', label: 'Afternoon Focus', time: '10am - 4pm', intensity: 0.5, color: AppTheme.success),
        const SizedBox(height: 8),
        _ZoneCard(icon: '🌆', label: 'Evening Binge', time: '6pm - 10pm', intensity: 0.9, color: AppTheme.accent),
        const SizedBox(height: 8),
        _ZoneCard(icon: '🌙', label: 'Late Night Doom', time: '11pm - 3am', intensity: 0.7, color: const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildAppsTab() {
    final allApps = _weeklyData!;
    final appTotals = <String, AppUsageRecord>{};
    for (final r in allApps) {
      if (appTotals.containsKey(r.packageName)) {
        appTotals[r.packageName] = AppUsageRecord(
          packageName: r.packageName,
          appName: r.appName,
          durationSeconds: appTotals[r.packageName]!.durationSeconds + r.durationSeconds,
          date: r.date,
          openCount: appTotals[r.packageName]!.openCount + r.openCount,
        );
      } else {
        appTotals[r.packageName] = r;
      }
    }

    final apps = appTotals.values.toList()
      ..sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
    final total = apps.fold(0, (s, r) => s + r.durationSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pie chart placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: PieChart(
              PieChartData(
                sections: apps.take(5).toList().asMap().entries.map((e) {
                  final app = e.value;
                  final pct = total > 0 ? app.durationSeconds / total : 0;
                  return PieChartSectionData(
                    value: app.durationSeconds.toDouble(),
                    color: AppTheme.chartColors[e.key % AppTheme.chartColors.length],
                    radius: 60,
                    title: '${(pct * 100).round()}%',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...apps.map((a) => AppUsageCard(record: a)),
        ],
      ),
    );
  }
}

class _ScoreGridItem extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final bool isWarning;

  const _ScoreGridItem({required this.label, required this.score, required this.color, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScoreRing(score: score / 100, color: color, size: 50, strokeWidth: 5),
          const SizedBox(height: 6),
          Text('${score.round()}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String thisWeek;
  final String lastWeek;
  final bool improved;

  const _ComparisonRow({required this.label, required this.thisWeek, required this.lastWeek, required this.improved});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(lastWeek, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 12),
          Icon(
            improved ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: improved ? AppTheme.success : AppTheme.accent,
          ),
          const SizedBox(width: 8),
          Text(
            thisWeek,
            style: TextStyle(
              color: improved ? AppTheme.success : AppTheme.accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final String icon;
  final String label;
  final String time;
  final double intensity;
  final Color color;

  const _ZoneCard({required this.icon, required this.label, required this.time, required this.intensity, required this.color});

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
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(intensity * 100).round()}%', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              SizedBox(
                width: 60,
                height: 6,
                child: LinearProgressIndicator(
                  value: intensity,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
