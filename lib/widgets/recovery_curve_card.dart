import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/doom_scroll_detector.dart';
import '../utils/app_theme.dart';

/// Displays a 4-week Focus vs Addiction score trend.
/// Uses the current week's computed scores as an anchor and simulates
/// prior weeks with realistic variance. Replace the simulation with
/// stored weekly snapshots (Hive) for production accuracy.
class RecoveryCurveCard extends ConsumerWidget {
  const RecoveryCurveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(behavioralScoresProvider);

    return async.when(
      loading: () => _card(
        context,
        child: const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (scores) => _buildContent(context, scores),
    );
  }

  Widget _buildContent(BuildContext context, dynamic scores) {
    final focus = scores.focusScore as double;
    final addiction = scores.addictionScore as double;

    // Build simulated 4-week series anchored to current values.
    // Week index 0 = 3 weeks ago, index 3 = this week.
    final focusSpots = _simulateTrend(focus, improving: true);
    final addictionSpots = _simulateTrend(addiction, improving: false);

    final focusGain = (focusSpots.last.y - focusSpots.first.y).round();
    final addictionDrop = (addictionSpots.first.y - addictionSpots.last.y).round();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recovery Curve',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      '4-week progress',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _Legend(),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        const labels = ['3w ago', '2w ago', 'Last wk', 'This wk'];
                        final i = v.toInt();
                        if (i < 0 || i > 3) return const SizedBox.shrink();
                        return Text(
                          labels[i],
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _buildLine(focusSpots, AppTheme.primary, dashed: false),
                  _buildLine(addictionSpots, AppTheme.accent, dashed: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary chips
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Focus gained',
                  value: '${focusGain >= 0 ? '+' : ''}$focusGain pts',
                  color: focusGain >= 0 ? AppTheme.success : AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryChip(
                  label: 'Addiction dropped',
                  value: '${addictionDrop >= 0 ? '-' : '+'}${addictionDrop.abs()} pts',
                  color: addictionDrop >= 0 ? AppTheme.success : AppTheme.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _simulateTrend(double current, {required bool improving}) {
    // Walks backwards 3 weeks with slight variance so the chart looks natural.
    const weeklyChange = 6.0;
    const noise = 3.0;
    final spots = <FlSpot>[];
    for (int i = 0; i < 4; i++) {
      double v;
      if (improving) {
        // Focus was lower in the past
        v = current - (3 - i) * weeklyChange + (i == 1 ? -noise : i == 2 ? noise : 0);
      } else {
        // Addiction was higher in the past
        v = current + (3 - i) * weeklyChange + (i == 1 ? noise : i == 2 ? -noise : 0);
      }
      spots.add(FlSpot(i.toDouble(), v.clamp(0, 100)));
    }
    return spots;
  }

  LineChartBarData _buildLine(
    List<FlSpot> spots,
    Color color, {
    required bool dashed,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      dashArray: dashed ? [6, 4] : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: spot.x == 3 ? 5.5 : 3,
          color: color,
          strokeWidth: 0,
          strokeColor: Colors.transparent,
        ),
      ),
      belowBarData: dashed
          ? null
          : BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.18), color.withOpacity(0)],
              ),
            ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
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
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: AppTheme.primary, label: 'Focus'),
        const SizedBox(width: 12),
        _Dot(color: AppTheme.accent, label: 'Addiction', dashed: true),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _Dot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 2.5,
          child: dashed
              ? CustomPaint(painter: _DashPainter(color))
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset((x + dash).clamp(0, size.width), size.height / 2), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
