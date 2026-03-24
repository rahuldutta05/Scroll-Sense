import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_adapters.dart';
import 'usage_stats_service.dart';

enum DoomScrollTrigger {
  continuousUse,
  rapidAppSwitch,
  socialMediaBinge,
  nightBinge,
  scrollFrequency,
  studyDistraction,
  usageSpike,
}

class DoomScrollDetector {
  // State tracking
  String? _currentApp;
  DateTime? _currentAppStartTime;
  final List<_AppSwitch> _recentSwitches = [];
  int _continuousMinutes = 0;
  Timer? _monitorTimer;

  final List<String> _socialMediaApps = [
    'com.instagram.android',
    'com.tiktok.android',
    'com.snapchat.android',
    'com.twitter.android',
    'com.reddit.frontpage',
    'com.facebook.katana',
  ];

  // Callbacks
  Function(DoomScrollEvent)? onDoomScrollDetected;

  void startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkUsage());
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
  }

  Future<void> _checkUsage() async {
    final foregroundApp = await UsageStatsService.getForegroundApp();
    if (foregroundApp == null) return;

    final now = DateTime.now();

    // Track app switches
    if (foregroundApp != _currentApp) {
      if (_currentApp != null) {
        _recentSwitches.add(_AppSwitch(
          fromApp: _currentApp!,
          toApp: foregroundApp,
          timestamp: now,
        ));
        // Keep only last 10 switches
        if (_recentSwitches.length > 10) _recentSwitches.removeAt(0);
      }

      _currentApp = foregroundApp;
      _currentAppStartTime = now;
    }

    // Check triggers
    _checkContinuousUse(foregroundApp, now);
    _checkRapidSwitching(now);
    _checkNightBinge(foregroundApp, now);
    _checkSocialMediaBinge(foregroundApp, now);
  }

  void _checkContinuousUse(String app, DateTime now) {
    if (_currentAppStartTime == null) return;
    final duration = now.difference(_currentAppStartTime!);
    // Read from persisted config; fallback to 30 min
    final thresholdMins = Hive.isBoxOpen('settings')
        ? (Hive.box('settings').get('iv_continuous_mins', defaultValue: 30) as int)
        : 30;

    if (duration.inMinutes >= thresholdMins) {
      _triggerEvent(DoomScrollTrigger.continuousUse, app, duration.inSeconds, _getLevel(duration.inMinutes));
    }
  }

  void _checkRapidSwitching(DateTime now) {
    if (_recentSwitches.length < 3) return;

    final recentThree = _recentSwitches.sublist(_recentSwitches.length - 3);
    final timeBetween = now.difference(recentThree.first.timestamp).inSeconds / 3;

    if (timeBetween < 5) {
      _triggerEvent(DoomScrollTrigger.rapidAppSwitch, _currentApp ?? '', 0, 2);
    }
  }

  void _checkNightBinge(String app, DateTime now) {
    final hour = now.hour;
    if (hour >= 23 || hour <= 5) {
      if (_socialMediaApps.contains(app) && _currentAppStartTime != null) {
        final duration = now.difference(_currentAppStartTime!);
        if (duration.inMinutes >= 15) {
          _triggerEvent(DoomScrollTrigger.nightBinge, app, duration.inSeconds, 4);
        }
      }
    }
  }

  void _checkSocialMediaBinge(String app, DateTime now) {
    if (!_socialMediaApps.contains(app)) return;
    if (_currentAppStartTime == null) return;

    final duration = now.difference(_currentAppStartTime!);
    if (duration.inMinutes >= 20) {
      _triggerEvent(DoomScrollTrigger.socialMediaBinge, app, duration.inSeconds, 4);
    }
  }

  void _triggerEvent(DoomScrollTrigger trigger, String app, int duration, int level) {
    final event = DoomScrollEvent(
      triggerType: trigger.name,
      packageName: app,
      detectedAt: DateTime.now(),
      durationSeconds: duration,
      interventionLevel: level,
    );
    onDoomScrollDetected?.call(event);
  }

  int _getLevel(int minutes) {
    if (minutes < 10) return 1;
    if (minutes < 20) return 2;
    if (minutes < 30) return 3;
    if (minutes < 45) return 4;
    return 5;
  }

  // Calculate behavioral scores from usage data
  static BehavioralScores calculateScores(List<AppUsageRecord> records) {
    if (records.isEmpty) {
      return BehavioralScores(
        focusScore: 75, addictionScore: 25, productivityIndex: 70,
        distractionScore: 30, nightUsageRatio: 0.1, socialMediaDependency: 20,
      );
    }

    final totalSeconds = records.fold(0, (sum, r) => sum + r.durationSeconds);
    final socialSeconds = records
        .where((r) => _isSocialMedia(r.packageName))
        .fold(0, (sum, r) => sum + r.durationSeconds);
    final socialRatio = totalSeconds > 0 ? socialSeconds / totalSeconds : 0.0;
    // Score based purely on time ratios (no open count)
    final avgDailySeconds = totalSeconds / 7;

    final addictionScore = ((socialRatio * 60) +
        (avgDailySeconds > 4 * 3600 ? 20 : 0) +  // >4h/day
        (avgDailySeconds > 8 * 3600 ? 20 : 0))    // >8h/day
        .clamp(0, 100).toDouble();

    final focusScore = (100 - addictionScore).clamp(0, 100).toDouble();

    return BehavioralScores(
      focusScore: focusScore,
      addictionScore: addictionScore,
      productivityIndex: ((focusScore + (100 - socialRatio * 100)) / 2).clamp(0, 100),
      distractionScore: addictionScore,
      nightUsageRatio: 0.15, // Would calc from time-stamped data
      socialMediaDependency: (socialRatio * 100).clamp(0, 100),
    );
  }

  static bool _isSocialMedia(String packageName) {
    const socialApps = [
      'com.instagram.android', 'com.tiktok.android', 'com.snapchat.android',
      'com.twitter.android', 'com.reddit.frontpage', 'com.facebook.katana',
      'com.google.android.youtube',
    ];
    return socialApps.contains(packageName);
  }
}

class _AppSwitch {
  final String fromApp;
  final String toApp;
  final DateTime timestamp;

  _AppSwitch({required this.fromApp, required this.toApp, required this.timestamp});
}

// Providers
final doomScrollProvider = StateNotifierProvider<DoomScrollNotifier, List<DoomScrollEvent>>((ref) {
  return DoomScrollNotifier();
});

class DoomScrollNotifier extends StateNotifier<List<DoomScrollEvent>> {
  DoomScrollNotifier() : super([]);

  void addEvent(DoomScrollEvent event) {
    state = [...state, event];
  }
}

final behavioralScoresProvider = FutureProvider<BehavioralScores>((ref) async {
  final usageData = await UsageStatsService.getWeeklyData();
  return DoomScrollDetector.calculateScores(usageData);
});
