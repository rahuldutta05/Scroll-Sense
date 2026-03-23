import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/digital_debt_service.dart';
import '../utils/app_theme.dart';

class DigitalDebtCard extends ConsumerWidget {
  const DigitalDebtCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(digitalDebtProvider);

    return debtAsync.when(
      loading: () => _ShimmerCard(height: 160),
      error: (_, __) => const SizedBox.shrink(),
      data: (debt) => _DebtCardContent(debt: debt, ref: ref),
    );
  }
}

class _DebtCardContent extends StatelessWidget {
  final DigitalDebtData debt;
  final WidgetRef ref;
  const _DebtCardContent({required this.debt, required this.ref});

  @override
  Widget build(BuildContext context) {
    final overBudget = debt.isOverBudget;
    final barColor = overBudget ? AppTheme.accent : AppTheme.success;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                overBudget ? '📊 Digital Debt' : '✅ On Budget',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _GoalChip(debt: debt, ref: ref),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          LayoutBuilder(
            builder: (_, c) {
              final fillWidth = (c.maxWidth * debt.debtProgress).clamp(0.0, c.maxWidth);
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: c.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    height: 10,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                debt.debtLabel,
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '${debt.todayLabel} / ${debt.goalLabel} goal',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          // Time saved section (only when positive)
          if (debt.weeklyTimeSavedMinutes > 0) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⏱️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time reclaimed this week',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      debt.savedLabel,
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final DigitalDebtData debt;
  final WidgetRef ref;
  const _GoalChip({required this.debt, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              'Goal: ${debt.dailyGoalMinutes ~/ 60}h',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _GoalDialog(
        current: debt.dailyGoalMinutes,
        onSave: (mins) {
          ref.read(digitalDebtServiceProvider).setDailyGoal(mins);
          ref.invalidate(digitalDebtProvider);
        },
      ),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  final int current;
  final void Function(int) onSave;
  const _GoalDialog({required this.current, required this.onSave});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late double _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.current.toDouble();
  }

  String _fmt(int m) =>
      m >= 60 ? '${m ~/ 60}h ${m % 60 > 0 ? '${m % 60}m' : ''}' : '${m}m';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Daily Screen Time Goal',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmt(_goal.round()),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _goal,
            min: 30,
            max: 480,
            divisions: 15,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _goal = v),
          ),
          const Text(
            'Slide to set your daily limit',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_goal.round());
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
