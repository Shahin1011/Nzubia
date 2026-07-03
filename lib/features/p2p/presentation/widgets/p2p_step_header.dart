import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';

/// Displays a progress indicator + step label used across all onboarding steps.
class P2pStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  static const _labels = [
    '',
    'Identity',
    'Documents',
    'Route',
    'Compliance',
    'Review',
  ];

  const P2pStepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = currentStep / totalSteps;
    final label = currentStep <= _labels.length - 1
        ? _labels[currentStep]
        : 'Step $currentStep';

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step $currentStep of $totalSteps — $label',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.4),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
