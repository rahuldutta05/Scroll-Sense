import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _interventionLevel = 3;
  int _lockDurationMins = 5;
  bool _nightModeEnabled = true;
  bool _accessibilityEnabled = false;
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _notificationsGranted = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPermissionsSection(),
                const SizedBox(height: 20),
                _buildDetectionSection(),
                const SizedBox(height: 20),
                _buildInterventionSection(),
                const SizedBox(height: 20),
                _buildAppearanceSection(isDark),
                const SizedBox(height: 20),
                _buildDataSection(),
                const SizedBox(height: 20),
                _buildAboutSection(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primary,
            fontSize: 13,
            letterSpacing: 0.5,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children.indexed.map((entry) {
              final (i, child) = entry;
              return Column(
                children: [
                  child,
                  if (i < children.length - 1)
                    Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return _buildSection('PERMISSIONS', [
      _PermissionTile(
        icon: Icons.query_stats_rounded,
        title: 'Usage Access',
        subtitle: _usageStatsGranted ? 'Granted ✓' : 'Required - Tap to grant',
        color: _usageStatsGranted ? AppTheme.success : AppTheme.accent,
        granted: _usageStatsGranted,
        onTap: () => setState(() => _usageStatsGranted = !_usageStatsGranted),
      ),
      _PermissionTile(
        icon: Icons.accessibility_new_rounded,
        title: 'Accessibility Service',
        subtitle: _accessibilityEnabled ? 'Active ✓' : 'Required for scroll detection',
        color: _accessibilityEnabled ? AppTheme.success : AppTheme.accent,
        granted: _accessibilityEnabled,
        onTap: () => setState(() => _accessibilityEnabled = !_accessibilityEnabled),
      ),
      _PermissionTile(
        icon: Icons.layers_rounded,
        title: 'Display Over Apps',
        subtitle: _overlayGranted ? 'Granted ✓' : 'Required for lock screen',
        color: _overlayGranted ? AppTheme.success : AppTheme.accent,
        granted: _overlayGranted,
        onTap: () => setState(() => _overlayGranted = !_overlayGranted),
      ),
      _PermissionTile(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        subtitle: _notificationsGranted ? 'Enabled ✓' : 'Tap to enable',
        color: _notificationsGranted ? AppTheme.success : AppTheme.warning,
        granted: _notificationsGranted,
        onTap: () => setState(() => _notificationsGranted = !_notificationsGranted),
      ),
    ]);
  }

  Widget _buildDetectionSection() {
    return _buildSection('DETECTION', [
      _SliderTile(
        icon: Icons.timer_rounded,
        title: 'Continuous Use Threshold',
        subtitle: 'Trigger after ${_lockDurationMins == 5 ? "30" : "20"} min of continuous use',
        value: _lockDurationMins.toDouble(),
        min: 5,
        max: 60,
        divisions: 11,
        onChanged: (v) => setState(() => _lockDurationMins = v.round()),
      ),
      _SwitchTile(
        icon: Icons.nightlight_rounded,
        title: 'Night Mode Detection',
        subtitle: 'Extra strict after 11 PM',
        value: _nightModeEnabled,
        onChanged: (v) => setState(() => _nightModeEnabled = v),
      ),
      _SwitchTile(
        icon: Icons.switch_access_shortcut_add_rounded,
        title: 'Rapid Switch Detection',
        subtitle: 'Detect app switching loops',
        value: true,
        onChanged: (v) {},
      ),
    ]);
  }

  Widget _buildInterventionSection() {
    return _buildSection('INTERVENTION', [
      _SliderTile(
        icon: Icons.warning_rounded,
        title: 'Intervention Level',
        subtitle: _getLevelDescription(_interventionLevel),
        value: _interventionLevel.toDouble(),
        min: 1,
        max: 5,
        divisions: 4,
        onChanged: (v) => setState(() => _interventionLevel = v.round()),
        activeColor: _getLevelColor(_interventionLevel),
      ),
      _SwitchTile(
        icon: Icons.lock_rounded,
        title: 'Hard Lock Enabled',
        subtitle: 'Full-screen non-dismissible overlay',
        value: _interventionLevel >= 5,
        onChanged: (v) => setState(() => _interventionLevel = v ? 5 : 3),
        color: AppTheme.accent,
      ),
      _NavigationTile(
        icon: Icons.block_rounded,
        title: 'Blocked Apps',
        subtitle: '4 apps configured',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildAppearanceSection(bool isDark) {
    return _buildSection('APPEARANCE', [
      _SwitchTile(
        icon: Icons.dark_mode_rounded,
        title: 'Dark Mode',
        subtitle: 'Use dark theme',
        value: isDark,
        onChanged: (v) {
          ref.read(themeModeProvider.notifier).state = v;
          Hive.box('settings').put('dark_mode', v);
        },
      ),
    ]);
  }

  Widget _buildDataSection() {
    return _buildSection('DATA', [
      _NavigationTile(
        icon: Icons.download_rounded,
        title: 'Export Data',
        subtitle: 'Download usage history as CSV',
        onTap: () {},
      ),
      _NavigationTile(
        icon: Icons.refresh_rounded,
        title: 'Reset Analytics',
        subtitle: 'Clear all tracked data',
        onTap: () => _showResetDialog(),
        color: AppTheme.accent,
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('ABOUT', [
      _InfoTile(icon: Icons.info_rounded, title: 'ScrollSense', subtitle: 'Version 1.0.0'),
      _InfoTile(icon: Icons.privacy_tip_rounded, title: 'Privacy Policy', subtitle: 'Data stays on device'),
      _NavigationTile(icon: Icons.star_rounded, title: 'Rate App', subtitle: 'Help us grow', onTap: () {}, color: AppTheme.warning),
    ]);
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Analytics?'),
        content: const Text('This will permanently delete all your tracked data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Hive.box('usage_data').clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getLevelDescription(int level) {
    return ['Gentle Notification', 'Warning Popup', 'Breathing Break',
        'Temporary Lock', 'HARD LOCK 🔒'][level - 1];
  }

  Color _getLevelColor(int level) {
    return [AppTheme.success, AppTheme.success, AppTheme.warning,
        AppTheme.warning, AppTheme.accent][level - 1];
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.granted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
      trailing: Icon(granted ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
          color: granted ? AppTheme.success : Colors.grey, size: granted ? 20 : 14),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final Color? color;

  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: c),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Function(double) onChanged;
  final Color? activeColor;

  const _SliderTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.min, required this.max, this.divisions, required this.onChanged, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (activeColor ?? AppTheme.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: activeColor ?? AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: activeColor ?? AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _NavigationTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
