import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';

class CourierApplyScreen extends StatelessWidget {
  const CourierApplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>()
        ..add(const P2pOnboardingStarted()),
      child: const _ApplyView(),
    );
  }
}

class _ApplyView extends StatelessWidget {
  const _ApplyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/p2p'),
        ),
        title: const Text('Become a Courier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.flight_takeoff_rounded,
                      size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    'Travel & Earn',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Carry packages for others on your travels and earn extra income.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Text(
              'Why become a courier?',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            _BenefitRow(
              icon: Icons.attach_money_outlined,
              color: Colors.green[600]!,
              title: 'Earn on every trip',
              subtitle:
                  'Get paid to carry packages you were going to carry anyway.',
            ),
            const SizedBox(height: 12),
            _BenefitRow(
              icon: Icons.schedule_outlined,
              color: AppTheme.primaryColor,
              title: 'Flexible schedule',
              subtitle: 'Post routes only when you have a confirmed trip.',
            ),
            const SizedBox(height: 12),
            _BenefitRow(
              icon: Icons.shield_outlined,
              color: Colors.blue[600]!,
              title: 'Fully insured',
              subtitle:
                  'Nzubia covers liability for all matched shipments up to \$500.',
            ),
            const SizedBox(height: 12),
            _BenefitRow(
              icon: Icons.verified_outlined,
              color: Colors.purple[600]!,
              title: 'Trusted network',
              subtitle:
                  'All couriers are ID-verified and background-checked.',
            ),

            const SizedBox(height: 28),

            // Compliance bullets
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Before you apply',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._complianceBullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 15, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(b,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/p2p/courier/identity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Verification — 4 quick steps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.push('/p2p/courier/compliance'),
                child: const Text('Read full compliance policy'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static const _complianceBullets = [
    'You must have a valid government-issued ID and live selfie verification.',
    'Prohibited items (weapons, narcotics, hazardous materials) are strictly forbidden.',
    'You are responsible for declaring carried goods at customs.',
    'Maximum declared item value per shipment: \$500 USD.',
  ];
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
