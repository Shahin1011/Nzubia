import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_offer.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class P2pShipmentDetailScreen extends StatelessWidget {
  final String shipmentId;

  const P2pShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<P2pShipmentBloc>()
        ..add(P2pShipmentDetailRequested(shipmentId)),
      child: _ShipmentDetailView(shipmentId: shipmentId),
    );
  }
}

class _ShipmentDetailView extends StatelessWidget {
  final String shipmentId;

  const _ShipmentDetailView({required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
      builder: (context, state) {
        switch (state.status) {
          case P2pShipmentStatus.initial:
          case P2pShipmentStatus.loading:
            return const Scaffold(
              body: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          case P2pShipmentStatus.failure:
            return Scaffold(
              appBar: AppBar(title: const Text('Shipment Detail')),
              body: _ErrorState(
                message: state.errorMessage ?? 'Failed to load shipment',
                onRetry: () => context
                    .read<P2pShipmentBloc>()
                    .add(P2pShipmentDetailRequested(shipmentId)),
              ),
            );
          case P2pShipmentStatus.success:
            final shipment = state.selectedRequest;
            if (shipment == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Shipment Detail')),
                body: const Center(child: Text('Shipment not found')),
              );
            }
            return _ShipmentBody(shipment: shipment);
        }
      },
    );
  }
}

class _ShipmentBody extends StatelessWidget {
  final P2pShipmentRequest shipment;

  const _ShipmentBody({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    final stepIndex = _statusToStep(shipment.status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Shipment #${shipment.id.length > 8 ? shipment.id.substring(0, 8) : shipment.id}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push(
              '/chat/${shipment.chatThreadId ?? shipment.id}',
              extra: 'Courier Chat',
            ),
            tooltip: 'Chat with courier',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status timeline ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: EasyStepper(
                activeStep: stepIndex,
                lineStyle: LineStyle(
                  lineType: LineType.normal,
                  lineLength: 40,
                  lineThickness: 2,
                  activeLineColor: AppTheme.primaryColor,
                  finishedLineColor: AppTheme.primaryColor,
                  defaultLineColor: theme.colorScheme.outline,
                ),
                stepRadius: 24,
                showLoadingAnimation: false,
                steps: const [
                  EasyStep(
                    icon: Icon(Icons.radio_button_checked_outlined, size: 16),
                    title: 'Open',
                    activeIcon: Icon(Icons.hourglass_empty, size: 16),
                    finishIcon: Icon(Icons.check, size: 16),
                  ),
                  EasyStep(
                    icon: Icon(Icons.handshake_outlined, size: 16),
                    title: 'Matched',
                    activeIcon: Icon(Icons.handshake_outlined, size: 16),
                    finishIcon: Icon(Icons.check, size: 16),
                  ),
                  EasyStep(
                    icon: Icon(Icons.local_shipping_outlined, size: 16),
                    title: 'In Transit',
                    activeIcon: Icon(Icons.local_shipping_outlined, size: 16),
                    finishIcon: Icon(Icons.check, size: 16),
                  ),
                  EasyStep(
                    icon: Icon(Icons.inventory_2_outlined, size: 16),
                    title: 'Delivered',
                    activeIcon: Icon(Icons.done_all, size: 16),
                    finishIcon: Icon(Icons.done_all, size: 16),
                  ),
                ],
                onStepReached: (_) {},
                activeStepBackgroundColor: AppTheme.primaryColor,
                activeStepBorderColor: AppTheme.primaryColor,
                finishedStepBackgroundColor: AppTheme.primaryColor,
                finishedStepBorderColor: AppTheme.primaryColor,
                unreachedStepBorderColor: theme.colorScheme.outline,
                unreachedStepBackgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.2),
                activeStepIconColor: Colors.white,
                finishedStepIconColor: Colors.white,
                unreachedStepIconColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),

            const SizedBox(height: 16),

            // ── Package summary ─────────────────────────────────────
            _SectionCard(
              title: 'Package',
              icon: Icons.inventory_2_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      label: 'Description',
                      value: shipment.itemDescription),
                  _DetailRow(
                      label: 'Category',
                      value: shipment.itemCategory.label),
                  _DetailRow(
                      label: 'Weight',
                      value: '${shipment.weightKg.toStringAsFixed(1)} kg'),
                  _DetailRow(
                      label: 'Declared value',
                      value:
                          '\$${shipment.declaredValueUsd.toStringAsFixed(2)}'),
                  if (shipment.dimensionsCm.isNotEmpty)
                    _DetailRow(
                      label: 'Dimensions',
                      value:
                          '${shipment.dimensionsCm['length']?.toStringAsFixed(0) ?? '?'} × '
                          '${shipment.dimensionsCm['width']?.toStringAsFixed(0) ?? '?'} × '
                          '${shipment.dimensionsCm['height']?.toStringAsFixed(0) ?? '?'} cm',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Route ───────────────────────────────────────────────
            _SectionCard(
              title: 'Route',
              icon: Icons.alt_route_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: 'Pickup',
                    value: shipment.originAddress,
                  ),
                  _DetailRow(
                    label: 'Delivery',
                    value:
                        '${shipment.destinationCity}, ${shipment.destinationCountry}',
                  ),
                  if (shipment.createdAt != null)
                    _DetailRow(
                      label: 'Created',
                      value: dateFmt.format(shipment.createdAt!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Couriers You Contacted ──────────────────────────────
            BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
              builder: (ctx, st) {
                final crs = st.courierRequests;
                if (crs.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SectionCard(
                    title: 'Couriers You Contacted',
                    icon: Icons.people_alt_outlined,
                    child: Column(
                      children: crs
                          .map((cr) => _CourierRequestStatusTile(
                                courierRequest: cr,
                                offers: st.offers,
                                shipmentId: shipment.id,
                                canConfirm: shipment.status ==
                                        ShipmentRequestStatus.open ||
                                    shipment.status ==
                                        ShipmentRequestStatus.draft,
                              ))
                          .toList(),
                    ),
                  ),
                );
              },
            ),

            // ── Offers ──────────────────────────────────────────────
            BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
              builder: (ctx, st) {
                final offers = st.offers;
                if (offers.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SectionCard(
                    title: 'Offers',
                    icon: Icons.local_offer_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final offer in offers)
                          _OfferTile(
                            offer: offer,
                            canRespond:
                                shipment.status == ShipmentRequestStatus.open ||
                                    shipment.status ==
                                        ShipmentRequestStatus.draft,
                            onAccept: () =>
                                ctx.read<P2pShipmentBloc>().add(
                                      P2pOfferAccepted(
                                        offer.id,
                                        shipmentId: shipment.id,
                                      ),
                                    ),
                            onReject: () =>
                                ctx.read<P2pShipmentBloc>().add(
                                      P2pOfferRejected(
                                        offer.id,
                                        shipmentId: shipment.id,
                                      ),
                                    ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Milestones ──────────────────────────────────────────
            _SectionCard(
              title: 'Milestones',
              icon: Icons.timeline_outlined,
              child: _MilestoneList(status: shipment.status),
            ),

            const SizedBox(height: 12),

            // ── Waiver status ───────────────────────────────────────
            _WaiverBadge(shipmentId: shipment.id),

            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────
            if (shipment.status == ShipmentRequestStatus.matched ||
                shipment.status == ShipmentRequestStatus.reserved ||
                shipment.status == ShipmentRequestStatus.handoffPending ||
                shipment.status == ShipmentRequestStatus.inTransit) ...[
              _ActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chat with your courier',
                subtitle: 'Coordinate pickup and delivery details',
                color: Colors.green[700]!,
                onTap: () => context.push(
                  '/chat/${shipment.chatThreadId ?? shipment.id}',
                  extra: 'Courier Chat',
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (shipment.status == ShipmentRequestStatus.open ||
                shipment.status == ShipmentRequestStatus.draft)
              _ActionCard(
                icon: Icons.people_alt_outlined,
                title: 'Find a courier',
                subtitle:
                    'Browse couriers going to ${shipment.destinationCity}',
                color: AppTheme.primaryColor,
                onTap: () => context.push(
                  '/p2p/couriers?destinationCity=${Uri.encodeComponent(shipment.destinationCity)}&destinationCountry=${Uri.encodeComponent(shipment.destinationCountry)}&shipmentId=${shipment.id}',
                ),
              ),

            if (shipment.status == ShipmentRequestStatus.handoffPending) ...[
              const SizedBox(height: 8),
              _LifecycleButton(
                label: 'Mark as In Transit',
                icon: Icons.local_shipping_outlined,
                color: AppTheme.primaryColor,
                onPressed: () => context.read<P2pShipmentBloc>().add(
                      P2pShipmentStatusChanged(
                        requestId: shipment.id,
                        newStatus: ShipmentRequestStatus.inTransit,
                      ),
                    ),
              ),
            ],

            if (shipment.status == ShipmentRequestStatus.inTransit) ...[
              const SizedBox(height: 8),
              _LifecycleButton(
                label: 'Confirm Delivery',
                icon: Icons.done_all_outlined,
                color: Colors.green[600]!,
                onPressed: () => context.read<P2pShipmentBloc>().add(
                      P2pShipmentDeliveryConfirmed(shipment.id),
                    ),
              ),
            ],

            if (shipment.status == ShipmentRequestStatus.delivered) ...[
              const SizedBox(height: 8),
              _ActionCard(
                icon: Icons.star_outline,
                title: 'Leave a review',
                subtitle: 'Rate your courier and complete this shipment',
                color: Colors.amber[800]!,
                onTap: () {
                  context.read<P2pShipmentBloc>().add(
                        P2pShipmentStatusChanged(
                          requestId: shipment.id,
                          newStatus: ShipmentRequestStatus.completed,
                        ),
                      );
                },
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  int _statusToStep(ShipmentRequestStatus status) {
    switch (status) {
      case ShipmentRequestStatus.draft:
      case ShipmentRequestStatus.open:
      case ShipmentRequestStatus.cancelled:
      case ShipmentRequestStatus.rejected:
        return 0;
      case ShipmentRequestStatus.matched:
      case ShipmentRequestStatus.reserved:
      case ShipmentRequestStatus.handoffPending:
        return 1;
      case ShipmentRequestStatus.inTransit:
        return 2;
      case ShipmentRequestStatus.delivered:
      case ShipmentRequestStatus.completed:
      case ShipmentRequestStatus.disputed:
        return 3;
    }
  }
}

class _LifecycleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _LifecycleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
      builder: (ctx, st) {
        final loading = st.status == P2pShipmentStatus.loading;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Milestones ───────────────────────────────────────────────────────────────

class _MilestoneList extends StatelessWidget {
  final ShipmentRequestStatus status;

  const _MilestoneList({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    bool atOrAfter(ShipmentRequestStatus minimum) {
      final order = [
        ShipmentRequestStatus.draft,
        ShipmentRequestStatus.open,
        ShipmentRequestStatus.matched,
        ShipmentRequestStatus.reserved,
        ShipmentRequestStatus.handoffPending,
        ShipmentRequestStatus.inTransit,
        ShipmentRequestStatus.delivered,
        ShipmentRequestStatus.completed,
      ];
      final cur = order.indexOf(status);
      final min = order.indexOf(minimum);
      return cur != -1 && min != -1 && cur >= min;
    }

    final milestones = [
      ('Request submitted', true, Icons.check_circle_outline),
      (
        'Courier matched',
        atOrAfter(ShipmentRequestStatus.matched),
        Icons.handshake_outlined,
      ),
      (
        'Item handed to courier',
        atOrAfter(ShipmentRequestStatus.handoffPending),
        Icons.flight_takeoff_outlined,
      ),
      (
        'In transit',
        atOrAfter(ShipmentRequestStatus.inTransit),
        Icons.local_shipping_outlined,
      ),
      (
        'Item delivered',
        atOrAfter(ShipmentRequestStatus.delivered),
        Icons.done_all_outlined,
      ),
    ];

    return Column(
      children: milestones.map((m) {
        final (label, done, icon) = m;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 18,
                color: done
                    ? AppTheme.primaryColor
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: done
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight:
                      done ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Waiver badge ─────────────────────────────────────────────────────────────

class _WaiverBadge extends StatelessWidget {
  final String shipmentId;

  const _WaiverBadge({required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Colors.amber[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Review the liability waiver before handoff',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber[900],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.push('/p2p/compliance?shipmentId=$shipmentId'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Could not load shipment',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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

// ─── Courier request status tile (seeker's view) ──────────────────────────────

class _CourierRequestStatusTile extends StatelessWidget {
  final P2pCourierRequest courierRequest;
  final List<P2pOffer> offers;
  final String shipmentId;
  final bool canConfirm;

  const _CourierRequestStatusTile({
    required this.courierRequest,
    required this.offers,
    required this.shipmentId,
    required this.canConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cr = courierRequest;
    final route = cr.route;
    final courierName = route?.courierProfile?.displayName ??
        '${cr.routeId.substring(0, 8)}…';
    final routeLabel = route != null
        ? '${route.pickupOrigin} → ${route.destinationCity}'
        : null;

    final (statusColor, statusIcon, statusLabel) = _statusStyle(cr.status);

    // Find the offer that was created when this courier accepted.
    final matchedOffer = cr.status == CourierRequestStatus.accepted
        ? offers.where((o) => o.routeId == cr.routeId).firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outlined,
                  size: 16, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  courierName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (routeLabel != null) ...[
            const SizedBox(height: 3),
            Text(
              routeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
          if (cr.status == CourierRequestStatus.declined &&
              cr.declineReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${cr.declineReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red[700], fontStyle: FontStyle.italic),
            ),
          ],
          // When courier accepted, show their offer so seeker can confirm
          if (cr.status == CourierRequestStatus.accepted &&
              matchedOffer != null &&
              canConfirm &&
              matchedOffer.status == OfferStatus.proposed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Courier accepted! Confirm to match.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (matchedOffer.offerAmountUsd != null)
                        Text(
                          '\$${matchedOffer.offerAmountUsd!.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.read<P2pShipmentBloc>().add(
                                    P2pOfferRejected(
                                      matchedOffer.id,
                                      shipmentId: shipmentId,
                                    ),
                                  ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[300]!),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              context.read<P2pShipmentBloc>().add(
                                    P2pOfferAccepted(
                                      matchedOffer.id,
                                      shipmentId: shipmentId,
                                    ),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Confirm Match'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _statusStyle(CourierRequestStatus status) {
    switch (status) {
      case CourierRequestStatus.pending:
        return (Colors.orange[700]!, Icons.hourglass_empty, 'Pending');
      case CourierRequestStatus.accepted:
        return (Colors.green[700]!, Icons.check_circle_outline, 'Accepted');
      case CourierRequestStatus.declined:
        return (Colors.red[600]!, Icons.cancel_outlined, 'Declined');
      case CourierRequestStatus.cancelled:
        return (Colors.grey[600]!, Icons.remove_circle_outline, 'Cancelled');
      case CourierRequestStatus.expired:
        return (Colors.grey[500]!, Icons.timer_off_outlined, 'Expired');
    }
  }
}

class _OfferTile extends StatelessWidget {
  final P2pOffer offer;
  final bool canRespond;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferTile({
    required this.offer,
    required this.canRespond,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final route = offer.route;
    final courier = route?.courierProfile;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  courier?.displayName ?? 'Courier offer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (offer.offerAmountUsd != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${offer.offerAmountUsd!.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (route != null) ...[
            const SizedBox(height: 4),
            Text(
              '${route.pickupOrigin} → ${route.destinationCity}, ${route.destinationCountry}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Status: ${offer.status.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(offer.status),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canRespond && offer.status == OfferStatus.proposed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.proposed:
        return Colors.orange[700]!;
      case OfferStatus.accepted:
        return Colors.green[700]!;
      case OfferStatus.rejected:
      case OfferStatus.cancelled:
        return Colors.red[700]!;
      case OfferStatus.expired:
        return Colors.grey[600]!;
    }
  }
}
