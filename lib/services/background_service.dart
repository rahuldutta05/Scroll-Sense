import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'usage_stats_service.dart';
import 'scroll_notification_service.dart';

Timer? timer;

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'scrollsense_bg',
      initialNotificationTitle: 'ScrollSense Active',
      initialNotificationContent: 'Monitoring screen time...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onBackgroundServiceStart,
    ),
  );

  // Initialize the notification channels at app start (not isolate)
  await ScrollNotificationService.init();
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');

  // Initialize notifications in this isolate too
  await ScrollNotificationService.init();

  int continuousSeconds = 0;
  String? lastApp;
  DateTime? lastInterventionAt;
  final List<DateTime> recentSwitches = [];

  Timer.periodic(const Duration(seconds: 15), (t) async {
    timer = t;
    final foregroundApp = await UsageStatsService.getForegroundApp();
    if (foregroundApp == null) return;

    // Read config
    final box = Hive.isBoxOpen('settings') ? Hive.box('settings') : null;
    final thresholdMins = box?.get('iv_continuous_mins', defaultValue: 30) as int? ?? 30;
    final maxLevel     = box?.get('iv_max_level',      defaultValue: 3) as int? ?? 3;
    final nightMode    = box?.get('iv_night_mode',     defaultValue: true) as bool? ?? true;
    final rapidSwitch  = box?.get('iv_rapid_switch',   defaultValue: true) as bool? ?? true;
    final cooldownMins = box?.get('iv_cooldown_mins',  defaultValue: 10) as int? ?? 10;
    final blockedApps  = List<String>.from(box?.get('iv_blocked_apps', defaultValue: <String>[]) as List? ?? []);

    // Track switching
    if (foregroundApp != lastApp) {
      lastApp = foregroundApp;
      recentSwitches.add(DateTime.now());
      if (recentSwitches.length > 6) recentSwitches.removeAt(0);
      continuousSeconds = 0;
    } else {
      continuousSeconds += 15;
    }

    // Notify UI (time spent only — no openCount here)
    service.invoke('usage_update', {
      'app': foregroundApp,
      'continuousSeconds': continuousSeconds,
      'isSocialMedia': _isSocialMedia(foregroundApp),
      'isNight': _isNightTime(),
    });

    // Cooldown check
    if (lastInterventionAt != null) {
      if (DateTime.now().difference(lastInterventionAt!).inMinutes < cooldownMins) return;
    }

    final isSocial   = _isSocialMedia(foregroundApp);
    final isBlocked  = blockedApps.contains(foregroundApp);
    final isNight    = _isNightTime();
    final effThresh  = isBlocked ? (thresholdMins ~/ 2) : thresholdMins;
    final contMins   = continuousSeconds ~/ 60;
    final appName    = _friendlyName(foregroundApp);

    int? fireLevel;

    if (nightMode && isNight && isSocial && contMins >= (effThresh ~/ 3)) {
      fireLevel = 4;
    } else if (isSocial && contMins >= (effThresh * 2 ~/ 3)) {
      fireLevel = 3;
    } else if (contMins >= effThresh) {
      fireLevel = _levelFromMins(contMins, effThresh);
    }

    if (rapidSwitch && recentSwitches.length >= 4) {
      final window = recentSwitches.last.difference(recentSwitches.first).inSeconds;
      if (window < 20) fireLevel = (fireLevel ?? 0) < 2 ? 2 : fireLevel;
    }

    if (fireLevel != null) {
      final level = fireLevel.clamp(1, maxLevel);
      lastInterventionAt = DateTime.now();

      // Send both system notification and persist in-app notification
      await ScrollNotificationService.sendInterventionNotification(
        level: level,
        appName: appName,
        minutes: contMins,
      );

      // Also invoke to UI for in-app overlay handling
      service.invoke('trigger_intervention', {
        'app': foregroundApp,
        'duration': continuousSeconds,
        'isNight': isNight,
        'level': level,
      });
    }
  });

  service.on('stop').listen((_) {
    timer?.cancel();
    service.stopSelf();
  });
}

int _levelFromMins(int mins, int threshold) {
  if (mins < threshold)       return 1;
  if (mins < threshold * 1.5) return 2;
  if (mins < threshold * 2)   return 3;
  if (mins < threshold * 3)   return 4;
  return 5;
}

bool _isSocialMedia(String pkg) {
  return [
    'com.instagram.android', 'com.tiktok.android', 'com.twitter.android',
    'com.snapchat.android', 'com.google.android.youtube', 'com.reddit.frontpage',
    'com.facebook.katana', 'com.zhiliaoapp.musically',
  ].contains(pkg);
}

bool _isNightTime() {
  final h = DateTime.now().hour;
  return h >= 23 || h <= 5;
}

String _friendlyName(String pkg) {
  const map = {
    'com.instagram.android': 'Instagram', 'com.tiktok.android': 'TikTok',
    'com.twitter.android': 'Twitter',     'com.snapchat.android': 'Snapchat',
    'com.reddit.frontpage': 'Reddit',     'com.facebook.katana': 'Facebook',
    'com.google.android.youtube': 'YouTube',
  };
  return map[pkg] ?? pkg.split('.').last;
}
