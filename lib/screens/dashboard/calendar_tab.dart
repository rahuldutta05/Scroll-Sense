import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/expense_tile.dart';
import '../../theme/app_theme.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});
  @override State<CalendarTab> createState() => _CT();
}

class _CT extends State<CalendarTab> {
  DateTime _month = DateTime.now();
  DateTime _sel   = DateTime.now();
  bool _listening = false;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  static const _days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const _mo   = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];

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
    final exp     = AppState.of(ctx).exp;
    final dayExps = exp.forDate(_sel);
    final total   = exp.dateTotal(_sel);
    final now     = DateTime.now();
    final isToday = _sel.year == now.year &&
        _sel.month == now.month && _sel.day == now.day;

    return Scaffold(
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(ctx).cardColor,
        elevation: 0,
        title: Text('Calendar',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22,
                color: Theme.of(ctx).colorScheme.onSurface)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() { _month = now; _sel = now; }),
            icon: const Icon(Icons.today_rounded, size: 16, color: kP),
            label: const Text('Today',
                style: TextStyle(color: kP, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(children: [
        // ── Calendar ──────────────────────────────────────────────────
        Container(
          color: Theme.of(ctx).cardColor,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(children: [
            _monthNav(ctx),
            const SizedBox(height: 8),
            _dayLabels(),
            const SizedBox(height: 6),
            _grid(ctx, exp),
          ]),
        ),
        const Divider(height: 1),
        // ── Date header ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Theme.of(ctx).scaffoldBackgroundColor,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              isToday
                  ? 'Today, ${_mo[_sel.month]} ${_sel.day}'
                  : '${_mo[_sel.month]} ${_sel.day}, ${_sel.year}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                  color: Theme.of(ctx).colorScheme.onSurface),
            ),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: kP.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${exp.cur}${total.toInt()}',
                    style: const TextStyle(color: kP,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
          ]),
        ),
        // ── Expense list ──────────────────────────────────────────────
        Expanded(
          child: dayExps.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_rounded, size: 56,
                        color: Colors.grey.shade200),
                    const SizedBox(height: 14),
                    Text('No expenses for this day',
                        style: TextStyle(color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => showAddSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add one'),
                      style: TextButton.styleFrom(foregroundColor: kP),
                    ),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: dayExps.length,
                  itemBuilder: (_, i) => ExpenseTile(e: dayExps[i]),
                ),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _monthNav(BuildContext ctx) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _navBtn(Icons.chevron_left_rounded,
          () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
      Text('${_months[_month.month - 1]} ${_month.year}',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18,
              color: Theme.of(ctx).colorScheme.onSurface)),
      _navBtn(Icons.chevron_right_rounded,
          () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
    ],
  );

  Widget _navBtn(IconData icon, VoidCallback fn) => Material(
    color: Colors.transparent,
    child: InkWell(onTap: fn, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(8),
          child: Icon(icon, color: kP, size: 24))),
  );

  Widget _dayLabels() => Row(
    children: _days.map((d) => Expanded(
      child: Center(child: Text(d, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: d == 'Sun' ? Colors.red.shade300 : Colors.grey.shade400))),
    )).toList(),
  );

  Widget _grid(BuildContext ctx, exp) {
    final first  = DateTime(_month.year, _month.month, 1);
    final last   = DateTime(_month.year, _month.month + 1, 0);
    final offset = first.weekday - 1;
    final rows   = ((offset + last.day) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) => Row(
        children: List.generate(7, (col) {
          final day = row * 7 + col - offset + 1;
          if (day < 1 || day > last.day) {
            return const Expanded(child: SizedBox(height: 46));
          }
          final date  = DateTime(_month.year, _month.month, day);
          final sel   = date.year == _sel.year && date.month == _sel.month
              && date.day == _sel.day;
          final today = date.year == DateTime.now().year
              && date.month == DateTime.now().month
              && date.day == DateTime.now().day;
          final hasExp   = exp.forDate(date).isNotEmpty;
          final dayTotal = exp.dateTotal(date);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sel = date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 46, margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? kP : today ? kP.withOpacity(.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day', style: TextStyle(
                        color: sel ? Colors.white
                            : today ? kP
                            : Theme.of(ctx).colorScheme.onSurface,
                        fontWeight: sel || today
                            ? FontWeight.w800 : FontWeight.w400,
                        fontSize: 14)),
                    if (hasExp) ...[
                      const SizedBox(height: 2),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 4, height: 4,
                            decoration: BoxDecoration(
                                color: sel ? Colors.white70 : kP,
                                shape: BoxShape.circle)),
                        if (dayTotal > 1000) ...[
                          const SizedBox(width: 2),
                          Container(width: 4, height: 4,
                              decoration: BoxDecoration(
                                  color: sel ? Colors.white54 : kL,
                                  shape: BoxShape.circle)),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      )),
    );
  }
}
