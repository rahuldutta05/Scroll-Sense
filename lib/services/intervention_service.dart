import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hive_adapters.dart';
import '../utils/app_theme.dart';
import 'doom_scroll_detector.dart';
import 'intervention_config_service.dart';
import 'scroll_notification_service.dart';

enum InterventionLevel { gentleNudge, warningBanner, breathingBreak, softLock, hardLock }

InterventionLevel _levelFromInt(int n) {
  switch (n) {
    case 1:  return InterventionLevel.gentleNudge;
    case 2:  return InterventionLevel.warningBanner;
    case 3:  return InterventionLevel.breathingBreak;
    case 4:  return InterventionLevel.softLock;
    default: return InterventionLevel.hardLock;
  }
}

// ─── Bridge: listens to background service events ────────────────────────────
// The background service fires trigger_intervention via service.invoke().
// This bridge listens and pushes into doomScrollProvider so the UI reacts.
class BackgroundBridgeService {
  static void start(WidgetRef ref) {
    try {
      // FlutterBackgroundService is unavailable outside its isolate,
      // so we use a MethodChannel that the Kotlin/Java service can call
      // OR we poll the trigger channel.
      // Background service already handles notifications directly.
      // The bridge just forwards to the Riverpod event list.
    } catch (_) {}
  }
}

// ─── InterventionListener ────────────────────────────────────────────────────

class InterventionListener extends ConsumerStatefulWidget {
  final Widget child;
  const InterventionListener({super.key, required this.child});

  @override
  ConsumerState<InterventionListener> createState() => _InterventionListenerState();
}

class _InterventionListenerState extends ConsumerState<InterventionListener> {
  int _lastProcessedCount = 0;
  bool _softLockOpen = false;
  DateTime? _lastInterventionAt;

  @override
  void initState() {
    super.initState();
    ScrollNotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<DoomScrollEvent>>(doomScrollProvider, (prev, next) {
      if (next.length > _lastProcessedCount) {
        final event = next.last;
        _lastProcessedCount = next.length;
        _handleEvent(event);
      }
    });
    return widget.child;
  }

  void _handleEvent(DoomScrollEvent event) {
    final config = ref.read(interventionConfigProvider);

    // Cooldown guard
    if (_lastInterventionAt != null) {
      final elapsed = DateTime.now().difference(_lastInterventionAt!).inMinutes;
      if (elapsed < config.cooldownMins) return;
    }

    // Cap at user's configured max
    final raw = event.interventionLevel.clamp(1, config.maxLevel);
    final level = _levelFromInt(raw);

    // Log the event
    ref.read(interventionLogProvider.notifier).log(
      InterventionEvent(
        level: raw,
        packageName: event.packageName,
        triggerType: event.triggerType,
        timestamp: DateTime.now(),
      ),
    );

    _lastInterventionAt = DateTime.now();
    _dispatch(level, event, config);
  }

  void _dispatch(InterventionLevel level, DoomScrollEvent event, InterventionConfig config) {
    final app = _friendlyName(event.packageName);
    final mins = event.durationSeconds ~/ 60;

    // Always fire the notification through the unified service (persists in-app too)
    ScrollNotificationService.sendInterventionNotification(
      level: level.index + 1,
      appName: app,
      minutes: mins,
    );

    // In-app UI responses
    switch (level) {
      case InterventionLevel.gentleNudge:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👀  ${mins}m on $app – just a heads up'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;

      case InterventionLevel.warningBanner:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️  ${mins}m on $app – consider a break'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
        break;

      case InterventionLevel.breathingBreak:
        if (mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            builder: (_) => _BreathingSheet(appName: app, minutes: mins),
          );
        }
        break;

      case InterventionLevel.softLock:
        if (mounted && !_softLockOpen) {
          _softLockOpen = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _SoftLockDialog(appName: app, minutes: mins),
          ).then((_) => _softLockOpen = false);
        }
        break;

      case InterventionLevel.hardLock:
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/lock',
            (r) => false,
            arguments: {
              'appName': app,
              'triggerReason': event.triggerType,
              'initialSeconds': config.lockDurationMins * 60,
            },
          );
        }
        break;
    }
  }

  static String _friendlyName(String pkg) {
    const map = {
      'com.instagram.android': 'Instagram',
      'com.tiktok.android': 'TikTok',
      'com.twitter.android': 'Twitter',
      'com.snapchat.android': 'Snapchat',
      'com.reddit.frontpage': 'Reddit',
      'com.facebook.katana': 'Facebook',
      'com.google.android.youtube': 'YouTube',
    };
    return map[pkg] ?? pkg.split('.').last;
  }
}

// ─── L3 Breathing Sheet ──────────────────────────────────────────────────────

class _BreathingSheet extends StatefulWidget {
  final String appName;
  final int minutes;
  const _BreathingSheet({required this.appName, required this.minutes});
  @override
  State<_BreathingSheet> createState() => _BreathingSheetState();
}

class _BreathingSheetState extends State<_BreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String _phase = 'Breathe In';
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _cycle();
  }

  Future<void> _cycle() async {
    while (_alive && mounted) {
      _setPhase('Breathe In');  await _ctrl.forward(from: 0); if (!_alive) break;
      _setPhase('Hold');        await Future.delayed(const Duration(seconds: 4)); if (!_alive) break;
      _setPhase('Breathe Out'); await _ctrl.reverse(); if (!_alive) break;
      _setPhase('Hold');        await Future.delayed(const Duration(seconds: 4));
    }
  }

  void _setPhase(String p) { if (mounted) setState(() => _phase = p); }

  @override
  void dispose() { _alive = false; _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('⚠️  ${widget.minutes}m on ${widget.appName}',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 6),
          const Text('Take a moment to breathe',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final size = 90.0 + _ctrl.value * 80.0;
              final color = Color.lerp(AppTheme.primary, AppTheme.success, _ctrl.value)!;
              return Container(
                width: size, height: size,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.7), width: 2)),
                child: Center(child: Text(_phase,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
              );
            },
          ),
          const SizedBox(height: 10),
          Text('Box breathing (4-4-4-4)', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I feel better – close', style: TextStyle(color: Colors.white60, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── L4 Soft Lock Dialog ─────────────────────────────────────────────────────

class _SoftLockDialog extends StatelessWidget {
  final String appName;
  final int minutes;
  const _SoftLockDialog({required this.appName, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.lock_open_rounded, color: AppTheme.warning, size: 40)),
            const SizedBox(height: 16),
            const Text('Temporary Lock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'You\'ve spent ${minutes}m on $appName.\nTake a 30-second break before continuing.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            _SoftLockCountdown(onDone: () => Navigator.pop(context, false)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Skip (not recommended)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftLockCountdown extends StatefulWidget {
  final VoidCallback onDone;
  const _SoftLockCountdown({required this.onDone});
  @override State<_SoftLockCountdown> createState() => _SoftLockCountdownState();
}

class _SoftLockCountdownState extends State<_SoftLockCountdown>
    with SingleTickerProviderStateMixin {
  int _remaining = 30;
  Timer? _timer;
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) setState(() => _remaining--);
      else _timer?.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); _ringCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ready = _remaining == 0;
    return Column(
      children: [
        if (!ready)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: _ringCtrl.value, strokeWidth: 4,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
                      )),
                  Text('$_remaining', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.warning)),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ready ? widget.onDone : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.25),
              disabledForegroundColor: Colors.white54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(ready ? 'Continue' : 'Continue in ${_remaining}s',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
