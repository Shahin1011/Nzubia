import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_dispute_sheet.dart';

class P2pTrackingScreen extends StatefulWidget {
  final String shipmentId;

  const P2pTrackingScreen({super.key, required this.shipmentId});

  @override
  State<P2pTrackingScreen> createState() => _P2pTrackingScreenState();
}

class _P2pTrackingScreenState extends State<P2pTrackingScreen> {
  late final P2pShipmentBloc _bloc;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  @override
  void initState() {
    super.initState();
    _bloc = P2pShipmentBloc(
      repository: GetIt.instance<P2pShipmentRepository>(),
    );
    _bloc.add(P2pShipmentDetailRequested(widget.shipmentId));
    _startPolling();
    final socket = GetIt.instance<SocketClient>();
    _socketSub = socket.p2pStatusUpdates.listen((_) {
      _bloc.add(P2pShipmentDetailRequested(widget.shipmentId));
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _bloc.add(P2pShipmentDetailRequested(widget.shipmentId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _socketSub?.cancel();
    _bloc.close();
    super.dispose();
  }

  void _confirmReceipt(BuildContext context) {
    _bloc.add(P2pShipmentDeliveryConfirmed(widget.shipmentId));
  }

  void _openDispute(BuildContext context, P2pShipmentRequest shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => P2pDisputeSheet(shipmentId: shipment.id),
    );
  }

  void _leaveReview(BuildContext context, P2pShipmentRequest shipment) {
    context.push('/p2p/shipment/${shipment.id}/review');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<P2pShipmentBloc, P2pShipmentState>(
        listener: (context, state) {
          if (state.status == P2pShipmentStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          if (state.selectedRequest?.status ==
              ShipmentRequestStatus.completed) {
            _stopPolling();
          }
        },
        builder: (context, state) {
          final shipment = state.selectedRequest;
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              title: const Text('Track Shipment'),
              leading: const BackButton(),
              actions: [
                if (shipment != null &&
                    (shipment.status == ShipmentRequestStatus.inTransit ||
                        shipment.status == ShipmentRequestStatus.delivered ||
                        shipment.status == ShipmentRequestStatus.completed))
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Open Chat',
                    onPressed: () {
                      final chatId =
                          shipment.chatThreadId ?? widget.shipmentId;
                      context.push('/chat/$chatId', extra: 'Courier Chat');
                    },
                  ),
              ],
            ),
            body: shipment == null &&
                    state.status == P2pShipmentStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : shipment == null
                    ? _ErrorView(
                        onRetry: () => _bloc.add(
                            P2pShipmentDetailRequested(widget.shipmentId)))
                    : _TrackingBody(
                        shipment: shipment,
                        isLoading: state.status == P2pShipmentStatus.loading,
                        onConfirmReceipt: () =>
                            _confirmReceipt(context),
                        onOpenDispute: () =>
                            _openDispute(context, shipment),
                        onLeaveReview: () =>
                            _leaveReview(context, shipment),
                      ),
          );
        },
      ),
    );
  }
}

// ── Step data ──────────────────────────────────────────────────────────────────

class _Step {
  final ShipmentRequestStatus status;
  final String label;
  final String description;
  final IconData icon;

  const _Step({
    required this.status,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _steps = [
  _Step(
    status: ShipmentRequestStatus.open,
    label: 'Shipment Posted',
    description: 'Your shipment is live and visible to couriers.',
    icon: Icons.check_circle_outline,
  ),
  _Step(
    status: ShipmentRequestStatus.reserved,
    label: 'Courier Matched',
    description: 'A courier has accepted your shipment.',
    icon: Icons.person_outline,
  ),
  _Step(
    status: ShipmentRequestStatus.handoffPending,
    label: 'Awaiting Handoff',
    description: 'Waiting for you to hand over the package.',
    icon: Icons.handshake_outlined,
  ),
  _Step(
    status: ShipmentRequestStatus.inTransit,
    label: 'In Transit',
    description: 'Your package is on its way.',
    icon: Icons.local_shipping_outlined,
  ),
  _Step(
    status: ShipmentRequestStatus.delivered,
    label: 'Delivered',
    description: 'The courier reports delivery. Please confirm.',
    icon: Icons.inventory_2_outlined,
  ),
  _Step(
    status: ShipmentRequestStatus.completed,
    label: 'Completed',
    description: 'Shipment successfully completed.',
    icon: Icons.task_alt,
  ),
];

int _currentStepIndex(ShipmentRequestStatus status) {
  final idx = _steps.indexWhere((s) => s.status == status);
  return idx < 0 ? 0 : idx;
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _TrackingBody extends StatelessWidget {
  final P2pShipmentRequest shipment;
  final bool isLoading;
  final VoidCallback onConfirmReceipt;
  final VoidCallback onOpenDispute;
  final VoidCallback onLeaveReview;

  const _TrackingBody({
    required this.shipment,
    required this.isLoading,
    required this.onConfirmReceipt,
    required this.onOpenDispute,
    required this.onLeaveReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIdx = _currentStepIndex(shipment.status);
    final isDelivered = shipment.status == ShipmentRequestStatus.delivered;
    final isCompleted = shipment.status == ShipmentRequestStatus.completed;
    final isDisputed = shipment.status == ShipmentRequestStatus.disputed;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipment Summary',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                    label: 'Destination',
                    value:
                        '${shipment.destinationCity}, ${shipment.destinationCountry}'),
                _SummaryRow(
                    label: 'Item', value: shipment.itemDescription),
                _SummaryRow(
                    label: 'Weight',
                    value: '${shipment.weightKg} kg'),
                _SummaryRow(
                    label: 'Declared Value',
                    value:
                        '\$${shipment.declaredValueUsd.toStringAsFixed(2)}'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Shipment Progress',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // ── Stepper ─────────────────────────────────────────────────────────
          if (!isDisputed)
            ...List.generate(_steps.length, (i) {
              final step = _steps[i];
              final isDone = i < activeIdx;
              final isActive = i == activeIdx;
              final isLast = i == _steps.length - 1;

              return _StepRow(
                step: step,
                isDone: isDone,
                isActive: isActive,
                isLast: isLast,
              );
            })
          else
            _DisputeStepRow(),

          const SizedBox(height: 32),

          // ── Actions ──────────────────────────────────────────────────────────
          if (isDelivered) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirmReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Confirm Receipt',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onOpenDispute,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Raise a Dispute',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

          if (isCompleted) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onLeaveReview,
                icon: const Icon(Icons.star_outline, size: 20),
                label: const Text(
                  'Leave a Review',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = isDone
        ? Colors.green
        : isActive
            ? AppTheme.primaryColor
            : theme.colorScheme.outline;
    final Color lineColor = isDone
        ? Colors.green
        : theme.colorScheme.outline.withValues(alpha: 0.35);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column ─────────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? Colors.green.withAlpha(20)
                        : isActive
                            ? AppTheme.primaryColor.withAlpha(18)
                            : theme.colorScheme.outline.withAlpha(15),
                    border: Border.all(color: iconColor, width: 1.5),
                  ),
                  child: Icon(
                    isDone ? Icons.check : step.icon,
                    size: 16,
                    color: iconColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Label ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDone || isActive
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeStepRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_outlined,
              color: AppTheme.errorColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Opened',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Our team has been notified and will review your case.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Could not load shipment',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
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
}
