import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_adapters.dart';

/// Single source of truth for all intervention configuration.
class InterventionConfig {
  final int maxLevel;
  final int continuousThresholdMins;
  final int lockDurationMins;
  final bool nightModeEnabled;
  final bool rapidSwitchDetection;
  final int cooldownMins;
  final List<String> blockedApps;
  final List<ScheduledBlock> scheduledBlocks;

  const InterventionConfig({
    this.maxLevel = 3,
    this.continuousThresholdMins = 30,
    this.lockDurationMins = 5,
    this.nightModeEnabled = true,
    this.rapidSwitchDetection = true,
    this.cooldownMins = 10,
    this.blockedApps = const [],
    this.scheduledBlocks = const [],
  });

  InterventionConfig copyWith({
    int? maxLevel,
    int? continuousThresholdMins,
    int? lockDurationMins,
    bool? nightModeEnabled,
    bool? rapidSwitchDetection,
    int? cooldownMins,
    List<String>? blockedApps,
    List<ScheduledBlock>? scheduledBlocks,
  }) =>
      InterventionConfig(
        maxLevel: maxLevel ?? this.maxLevel,
        continuousThresholdMins: continuousThresholdMins ?? this.continuousThresholdMins,
        lockDurationMins: lockDurationMins ?? this.lockDurationMins,
        nightModeEnabled: nightModeEnabled ?? this.nightModeEnabled,
        rapidSwitchDetection: rapidSwitchDetection ?? this.rapidSwitchDetection,
        cooldownMins: cooldownMins ?? this.cooldownMins,
        blockedApps: blockedApps ?? this.blockedApps,
        scheduledBlocks: scheduledBlocks ?? this.scheduledBlocks,
      );

  void saveTo(Box box) {
    box.put('iv_max_level', maxLevel);
    box.put('iv_continuous_mins', continuousThresholdMins);
    box.put('iv_lock_duration', lockDurationMins);
    box.put('iv_night_mode', nightModeEnabled);
    box.put('iv_rapid_switch', rapidSwitchDetection);
    box.put('iv_cooldown_mins', cooldownMins);
    box.put('iv_blocked_apps', blockedApps);
    // Persist scheduled blocks as JSON list
    final blocks = scheduledBlocks.map((b) => jsonEncode({
      'name': b.name,
      'startH': b.startTime.hour,
      'startM': b.startTime.minute,
      'endH': b.endTime.hour,
      'endM': b.endTime.minute,
      'days': b.weekdays,
      'apps': b.appsToBlock,
    })).toList();
    box.put('iv_scheduled_blocks', blocks);
  }

  factory InterventionConfig.fromBox(Box box) {
    // Decode scheduled blocks
    final rawBlocks = box.get('iv_scheduled_blocks', defaultValue: <String>[]) as List;
    final blocks = rawBlocks.map((raw) {
      try {
        final m = jsonDecode(raw as String) as Map;
        return ScheduledBlock(
          name: m['name'] as String,
          startTime: TimeOfDay(hour: m['startH'] as int, minute: m['startM'] as int),
          endTime: TimeOfDay(hour: m['endH'] as int, minute: m['endM'] as int),
          weekdays: List<int>.from(m['days'] as List),
          appsToBlock: List<String>.from(m['apps'] as List),
        );
      } catch (_) {
        return null;
      }
    }).whereType<ScheduledBlock>().toList();

    return InterventionConfig(
      maxLevel: box.get('iv_max_level', defaultValue: 3) as int,
      continuousThresholdMins: box.get('iv_continuous_mins', defaultValue: 30) as int,
      lockDurationMins: box.get('iv_lock_duration', defaultValue: 5) as int,
      nightModeEnabled: box.get('iv_night_mode', defaultValue: true) as bool,
      rapidSwitchDetection: box.get('iv_rapid_switch', defaultValue: true) as bool,
      cooldownMins: box.get('iv_cooldown_mins', defaultValue: 10) as int,
      blockedApps: List<String>.from(
        box.get('iv_blocked_apps', defaultValue: <String>[]) as List,
      ),
      scheduledBlocks: blocks,
    );
  }

  static String levelLabel(int level) {
    const labels = [
      'Gentle Notification',
      'Warning Popup',
      'Breathing Break',
      'Temporary Lock',
      'HARD LOCK 🔒',
    ];
    return level >= 1 && level <= 5 ? labels[level - 1] : 'Unknown';
  }

  static Color levelColor(int level) {
    const colors = [
      Color(0xFF10B981), // emerald
      Color(0xFF10B981), // emerald
      Color(0xFFF59E0B), // amber
      Color(0xFFF59E0B), // amber
      Color(0xFFFF6B6B), // coral
    ];
    return level >= 1 && level <= 5 ? colors[level - 1] : const Color(0xFF10B981);
  }

  static IconData levelIcon(int level) {
    const icons = [
      Icons.notifications_outlined,
      Icons.warning_amber_rounded,
      Icons.self_improvement_rounded,
      Icons.lock_open_rounded,
      Icons.lock_rounded,
    ];
    return level >= 1 && level <= 5 ? icons[level - 1] : Icons.notifications_outlined;
  }
}

/// Intervention event log entry persisted to Hive
class InterventionEvent {
  final int level;
  final String packageName;
  final String triggerType;
  final DateTime timestamp;
  final bool wasSkipped; // user pressed "skip" on soft lock

  const InterventionEvent({
    required this.level,
    required this.packageName,
    required this.triggerType,
    required this.timestamp,
    this.wasSkipped = false,
  });

  Map<String, dynamic> toMap() => {
        'level': level,
        'packageName': packageName,
        'triggerType': triggerType,
        'timestamp': timestamp.toIso8601String(),
        'wasSkipped': wasSkipped,
      };

  factory InterventionEvent.fromMap(Map<dynamic, dynamic> m) => InterventionEvent(
        level: m['level'] as int,
        packageName: m['packageName'] as String,
        triggerType: m['triggerType'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        wasSkipped: m['wasSkipped'] as bool? ?? false,
      );
}

// ─── Providers ──────────────────────────────────────────────────────────────

class InterventionConfigNotifier extends StateNotifier<InterventionConfig> {
  InterventionConfigNotifier() : super(const InterventionConfig()) {
    _load();
  }

  void _load() {
    if (Hive.isBoxOpen('settings')) {
      state = InterventionConfig.fromBox(Hive.box('settings'));
    }
  }

  void update(InterventionConfig config) {
    state = config;
    if (Hive.isBoxOpen('settings')) {
      config.saveTo(Hive.box('settings'));
    }
  }

  void setLevel(int level) => update(state.copyWith(maxLevel: level));
  void setContinuousThreshold(int mins) => update(state.copyWith(continuousThresholdMins: mins));
  void setLockDuration(int mins) => update(state.copyWith(lockDurationMins: mins));
  void setNightMode(bool v) => update(state.copyWith(nightModeEnabled: v));
  void setRapidSwitch(bool v) => update(state.copyWith(rapidSwitchDetection: v));
  void setCooldown(int mins) => update(state.copyWith(cooldownMins: mins));
  void setBlockedApps(List<String> apps) => update(state.copyWith(blockedApps: apps));
  void setScheduledBlocks(List<ScheduledBlock> blocks) => update(state.copyWith(scheduledBlocks: blocks));

  void toggleApp(String pkg) {
    final current = List<String>.from(state.blockedApps);
    if (current.contains(pkg)) {
      current.remove(pkg);
    } else {
      current.add(pkg);
    }
    update(state.copyWith(blockedApps: current));
  }
}

final interventionConfigProvider =
    StateNotifierProvider<InterventionConfigNotifier, InterventionConfig>(
  (ref) => InterventionConfigNotifier(),
);

// Log of recent intervention events (last 100, persisted)
class InterventionLogNotifier extends StateNotifier<List<InterventionEvent>> {
  InterventionLogNotifier() : super([]) {
    _load();
  }

  void _load() {
    if (!Hive.isBoxOpen('settings')) return;
    final raw = Hive.box('settings').get('iv_event_log');
    if (raw is List) {
      state = raw
          .whereType<Map>()
          .map((m) => InterventionEvent.fromMap(m))
          .toList()
          .reversed
          .take(100)
          .toList();
    }
  }

  void log(InterventionEvent event) {
    final updated = [event, ...state].take(100).toList();
    state = updated;
    if (Hive.isBoxOpen('settings')) {
      Hive.box('settings').put('iv_event_log', updated.map((e) => e.toMap()).toList());
    }
  }
}

final interventionLogProvider =
    StateNotifierProvider<InterventionLogNotifier, List<InterventionEvent>>(
  (ref) => InterventionLogNotifier(),
);
