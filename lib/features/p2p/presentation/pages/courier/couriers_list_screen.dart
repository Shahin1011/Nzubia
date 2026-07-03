import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/marketplace/marketplace_bloc.dart';

enum _SortOption { departure, rating, capacity }

class CouriersListScreen extends StatelessWidget {
  const CouriersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final destinationCity = query['destinationCity'];
    final destinationCountry = query['destinationCountry'];
    final shipmentId = query['shipmentId'];

    return BlocProvider(
      create: (_) => GetIt.instance<MarketplaceBloc>()
        ..add(MarketplaceRouteFeedRequested(
          destinationCity: destinationCity,
          destinationCountry: destinationCountry,
        )),
      child: _CouriersListView(shipmentId: shipmentId),
    );
  }
}

class _CouriersListView extends StatefulWidget {
  final String? shipmentId;
  const _CouriersListView({this.shipmentId});

  @override
  State<_CouriersListView> createState() => _CouriersListViewState();
}

class _CouriersListViewState extends State<_CouriersListView> {
  _SortOption _sortBy = _SortOption.departure;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<P2pRoute> _filterAndSort(List<P2pRoute> routes) {
    var filtered = routes.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.destinationCity.toLowerCase().contains(q) ||
          r.destinationCountry.toLowerCase().contains(q) ||
          r.pickupOrigin.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case _SortOption.departure:
        filtered.sort((a, b) => a.departureDate.compareTo(b.departureDate));
      case _SortOption.rating:
        filtered.sort((a, b) {
          final ar = a.courierProfile?.rating ?? 0;
          final br = b.courierProfile?.rating ?? 0;
          return br.compareTo(ar);
        });
      case _SortOption.capacity:
        filtered.sort((a, b) => b.capacityKg.compareTo(a.capacityKg));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasShipment = widget.shipmentId != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Find a Courier'),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_outlined),
            tooltip: 'Sort by',
            onSelected: (s) => setState(() => _sortBy = s),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SortOption.departure,
                child: _menuRow(
                  active: _sortBy == _SortOption.departure,
                  text: 'Earliest departure',
                ),
              ),
              PopupMenuItem(
                value: _SortOption.rating,
                child: _menuRow(
                  active: _sortBy == _SortOption.rating,
                  text: 'Highest rated',
                ),
              ),
              PopupMenuItem(
                value: _SortOption.capacity,
                child: _menuRow(
                  active: _sortBy == _SortOption.capacity,
                  text: 'Most capacity',
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by destination…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.outline.withValues(alpha: 0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
        builder: (context, state) {
          switch (state.status) {
            case MarketplaceStatus.initial:
            case MarketplaceStatus.loading:
              return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryColor),
              );

            case MarketplaceStatus.failure:
              return _ErrorState(
                message: state.errorMessage ?? 'Failed to load couriers',
                onRetry: () => context
                    .read<MarketplaceBloc>()
                    .add(const MarketplaceRefreshed()),
              );

            case MarketplaceStatus.success:
              final filtered = _filterAndSort(state.routes);
              if (filtered.isEmpty) {
                return _EmptyState(query: _searchQuery);
              }
              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async => context
                    .read<MarketplaceBloc>()
                    .add(const MarketplaceRefreshed()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasShipment)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap "Request" on a courier to send them a direct booking request.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '${filtered.length} courier${filtered.length == 1 ? '' : 's'} found',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _CourierListCard(
                          route: filtered[i],
                          shipmentId: widget.shipmentId,
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
      floatingActionButton: hasShipment
          ? null
          : FloatingActionButton.extended(
              heroTag: 'couriers-list-fab',
              onPressed: () => context.push('/p2p/shipment/create'),
              label: const Text('Post a Request'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _menuRow({required bool active, required String text}) {
    return Row(
      children: [
        if (active)
          const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

// ─── Courier list card ────────────────────────────────────────────────────────

class _CourierListCard extends StatelessWidget {
  final P2pRoute route;
  final String? shipmentId;

  const _CourierListCard({required this.route, this.shipmentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM');
    final now = DateTime.now();
    final daysUntil = route.departureDate.difference(now).inDays;
    final courier = route.courierProfile;
    final displayName = courier?.displayName ?? 'Courier';
    final hasShipment = shipmentId != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Courier info row (tappable → profile) ──
          InkWell(
            onTap: () => context.push('/p2p/couriers/${route.courierProfileId}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, hasShipment ? 8 : 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryColor.withAlpha(25),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (courier != null)
                              _RatingBadge(rating: courier.rating),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${route.pickupOrigin} → ${route.destinationCity}, ${route.destinationCountry}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Tag(
                              icon: Icons.calendar_today_outlined,
                              label: dateFmt.format(route.departureDate),
                              color: daysUntil <= 3
                                  ? Colors.orange[600]!
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 8),
                            _Tag(
                              icon: Icons.scale_outlined,
                              label:
                                  '${route.capacityKg.toStringAsFixed(0)} kg',
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                ],
              ),
            ),
          ),

          // ── Request CTA (only when browsing for a specific shipment) ──
          if (hasShipment) ...[
            Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestSheet(context),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendRequestSheet(
        shipmentId: shipmentId!,
        routeId: route.id,
        courierName: route.courierProfile?.displayName ?? 'this courier',
      ),
    );
  }
}

// ─── Send-request bottom sheet ────────────────────────────────────────────────

class _SendRequestSheet extends StatefulWidget {
  final String shipmentId;
  final String routeId;
  final String courierName;

  const _SendRequestSheet({
    required this.shipmentId,
    required this.routeId,
    required this.courierName,
  });

  @override
  State<_SendRequestSheet> createState() => _SendRequestSheetState();
}

class _SendRequestSheetState extends State<_SendRequestSheet> {
  final _messageCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = GetIt.instance<P2pShipmentRepository>();
      await repo.sendCourierRequest(
        widget.shipmentId,
        widget.routeId,
        message: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Request sent to ${widget.courierName}! You\'ll be notified when they respond.'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Request ${widget.courierName}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'They\'ll get notified and can accept or decline your request.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),

          // Optional message
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Message to courier (optional)',
              hintText: 'e.g. I need this delivered by next Friday…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: theme.colorScheme.outline.withValues(alpha: 0.06),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Request',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontSize: 11),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No couriers found for "$query"'
                  : 'No couriers available yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Post a shipment request — couriers will reach out to you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/p2p/shipment/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Post a Request'),
            ),
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
            Icon(Icons.cloud_off_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load couriers',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
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
