import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'usage_stats_service.dart';

Timer? timer;
Future<void> initializeBackgroundService() async {
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

  int continuousSeconds = 0;
  String? lastApp;
  DateTime? lastAppStart;
  final List<DateTime> recentSwitches = [];

  // Monitor every 15 seconds
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    final foregroundApp = await UsageStatsService.getForegroundApp();

    if (foregroundApp != null) {
      if (foregroundApp != lastApp) {
        lastApp = foregroundApp;
        lastAppStart = DateTime.now();
        recentSwitches.add(DateTime.now());
        if (recentSwitches.length > 5) recentSwitches.removeAt(0);
        continuousSeconds = 0;
      } else {
        continuousSeconds += 15;
      }

      // Check for doom scroll
      final isSocialMedia = _isSocialMedia(foregroundApp);
      final isNight = _isNightTime();

      // Notify UI about usage update
      service.invoke('usage_update', {
        'app': foregroundApp,
        'continuousSeconds': continuousSeconds,
        'isSocialMedia': isSocialMedia,
        'isNight': isNight,
      });

      // Check intervention needed
      if (continuousSeconds >= 30 * 60 || // 30 mins
          (isSocialMedia && continuousSeconds >= 20 * 60) || // 20 mins social
          (isNight && isSocialMedia && continuousSeconds >= 10 * 60)) { // 10 mins night
        service.invoke('trigger_intervention', {
          'app': foregroundApp,
          'duration': continuousSeconds,
          'isNight': isNight,
        });
      }
    }
  });

  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}

bool _isSocialMedia(String pkg) {
  return ['com.instagram.android', 'com.tiktok.android',
    'com.twitter.android', 'com.snapchat.android',
    'com.google.android.youtube', 'com.reddit.frontpage'].contains(pkg);
}

bool _isNightTime() {
  final hour = DateTime.now().hour;
  return hour >= 23 || hour <= 5;
}
