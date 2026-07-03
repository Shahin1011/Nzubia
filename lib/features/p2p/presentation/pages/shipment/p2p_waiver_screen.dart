import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/data/services/p2p_payment_tracker.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_waiver.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_compliance_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

class P2pWaiverScreen extends StatefulWidget {
  final String shipmentId;

  const P2pWaiverScreen({super.key, required this.shipmentId});

  @override
  State<P2pWaiverScreen> createState() => _P2pWaiverScreenState();
}

class _P2pWaiverScreenState extends State<P2pWaiverScreen> {
  late final Future<P2pWaiverPreview> _previewFuture;
  final Set<String> _checked = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = GetIt.instance<P2pComplianceRepository>()
        .previewWaiver(widget.shipmentId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforcePaymentGate());
  }

  void _enforcePaymentGate() {
    if (!mounted) return;
    // If a payment is still pending (not yet confirmed by the payment sheet),
    // redirect back to the payment screen rather than letting the user sign the
    // waiver and call reserve — the backend will reject it, but we can surface
    // a better UX here first.
    if (!P2pPaymentTracker.hasCompletedPayment(widget.shipmentId) &&
        P2pPaymentTracker.hasPaymentPending(widget.shipmentId)) {
      final secret =
          P2pPaymentTracker.getPendingClientSecret(widget.shipmentId);
      final amount = P2pPaymentTracker.getPendingAmount(widget.shipmentId);
      final offerId = P2pPaymentTracker.getPendingOfferId(widget.shipmentId);
      if (secret != null && amount != null) {
        context.pushReplacement(
          '/p2p/shipment/${widget.shipmentId}/payment',
          extra: {
            'offerId': offerId ?? '',
            'clientSecret': secret,
            'amountUsd': amount,
          },
        );
      }
    }
  }

  bool _allChecked(P2pWaiverPreview preview) =>
      preview.rules.every((r) => _checked.contains(r.flag));

  Future<void> _submit(P2pWaiverPreview preview) async {
    if (!_allChecked(preview)) return;
    setState(() => _submitting = true);
    try {
      final complianceRepo = GetIt.instance<P2pComplianceRepository>();
      final shipmentRepo = GetIt.instance<P2pShipmentRepository>();

      await complianceRepo.acceptWaiver(
        widget.shipmentId,
        acknowledgedFlags: preview.rules.map((r) => r.flag).toList(),
      );
      await shipmentRepo.reserveShipment(widget.shipmentId);

      if (mounted) {
        context.pushReplacement(
            '/p2p/shipment/${widget.shipmentId}/handoff');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Risk Waiver'),
        leading: const BackButton(),
      ),
      body: FutureBuilder<P2pWaiverPreview>(
        future: _previewFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load waiver',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final preview = snap.data!;
          final allChecked = _allChecked(preview);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.gavel_outlined,
                                color: Colors.amber[800], size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Before your shipment is reserved',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Please read and acknowledge each item below. '
                                    'All items are required to proceed.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.amber[800],
                                      height: 1.4,
                                    ),
                                  ),
                                  if (preview.termsVersion.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Terms v${preview.termsVersion}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.amber[700],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Waiver text ────────────────────────────────────
                      if (preview.waiverText.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Waiver',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.45)),
                          ),
                          child: Text(
                            preview.waiverText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],

                      // ── Risk flags ─────────────────────────────────────
                      const SizedBox(height: 24),
                      Text(
                        'I acknowledge the following',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      ...preview.rules.map((rule) {
                        final isChecked = _checked.contains(rule.flag);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() {
                              if (isChecked) {
                                _checked.remove(rule.flag);
                              } else {
                                _checked.add(rule.flag);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppTheme.primaryColor.withAlpha(10)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isChecked
                                      ? AppTheme.primaryColor.withAlpha(80)
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: (_) => setState(() {
                                      if (isChecked) {
                                        _checked.remove(rule.flag);
                                      } else {
                                        _checked.add(rule.flag);
                                      }
                                    }),
                                    activeColor: AppTheme.primaryColor,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rule.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          rule.description,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Footer: submit button ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!allChecked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'All items must be acknowledged to continue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            (allChecked && !_submitting)
                                ? () => _submit(preview)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primaryColor.withAlpha(60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'I Acknowledge & Continue',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
