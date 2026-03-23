import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_sense/main.dart';
import 'package:scroll_sense/models/hive_adapters.dart';
import '../widgets/mood_checkin_sheet.dart';
import '../utils/app_theme.dart';
import '../services/focus_session_store.dart';
import '../services/intervention_config_service.dart';

final focusModeProvider = StateNotifierProvider<FocusModeNotifier, FocusModeState>((ref) {
  return FocusModeNotifier(ref);
});

class FocusModeState {
  final bool isActive;
  final int remainingSeconds;
  final int totalSeconds;      // ← NEW: original duration for accurate progress
  final String sessionType;
  final List<String> blockedApps;
  final int pomodoroCount;
  final String? sessionId;     // ← NEW: tracks current session in Hive

  FocusModeState({
    this.isActive = false,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.sessionType = 'custom',
    this.blockedApps = const [],
    this.pomodoroCount = 0,
    this.sessionId,
  });

  FocusModeState copyWith({
    bool? isActive,
    int? remainingSeconds,
    int? totalSeconds,
    String? sessionType,
    List<String>? blockedApps,
    int? pomodoroCount,
    String? sessionId,
  }) {
    return FocusModeState(
      isActive: isActive ?? this.isActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      sessionType: sessionType ?? this.sessionType,
      blockedApps: blockedApps ?? this.blockedApps,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  int get elapsedMinutes => (totalSeconds - remainingSeconds) ~/ 60;
}

class FocusModeNotifier extends StateNotifier<FocusModeState> {
  FocusModeNotifier(this._ref) : super(FocusModeState());
  final Ref _ref;
  Timer? _timer;
  DateTime? _sessionStart;
  static const platform = MethodChannel('com.scrollsense/usage_stats');

  void startSession(int minutes, String type, List<String> apps) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStart = DateTime.now();
    final totalSecs = minutes * 60;

    state = state.copyWith(
      isActive: true,
      remainingSeconds: totalSecs,
      totalSeconds: totalSecs,
      sessionType: type,
      blockedApps: apps,
      sessionId: id,
    );

    // Persist session start
    final store = _ref.read(focusSessionStoreProvider);
    await store.save(FocusSession(
      id: id,
      startTime: _sessionStart!,
      durationMinutes: minutes,
      completed: false,
      blockedApps: apps,
      sessionType: type,
    ));

    _startTimer();

    try {
      await platform.invokeMethod('setFocusMode', {'active': true, 'apps': apps});
    } catch (e) {
      debugPrint('Failed to set focus mode: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        stopSession(completed: true);
      }
    });
  }

  void stopSession({bool completed = false}) async {
    _timer?.cancel();
    final elapsed = state.elapsedMinutes;
    final id = state.sessionId;

    state = state.copyWith(
      isActive: false,
      remainingSeconds: 0,
      pomodoroCount: state.pomodoroCount + (state.sessionType == 'pomodoro' && completed ? 1 : 0),
      sessionId: null,
    );

    // Update persisted session as completed
    if (id != null && _sessionStart != null) {
      final store = _ref.read(focusSessionStoreProvider);
      await store.save(FocusSession(
        id: id,
        startTime: _sessionStart!,
        endTime: DateTime.now(),
        durationMinutes: elapsed > 0 ? elapsed : 1,
        completed: completed,
        blockedApps: state.blockedApps,
        sessionType: state.sessionType,
      ));
    }

    try {
      await platform.invokeMethod('setFocusMode', {'active': false, 'apps': []});
    } catch (e) {
      debugPrint('Failed to disable focus mode: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _selectedDuration = 25;
  final List<String> _selectedApps = [];

  final _socialApps = [
    ('Instagram', '📸', 'com.instagram.android'),
    ('TikTok', '🎵', 'com.tiktok.android'),
    ('Twitter', '🐦', 'com.twitter.android'),
    ('YouTube', '▶️', 'com.google.android.youtube'),
    ('Snapchat', '👻', 'com.snapchat.android'),
    ('Reddit', '🔴', 'com.reddit.frontpage'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusModeProvider);

    // Trigger mood check-in when a session ends
    ref.listen<FocusModeState>(focusModeProvider, (prev, next) {
      if (prev?.isActive == true && next.isActive == false) {
        MoodCheckinSheet.show(
          context,
          ref,
          sessionApp: 'Focus Mode',
          sessionDurationMinutes: prev?.elapsedMinutes ?? 0,
        );
      }
    });

    final isPomodoro = ref.watch(focusTabModeProvider);

    return Scaffold(
      body: SafeArea(
        child: state.isActive
            ? _buildActiveSession(state)
            : _buildSetupScreen(isPomodoro),
      ),
    );
  }

  Widget _buildActiveSession(FocusModeState state) {
    final hours = state.remainingSeconds ~/ 3600;
    final minutes = (state.remainingSeconds % 3600) ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final total = state.totalSeconds > 0 ? state.totalSeconds : 1;
    final progress = 1 - (state.remainingSeconds / total);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primary.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: () => ref.read(focusModeProvider.notifier).stopSession(completed: false),
                icon: const Icon(Icons.stop_rounded, color: AppTheme.accent),
                label: const Text('End Session', style: TextStyle(color: AppTheme.accent)),
              ),
            ),
            const Spacer(),
            Text(
              state.sessionType == 'pomodoro' ? '🍅 Pomodoro' : '🎯 Focus Mode',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      hours > 0
                          ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                          : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        color: AppTheme.primary,
                        fontVariations: const [FontVariation('wght', 900)],
                      ),
                    ),
                    Text(
                      'remaining',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              '${state.blockedApps.length} apps blocked 🔒',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Pomodoro stats
            if (state.pomodoroCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    state.pomodoroCount,
                    (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('🍅', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupScreen(bool isPomodoro) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Focus Mode', style: Theme.of(context).textTheme.displayMedium),
          Text('Block distractions & stay productive', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Mode Selection
          _buildModeSelector(isPomodoro),
          const SizedBox(height: 20),

          // Duration
          if (!isPomodoro) _buildDurationSelector(),
          if (!isPomodoro) const SizedBox(height: 20),

          // App Selection
          _buildAppSelector(),
          const SizedBox(height: 20),

          // Scheduled Blocks
          _buildScheduledBlocks(),
          const SizedBox(height: 24),

          // Start Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startSession(isPomodoro),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                isPomodoro ? 'Start Pomodoro (25 min)' : 'Start Focus Session',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isPomodoro) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: '🎯',
            title: 'Custom Focus',
            subtitle: 'Set your own duration',
            selected: !isPomodoro,
            onTap: () => ref.read(focusTabModeProvider.notifier).state = false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: '🍅',
            title: 'Pomodoro',
            subtitle: '25min work + 5min break',
            selected: isPomodoro,
            onTap: () => ref.read(focusTabModeProvider.notifier).state = true,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    final durations = [15, 25, 30, 45, 60, 90, 120];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: durations.map((d) => GestureDetector(
            onTap: () => setState(() => _selectedDuration = d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedDuration == d
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d >= 60 ? '${d ~/ 60}h' : '${d}m',
                style: TextStyle(
                  color: _selectedDuration == d ? Colors.white : AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAppSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Block These Apps', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _socialApps.map((app) {
            final selected = _selectedApps.contains(app.$3);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _selectedApps.remove(app.$3);
                else _selectedApps.add(app.$3);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accent.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(app.$2, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(app.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 14),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduledBlocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Scheduled Blocks', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _showAddBlockDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (ctx, ref, _) {
            final config = ref.watch(interventionConfigProvider);
            if (config.scheduledBlocks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.15),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.grey.withOpacity(0.5), size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'No scheduled blocks yet.\nTap Add to create one.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: config.scheduledBlocks.map((block) {
                final start = block.startTime;
                final end = block.endTime;
                final startStr = '${start.hourOfPeriod}:${start.minute.toString().padLeft(2,'0')} ${start.period.name.toUpperCase()}';
                final endStr = '${end.hourOfPeriod}:${end.minute.toString().padLeft(2,'0')} ${end.period.name.toUpperCase()}';
                final dayNames = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                final dayStr = block.weekdays.length == 7
                    ? 'Every Day'
                    : block.weekdays.map((d) => dayNames[d - 1]).join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ScheduledBlockCard(
                    name: block.name,
                    time: '$startStr – $endStr',
                    days: dayStr,
                    appsCount: block.appsToBlock.length,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showAddBlockDialog() {
    final nameCtrl = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
    final selectedDays = <int>{1, 2, 3, 4, 5}; // Mon-Fri default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Scheduled Block',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Block name',
                    hintText: 'e.g. Study Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                // Time pickers
                Row(
                  children: [
                    Expanded(
                      child: _TimeTile(
                        label: 'Start',
                        time: startTime,
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: startTime);
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeTile(
                        label: 'End',
                        time: endTime,
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: endTime);
                          if (t != null) setDialogState(() => endTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (int d = 1; d <= 7; d++)
                      GestureDetector(
                        onTap: () => setDialogState(() {
                          if (selectedDays.contains(d)) {
                            selectedDays.remove(d);
                          } else {
                            selectedDays.add(d);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selectedDays.contains(d)
                                ? AppTheme.primary
                                : AppTheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              ['M','T','W','T','F','S','S'][d - 1],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selectedDays.contains(d)
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || selectedDays.isEmpty) return;
                final newBlock = ScheduledBlock(
                  name: nameCtrl.text.trim(),
                  startTime: startTime,
                  endTime: endTime,
                  weekdays: selectedDays.toList()..sort(),
                  appsToBlock: _selectedApps.isNotEmpty
                      ? List.from(_selectedApps)
                      : _socialApps.map((a) => a.$3).toList(),
                );
                final config = ref.read(interventionConfigProvider);
                ref.read(interventionConfigProvider.notifier).update(
                  config.copyWith(
                    scheduledBlocks: [...config.scheduledBlocks, newBlock],
                  ),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(bool isPomodoro) {
    final apps = _selectedApps.isEmpty
        ? _socialApps.map((a) => a.$3).toList()
        : _selectedApps;
    ref.read(focusModeProvider.notifier).startSession(
      isPomodoro ? 25 : _selectedDuration,
      isPomodoro ? 'pomodoro' : 'custom',
      apps,
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ScheduledBlockCard extends StatelessWidget {
  final String name;
  final String time;
  final String days;
  final int appsCount;

  const _ScheduledBlockCard({required this.name, required this.time, required this.days, required this.appsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$time • $days', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('$appsCount apps', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Switch(
            value: true,
            onChanged: (_) {},
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              '$hour:$min $period',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
