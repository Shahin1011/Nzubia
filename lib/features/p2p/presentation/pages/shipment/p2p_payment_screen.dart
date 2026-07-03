import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/services/payment_service.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/data/services/p2p_payment_tracker.dart';

/// Shown after the seeker accepts a courier offer that has a payment amount.
/// Presents the Stripe payment sheet using the PaymentIntent client_secret
/// returned by the backend at offer-acceptance time.
/// Back navigation is blocked: payment is mandatory to proceed to the waiver.
class P2pPaymentScreen extends StatefulWidget {
  final String shipmentId;
  final String offerId;
  final String clientSecret;
  final double amountUsd;
  final String? courierName;

  const P2pPaymentScreen({
    super.key,
    required this.shipmentId,
    required this.offerId,
    required this.clientSecret,
    required this.amountUsd,
    this.courierName,
  });

  @override
  State<P2pPaymentScreen> createState() => _P2pPaymentScreenState();
}

class _P2pPaymentScreenState extends State<P2pPaymentScreen> {
  bool _processing = false;
  bool _done = false;
  String? _errorMessage;
  // Mutable — may be replaced by a refreshed PaymentIntent.
  late String _clientSecret;

  @override
  void initState() {
    super.initState();
    _clientSecret = widget.clientSecret;
  }

  Future<void> _pay() async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      final paymentService = GetIt.instance<PaymentService>();

      await paymentService.initPaymentSheetWithClientSecret(_clientSecret);
      await paymentService.presentPaymentSheet();

      P2pPaymentTracker.markPaymentComplete(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.pushReplacement('/p2p/shipment/${widget.shipmentId}/waiver');
    } on Exception catch (e) {
      final raw = e.toString();
      // FailureCode.Failed means the PaymentIntent is broken (e.g. it was
      // created routing to an incomplete Stripe Connect account). Fetch a
      // fresh PI from the backend and ask the user to try again.
      if (raw.contains('FailureCode.Failed') && widget.offerId.isNotEmpty) {
        await _refreshPaymentIntent();
        return;
      }
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = _friendlyError(raw);
      });
    }
  }

  Future<void> _refreshPaymentIntent() async {
    try {
      final dio = GetIt.instance<DioClient>().dio;
      final response = await dio.post(
        ApiConstants.p2pOfferRefreshPayment(widget.offerId),
      );
      final freshSecret = response.data['clientSecret'] as String?;
      if (freshSecret == null || freshSecret.isEmpty) {
        throw Exception('No client secret returned');
      }
      _clientSecret = freshSecret;
      P2pPaymentTracker.updatePendingClientSecret(widget.shipmentId, freshSecret);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Payment was reset. Please tap Pay to try again.';
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Payment setup failed. Please contact support.';
      });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('cancel') || raw.contains('Canceled')) {
      return 'Payment cancelled. Tap below to try again.';
    }
    if (raw.contains('declined') || raw.contains('insufficient_funds')) {
      return 'Your card was declined. Please try a different payment method.';
    }
    // In debug builds, surface the raw Stripe error so it can be diagnosed.
    if (kDebugMode) return 'Payment failed: $raw';
    return 'Payment failed. Please try again.';
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment required'),
        content: const Text(
          'You must complete payment before continuing. '
          'If you go back now, your booking will remain on hold '
          'and you will need to return to complete payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Platform fee is 2.5% of the offer amount; the courier receives the rest.
    const feeRate = 0.025;
    final fee = widget.amountUsd * feeRate;
    final courierReceives = widget.amountUsd - fee;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final allow = await _onWillPop();
          if (allow && context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: const Text('Confirm Payment'),
          leading: BackButton(onPressed: () async {
            final allow = await _onWillPop();
            if (allow && context.mounted) context.pop();
          }),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Escrow assurance header ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure payment held in escrow',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Funds are only released to the courier after you confirm delivery.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Order summary ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Order Summary',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.courierName != null) ...[
                      _SummaryRow(
                          label: 'Courier',
                          value: widget.courierName!,
                          bold: false),
                      const SizedBox(height: 10),
                    ],
                    _SummaryRow(
                      label: 'Courier fee',
                      value: '\$${courierReceives.toStringAsFixed(2)}',
                      bold: false,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Platform fee (2.5%)',
                      value: '\$${fee.toStringAsFixed(2)}',
                      bold: false,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _SummaryRow(
                      label: 'Total charged now',
                      value: '\$${widget.amountUsd.toStringAsFixed(2)} USD',
                      bold: true,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Released to courier only after you confirm delivery.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Error message ─────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 18, color: AppTheme.errorColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Pay button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (_processing || _done) ? null : _pay,
                  icon: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : _done
                          ? const Icon(Icons.check_circle_outline)
                          : const Icon(Icons.payment_outlined),
                  label: Text(
                    _processing
                        ? 'Processing…'
                        : _done
                            ? 'Payment confirmed!'
                            : 'Pay \$${widget.amountUsd.toStringAsFixed(2)} & Continue',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _done ? Colors.green[600] : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _done
                        ? Colors.green[600]
                        : AppTheme.primaryColor.withAlpha(80),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Powered by Stripe · Your payment is encrypted and secure',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: bold
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? AppTheme.primaryColor : theme.colorScheme.onSurface,
            fontSize: bold ? 15 : null,
          ),
        ),
      ],
    );
  }
}
