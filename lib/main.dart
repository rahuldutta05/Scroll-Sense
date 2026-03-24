import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/blocked_apps_screen.dart';
import 'services/intervention_service.dart';
import 'services/intervention_config_service.dart';
import 'screens/insights_screen.dart';
import 'screens/lock_overlay_screen.dart';
import 'services/background_service.dart';
import 'utils/app_theme.dart';
import 'models/hive_adapters.dart';
import 'screens/notifications/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AppUsageRecordAdapter());
  Hive.registerAdapter(FocusSessionAdapter());
  Hive.registerAdapter(AchievementAdapter());

  await Hive.openBox('settings');
  await Hive.openBox('usage_data');
  await Hive.openBox('focus_sessions');
  await Hive.openBox('achievements');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeBackgroundService();

  runApp(const ProviderScope(child: ScrollSenseApp()));
}

class ScrollSenseApp extends ConsumerWidget {
  const ScrollSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ScrollSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (ctx) => const SplashScreen(),
        '/onboarding': (ctx) => const OnboardingScreen(),
        '/home': (ctx) => const InterventionListener(child: MainShell()),
        '/blocked_apps': (ctx) => const BlockedAppsScreen(),
        '/lock': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is Map) {
            return LockOverlayScreen(
              appName: args['appName'] as String? ?? 'an app',
              triggerReason: args['triggerReason'] as String? ?? 'Doom scroll detected',
              initialSeconds: args['initialSeconds'] as int? ?? 300,
            );
          }
          return const LockOverlayScreen();
        },
        '/notifications': (ctx) => const NotificationScreen(),
      },
    );
  }
}

final themeModeProvider = StateProvider<bool>((ref) {
  final box = Hive.box('settings');
  return box.get('dark_mode', defaultValue: false);
});

final navigationProvider = StateProvider<int>((ref) => 0);
final focusTabModeProvider = StateProvider<bool>((ref) => false);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const DashboardScreen(),
    const FocusScreen(),
    const InsightsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats', index: 1, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
              _NavItem(icon: Icons.center_focus_strong_rounded, label: 'Focus', index: 2, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
              _NavItem(icon: Icons.insights_rounded, label: 'Insights', index: 3, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
              _NavItem(icon: Icons.emoji_events_rounded, label: 'Reports', index: 4, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
              _NavItem(icon: Icons.tune_rounded, label: 'Settings', index: 5, current: currentIndex, onTap: (i) => ref.read(navigationProvider.notifier).state = i),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}