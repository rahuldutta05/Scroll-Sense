import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/app_state.dart';
import '../../utils/cats.dart';
import '../../utils/analytics.dart';
import '../../widgets/expense_tile.dart';
import '../../theme/app_theme.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override State<HomeTab> createState() => _HT();
}

class _HT extends State<HomeTab> {
  String _q = '';
  bool _listening = false;

  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      AppState.of(context).exp.addListener(_r);
      AppState.of(context).notifs.addListener(_r);
    }
  }

  @override
  void dispose() {
    AppState.of(context).exp.removeListener(_r);
    AppState.of(context).notifs.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
    body: CustomScrollView(slivers: [
      _appBar(),
      SliverToBoxAdapter(child: _summary()),
      SliverToBoxAdapter(child: _insights()),
      SliverToBoxAdapter(child: _weekBar()),
      SliverToBoxAdapter(child: _catRow()),
      SliverToBoxAdapter(child: _search()),
      SliverToBoxAdapter(child: _listHdr()),
      _expList(),
      const SliverToBoxAdapter(child: SizedBox(height: 110)),
    ]),
  );

  // ── App Bar ─────────────────────────────────────────────────────────
  Widget _appBar() {
    final s  = AppState.of(context);
    final u  = s.users.current;
    final nr = s.notifs.unread;
    return SliverAppBar(
      floating: true, snap: true,
      backgroundColor: kP, elevation: 0,
      title: const Text('ExpenseFlow',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 22, letterSpacing: -0.8)),
      actions: [
        ValueListenableBuilder(
          valueListenable: s.dark,
          builder: (_, dk, __) => IconButton(
            icon: Icon(dk ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white),
            onPressed: () => s.dark.value = !s.dark.value,
          ),
        ),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          if (nr > 0)
            Positioned(
              right: 8, top: 8,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text('$nr',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
        ]),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          onPressed: () async {
            final path = await AppState.of(context).exp.exportCSV();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Exported: $path'),
                  backgroundColor: kP, behavior: SnackBarBehavior.floating));
            }
          },
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17, backgroundColor: Colors.white24,
              child: Text(u?.avatar ?? '?',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary card ────────────────────────────────────────────────────
  Widget _summary() {
    final exp   = AppState.of(context).exp;
    final total = exp.totalMonth;
    final over  = total > exp.budget;
    final now   = DateTime.now();
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kD, kL],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: kP.withOpacity(.38), blurRadius: 22,
            offset: const Offset(0, 9))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Spending',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text('${exp.cur}${total.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 42,
                fontWeight: FontWeight.w900, letterSpacing: -1.5)),
        const SizedBox(height: 16),
        Row(children: [
          _chip(Icons.receipt_rounded,
              '${exp.expenses.where((e) => e.date.month == now.month).length} txns'),
          const SizedBox(width: 10),
          _chip(Icons.calendar_today_rounded, mn[now.month]),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget  ${exp.cur}${exp.budget.toInt()}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(
            over ? '⚠ Over budget!'
                 : '${exp.cur}${(exp.budget - total).toInt()} left',
            style: TextStyle(
                color: over ? Colors.red.shade200 : Colors.white70,
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (total / exp.budget).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(.15),
            valueColor: AlwaysStoppedAnimation(
                over ? Colors.red.shade300 : Colors.white),
            minHeight: 7,
          ),
        ),
      ]),
    );
  }

  Widget _chip(IconData i, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(i, color: Colors.white, size: 13),
      const SizedBox(width: 6),
      Text(l, style: const TextStyle(color: Colors.white,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── Insight chips ───────────────────────────────────────────────────
  Widget _insights() {
    final exp  = AppState.of(context).exp;
    final all  = exp.expenses.toList();
    final avg  = Analytics.dailyAvg(all);
    final top  = Analytics.topCat(all);
    final peak = Analytics.peakDay(all);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _ins('${exp.cur}${avg.toInt()}', 'Daily Avg',
            Icons.today_rounded, Colors.blue),
        const SizedBox(width: 10),
        _ins(top, 'Top Cat', Icons.star_rounded, Colors.orange),
        const SizedBox(width: 10),
        _ins(peak, 'Peak Day',
            Icons.local_fire_department_rounded, Colors.red),
      ]),
    );
  }

  Widget _ins(String v, String l, IconData icon, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: c.withOpacity(.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: c, size: 15),
        ),
        const SizedBox(height: 8),
        Text(v,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface),
            overflow: TextOverflow.ellipsis),
        Text(l, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ]),
    ),
  );

  // ── Weekly bar chart ─────────────────────────────────────────────────
  Widget _weekBar() {
    final exp   = AppState.of(context).exp;
    final trend = Analytics.weekly(exp.expenses.toList());
    final mx    = trend.map((d) => d['total'] as double)
        .reduce((a, b) => a > b ? a : b);
    if (mx == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('This Week', style: TextStyle(fontWeight: FontWeight.w700,
            fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: BarChart(BarChartData(
            barGroups: trend.asMap().entries.map((e) {
              final val = e.value['total'] as double;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: val,
                  color: val == mx ? kP : kP.withOpacity(.25),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ]);
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 22,
                getTitlesWidget: (v, _) => Text(
                  trend[v.toInt()]['day'] as String,
                  style: TextStyle(color: Colors.grey.shade500,
                      fontSize: 10, fontWeight: FontWeight.w600),
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

  // ── Category scroll row ──────────────────────────────────────────────
  Widget _catRow() {
    final exp  = AppState.of(context).exp;
    final cats = exp.catTotals;
    final cur  = exp.cur;
    if (cats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        children: cats.entries.map((e) {
          final info = catInfo(e.key);
          return Container(
            width: 86, margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(.12),
                    shape: BoxShape.circle),
                child: Icon(info['icon'] as IconData,
                    color: info['color'] as Color, size: 18),
              ),
              const SizedBox(height: 5),
              Text(e.key,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text('$cur${e.value.toInt()}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: info['color'] as Color)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────
  Widget _search() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: TextField(
      decoration: InputDecoration(
        hintText: 'Search expenses…',
        prefixIcon: const Icon(Icons.search_rounded, color: kP),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onChanged: (v) => setState(() => _q = v.toLowerCase()),
    ),
  );

  // ── List header ──────────────────────────────────────────────────────
  Widget _listHdr() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Recent Expenses',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface)),
      const Text('See all',
          style: TextStyle(color: kP, fontWeight: FontWeight.w600,
              fontSize: 13)),
    ]),
  );

  // ── Expense list ─────────────────────────────────────────────────────
  SliverList _expList() {
    final all = AppState.of(context).exp.expenses
        .where((e) => _q.isEmpty
            || e.title.toLowerCase().contains(_q)
            || e.category.toLowerCase().contains(_q))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (all.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Column(children: [
              Icon(Icons.search_off_rounded, size: 52,
                  color: Colors.grey.shade200),
              const SizedBox(height: 10),
              Text('No expenses found',
                  style: TextStyle(color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500)),
            ])),
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => ExpenseTile(e: all[i]),
        childCount: all.length,
      ),
    );
  }
}
