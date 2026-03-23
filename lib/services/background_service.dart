import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'usage_stats_service.dart';

Timer? timer;

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'scrollsense_bg',
    'ScrollSense Monitoring',
    description: 'Monitors your screen time in background',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'scrollsense_bg',
      initialNotificationTitle: 'ScrollSense Active',
      initialNotificationContent: 'Monitoring your screen time...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onBackgroundServiceStart,
    ),
  );
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Init Hive so we can read persisted config in the background isolate
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('settings')) {
    await Hive.openBox('settings');
  }

  int continuousSeconds = 0;
  String? lastApp;
  DateTime? lastAppStart;
  final List<DateTime> recentSwitches = [];
  DateTime? lastInterventionAt;

  Timer.periodic(const Duration(seconds: 15), (t) async {
    timer = t;
    final foregroundApp = await UsageStatsService.getForegroundApp();
    if (foregroundApp == null) return;

    // ── Read user config from Hive ────────────────────────────────────────
    final box = Hive.isBoxOpen('settings') ? Hive.box('settings') : null;
    final thresholdMins = box?.get('iv_continuous_mins', defaultValue: 30) as int? ?? 30;
    final maxLevel = box?.get('iv_max_level', defaultValue: 3) as int? ?? 3;
    final nightModeEnabled = box?.get('iv_night_mode', defaultValue: true) as bool? ?? true;
    final rapidSwitchEnabled = box?.get('iv_rapid_switch', defaultValue: true) as bool? ?? true;
    final cooldownMins = box?.get('iv_cooldown_mins', defaultValue: 10) as int? ?? 10;
    final blockedApps = List<String>.from(box?.get('iv_blocked_apps', defaultValue: <String>[]) as List? ?? []);

    // ── Track app switches ────────────────────────────────────────────────
    if (foregroundApp != lastApp) {
      lastApp = foregroundApp;
      lastAppStart = DateTime.now();
      recentSwitches.add(DateTime.now());
      if (recentSwitches.length > 6) recentSwitches.removeAt(0);
      continuousSeconds = 0;
    } else {
      continuousSeconds += 15;
    }

    final isSocialMedia = _isSocialMedia(foregroundApp);
    final isBlocked = blockedApps.contains(foregroundApp);
    final isNight = _isNightTime();

    // Notify UI
    service.invoke('usage_update', {
      'app': foregroundApp,
      'continuousSeconds': continuousSeconds,
      'isSocialMedia': isSocialMedia,
      'isNight': isNight,
    });

    // ── Cooldown check ────────────────────────────────────────────────────
    if (lastInterventionAt != null) {
      final minsSinceLast = DateTime.now().difference(lastInterventionAt!).inMinutes;
      if (minsSinceLast < cooldownMins) return;
    }

    // ── Determine intervention level to fire ─────────────────────────────
    int? fireLevel;

    // Blocked app: halved threshold
    final effectiveThreshold = isBlocked ? (thresholdMins ~/ 2) : thresholdMins;
    final continuousMins = continuousSeconds ~/ 60;

    if (nightModeEnabled && isNight && isSocialMedia && continuousMins >= (effectiveThreshold ~/ 3)) {
      fireLevel = 4; // night binge — escalate
    } else if (isSocialMedia && continuousMins >= (effectiveThreshold * 2 ~/ 3)) {
      fireLevel = 3; // social binge
    } else if (continuousMins >= effectiveThreshold) {
      fireLevel = _levelFromMins(continuousMins, effectiveThreshold);
    }

    // Rapid switch detection
    if (rapidSwitchEnabled && recentSwitches.length >= 4) {
      final window = recentSwitches.last.difference(recentSwitches.first).inSeconds;
      if (window < 20) fireLevel = (fireLevel ?? 0) < 2 ? 2 : fireLevel;
    }

    if (fireLevel != null) {
      final level = fireLevel.clamp(1, maxLevel);
      lastInterventionAt = DateTime.now();
      service.invoke('trigger_intervention', {
        'app': foregroundApp,
        'duration': continuousSeconds,
        'isNight': isNight,
        'level': level,
      });
    }
  });

  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}

int _levelFromMins(int mins, int threshold) {
  if (mins < threshold) return 1;
  if (mins < threshold * 1.5) return 2;
  if (mins < threshold * 2) return 3;
  if (mins < threshold * 3) return 4;
  return 5;
}

bool _isSocialMedia(String pkg) {
  return [
    'com.instagram.android', 'com.tiktok.android',
    'com.twitter.android', 'com.snapchat.android',
    'com.google.android.youtube', 'com.reddit.frontpage',
    'com.facebook.katana', 'com.zhiliaoapp.musically',
  ].contains(pkg);
}

bool _isNightTime() {
  final hour = DateTime.now().hour;
  return hour >= 23 || hour <= 5;
}
