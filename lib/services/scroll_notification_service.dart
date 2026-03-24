import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Central notification service for ScrollSense.
/// Handles both system (flutter_local_notifications) and in-app notifications.
/// Called by InterventionListener and the background service bridge.
class ScrollNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── Channels ────────────────────────────────────────────────────────────
  static const _nudgeCh    = AndroidNotificationChannel('ss_nudge',    'Gentle Nudges',     description: 'Low-priority scroll reminders', importance: Importance.defaultImportance);
  static const _warnCh     = AndroidNotificationChannel('ss_warning',  'Usage Warnings',    description: 'Medium-priority warnings',       importance: Importance.high);
  static const _lockCh     = AndroidNotificationChannel('ss_lock',     'Focus Locks',       description: 'Hard lock alerts',              importance: Importance.max);
  static const _focusCh    = AndroidNotificationChannel('ss_focus',    'Focus Sessions',    description: 'Focus start/end alerts',         importance: Importance.defaultImportance);
  static const _streakCh   = AndroidNotificationChannel('ss_streak',   'Streak Milestones', description: 'Achievement & streak alerts',    importance: Importance.defaultImportance);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // Create all channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final ch in [_nudgeCh, _warnCh, _lockCh, _focusCh, _streakCh]) {
      await androidPlugin?.createNotificationChannel(ch);
    }
  }

  // ─── Intervention notifications ───────────────────────────────────────────

  static Future<void> sendNudge({required String appName, required int minutes}) =>
      _show(id: 200, title: 'Time check \ud83d\udc40',
            body: 'You\'ve been on $appName for ${minutes}m. Ready for a break?',
            channelId: _nudgeCh.id, importance: Importance.defaultImportance);

  static Future<void> sendWarning({required String appName, required int minutes}) =>
      _show(id: 201, title: '\u26a0\ufe0f Usage Warning',
            body: '$appName: ${minutes}m of continuous use detected.',
            channelId: _warnCh.id, importance: Importance.high);

  static Future<void> sendBreathingReminder({required String appName}) =>
      _show(id: 202, title: '\ud83e\uddd8 Time to breathe',
            body: 'Extended use on $appName. Open ScrollSense for a guided break.',
            channelId: _warnCh.id, importance: Importance.high);

  static Future<void> sendSoftLock({required String appName, required int minutes}) =>
      _show(id: 203, title: '\ud83d\uded1 Soft Lock Active',
            body: '${minutes}m on $appName. A 30-second cooldown has started.',
            channelId: _warnCh.id, importance: Importance.high);

  static Future<void> sendHardLock({required String appName}) =>
      _show(id: 204, title: '\ud83d\udd12 Screen Locked',
            body: '$appName has been locked. Open ScrollSense to continue.',
            channelId: _lockCh.id, importance: Importance.max);

  // ─── Focus session notifications ──────────────────────────────────────────

  static Future<void> sendFocusStarted({required int minutes, required String type}) =>
      _show(id: 300, title: type == 'pomodoro' ? '\ud83c\udf45 Pomodoro Started' : '\ud83c\udfaf Focus Session Started',
            body: '${minutes}min session underway. Stay off distracting apps!',
            channelId: _focusCh.id, importance: Importance.defaultImportance);

  static Future<void> sendFocusCompleted({required int minutes}) =>
      _show(id: 301, title: '\u2705 Focus Session Complete!',
            body: 'Great work \u2014 ${minutes}m of focused time logged.',
            channelId: _focusCh.id, importance: Importance.defaultImportance);

  static Future<void> sendPomodoroBreak({required int breakMins}) =>
      _show(id: 302, title: '\u2615 Break Time!',
            body: 'Take a ${breakMins}-minute break. You\'ve earned it.',
            channelId: _focusCh.id, importance: Importance.defaultImportance);

  // ─── Streak/achievement notifications ────────────────────────────────────

  static Future<void> sendStreakAchievement({required int days}) =>
      _show(id: 400 + days, title: '\ud83d\udd25 ${days}-Day Streak!',
            body: '${days} days under your screen time budget. Keep it going!',
            channelId: _streakCh.id, importance: Importance.defaultImportance);

  static Future<void> sendDailyBudgetWarning({required int usedMins, required int goalMins}) {
    final pct = ((usedMins / goalMins) * 100).round();
    return _show(id: 401, title: '\u23f1\ufe0f $pct% of Daily Budget Used',
          body: '${usedMins ~/ 60}h ${usedMins % 60}m used of your ${goalMins ~/ 60}h goal.',
          channelId: _warnCh.id, importance: Importance.defaultImportance);
  }

  static Future<void> sendBudgetExceeded({required int goalMins}) =>
      _show(id: 402, title: '\u274c Daily Budget Exceeded',
            body: 'You\'ve passed your ${goalMins ~/ 60}h screen time goal for today.',
            channelId: _warnCh.id, importance: Importance.high);

  // ─── In-app notification persistence ────────────────────────────────────
  // Stores notifications in Hive so the bell icon + notification screen work.

  static const _inAppBox = 'in_app_notifications';

  static Future<void> persistInApp({
    required String title,
    required String body,
    required String type,
  }) async {
    if (!Hive.isBoxOpen(_inAppBox)) {
      await Hive.openBox(_inAppBox);
    }
    final box = Hive.box(_inAppBox);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    };
    final dynamic existingRaw = box.get('list');
    final List list = existingRaw != null ? jsonDecode(existingRaw as String) as List : [];
    list.add(entry);

    // Keep last 50
    final trimmed = list.length > 50 ? list.sublist(list.length - 50) : list;
    await box.put('list', jsonEncode(trimmed));
  }

  static Future<List<Map<String, dynamic>>> getInAppNotifications() async {
    if (!Hive.isBoxOpen(_inAppBox)) {
      await Hive.openBox(_inAppBox);
    }
    final raw = Hive.box(_inAppBox).get('list');
    if (raw == null) return [];
    final list = (jsonDecode(raw as String) as List)
        .cast<Map<String, dynamic>>()
        ..sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
    return list;
  }

  static Future<int> getUnreadCount() async {
    final list = await getInAppNotifications();
    return list.where((n) => n['read'] == false).length;
  }

  static Future<void> markRead(String id) async {
    if (!Hive.isBoxOpen(_inAppBox)) return;
    final raw = Hive.box(_inAppBox).get('list');
    if (raw == null) return;
    final list = (jsonDecode(raw as String) as List).cast<Map<String, dynamic>>();
    for (final n in list) { if (n['id'] == id) n['read'] = true; }
    await Hive.box(_inAppBox).put('list', jsonEncode(list));
  }

  static Future<void> markAllRead() async {
    if (!Hive.isBoxOpen(_inAppBox)) return;
    final raw = Hive.box(_inAppBox).get('list');
    if (raw == null) return;
    final list = (jsonDecode(raw as String) as List).cast<Map<String, dynamic>>();
    for (final n in list) { n['read'] = true; }
    await Hive.box(_inAppBox).put('list', jsonEncode(list));
  }

  static Future<void> clearAll() async {
    if (!Hive.isBoxOpen(_inAppBox)) return;
    await Hive.box(_inAppBox).put('list', jsonEncode([]));
  }

  // ─── Combined send (system + in-app) ─────────────────────────────────────

  static Future<void> sendInterventionNotification({
    required int level,
    required String appName,
    required int minutes,
  }) async {
    String title, body, type;
    switch (level) {
      case 1:
        title = 'Time check \ud83d\udc40';
        body = '${minutes}m on $appName \u2014 ready for a break?';
        type = 'nudge';
        await sendNudge(appName: appName, minutes: minutes);
        break;
      case 2:
        title = '\u26a0\ufe0f Usage Warning';
        body = '${minutes}m on $appName detected.';
        type = 'warning';
        await sendWarning(appName: appName, minutes: minutes);
        break;
      case 3:
        title = '\ud83e\uddd8 Breathing Break';
        body = 'Extended use on $appName. Take a breath.';
        type = 'breathing';
        await sendBreathingReminder(appName: appName);
        break;
      case 4:
        title = '\ud83d\uded1 Temporary Lock';
        body = '${minutes}m on $appName. 30-second cooldown active.';
        type = 'soft_lock';
        await sendSoftLock(appName: appName, minutes: minutes);
        break;
      default:
        title = '\ud83d\udd12 App Locked';
        body = '$appName locked due to excessive use.';
        type = 'hard_lock';
        await sendHardLock(appName: appName);
    }
    await persistInApp(title: title, body: body, type: type);
  }

  // ─── Private helper ───────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required Importance importance,
  }) async {
    await init();
    await _plugin.show(
      id, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, channelId,
          importance: importance,
          priority: importance == Importance.max || importance == Importance.high
              ? Priority.high
              : Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}
