import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_theme.dart';
import 'package:flutter/services.dart';
import '../services/usage_stats_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      emoji: '🧠',
      title: 'Meet ScrollSense',
      subtitle: 'Your intelligent screen time guardian that helps you break free from doom scrolling',
      color: AppTheme.primary,
    ),
    _OnboardingPage(
      emoji: '🚨',
      title: 'Hard Lock Protection',
      subtitle: 'When you doom-scroll, ScrollSense locks the app completely — no skipping, no bypassing',
      color: AppTheme.accent,
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'Deep Analytics',
      subtitle: 'Track your Focus Score, Addiction Score, and behavioral patterns over time',
      color: const Color(0xFF10B981),
    ),
    _OnboardingPage(
      emoji: '⚙️',
      title: 'Grant Permissions',
      subtitle: 'ScrollSense needs a few permissions to protect you',
      color: AppTheme.warning,
      isPermissions: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1035), Color(0xFF1A1B3E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (ctx, i) => _buildPage(_pages[i]),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: page.color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(page.emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (page.isPermissions) ...[
            const SizedBox(height: 32),
            _buildPermissionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionButtons() {
    return Column(
      children: [
        _PermissionTile(
          icon: Icons.bar_chart,
          title: 'Usage Access',
          subtitle: 'Track which apps you use',
          onTap: () => UsageStatsService.requestPermission(),
        ),
        const SizedBox(height: 12),
        _PermissionTile(
          icon: Icons.accessibility_new,
          title: 'Accessibility Service',
          subtitle: 'Detect scroll behavior',
          onTap: () async {
            try {
              await const MethodChannel('com.scrollsense/usage_stats')
                  .invokeMethod('requestAccessibilityPermission');
            } catch (_) {}
          },
        ),
        const SizedBox(height: 12),
        _PermissionTile(
          icon: Icons.layers,
          title: 'Display Over Apps',
          subtitle: 'Show lock screen overlay',
          onTap: () async {
            try {
              await const MethodChannel('com.scrollsense/usage_stats')
                  .invokeMethod('requestOverlayPermission');
            } catch (_) {}
          },
        ),
        const SizedBox(height: 12),
        _PermissionTile(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Send intervention alerts',
          onTap: () async {
            try {
              await const MethodChannel('com.scrollsense/usage_stats')
                  .invokeMethod('requestNotificationPermission');
            } catch (_) {}
          },
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppTheme.primary
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finishOnboarding();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() {
    Hive.box('settings').put('onboarded', true);
    Navigator.pushReplacementNamed(context, '/home');
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool isPermissions;

  _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isPermissions = false,
  });
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }
}
