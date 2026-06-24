import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/data/services/p2p_payment_tracker.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class P2pMyShipmentsScreen extends StatelessWidget {
  const P2pMyShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<P2pShipmentBloc>()
        ..add(const P2pShipmentListRequested()),
      child: const _MyShipmentsView(),
    );
  }
}

class _MyShipmentsView extends StatelessWidget {
  const _MyShipmentsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('My Shipment Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context
                .read<P2pShipmentBloc>()
                .add(const P2pShipmentListRequested()),
          ),
        ],
      ),
      body: BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
        builder: (context, state) {
          switch (state.status) {
            case P2pShipmentStatus.initial:
            case P2pShipmentStatus.loading:
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            case P2pShipmentStatus.failure:
              return _ErrorPanel(
                message: state.errorMessage ?? 'Failed to load shipments',
                onRetry: () => context
                    .read<P2pShipmentBloc>()
                    .add(const P2pShipmentListRequested()),
              );
            case P2pShipmentStatus.success:
              if (state.requests.isEmpty) {
                return _EmptyPanel(
                  onSend: () => context.push('/p2p/shipment/create'),
                );
              }
              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async => context
                    .read<P2pShipmentBloc>()
                    .add(const P2pShipmentListRequested()),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _ShipmentCard(
                    shipment: state.requests[i],
                    courierRequestCount:
                        state.courierRequestCounts[state.requests[i].id] ?? 0,
                  ),
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/p2p/shipment/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final P2pShipmentRequest shipment;
  final int courierRequestCount;
  const _ShipmentCard({
    required this.shipment,
    required this.courierRequestCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    final (statusColor, statusLabel) = _statusStyle(shipment.status);

    return GestureDetector(
      onTap: () => _navigateForStatus(context, shipment),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.itemDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${shipment.destinationCity}, ${shipment.destinationCountry}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (shipment.status == ShipmentRequestStatus.open &&
                    courierRequestCount > 0) ...[
                  const SizedBox(width: 8),
                  _CountBadge(count: courierRequestCount),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.scale_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 4),
                Text(
                  '${shipment.weightKg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55)),
                ),
                const SizedBox(width: 14),
                Icon(Icons.attach_money,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45)),
                Text(
                  '\$${shipment.declaredValueUsd.toStringAsFixed(0)} declared',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55)),
                ),
                const Spacer(),
                if (shipment.createdAt != null)
                  Text(
                    dateFmt.format(shipment.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11),
                  ),
              ],
            ),
            // Hint when there's an action needed
            if (shipment.status == ShipmentRequestStatus.open) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to see courier responses',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600], fontSize: 11),
                  ),
                ],
              ),
            ],
            if (shipment.status == ShipmentRequestStatus.matched) ...[
              const SizedBox(height: 8),
              Builder(builder: (ctx) {
                final paymentPending =
                    P2pPaymentTracker.hasPaymentPending(shipment.id);
                return Row(
                  children: [
                    Icon(
                      paymentPending
                          ? Icons.payment_outlined
                          : Icons.description_outlined,
                      size: 13,
                      color: paymentPending
                          ? AppTheme.errorColor
                          : Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentPending
                          ? 'Payment required — tap to complete'
                          : 'Matched! Tap to sign the waiver',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: paymentPending
                            ? AppTheme.errorColor
                            : Colors.green[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ],
            if (shipment.status == ShipmentRequestStatus.reserved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 13, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Reserved! Tap to get handoff code',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateForStatus(BuildContext context, P2pShipmentRequest s) {
    switch (s.status) {
      case ShipmentRequestStatus.open:
      case ShipmentRequestStatus.draft:
        context.push('/p2p/shipment/${s.id}/offers');
        break;
      case ShipmentRequestStatus.matched:
        // Route based on payment state:
        //  - completed → waiver (payment already captured)
        //  - pending with secret → payment screen
        //  - pending without secret (app data cleared) → shipment detail;
        //    the backend will block reserve until payment is captured
        //  - no record (free offer) → waiver
        final pendingAmount = P2pPaymentTracker.getPendingAmount(s.id);
        final pendingSecret = P2pPaymentTracker.getPendingClientSecret(s.id);
        final pendingOfferId = P2pPaymentTracker.getPendingOfferId(s.id);
        if (P2pPaymentTracker.hasCompletedPayment(s.id)) {
          context.push('/p2p/shipment/${s.id}/waiver');
        } else if (pendingAmount != null && pendingAmount > 0 && pendingSecret != null) {
          context.push(
            '/p2p/shipment/${s.id}/payment',
            extra: {
              'offerId': pendingOfferId ?? '',
              'clientSecret': pendingSecret,
              'amountUsd': pendingAmount,
            },
          );
        } else if (pendingAmount != null && pendingAmount > 0) {
          // Secret lost (cleared storage) — show detail; backend guards reserve.
          context.push('/p2p/shipment/${s.id}');
        } else {
          context.push('/p2p/shipment/${s.id}/waiver');
        }
        break;
      case ShipmentRequestStatus.reserved:
      case ShipmentRequestStatus.handoffPending:
        context.push('/p2p/shipment/${s.id}/handoff');
        break;
      case ShipmentRequestStatus.inTransit:
      case ShipmentRequestStatus.delivered:
      case ShipmentRequestStatus.completed:
      case ShipmentRequestStatus.disputed:
        context.push('/p2p/shipment/${s.id}/tracking');
        break;
      default:
        context.push('/p2p/shipment/${s.id}');
    }
  }

  (Color, String) _statusStyle(ShipmentRequestStatus status) {
    switch (status) {
      case ShipmentRequestStatus.draft:
        return (Colors.grey[600]!, 'Draft');
      case ShipmentRequestStatus.open:
        return (Colors.blue[600]!, 'Open');
      case ShipmentRequestStatus.matched:
        return (Colors.green[600]!, 'Matched');
      case ShipmentRequestStatus.reserved:
        return (Colors.green[700]!, 'Reserved');
      case ShipmentRequestStatus.handoffPending:
        return (Colors.orange[700]!, 'Handoff Pending');
      case ShipmentRequestStatus.inTransit:
        return (AppTheme.primaryColor, 'In Transit');
      case ShipmentRequestStatus.delivered:
        return (Colors.teal[600]!, 'Delivered');
      case ShipmentRequestStatus.completed:
        return (Colors.teal[700]!, 'Completed');
      case ShipmentRequestStatus.cancelled:
        return (Colors.red[600]!, 'Cancelled');
      case ShipmentRequestStatus.disputed:
        return (Colors.red[700]!, 'Disputed');
      case ShipmentRequestStatus.rejected:
        return (Colors.red[800]!, 'Rejected');
    }
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.orange[800],
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final VoidCallback onSend;
  const _EmptyPanel({required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No shipment requests yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Send your first package and track everything here.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.add),
              label: const Text('Send a Package'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

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
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
