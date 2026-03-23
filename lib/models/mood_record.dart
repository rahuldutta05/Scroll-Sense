import 'dart:convert';

class MoodRecord {
  final String id;
  final DateTime timestamp;
  final int mood; // 1–5: 😫 😕 😐 🙂 😊
  final String? sessionApp;
  final int sessionDurationMinutes;
  final String? openingIntent; // 'task', 'checking', 'boredom', 'habit'

  MoodRecord({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.sessionApp,
    this.sessionDurationMinutes = 0,
    this.openingIntent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'sessionApp': sessionApp,
        'sessionDurationMinutes': sessionDurationMinutes,
        'openingIntent': openingIntent,
      };

  factory MoodRecord.fromJson(Map<String, dynamic> json) => MoodRecord(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        mood: json['mood'] as int,
        sessionApp: json['sessionApp'] as String?,
        sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 0,
        openingIntent: json['openingIntent'] as String?,
      );

  String get moodEmoji {
    const emojis = ['', '😫', '😕', '😐', '🙂', '😊'];
    return mood >= 1 && mood <= 5 ? emojis[mood] : '😐';
  }

  String get moodLabel {
    const labels = ['', 'Awful', 'Bad', 'Okay', 'Good', 'Great'];
    return mood >= 1 && mood <= 5 ? labels[mood] : 'Unknown';
  }
}
