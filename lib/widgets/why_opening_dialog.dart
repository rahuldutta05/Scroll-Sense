import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A friction dialog that surfaces before a user opens a flagged app.
/// Call [WhyOpeningDialog.show] from your lock overlay or accessibility
/// service callback to capture the user's opening intent.
///
/// Returns the intent key if the user proceeds, or null if they cancel.
class WhyOpeningDialog extends StatelessWidget {
  final String appName;
  final void Function(String intent) onProceed;
  final VoidCallback onCancel;

  const WhyOpeningDialog({
    super.key,
    required this.appName,
    required this.onProceed,
    required this.onCancel,
  });

  static const _intents = [
    ('🎯', 'I have a specific task', 'task'),
    ('👀', 'Just quickly checking', 'checking'),
    ('😑', 'Boredom / nothing to do', 'boredom'),
    ('🔁', 'Force of habit', 'habit'),
  ];

  /// Shows the dialog and returns the chosen intent key, or null if cancelled.
  static Future<String?> show(BuildContext context, String appName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhyOpeningDialog(
        appName: appName,
        onProceed: (intent) => Navigator.pop(context, intent),
        onCancel: () => Navigator.pop(context, null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤔', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            Text(
              'Why are you opening\n$appName?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'One moment of intention before you scroll.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Intent options
            ..._intents.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _IntentTile(
                  emoji: item.$1,
                  label: item.$2,
                  onTap: () => onProceed(item.$3),
                ),
              ),
            ),

            const SizedBox(height: 4),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Actually, never mind',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _IntentTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
