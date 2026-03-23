import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_record.dart';
import '../services/mood_service.dart';
import '../services/digital_debt_service.dart';
import '../widgets/digital_debt_card.dart';
import '../widgets/recovery_curve_card.dart';
import '../widgets/mood_checkin_sheet.dart';
import '../widgets/intervention_history_card.dart';
import '../utils/app_theme.dart';

/// New Insights screen — add to MainShell's _screens list and nav bar.
///
///   _screens: [..., const InsightsScreen()]
///   _NavItem(icon: Icons.insights_rounded, label: 'Insights', index: X, ...)
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.mood_rounded),
                tooltip: 'Log how you feel',
                onPressed: () => MoodCheckinSheet.show(context, ref),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Intervention Log ──────────────────────────────
                _SectionLabel(label: 'Intervention History'),
                const SizedBox(height: 10),
                const InterventionHistoryCard(maxItems: 8),
                const SizedBox(height: 24),

                // ── Digital Debt ──────────────────────────────────
                _SectionLabel(label: 'Digital Budget'),
                const SizedBox(height: 10),
                const DigitalDebtCard(),
                const SizedBox(height: 24),

                // ── Recovery Curve ────────────────────────────────
                _SectionLabel(label: 'Recovery Progress'),
                const SizedBox(height: 10),
                const RecoveryCurveCard(),
                const SizedBox(height: 24),

                // ── Mood Tracking ─────────────────────────────────
                _SectionLabel(label: 'Mood Patterns'),
                const SizedBox(height: 10),
                const _MoodSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

// ─── Mood Section ────────────────────────────────────────────────────────────

class _MoodSection extends ConsumerWidget {
  const _MoodSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(moodHistoryProvider);
    final byHourAsync = ref.watch(moodByHourProvider);

    return historyAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (history) {
        if (history.isEmpty) return _EmptyMoodCard(ref: ref);
        return Column(
          children: [
            _MoodWeekRow(history: history.take(7).toList()),
            const SizedBox(height: 12),
            byHourAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (byHour) => byHour.length >= 2
                  ? _MoodHourChart(byHour: byHour)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            _MoodAppBreakdown(ref: ref),
          ],
        );
      },
    );
  }
}

// Empty state
class _EmptyMoodCard extends StatelessWidget {
  final WidgetRef ref;
  const _EmptyMoodCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          const Text('😐', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text(
            'No mood data yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track how you feel after scrolling sessions\nto discover patterns about your habits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => MoodCheckinSheet.show(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Log your first mood'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// Last 7 check-ins row
class _MoodWeekRow extends StatelessWidget {
  final List<MoodRecord> history;
  const _MoodWeekRow({required this.history});

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent check-ins',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${history.length} logged',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: history.map((r) {
              return Column(
                children: [
                  Text(r.moodEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 5),
                  Text(
                    _dayLabel(r.timestamp),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Now';
    if (diff.inHours < 24) return 'Today';
    if (diff.inHours < 48) return 'Yest.';
    return '${diff.inDays}d ago';
  }
}

// Mood by hour chart
class _MoodHourChart extends StatelessWidget {
  final Map<int, double> byHour;
  const _MoodHourChart({required this.byHour});

  @override
  Widget build(BuildContext context) {
    final spots = byHour.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood by time of day',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Text(
            'Average mood score after scrolling each hour',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        final labels = {1.0: '😫', 3.0: '😐', 5.0: '😊'};
                        return Text(
                          labels[v] ?? '',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (v, _) {
                        final h = v.toInt();
                        if (h % 6 != 0) return const SizedBox.shrink();
                        final label = h == 0
                            ? '12a'
                            : h < 12
                                ? '${h}a'
                                : h == 12
                                    ? '12p'
                                    : '${h - 12}p';
                        return Text(
                          label,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.primary,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withOpacity(0.2),
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
}

// Mood by app breakdown
class _MoodAppBreakdown extends ConsumerWidget {
  final WidgetRef ref;
  const _MoodAppBreakdown({required this.ref});

  static const _friendlyNames = {
    'com.instagram.android': 'Instagram',
    'com.tiktok.android': 'TikTok',
    'com.twitter.android': 'Twitter',
    'com.snapchat.android': 'Snapchat',
    'com.reddit.frontpage': 'Reddit',
    'com.facebook.katana': 'Facebook',
    'com.google.android.youtube': 'YouTube',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byAppAsync = ref.watch(moodByAppProvider);

    return byAppAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (byApp) {
        if (byApp.isEmpty) return const SizedBox.shrink();
        final sorted = byApp.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)); // worst first

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood by app',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Text(
                'How you typically feel after each app',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 14),
              ...sorted.map((e) {
                final name = _friendlyNames[e.key] ??
                    e.key.split('.').last;
                final score = e.value;
                final emoji = _moodEmoji(score);
                final color = _moodColor(score);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (score - 1) / 4, // 1–5 → 0–1
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _moodEmoji(double score) {
    if (score < 1.5) return '😫';
    if (score < 2.5) return '😕';
    if (score < 3.5) return '😐';
    if (score < 4.5) return '🙂';
    return '😊';
  }

  Color _moodColor(double score) {
    if (score < 2) return AppTheme.accent;
    if (score < 3) return AppTheme.warning;
    if (score < 4) return const Color(0xFFFFD700);
    return AppTheme.success;
  }
}
