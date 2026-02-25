import 'package:flutter/material.dart';
import '../../models/app_notif.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override State<NotificationScreen> createState() => _NS();
}

class _NS extends State<NotificationScreen> {
  bool _listening = false;
  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      AppState.of(context).notifs.addListener(_r);
    }
  }

  @override
  void dispose() {
    AppState.of(context).notifs.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final s    = AppState.of(ctx).notifs;
    final list = s.all;
    return Scaffold(
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(ctx).cardColor,
        elevation: 0,
        title: Row(children: [
          Text('Notifications',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22,
                  color: Theme.of(ctx).colorScheme.onSurface)),
          if (s.unread > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: kP,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${s.unread} new',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          if (list.isNotEmpty) ...[
            TextButton(
              onPressed: s.markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: kP, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade400),
              onPressed: () => _clearDlg(ctx, s),
            ),
          ],
        ],
      ),
      body: list.isEmpty ? _empty() : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _Tile(
          n: list[i],
          onTap:    () => s.markRead(list[i].id),
          onDelete: () => s.remove(list[i].id),
        ),
      ),
    );
  }

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kD, kL]),
            shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none_rounded,
            size: 52, color: Colors.white)),
      const SizedBox(height: 20),
      const Text('All clear!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Smart alerts will appear here.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    ],
  ));

  void _clearDlg(BuildContext ctx, s) => showDialog(
    context: ctx,
    builder: (dlg) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Delete all notifications?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlg),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
        ElevatedButton(
          onPressed: () { s.clear(); Navigator.pop(dlg); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Clear All'),
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  final AppNotif n;
  final VoidCallback onTap, onDelete;
  const _Tile({required this.n, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext ctx) {
    final info = _info(n.type);
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.read
                ? Theme.of(ctx).cardColor
                : (info['color'] as Color).withOpacity(.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: n.read
                    ? Colors.transparent
                    : (info['color'] as Color).withOpacity(.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(info['icon'] as IconData,
                  color: info['color'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(n.title,
                      style: TextStyle(
                          fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 14,
                          color: Theme.of(ctx).colorScheme.onSurface))),
                  if (!n.read)
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: info['color'] as Color,
                            shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 5),
                Text(n.body, style: TextStyle(color: Colors.grey.shade500,
                    fontSize: 12, height: 1.4)),
                const SizedBox(height: 6),
                Text(_ago(n.time),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Map<String, dynamic> _info(NType t) {
    switch (t) {
      case NType.added:      return {'icon': Icons.check_circle_rounded, 'color': const Color(0xFF22C55E)};
      case NType.budgetWarn: return {'icon': Icons.warning_amber_rounded, 'color': Colors.orange};
      case NType.budgetOver: return {'icon': Icons.error_rounded,         'color': Colors.red};
      case NType.bigSpend:   return {'icon': Icons.bolt_rounded,          'color': Colors.deepPurple};
      case NType.summary:    return {'icon': Icons.bar_chart_rounded,     'color': kP};
      default:               return {'icon': Icons.notifications_rounded, 'color': Colors.grey};
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
