import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_record.dart';
import '../services/mood_service.dart';
import '../utils/app_theme.dart';

/// A bottom sheet that asks the user how they feel after a scroll session.
///
/// Call [MoodCheckinSheet.show] from anywhere in the app, e.g.:
///   - After a focus session completes (in focus_screen.dart)
///   - After a soft-lock cooldown ends (in intervention_service.dart)
///   - Via the floating action button in InsightsScreen
class MoodCheckinSheet extends ConsumerStatefulWidget {
  final String? sessionApp;
  final int sessionDurationMinutes;

  const MoodCheckinSheet({
    super.key,
    this.sessionApp,
    this.sessionDurationMinutes = 0,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    String? sessionApp,
    int sessionDurationMinutes = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: MoodCheckinSheet(
          sessionApp: sessionApp,
          sessionDurationMinutes: sessionDurationMinutes,
        ),
      ),
    );
  }

  @override
  ConsumerState<MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends ConsumerState<MoodCheckinSheet> {
  int? _selected;
  bool _saving = false;

  static const _options = [
    (1, '😫', 'Awful'),
    (2, '😕', 'Bad'),
    (3, '😐', 'Meh'),
    (4, '🙂', 'Good'),
    (5, '😊', 'Great'),
  ];

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _saving = true);

    final record = MoodRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: _selected!,
      sessionApp: widget.sessionApp,
      sessionDurationMinutes: widget.sessionDurationMinutes,
    );

    await ref.read(moodServiceProvider).saveMood(record);
    ref.invalidate(moodHistoryProvider);
    ref.invalidate(moodByHourProvider);
    ref.invalidate(weeklyMoodTrendProvider);

    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'How do you feel?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.sessionApp != null
                ? 'After your ${widget.sessionDurationMinutes}m session'
                : 'After this scroll session',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Mood buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _options.map((opt) {
              final isSelected = _selected == opt.$1;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = opt.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.all(isSelected ? 12 : 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(fontSize: isSelected ? 34 : 28),
                        child: Text(opt.$2),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        opt.$3,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? AppTheme.primary : Colors.grey,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected != null && !_saving) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
