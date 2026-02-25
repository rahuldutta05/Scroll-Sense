import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
part 'hive_adapters.g.dart';
// App Usage Record
@HiveType(typeId: 0)
class AppUsageRecord extends HiveObject {
  @HiveField(0)
  String packageName;

  @HiveField(1)
  String appName;

  @HiveField(2)
  int durationSeconds;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int openCount;

  @HiveField(5)
  String? appIcon; // base64

  AppUsageRecord({
    required this.packageName,
    required this.appName,
    required this.durationSeconds,
    required this.date,
    this.openCount = 0,
    this.appIcon,
  });
}

// Focus Session
@HiveType(typeId: 1)
class FocusSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  List<String> blockedApps;

  @HiveField(6)
  String sessionType; // 'pomodoro', 'custom', 'scheduled'

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.completed = false,
    required this.blockedApps,
    this.sessionType = 'custom',
  });
}

// Achievement
@HiveType(typeId: 2)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String emoji;

  @HiveField(4)
  bool unlocked;

  @HiveField(5)
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlocked = false,
    this.unlockedAt,
  });
}

// Behavioral Scores
class BehavioralScores {
  final double focusScore;
  final double addictionScore;
  final double productivityIndex;
  final double distractionScore;
  final double nightUsageRatio;
  final double socialMediaDependency;

  BehavioralScores({
    required this.focusScore,
    required this.addictionScore,
    required this.productivityIndex,
    required this.distractionScore,
    required this.nightUsageRatio,
    required this.socialMediaDependency,
  });
}

// Doom Scroll Detection Event
class DoomScrollEvent {
  final String triggerType; // 'continuous_use', 'rapid_switch', 'night_binge', 'social_binge'
  final String packageName;
  final DateTime detectedAt;
  final int durationSeconds;
  final int interventionLevel; // 1-5

  DoomScrollEvent({
    required this.triggerType,
    required this.packageName,
    required this.detectedAt,
    required this.durationSeconds,
    required this.interventionLevel,
  });
}

// App Config
class AppConfig {
  final List<String> blockedApps;
  final int continuousUsageThresholdMins;
  final int rapidSwitchThresholdSecs;
  final int nightStartHour; // 23 = 11pm
  final int nightEndHour;   // 6 = 6am
  final bool focusModeActive;
  final int lockDurationMins;
  final int interventionLevel;
  final List<ScheduledBlock> scheduledBlocks;

  AppConfig({
    this.blockedApps = const [],
    this.continuousUsageThresholdMins = 30,
    this.rapidSwitchThresholdSecs = 5,
    this.nightStartHour = 23,
    this.nightEndHour = 6,
    this.focusModeActive = false,
    this.lockDurationMins = 5,
    this.interventionLevel = 3,
    this.scheduledBlocks = const [],
  });

  AppConfig copyWith({
    List<String>? blockedApps,
    int? continuousUsageThresholdMins,
    int? rapidSwitchThresholdSecs,
    int? nightStartHour,
    int? nightEndHour,
    bool? focusModeActive,
    int? lockDurationMins,
    int? interventionLevel,
    List<ScheduledBlock>? scheduledBlocks,
  }) {
    return AppConfig(
      blockedApps: blockedApps ?? this.blockedApps,
      continuousUsageThresholdMins: continuousUsageThresholdMins ?? this.continuousUsageThresholdMins,
      rapidSwitchThresholdSecs: rapidSwitchThresholdSecs ?? this.rapidSwitchThresholdSecs,
      nightStartHour: nightStartHour ?? this.nightStartHour,
      nightEndHour: nightEndHour ?? this.nightEndHour,
      focusModeActive: focusModeActive ?? this.focusModeActive,
      lockDurationMins: lockDurationMins ?? this.lockDurationMins,
      interventionLevel: interventionLevel ?? this.interventionLevel,
      scheduledBlocks: scheduledBlocks ?? this.scheduledBlocks,
    );
  }
}

class ScheduledBlock {
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> weekdays; // 1=Mon, 7=Sun
  final List<String> appsToBlock;

  ScheduledBlock({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.weekdays,
    required this.appsToBlock,
  });
}
