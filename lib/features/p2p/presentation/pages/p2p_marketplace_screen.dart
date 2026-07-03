import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/marketplace/marketplace_bloc.dart';

class P2pMarketplaceScreen extends StatelessWidget {
  const P2pMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<MarketplaceBloc>()
        ..add(const MarketplaceRouteFeedRequested()),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  String? _selectedDestination;

  static const _destinations = [
    'All', 'United Kingdom', 'United States', 'France', 'Germany',
    'Canada', 'Australia', 'Netherlands', 'UAE',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('P2P Marketplace'),
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => context.push('/p2p/my-shipments'),
                tooltip: 'My shipment requests',
              ),
              BlocBuilder<MarketplaceBloc, MarketplaceState>(
                buildWhen: (prev, curr) => prev.isCourier != curr.isCourier,
                builder: (context, state) {
                  if (state.isCourier == true) {
                    return IconButton(
                      icon: const Icon(Icons.dashboard_outlined),
                      onPressed: () =>
                          context.push('/p2p/courier/dashboard'),
                      tooltip: 'Courier Dashboard',
                    );
                  }
                  return IconButton(
                    icon: const Icon(Icons.flight_takeoff_outlined),
                    onPressed: () => context.push('/p2p/courier/apply'),
                    tooltip: 'Become a courier',
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _DestinationFilterBar(
                destinations: _destinations,
                selected: _selectedDestination,
                onSelected: (dest) {
                  setState(() {
                    _selectedDestination = dest == 'All' ? null : dest;
                  });
                  context.read<MarketplaceBloc>().add(
                        MarketplaceRouteFeedRequested(
                          destinationCountry:
                              dest == 'All' ? null : dest,
                        ),
                      );
                },
              ),
            ),
          ),
        ],
        body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            switch (state.status) {
              case MarketplaceStatus.initial:
              case MarketplaceStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );

              case MarketplaceStatus.failure:
                return _ErrorState(
                  message: state.errorMessage ?? 'Failed to load routes',
                  onRetry: () => context.read<MarketplaceBloc>().add(
                        const MarketplaceRefreshed(),
                      ),
                );

              case MarketplaceStatus.success:
                if (state.routes.isEmpty) {
                  return Column(
                    children: [
                      if (state.isCourier == true) _CourierDashboardBanner(),
                      Expanded(
                        child: _EmptyState(
                          destination: _selectedDestination,
                          onClearFilter: () {
                            setState(() => _selectedDestination = null);
                            context
                                .read<MarketplaceBloc>()
                                .add(const MarketplaceRouteFeedRequested());
                          },
                        ),
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async {
                    context
                        .read<MarketplaceBloc>()
                        .add(const MarketplaceRefreshed());
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.isCourier == true)
                        _CourierDashboardBanner(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          '${state.routes.length} routes available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: state.routes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _RouteCard(route: state.routes[i]),
                        ),
                      ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'marketplace-send-fab',
        onPressed: () => context.push('/p2p/shipment/create'),
        label: const Text('Send Package'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Courier dashboard banner ─────────────────────────────────────────────────

class _CourierDashboardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/p2p/courier/dashboard'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.dashboard_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re a courier',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'View your dashboard, routes & requests',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Destination filter bar ───────────────────────────────────────────────────

class _DestinationFilterBar extends StatelessWidget {
  final List<String> destinations;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _DestinationFilterBar({
    required this.destinations,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      color: theme.colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final dest = destinations[i];
          final isActive =
              dest == 'All' ? selected == null : selected == dest;
          return FilterChip(
            label: Text(dest),
            selected: isActive,
            onSelected: (_) => onSelected(dest),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : theme.colorScheme.onSurface,
              fontSize: 13,
            ),
            checkmarkColor: Colors.white,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.12),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

// ─── Route card ───────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final P2pRoute route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d');
    final now = DateTime.now();
    final daysUntil = route.departureDate.difference(now).inDays;
    final daysText =
        daysUntil <= 0 ? 'Today' : 'in $daysUntil day${daysUntil == 1 ? '' : 's'}';

    return GestureDetector(
      onTap: () => context.push('/p2p/couriers/${route.courierProfileId}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route header: pickup → destination
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            route.pickupOrigin,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${route.destinationCity}, ${route.destinationCountry}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.flight_land,
                            size: 16, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Metadata row
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: '${dateFmt.format(route.departureDate)} • $daysText',
                    color: daysUntil <= 3
                        ? Colors.orange[700]!
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.scale_outlined,
                    label: '${route.capacityKg.toStringAsFixed(1)} kg cap',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const Spacer(),
                  if (route.courierProfile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '★ ${route.courierProfile!.rating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (route.acceptedItemCategories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: route.acceptedItemCategories
                      .take(4)
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              // Trust / CTA row
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Verified courier',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View profile →',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? destination;
  final VoidCallback onClearFilter;

  const _EmptyState({this.destination, required this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_outlined, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              destination != null
                  ? 'No routes to $destination'
                  : 'No routes available yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first — become a courier and post your route.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (destination != null)
              OutlinedButton(
                onPressed: onClearFilter,
                child: const Text('Clear filter'),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/p2p/courier/apply'),
              icon: const Icon(Icons.flight_takeoff_outlined),
              label: const Text('Become a Courier'),
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
            Icon(Icons.cloud_off_outlined, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load routes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
