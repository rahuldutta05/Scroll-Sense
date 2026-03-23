import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/why_opening_dialog.dart';
import '../utils/app_theme.dart';

/// HARD LOCK OVERLAY SCREEN
/// This is rendered as a system overlay on top of blocked apps.
/// Non-dismissible - user must wait for timer or go to ScrollSense app.
class LockOverlayScreen extends StatefulWidget {
  final String? appName;
  final String? triggerReason;
  final int initialSeconds;

  const LockOverlayScreen({
    super.key,
    this.appName = 'Instagram',
    this.triggerReason = 'Doom scroll detected',
    this.initialSeconds = 300,
  });

  @override
  State<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends State<LockOverlayScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
    ]).animate(_shakeController);

    _startTimer();

    // Prevent back button & navigation gestures
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.pop') return;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _unlockApp();
      }
    });
  }

  Future<void> _unlockApp() async {
    _timer?.cancel();
    final intent = await WhyOpeningDialog.show(context, widget.appName ?? 'this app');
    if (intent != null && mounted) {
      Navigator.of(context).pop();
    } else {
      // If cancelled, restart timer or stay locked. 
      // For now, just restarting the timer if it was finished.
      if (_remainingSeconds <= 0) {
        setState(() => _remainingSeconds = 30); // Give 30s penalty/buffer
        _startTimer();
      }
    }
  }

  void _attemptClose() {
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Intercept back button
    return WillPopScope(
      onWillPop: () async {
        _attemptClose();
        return false; // Never allow back
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0E1F), Color(0xFF1A0A20), Color(0xFF0D0E1F)],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              CustomPaint(
                painter: _GridPainter(),
                child: Container(),
              ),

              // Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Lock icon with pulse
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (ctx, _) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent.withOpacity(0.15),
                              border: Border.all(
                                color: AppTheme.accent.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppTheme.accent,
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Blocked app name
                      Text(
                        '${widget.appName} is Locked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          '🚨 ${widget.triggerReason}',
                          style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),

                      const Spacer(),

                      // Countdown timer
                      _buildCountdownTimer(),

                      const Spacer(),

                      // Cannot close message with shake
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (ctx, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'This overlay cannot be dismissed',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  _BlockedAction(icon: '❌', label: 'Skip'),
                                  _BlockedAction(icon: '❌', label: 'Close'),
                                  _BlockedAction(icon: '❌', label: 'Back button'),
                                  _BlockedAction(icon: '❌', label: 'Swipe'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Extend timer options
                      _buildExtendOptions(),

                      const SizedBox(height: 20),

                      // Breathing exercise link
                      TextButton.icon(
                        onPressed: _showBreathingOverlay,
                        icon: const Icon(Icons.self_improvement_rounded, color: Colors.white38, size: 18),
                        label: const Text(
                          'Try a breathing exercise instead',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = 1 - (_remainingSeconds / widget.initialSeconds);

    return Column(
      children: [
        Text(
          'Unlock in',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds > 60 ? AppTheme.primary : AppTheme.accent,
                ),
              ),
            ),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _remainingSeconds > 60 ? AppTheme.primary : AppTheme.accent,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtendOptions() {
    return Column(
      children: [
        Text(
          'Extend lock duration',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 5, 10].map((mins) => GestureDetector(
            onTap: () => setState(() => _remainingSeconds += mins * 60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '+${mins}m',
                style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _showBreathingOverlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B3E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('4-4-4 Breathing', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            _BreathingCircle(),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedAction extends StatelessWidget {
  final String icon;
  final String label;
  const _BlockedAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BreathingCircle extends StatefulWidget {
  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  String _phase = 'Breathe In';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _startCycle();
  }

  void _startCycle() async {
    while (mounted) {
      setState(() => _phase = 'Breathe In');
      await _ctrl.forward();
      setState(() => _phase = 'Hold');
      await Future.delayed(const Duration(seconds: 4));
      setState(() => _phase = 'Breathe Out');
      await _ctrl.reverse();
      setState(() => _phase = 'Hold');
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => Container(
        width: 80 + _ctrl.value * 60,
        height: 80 + _ctrl.value * 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary.withOpacity(0.2),
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: Center(
          child: Text(_phase, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    );
  }
}
