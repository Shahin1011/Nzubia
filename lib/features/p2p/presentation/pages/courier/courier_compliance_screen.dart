import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/widgets/p2p_step_header.dart';

class CourierComplianceScreen extends StatelessWidget {
  const CourierComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>(),
      child: const _ComplianceView(),
    );
  }
}

class _ComplianceView extends StatefulWidget {
  const _ComplianceView();

  @override
  State<_ComplianceView> createState() => _ComplianceViewState();
}

class _ComplianceViewState extends State<_ComplianceView> {
  bool _insuranceAck = false;
  bool _liabilityAck = false;
  bool _prohibitedAck = false;
  bool _customsAck = false;
  bool _termsAck = false;

  bool get _allAcknowledged =>
      _insuranceAck &&
      _liabilityAck &&
      _prohibitedAck &&
      _customsAck &&
      _termsAck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Insurance & Compliance'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const P2pStepHeader(currentStep: 4, totalSteps: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Insurance explainer card (amber warning style)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.policy_outlined,
                                color: Colors.amber[800], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Nzubia P2P Insurance',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nzubia provides limited liability coverage on all matched shipments. '
                          'As a courier, you are covered up to the limits below:',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.amber[900]),
                        ),
                        const SizedBox(height: 12),
                        _InsuranceRow(
                            label: 'Item damage in transit',
                            value: 'Up to \$500 USD'),
                        _InsuranceRow(
                            label: 'Theft at handoff',
                            value: 'Up to \$200 USD'),
                        _InsuranceRow(
                            label: 'Customs seizure (prohibited item)',
                            value: 'NOT COVERED'),
                        _InsuranceRow(
                            label: 'Personal injury',
                            value: 'NOT COVERED'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_outlined,
                                  color: Colors.red[700], size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Couriers who carry prohibited items forfeit all coverage '
                                  'and are subject to legal action.',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Liability boundary text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liability Boundaries',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You, as the courier, agree that Nzubia acts solely as a platform '
                          'facilitating connections between senders and couriers. '
                          'Nzubia is not a common carrier and does not assume responsibility '
                          'for items beyond the stated coverage limits. You acknowledge full '
                          'responsibility for customs declarations, legal compliance in all '
                          'countries on your route, and adherence to airline baggage policies.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Acknowledgements',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  _AckCheckbox(
                    value: _insuranceAck,
                    onChanged: (v) => setState(() => _insuranceAck = v!),
                    label:
                        'I understand the insurance coverage limits and exclusions.',
                  ),
                  _AckCheckbox(
                    value: _liabilityAck,
                    onChanged: (v) => setState(() => _liabilityAck = v!),
                    label:
                        'I accept the liability boundary terms described above.',
                  ),
                  _AckCheckbox(
                    value: _prohibitedAck,
                    onChanged: (v) => setState(() => _prohibitedAck = v!),
                    label:
                        'I confirm I will not carry prohibited items (weapons, narcotics, hazardous materials, counterfeit goods).',
                  ),
                  _AckCheckbox(
                    value: _customsAck,
                    onChanged: (v) => setState(() => _customsAck = v!),
                    label:
                        'I understand I am solely responsible for making accurate customs declarations.',
                  ),
                  _AckCheckbox(
                    value: _termsAck,
                    onChanged: (v) => setState(() => _termsAck = v!),
                    label:
                        'I have read and agree to the Nzubia P2P Courier Terms of Service.',
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _allAcknowledged ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _allAcknowledged
                            ? 'Next: Review & Submit'
                            : 'Accept all items above to continue',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
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
  }

  void _onNext() {
    context.read<P2pOnboardingBloc>().add(
          P2pOnboardingComplianceSubmitted({
            'insurance_acknowledged': _insuranceAck,
            'liability_acknowledged': _liabilityAck,
            'prohibited_acknowledged': _prohibitedAck,
            'customs_acknowledged': _customsAck,
            'terms_acknowledged': _termsAck,
            'compliance_accepted_at': DateTime.now().toIso8601String(),
          }),
        );
    context.push('/p2p/courier/review');
  }
}

class _InsuranceRow extends StatelessWidget {
  final String label;
  final String value;

  const _InsuranceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isNotCovered = value == 'NOT COVERED';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.amber[800]),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isNotCovered ? Colors.red[600] : Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AckCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const _AckCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
