import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/app_state.dart';
import '../../utils/cats.dart';
import '../../utils/analytics.dart';
import '../../theme/app_theme.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override State<StatsTab> createState() => _ST();
}

class _ST extends State<StatsTab> {
  int? _touchedIdx;
  bool _listening = false;

  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      AppState.of(context).exp.addListener(_r);
    }
  }

  @override
  void dispose() {
    AppState.of(context).exp.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final exp   = AppState.of(ctx).exp;
    final cats  = exp.catTotals;
    final all   = exp.expenses.toList();
    final grand = cats.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(ctx).cardColor,
        elevation: 0,
        title: Text('Statistics',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22,
                color: Theme.of(ctx).colorScheme.onSurface)),
      ),
      body: grand == 0 ? _empty() : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sec(ctx, 'Insights'), const SizedBox(height: 12),
          _insightsRow(ctx, exp, all), const SizedBox(height: 24),

          _sec(ctx, 'Spending by Category'), const SizedBox(height: 12),
          _pieCard(ctx, cats, grand), const SizedBox(height: 24),

          _sec(ctx, 'Weekly Trend'), const SizedBox(height: 12),
          _weeklyCard(ctx, all, exp.cur), const SizedBox(height: 24),

          _sec(ctx, 'Category Breakdown'), const SizedBox(height: 12),
          _breakdown(ctx, cats, grand, exp.cur),
        ]),
      ),
    );
  }

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kD, kL]),
            shape: BoxShape.circle),
        child: const Icon(Icons.bar_chart_rounded, size: 52, color: Colors.white)),
      const SizedBox(height: 20),
      const Text('No data yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Add expenses to see statistics.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    ],
  ));

  Widget _sec(BuildContext ctx, String t) => Text(t,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
          color: Theme.of(ctx).colorScheme.onSurface));

  // ── Insights row ────────────────────────────────────────────────────
  Widget _insightsRow(BuildContext ctx, exp, List all) {
    final avg  = Analytics.dailyAvg(all);
    final top  = Analytics.topCat(all);
    final peak = Analytics.peakDay(all);
    final now  = DateTime.now();
    final mtxn = all.where((e) => e.date.month == now.month).length;
    return Row(children: [
      _ins(ctx, '${exp.cur}${avg.toInt()}', 'Daily Avg',
          Icons.today_rounded, Colors.blue),
      const SizedBox(width: 10),
      _ins(ctx, top, 'Top Category', Icons.star_rounded, Colors.orange),
      const SizedBox(width: 10),
      _ins(ctx, peak, 'Peak Day',
          Icons.local_fire_department_rounded, Colors.red),
      const SizedBox(width: 10),
      _ins(ctx, '$mtxn', 'Transactions',
          Icons.receipt_rounded, Colors.teal),
    ]);
  }

  Widget _ins(BuildContext ctx, String v, String l, IconData icon, Color c) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: c.withOpacity(.12),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: c, size: 14)),
          const SizedBox(height: 8),
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
              color: Theme.of(ctx).colorScheme.onSurface),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          Text(l, style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ]),
      ));

  // ── Pie chart ─────────────────────────────────────────────────────────
  Widget _pieCard(BuildContext ctx, Map<String, double> cats, double grand) {
    final entries = cats.entries.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        SizedBox(height: 220, child: PieChart(PieChartData(
          sections: entries.asMap().entries.map((e) {
            final idx      = e.key;
            final cat      = e.value;
            final info     = catInfo(cat.key);
            final touched  = idx == _touchedIdx;
            return PieChartSectionData(
              value: cat.value,
              color: info['color'] as Color,
              title: touched
                  ? '${cat.key}\n${(cat.value / grand * 100).toStringAsFixed(0)}%'
                  : '${(cat.value / grand * 100).toStringAsFixed(0)}%',
              radius: touched ? 82 : 68,
              titleStyle: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: touched ? 12 : 11),
            );
          }).toList(),
          sectionsSpace: 3,
          centerSpaceRadius: 38,
          pieTouchData: PieTouchData(
            touchCallback: (_, resp) => setState(() =>
                _touchedIdx = resp?.touchedSection?.touchedSectionIndex),
          ),
        ))),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((e) {
            final info = catInfo(e.key);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: info['color'] as Color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(e.key, style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(.7))),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  // ── Weekly bar chart ─────────────────────────────────────────────────
  Widget _weeklyCard(BuildContext ctx, List all, String cur) {
    final trend  = Analytics.weekly(all);
    final maxVal = trend.map((d) => d['total'] as double)
        .reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 14, color: Theme.of(ctx).colorScheme.onSurface)),
          Text('$cur${trend.map((d) => d['total'] as double)
              .reduce((a, b) => a + b).toInt()} total',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: maxVal == 0
              ? Center(child: Text('No data',
                  style: TextStyle(color: Colors.grey.shade400)))
              : BarChart(BarChartData(
                  barGroups: trend.asMap().entries.map((e) {
                    final val   = e.value['total'] as double;
                    final isMax = val == maxVal && maxVal > 0;
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: val,
                        color: isMax ? kP : kP.withOpacity(.25),
                        width: 22,
                        borderRadius: BorderRadius.circular(7),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true, toY: maxVal,
                          color: Theme.of(ctx).scaffoldBackgroundColor),
                      ),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 26,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(trend[v.toInt()]['day'] as String,
                            style: TextStyle(color: Colors.grey.shade500,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    )),
                    leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData:   const FlGridData(show: false),
                )),
        ),
      ]),
    );
  }

  // ── Category breakdown ────────────────────────────────────────────────
  Widget _breakdown(BuildContext ctx, Map<String, double> cats,
      double grand, String cur) {
    final sorted = cats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final info = catInfo(e.key);
        final pct  = e.value / grand;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
                blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(.12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(info['icon'] as IconData,
                  color: info['color'] as Color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key, style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(ctx).colorScheme.onSurface)),
                  Row(children: [
                    Text('$cur${e.value.toInt()}',
                        style: TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 14, color: info['color'] as Color)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: (info['color'] as Color).withOpacity(.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: info['color'] as Color,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: (info['color'] as Color).withOpacity(.1),
                    valueColor: AlwaysStoppedAnimation(info['color'] as Color),
                    minHeight: 7,
                  ),
                ),
              ],
            )),
          ]),
        );
      }).toList(),
    );
  }
}
