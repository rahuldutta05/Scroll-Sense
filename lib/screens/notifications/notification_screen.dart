import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/scroll_notification_service.dart';
import '../../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ScrollNotificationService.getInAppNotifications();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  Future<void> _markRead(String id) async {
    await ScrollNotificationService.markRead(id);
    await _load();
  }

  Future<void> _markAllRead() async {
    await ScrollNotificationService.markAllRead();
    await _load();
  }

  Future<void> _clearAll() async {
    await ScrollNotificationService.clearAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            if (unread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('$unread new',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade400),
              onPressed: () => _showClearDialog(),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifTile(
                    notif: _notifications[i],
                    onTap: () => _markRead(_notifications[i]['id'] as String),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.6)]),
              shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text('All clear!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Scroll alerts will appear here.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      ],
    ),
  );

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Delete all notifications?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlg),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            onPressed: () { _clearAll(); Navigator.pop(dlg); },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type  = notif['type'] as String? ?? 'general';
    final read  = notif['read'] as bool? ?? true;
    final title = notif['title'] as String? ?? '';
    final body  = notif['body'] as String? ?? '';
    final time  = DateTime.tryParse(notif['time'] as String? ?? '') ?? DateTime.now();

    final info = _typeInfo(type);
    final color = info['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: read ? Theme.of(context).cardTheme.color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: read ? Colors.transparent : color.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(info['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(
                            fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      if (!read)
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(body, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 6),
                  Text(_ago(time), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Map<String, dynamic> _typeInfo(String type) {
    switch (type) {
      case 'nudge':
        return {'icon': Icons.visibility_rounded, 'color': AppTheme.primary};
      case 'warning':
        return {'icon': Icons.warning_amber_rounded, 'color': Colors.orange};
      case 'breathing':
        return {'icon': Icons.self_improvement_rounded, 'color': Colors.teal};
      case 'soft_lock':
        return {'icon': Icons.lock_open_rounded, 'color': const Color(0xFFF59E0B)};
      case 'hard_lock':
        return {'icon': Icons.lock_rounded, 'color': AppTheme.accent};
      case 'focus_start':
        return {'icon': Icons.play_circle_rounded, 'color': AppTheme.success};
      case 'focus_done':
        return {'icon': Icons.check_circle_rounded, 'color': AppTheme.success};
      case 'streak':
        return {'icon': Icons.local_fire_department_rounded, 'color': Colors.orange};
      case 'budget_warn':
        return {'icon': Icons.timelapse_rounded, 'color': Colors.orange};
      case 'budget_over':
        return {'icon': Icons.timer_off_rounded, 'color': AppTheme.accent};
      default:
        return {'icon': Icons.notifications_rounded, 'color': Colors.grey};
    }
  }

  static String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
