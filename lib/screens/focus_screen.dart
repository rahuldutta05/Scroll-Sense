import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';

final focusModeProvider = StateNotifierProvider<FocusModeNotifier, FocusModeState>((ref) {
  return FocusModeNotifier();
});

class FocusModeState {
  final bool isActive;
  final int remainingSeconds;
  final String sessionType;
  final List<String> blockedApps;
  final int pomodoroCount;

  FocusModeState({
    this.isActive = false,
    this.remainingSeconds = 0,
    this.sessionType = 'custom',
    this.blockedApps = const [],
    this.pomodoroCount = 0,
  });

  FocusModeState copyWith({bool? isActive, int? remainingSeconds, String? sessionType, List<String>? blockedApps, int? pomodoroCount}) {
    return FocusModeState(
      isActive: isActive ?? this.isActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionType: sessionType ?? this.sessionType,
      blockedApps: blockedApps ?? this.blockedApps,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
    );
  }
}

class FocusModeNotifier extends StateNotifier<FocusModeState> {
  FocusModeNotifier() : super(FocusModeState());
  Timer? _timer;

  void startSession(int minutes, String type, List<String> apps) {
    state = state.copyWith(
      isActive: true,
      remainingSeconds: minutes * 60,
      sessionType: type,
      blockedApps: apps,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        stopSession();
      }
    });
  }

  void stopSession() {
    _timer?.cancel();
    state = state.copyWith(
      isActive: false,
      remainingSeconds: 0,
      pomodoroCount: state.pomodoroCount + (state.sessionType == 'pomodoro' ? 1 : 0),
    );
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
  bool _isPomodoro = false;

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

    return Scaffold(
      body: SafeArea(
        child: state.isActive
            ? _buildActiveSession(state)
            : _buildSetupScreen(),
      ),
    );
  }

  Widget _buildActiveSession(FocusModeState state) {
    final hours = state.remainingSeconds ~/ 3600;
    final minutes = (state.remainingSeconds % 3600) ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final total = state.sessionType == 'pomodoro' ? 25 * 60 : _selectedDuration * 60;
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
                onPressed: () => ref.read(focusModeProvider.notifier).stopSession(),
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

  Widget _buildSetupScreen() {
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
          _buildModeSelector(),
          const SizedBox(height: 20),

          // Duration
          if (!_isPomodoro) _buildDurationSelector(),
          if (!_isPomodoro) const SizedBox(height: 20),

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
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                _isPomodoro ? 'Start Pomodoro (25 min)' : 'Start Focus Session',
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

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: '🎯',
            title: 'Custom Focus',
            subtitle: 'Set your own duration',
            selected: !_isPomodoro,
            onTap: () => setState(() => _isPomodoro = false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: '🍅',
            title: 'Pomodoro',
            subtitle: '25min work + 5min break',
            selected: _isPomodoro,
            onTap: () => setState(() => _isPomodoro = true),
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
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ScheduledBlockCard(
          name: 'Study Time',
          time: '9:00 AM - 12:00 PM',
          days: 'Mon - Fri',
          appsCount: 4,
        ),
        const SizedBox(height: 8),
        _ScheduledBlockCard(
          name: 'Night Mode',
          time: '11:00 PM - 7:00 AM',
          days: 'Every Day',
          appsCount: 6,
        ),
      ],
    );
  }

  void _startSession() {
    final apps = _selectedApps.isEmpty
        ? _socialApps.map((a) => a.$3).toList()
        : _selectedApps;
    ref.read(focusModeProvider.notifier).startSession(
      _isPomodoro ? 25 : _selectedDuration,
      _isPomodoro ? 'pomodoro' : 'custom',
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
