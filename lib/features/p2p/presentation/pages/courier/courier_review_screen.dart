import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/widgets/p2p_step_header.dart';

class CourierReviewScreen extends StatelessWidget {
  const CourierReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>(),
      child: const _ReviewView(),
    );
  }
}

class _ReviewView extends StatefulWidget {
  const _ReviewView();

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  bool _finalAccepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<P2pOnboardingBloc, P2pOnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '🎉 Application submitted! We\'ll review it within 24 hours.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.go('/p2p');
        }
        if (state.status == OnboardingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Submission failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final data = state.collectedData;
        final isSubmitting = state.status == OnboardingStatus.submitting;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            title: const Text('Review & Submit'),
            leading: const BackButton(),
          ),
          body: Column(
            children: [
              const P2pStepHeader(currentStep: 5, totalSteps: 5),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identity summary
                      _SummaryCard(
                        title: 'Identity',
                        icon: Icons.badge_outlined,
                        onEdit: () => context.go('/p2p/courier/identity'),
                        rows: [
                          _SummaryRow(
                              label: 'Name',
                              value: data['full_name'] ?? '—'),
                          _SummaryRow(
                            label: 'Date of birth',
                            value: _formatDate(data['dob']),
                          ),
                          _SummaryRow(
                              label: 'Nationality',
                              value: data['nationality'] ?? '—'),
                          _SummaryRow(
                              label: 'ID type',
                              value: data['id_type'] ?? '—'),
                          _SummaryRow(
                              label: 'ID number',
                              value: _mask(data['id_number'])),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Documents summary
                      _SummaryCard(
                        title: 'Documents',
                        icon: Icons.folder_outlined,
                        onEdit: () => context.go('/p2p/courier/documents'),
                        rows: [
                          _SummaryRow(
                            label: 'Passport',
                            value: data['passport_image_path'] != null
                                ? '✓ Uploaded'
                                : '—',
                            valueColor: data['passport_image_path'] != null
                                ? AppTheme.primaryColor
                                : null,
                          ),
                          _SummaryRow(
                            label: 'Visa',
                            value: data['visa_image_path'] != null
                                ? '✓ Uploaded'
                                : 'Not provided',
                            valueColor: data['visa_image_path'] != null
                                ? AppTheme.primaryColor
                                : null,
                          ),
                          _SummaryRow(
                            label: 'Itinerary',
                            value: data['itinerary_image_path'] != null
                                ? '✓ Uploaded'
                                : '—',
                            valueColor: data['itinerary_image_path'] != null
                                ? AppTheme.primaryColor
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Route summary
                      _SummaryCard(
                        title: 'Route',
                        icon: Icons.alt_route_outlined,
                        onEdit: () => context.go('/p2p/courier/route'),
                        rows: [
                          _SummaryRow(
                            label: 'From',
                            value: (data['pickupOrigin'] as String?) ??
                                _routeCity(
                                    data['origin_city'], data['origin_country']),
                          ),
                          _SummaryRow(
                            label: 'To',
                            value: _routeCity(data['destinationCity'],
                                data['destinationCountry']),
                          ),
                          _SummaryRow(
                            label: 'Departure',
                            value: _formatDate(data['departureDate']),
                          ),
                          _SummaryRow(
                            label: 'Capacity',
                            value:
                                '${data['capacityKg']?.toString() ?? '—'} kg',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Compliance check result (green — semantic success colour)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All compliance acknowledgements accepted',
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                context.go('/p2p/courier/compliance'),
                              style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Final acceptance checkbox
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _finalAccepted
                                ? AppTheme.primaryColor
                                : theme.colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _finalAccepted,
                                onChanged: (v) =>
                                    setState(() => _finalAccepted = v!),
                                activeColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _finalAccepted = !_finalAccepted),
                                child: Text(
                                  'I confirm all information provided is accurate and complete. '
                                  'I understand that providing false information may result in '
                                  'permanent account suspension.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.8),
                                        height: 1.5,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              (_finalAccepted && !isSubmitting) ? _onSubmit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                theme.colorScheme.outline.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSubmit() {
    context
        .read<P2pOnboardingBloc>()
        .add(const P2pOnboardingConfirmSubmit());
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String _mask(dynamic val) {
    if (val == null) return '—';
    final s = val.toString();
    if (s.length <= 4) return s;
    return '••••${s.substring(s.length - 4)}';
  }

  String _routeCity(dynamic city, dynamic country) {
    final c = city?.toString() ?? '';
    final co = country?.toString() ?? '';
    if (c.isEmpty && co.isEmpty) return '—';
    return '$c, $co'.trim().replaceAll(RegExp(r'^,\s*'), '');
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<_SummaryRow> rows;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                r.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45)),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                r.value,
                                style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: r.valueColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
}
