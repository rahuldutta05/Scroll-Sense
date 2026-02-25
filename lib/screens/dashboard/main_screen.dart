import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/expense_tile.dart';
import '../../theme/app_theme.dart';
import 'home_tab.dart';
import 'calendar_tab.dart';
import 'stats_tab.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MS();
}

class _MS extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _idx = 0;
  late final AnimationController _fabAc;

  static const _tabs = [
    HomeTab(),
    CalendarTab(),
    StatsTab(),
    ProfileScreen(),
  ];

  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _fabAc = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fabAc.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      AppState.of(context).notifs.addListener(_r);
    }
  }

  void _r() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _fabAc.dispose();
    AppState.of(context).notifs.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_idx),
          child: _tabs[_idx],
        ),
      ),
      bottomNavigationBar: _nav(ctx),
      floatingActionButton: _showFab ? _fab(ctx) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  bool get _showFab => _idx == 0 || _idx == 1;

  Widget _fab(BuildContext ctx) => ScaleTransition(
    scale: CurvedAnimation(parent: _fabAc, curve: Curves.elasticOut),
    child: FloatingActionButton.extended(
      onPressed: () => showAddSheet(ctx),
      backgroundColor: kP,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      label: const Text('Add Expense',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    ),
  );

  Widget _nav(BuildContext ctx) {
    final unread = AppState.of(ctx).notifs.unread;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.09),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(ctx, 0, Icons.home_rounded,            Icons.home_outlined,            'Home',     0),
              _navItem(ctx, 1, Icons.calendar_month_rounded,  Icons.calendar_month_outlined,  'Calendar', 0),
              _navItem(ctx, 2, Icons.bar_chart_rounded,       Icons.bar_chart_outlined,       'Stats',    0),
              _navItem(ctx, 3, Icons.person_rounded,          Icons.person_outline_rounded,   'Profile',  unread),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext ctx, int idx, IconData active, IconData inactive,
      String label, int badge) {
    final sel = _idx == idx;
    return GestureDetector(
      onTap: () {
        if (_idx != idx) {
          setState(() => _idx = idx);
          if (idx == 0 || idx == 1) {
            _fabAc.reset();
            _fabAc.forward();
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kP.withOpacity(.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            Icon(sel ? active : inactive,
                size: 24,
                color: sel ? kP : Colors.grey.shade400),
            if (badge > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
                fontSize: 10,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? kP : Colors.grey.shade400),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}
