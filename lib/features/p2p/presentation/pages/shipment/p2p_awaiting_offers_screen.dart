import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_offer.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class P2pAwaitingOffersScreen extends StatelessWidget {
  final String shipmentId;
  final String? destinationCity;
  final String? destinationCountry;

  const P2pAwaitingOffersScreen({
    super.key,
    required this.shipmentId,
    this.destinationCity,
    this.destinationCountry,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<P2pShipmentBloc>()
        ..add(P2pShipmentDetailRequested(shipmentId)),
      child: _AwaitingOffersView(
        shipmentId: shipmentId,
        destinationCity: destinationCity,
        destinationCountry: destinationCountry,
      ),
    );
  }
}

class _AwaitingOffersView extends StatefulWidget {
  final String shipmentId;
  final String? destinationCity;
  final String? destinationCountry;

  const _AwaitingOffersView({
    required this.shipmentId,
    this.destinationCity,
    this.destinationCountry,
  });

  @override
  State<_AwaitingOffersView> createState() => _AwaitingOffersViewState();
}

class _AwaitingOffersViewState extends State<_AwaitingOffersView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _shipmentSub;
  StreamSubscription<Map<String, dynamic>>? _offerSub;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final socket = GetIt.instance<SocketClient>();
    _shipmentSub = socket.shipmentUpdates.listen((_) => _reload());
    _offerSub = socket.newOfferUpdates.listen((_) => _reload());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shipmentSub?.cancel();
    _offerSub?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    context
        .read<P2pShipmentBloc>()
        .add(P2pShipmentDetailRequested(widget.shipmentId));
  }

  void _acceptOffer(P2pOffer offer) {
    setState(() => _accepting = true);
    context.read<P2pShipmentBloc>().add(
          P2pOfferAccepted(offer.id, shipmentId: widget.shipmentId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destParts = [widget.destinationCity, widget.destinationCountry]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return BlocListener<P2pShipmentBloc, P2pShipmentState>(
      listener: (context, state) {
        if (_accepting && state.status == P2pShipmentStatus.success) {
          setState(() => _accepting = false);
          final clientSecret = state.pendingPaymentClientSecret;
          final amount = state.pendingPaymentAmountUsd;
          if (clientSecret != null && amount != null && amount > 0) {
            context.push(
              '/p2p/shipment/${widget.shipmentId}/payment',
              extra: {
                'offerId': state.pendingPaymentOfferId ?? '',
                'clientSecret': clientSecret,
                'amountUsd': amount,
              },
            );
          } else {
            context.push('/p2p/shipment/${widget.shipmentId}/waiver');
          }
        }
        if (_accepting && state.status == P2pShipmentStatus.failure) {
          setState(() => _accepting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to accept offer'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: const Text('Offers'),
          leading: const BackButton(),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _reload,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Confirmation banner ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(14),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryColor.withAlpha(38),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your request is live',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          destParts.isNotEmpty
                              ? "We've notified matched couriers heading to $destParts. Offers will appear below."
                              : "We've notified matched couriers. Offers will appear below.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.65),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Offer list / empty state ─────────────────────────────────
            Expanded(
              child: BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
                builder: (context, state) {
                  if (state.status == P2pShipmentStatus.loading &&
                      state.offers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    );
                  }

                  if (state.status == P2pShipmentStatus.failure &&
                      state.offers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage ?? 'Failed to load offers',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reload,
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

                  final pending = state.offers
                      .where((o) => o.status == OfferStatus.proposed)
                      .toList();

                  return RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: () async => _reload(),
                    child: pending.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: _EmptyOffersState(
                                    pulseAnimation: _pulseAnimation),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: pending.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _OfferCard(
                              offer: pending[i],
                              accepting: _accepting,
                              onAccept: () => _acceptOffer(pending[i]),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyOffersState extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const _EmptyOffersState({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 38,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Waiting for couriers to submit offers...',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Matched couriers have been notified by email. Pull down to refresh, or check back soon.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offer card ────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final P2pOffer offer;
  final bool accepting;
  final VoidCallback onAccept;

  const _OfferCard({
    required this.offer,
    required this.accepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = offer.route;
    final profile = route?.courierProfile;
    final displayName = profile?.displayName ?? 'Courier';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';
    final rating = profile?.rating ?? 0.0;
    final courierId = profile?.id;

    final departureFmt = route != null
        ? DateFormat('dd MMM yyyy').format(route.departureDate)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.45)),
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
          // ── Header row: avatar + name + amount ──────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryColor.withAlpha(22),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 13,
                            color: Colors.amber[600],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          rating >= 0.1
                              ? rating.toStringAsFixed(1)
                              : 'New',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer.offerAmountUsd != null
                        ? '\$${offer.offerAmountUsd!.toStringAsFixed(2)}'
                        : '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'USD',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Route details row ────────────────────────────────────────
          if (route != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.flight_takeoff_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route.pickupOrigin,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (departureFmt != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    departureFmt,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // ── Action buttons ───────────────────────────────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              if (courierId != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/p2p/couriers/$courierId'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.primaryColor.withAlpha(110)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: accepting ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: accepting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Accept Offer',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
