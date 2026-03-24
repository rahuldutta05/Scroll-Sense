import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:scroll_sense/main.dart';
import 'package:scroll_sense/models/hive_adapters.dart';
import '../utils/app_theme.dart';
import '../services/intervention_config_service.dart';
import '../services/mood_service.dart';
import 'blocked_apps_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.scrollsense/usage_stats');

  bool _accessibilityEnabled = false;
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _notificationsGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    try {
      final usage = await _channel.invokeMethod<bool>('hasUsagePermission') ?? false;
      final overlay = await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
      final access = await _channel.invokeMethod<bool>('hasAccessibilityPermission') ?? false;
      if (mounted) setState(() {
        _usageStatsGranted = usage;
        _overlayGranted = overlay;
        _accessibilityEnabled = access;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    // Single read – InterventionConfigNotifier handles persistence
    final config = ref.watch(interventionConfigProvider);
    final notifier = ref.read(interventionConfigProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refreshPermissions,
                tooltip: 'Refresh permissions',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPermissionsSection(),
                const SizedBox(height: 20),
                _buildDetectionSection(config, notifier),
                const SizedBox(height: 20),
                _buildInterventionSection(config, notifier),
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

  // ─── Sections ─────────────────────────────────────────────────────────────

  Widget _buildPermissionsSection() {
    return _buildSection('PERMISSIONS', [
      _PermissionTile(
        icon: Icons.query_stats_rounded,
        title: 'Usage Access',
        subtitle: _usageStatsGranted ? 'Granted ✓' : 'Required — Tap to grant',
        color: _usageStatsGranted ? AppTheme.success : AppTheme.accent,
        granted: _usageStatsGranted,
        onTap: () => _channel.invokeMethod('requestUsagePermission'),
      ),
      _PermissionTile(
        icon: Icons.accessibility_new_rounded,
        title: 'Accessibility Service',
        subtitle: _accessibilityEnabled ? 'Active ✓' : 'Required for app blocking — Tap to enable',
        color: _accessibilityEnabled ? AppTheme.success : AppTheme.accent,
        granted: _accessibilityEnabled,
        onTap: () => _channel.invokeMethod('requestAccessibilityPermission'),
      ),
      _PermissionTile(
        icon: Icons.layers_rounded,
        title: 'Display Over Apps',
        subtitle: _overlayGranted ? 'Granted ✓' : 'Required for lock screen — Tap to grant',
        color: _overlayGranted ? AppTheme.success : AppTheme.accent,
        granted: _overlayGranted,
        onTap: () => _channel.invokeMethod('requestOverlayPermission'),
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

  Widget _buildDetectionSection(
      InterventionConfig config, InterventionConfigNotifier notifier) {
    return _buildSection('DETECTION', [
      _SliderTile(
        icon: Icons.timer_rounded,
        title: 'Continuous Use Threshold',
        subtitle: '${config.continuousThresholdMins} min before triggering',
        value: config.continuousThresholdMins.toDouble(),
        min: 10,
        max: 60,
        divisions: 10,
        onChanged: (v) => notifier.setContinuousThreshold(v.round()),
      ),
      _SliderTile(
        icon: Icons.hourglass_empty_rounded,
        title: 'Cooldown Between Interventions',
        subtitle: '${config.cooldownMins} min cooldown (avoids spam)',
        value: config.cooldownMins.toDouble(),
        min: 5,
        max: 60,
        divisions: 11,
        onChanged: (v) => notifier.setCooldown(v.round()),
        activeColor: AppTheme.warning,
      ),
      _SwitchTile(
        icon: Icons.nightlight_rounded,
        title: 'Night Mode Detection',
        subtitle: 'Extra strict after 11 PM',
        value: config.nightModeEnabled,
        onChanged: notifier.setNightMode,
      ),
      _SwitchTile(
        icon: Icons.switch_access_shortcut_add_rounded,
        title: 'Rapid Switch Detection',
        subtitle: 'Detect app-switching loops (<5 s)',
        value: config.rapidSwitchDetection,
        onChanged: notifier.setRapidSwitch,
      ),
    ]);
  }

  Widget _buildInterventionSection(
      InterventionConfig config, InterventionConfigNotifier notifier) {
    final level = config.maxLevel;
    final color = InterventionConfig.levelColor(level);

    return _buildSection('INTERVENTION', [
      // ── Slider with live level preview ──────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(InterventionConfig.levelIcon(level), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Intervention Level',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        InterventionConfig.levelLabel(level),
                        key: ValueKey(level),
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Segmented track with colour gradient
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.grey.withOpacity(0.15),
                  ),
                ),
                // Coloured fill
                FractionallySizedBox(
                  widthFactor: (level - 1) / 4,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success,
                          AppTheme.warning,
                          AppTheme.accent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Step dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final active = i < level;
                    return GestureDetector(
                      onTap: () => notifier.setLevel(i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 14 : 10,
                        height: active ? 14 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? InterventionConfig.levelColor(i + 1) : Colors.grey.withOpacity(0.3),
                          border: Border.all(
                            color: active ? Colors.white.withOpacity(0.4) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Level labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Notify', 'Warn', 'Breathe', 'Soft Lock', 'Hard Lock']
                  .map((l) => Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)))
                  .toList(),
            ),
            // Slider as fine control
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: color,
                overlayColor: color.withOpacity(0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: level.toDouble(),
                min: 1, max: 5, divisions: 4,
                onChanged: (v) => notifier.setLevel(v.round()),
              ),
            ),
          ],
        ),
      ),

      // Hard lock toggle (only relevant at L5)
      _SwitchTile(
        icon: Icons.lock_rounded,
        title: 'Hard Lock Enabled',
        subtitle: 'Full-screen non-dismissible overlay',
        value: level >= 5,
        onChanged: (v) => notifier.setLevel(v ? 5 : 4),
        color: AppTheme.accent,
      ),

      // Lock duration (only when L4 or L5)
      if (level >= 4)
        _SliderTile(
          icon: Icons.timelapse_rounded,
          title: 'Lock Duration',
          subtitle: '${config.lockDurationMins} minutes per lock session',
          value: config.lockDurationMins.toDouble(),
          min: 1, max: 30, divisions: 29,
          onChanged: (v) => notifier.setLockDuration(v.round()),
          activeColor: AppTheme.accent,
        ),

      // Blocked apps
      _NavigationTile(
        icon: Icons.block_rounded,
        title: 'Blocked Apps',
        subtitle: '${config.blockedApps.length} apps configured',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BlockedAppsScreen()),
        ),
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
        onTap: _exportData,
      ),
      _NavigationTile(
        icon: Icons.mood_bad_rounded,
        title: 'Clear Mood Data',
        subtitle: 'Delete all mood check-ins',
        onTap: () => _showClearMoodDialog(),
        color: AppTheme.warning,
      ),
      _NavigationTile(
        icon: Icons.refresh_rounded,
        title: 'Reset Analytics',
        subtitle: 'Clear all tracked usage data',
        onTap: () => _showResetDialog(),
        color: AppTheme.accent,
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('ABOUT', [
      _InfoTile(icon: Icons.info_rounded, title: 'ScrollSense', subtitle: 'Version 1.0.0'),
      _InfoTile(icon: Icons.privacy_tip_rounded, title: 'Privacy', subtitle: 'All data stored on-device only'),
      _NavigationTile(
        icon: Icons.star_rounded,
        title: 'Rate App',
        subtitle: 'Help us grow',
        onTap: () async {
          const url = 'market://details?id=com.scrollsense.app';
          try {
            await _channel.invokeMethod('openUrl', {'url': url});
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Play Store')),
              );
            }
          }
        },
        color: AppTheme.warning,
      ),
    ]);
  }

  // ─── Shared card wrapper ───────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primary, fontSize: 13, letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children.indexed.map((entry) {
              final (i, child) = entry;
              return Column(children: [
                child,
                if (i < children.length - 1)
                  Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.1)),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    try {
      final box = Hive.box('usage_data');
      final records = box.values.cast<AppUsageRecord>().toList();

      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      // Header
      rows.add(['Date', 'App Name', 'Package', 'Duration (seconds)', 'Open Count']);

      for (var record in records) {
        rows.add([
          record.date.toIso8601String(),
          record.appName,
          record.packageName,
          record.durationSeconds,
          record.openCount,
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final path = "${directory.path}/usage_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);

      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Analytics?'),
        content: const Text('This will permanently delete all tracked data.'),
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

  void _showClearMoodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Mood Data?'),
        content: const Text('All mood check-in history will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(moodServiceProvider).deleteAll();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Tile widgets (unchanged interface) ──────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.granted, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
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

  const _SwitchTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.onChanged, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
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

  const _SliderTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.min, required this.max,
    this.divisions, required this.onChanged, this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = activeColor ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
          Slider(value: value, min: min, max: max, divisions: divisions, activeColor: c, onChanged: onChanged),
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

  const _NavigationTile({
    required this.icon, required this.title, required this.subtitle,
    required this.onTap, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
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
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.grey, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
