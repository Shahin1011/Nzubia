import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_offer_sheet.dart';

class CourierMatchedShipmentsScreen extends StatefulWidget {
  const CourierMatchedShipmentsScreen({super.key});

  @override
  State<CourierMatchedShipmentsScreen> createState() =>
      _CourierMatchedShipmentsScreenState();
}

class _CourierMatchedShipmentsScreenState
    extends State<CourierMatchedShipmentsScreen> {
  final _repo = GetIt.instance<P2pShipmentRepository>();
  List<P2pShipmentRequest> _items = [];
  final Set<String> _submittedOfferShipmentIds = {};
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      if (_items.isEmpty) _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchNearbyShipments();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
        title: const Text('Available Shipments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No available shipments',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Check back later for new shipping opportunities',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _ShipmentCard(
          shipment: _items[index],
          hasSubmittedOffer:
              _submittedOfferShipmentIds.contains(_items[index].id),
          onOfferSent: () {
            setState(() {
              _submittedOfferShipmentIds.add(_items[index].id);
            });
            _load();
          },
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final P2pShipmentRequest shipment;
  final VoidCallback onOfferSent;
  final bool hasSubmittedOffer;

  const _ShipmentCard({
    required this.shipment,
    required this.onOfferSent,
    required this.hasSubmittedOffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName =
        (shipment.seeker?.fullName ?? 'Seeker').split(' ').first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryBadge(shipment.itemCategory.label),
                const Spacer(),
                Text(
                  '\$${shipment.declaredValueUsd.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${shipment.destinationCity}, ${shipment.destinationCountry}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.scale_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${shipment.weightKg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 4),
                Text(firstName, style: theme.textTheme.bodySmall),
              ],
            ),
            if (shipment.itemDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shipment.itemDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasSubmittedOffer ? theme.colorScheme.outline : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: hasSubmittedOffer
                    ? null
                    : () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CourierOfferSheet(
                      shipment: shipment,
                      onSubmitted: onOfferSent,
                    ),
                  );
                  },
                child: Text(hasSubmittedOffer ? 'Offer Submitted' : 'Submit Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
