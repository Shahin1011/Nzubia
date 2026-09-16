import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/widgets/animated_scale_button.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_state.dart';
import 'package:customer_nzubia_global/features/home/presentation/widgets/tracking_search_bar.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/widgets/review_dialog.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ShipmentListBloc(
            shipmentRepository: sl(),
            socketClient: sl<SocketClient>(),
          )..add(const LoadShipments()),
        ),
        BlocProvider(
          create: (context) => P2pShipmentBloc(repository: sl())
            ..add(const P2pShipmentListRequested()),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }
        if (authState.user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authState.user!;
        final displayName = user.fullName.isNotEmpty ? user.fullName : (user.firstName?.isNotEmpty == true ? user.firstName! : '');
        final greetingText = displayName.isNotEmpty ? 'Welcome, $displayName! 👋' : 'Welcome! 👋';
        final initials = _initials(user.firstName, user.lastName);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildHeader(context, greetingText, initials),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      _buildTabBar(context),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _ShipmentList(
                    filter: (s) => s.customerId == user.id,
                    emptyTitle: 'No sent shipments',
                    emptySubtitle: 'Tap "Ship Now" to create your first shipment.',
                    emptyIcon: Icons.send_rounded,
                  ),
                  _ShipmentList(
                    filter: (s) =>
                        s.recipient?.email.toLowerCase() == user.email.toLowerCase(),
                    emptyTitle: 'No received shipments',
                    emptySubtitle: 'Packages addressed to you will appear here.',
                    emptyIcon: Icons.move_to_inbox_rounded,
                  ),
                ],
              ),
            ),
            floatingActionButton: AnimatedScaleButton(
              onPressed: () => _showShipmentTypeModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Ship Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String? firstName, String? lastName) {
    final a = firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    final b = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    if (a.isEmpty && b.isEmpty) return '?';
    return '$a$b';
  }

  TabBar _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return TabBar(
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      indicatorColor: Colors.transparent,
      labelColor: primaryColor,
      unselectedLabelColor: subtitleColor,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      tabs: const [Tab(text: 'Sent'), Tab(text: 'Received')],
    );
  }

  Widget _buildHeader(BuildContext context, String greetingText, String initials) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return BlocBuilder<ShipmentListBloc, ShipmentListState>(
      builder: (context, state) {
        return BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
          builder: (context, p2pState) {
            final p2pActiveCount = p2pState.requests
                .where((r) => const {
                      ShipmentRequestStatus.inTransit,
                      ShipmentRequestStatus.handoffPending,
                    }.contains(r.status))
                .length;
            final p2pDeliveredCount = p2pState.requests
                .where((r) => const {
                      ShipmentRequestStatus.delivered,
                      ShipmentRequestStatus.completed,
                    }.contains(r.status))
                .length;

            final activeCount = state.shipments
                    .where((s) =>
                        ['IN_TRANSIT', 'BOOKED', 'PENDING_AGENTS'].contains(s.status))
                    .length +
                p2pActiveCount;
            final deliveredCount =
                state.shipments.where((s) => s.status == 'DELIVERED').length +
                    p2pDeliveredCount;
            final isLoading =
                state.status == ShipmentListStatus.loading && state.shipments.isEmpty;

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: avatar + greeting + refresh
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.65)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Track and manage your shipments',
                            style: TextStyle(color: subtitleColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: state.status == ShipmentListStatus.loading
                            ? null
                            : () {
                                context
                                    .read<ShipmentListBloc>()
                                    .add(const LoadShipments());
                                context
                                    .read<P2pShipmentBloc>()
                                    .add(const P2pShipmentListRequested());
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: state.status == ShipmentListStatus.loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                )
                              : Icon(Icons.refresh_rounded,
                                  color: subtitleColor, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tracking search bar
                const TrackingSearchBar(),

                const SizedBox(height: 20),

                // Stat pills
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.local_shipping_rounded,
                      count: isLoading ? null : activeCount,
                      label: 'Active',
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      icon: Icons.check_circle_rounded,
                      count: isLoading ? null : deliveredCount,
                      label: 'Delivered',
                      color: theme.extension<AppColorsExtension>()?.success ??
                          Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick actions label
                Text(
                  'Quick Actions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // P2P action cards side-by-side
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.send_rounded,
                          color: Colors.teal,
                          title: 'Send via P2P',
                          subtitle: 'Ship with a traveler',
                          onTap: () => context.push('/p2p/my-shipments'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _CourierModeCard()),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  void _showShipmentTypeModal(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<ShipmentListBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How would you like to ship?',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the shipping method that works best for you.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            _ShipOptionTile(
              icon: Icons.send_rounded,
              color: Colors.teal,
              title: 'Send via P2P',
              subtitle: 'Ship with a traveler going your way',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/p2p/shipment/create');
              },
            ),
            const SizedBox(height: 12),
            _ShipOptionTile(
              icon: Icons.local_shipping_rounded,
              color: theme.colorScheme.primary,
              title: 'Logistics Agent',
              subtitle: 'Book a professional freight agent',
              onTap: () async {
                Navigator.of(context).pop();
                await context.push('/create-shipment');
                if (context.mounted) bloc.add(const LoadShipments());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact stat pill ─────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final int? count;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == null ? '—' : '$count',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action card (P2P Send) ──────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Courier mode card (stateful) ──────────────────────────────────────────────

class _CourierModeCard extends StatefulWidget {
  const _CourierModeCard();

  @override
  State<_CourierModeCard> createState() => _CourierModeCardState();
}

class _CourierModeCardState extends State<_CourierModeCard> {
  bool _checking = false;

  Future<void> _handleTap() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final profile = await GetIt.instance<P2pCourierRepository>().getMyProfile();
      if (!mounted) return;
      if (profile != null) {
        context.push('/p2p/courier/dashboard');
      } else {
        context.push('/p2p/courier/apply');
      }
    } catch (_) {
      if (mounted) context.push('/p2p/courier/apply');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppTheme.primaryColor;

    return InkWell(
      onTap: _checking ? null : _handleTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: color, size: 20),
                ),
                if (_checking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Courier Mode',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Carry packages & earn on your travels',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shipment list ─────────────────────────────────────────────────────────────

class _ShipmentList extends StatelessWidget {
  final bool Function(ShipmentEntity) filter;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _ShipmentList({
    required this.filter,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ShipmentListBloc>().add(const LoadShipments()),
      child: BlocBuilder<ShipmentListBloc, ShipmentListState>(
        builder: (context, state) {
          if (state.status == ShipmentListStatus.loading && state.shipments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ShipmentListStatus.failure) {
            return OfflineErrorWidget(
              errorMessage: state.errorMessage ?? 'An error occurred',
              onRetry: () =>
                  context.read<ShipmentListBloc>().add(const LoadShipments()),
            );
          }

          final filtered = state.shipments.where(filter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: subtitleColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(emptyIcon, size: 48, color: subtitleColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShipmentCard(shipment: filtered[index]),
            ),
          );
        },
      ),
    );
  }
}

// ── Tab bar delegate ──────────────────────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _color;

  _SliverTabBarDelegate(this._tabBar, {required Color color}) : _color = color;

  @override
  double get minExtent => _tabBar.preferredSize.height + 12;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 12;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _color, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// ── Shipment card ─────────────────────────────────────────────────────────────

class _ShipmentCard extends StatelessWidget {
  final ShipmentEntity shipment;

  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final primaryColor = theme.colorScheme.primary;

    final statusColor = _statusColor(shipment.status, colors, primaryColor);
    final statusLabel = _localizedStatus(context, shipment.status);
    final statusIcon = _statusIcon(shipment.status);

    return Hero(
      tag: 'shipment-${shipment.id}',
      child: AnimatedScaleButton(
        onPressed: () => context.push('/shipment-details', extra: shipment),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      shipment.serviceLevel.replaceAll('_', ' '),
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Route
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 5,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shipment.originAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SizedBox(
                  height: 16,
                  child: VerticalDivider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                    thickness: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                              blurRadius: 5,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shipment.destinationAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer: cargo count + price + tracking
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15), height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    // Cargo count
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${shipment.cargoItems.length} item${shipment.cargoItems.length != 1 ? 's' : ''}',
                        style: TextStyle(
                            color: subtitleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (shipment.trackingNumber != null &&
                        shipment.trackingNumber!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.qr_code_rounded, size: 12, color: subtitleColor),
                      const SizedBox(width: 3),
                      Text(
                        shipment.trackingNumber!,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (shipment.estimatedPrice != null)
                      Text(
                        '\$${shipment.estimatedPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colors?.success ?? Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              // Review / review-submitted
              if (_canLeaveReview(context)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(context),
                      icon: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                      label: Text(
                        AppLocalizations.of(context)!.rateReviewAgent,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ] else if (_hasAlreadyReviewed(context)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Review Submitted',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, AppColorsExtension? colors, Color primary) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return colors?.success ?? Colors.green;
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return primary;
      case 'BOOKED':
      case 'PAYMENT_PENDING':
        return colors?.warning ?? Colors.orange;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Colors.teal;
      case 'DELAYED':
      case 'CANCELLED':
        return Colors.red;
      case 'QUOTATION_ACCEPTED':
      case 'ACCEPTED':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return Icons.local_shipping_rounded;
      case 'BOOKED':
        return Icons.book_online_rounded;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Icons.inventory_2_rounded;
      case 'DELAYED':
        return Icons.warning_amber_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      case 'IN_CUSTOMS':
      case 'CUSTOMS_CLEARED':
        return Icons.account_balance_rounded;
      case 'PAYMENT_PENDING':
        return Icons.payment_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _localizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return l10n.statusRequested;
      case 'PENDING_AGENTS':
        return l10n.statusPendingAgents;
      case 'BIDDING_ACTIVE':
        return l10n.statusBiddingActive;
      case 'QUOTED':
        return l10n.statusQuoted;
      case 'QUOTATION_ACCEPTED':
        return 'Quotation Accepted';
      case 'PAYMENT_PENDING':
        return 'Payment Pending';
      case 'ACCEPTED':
        return l10n.statusAccepted;
      case 'BOOKED':
        return l10n.statusBooked;
      case 'READY_FOR_PICKUP':
        return l10n.readyForPickup;
      case 'PICKED_UP':
        return 'Picked Up';
      case 'RECEIVED_AT_WAREHOUSE':
        return 'At Warehouse';
      case 'LEAVING_ORIGIN_COUNTRY':
        return 'Leaving Origin';
      case 'IN_TRANSIT':
        return l10n.statusInTransit;
      case 'IN_CUSTOMS':
        return l10n.inCustoms;
      case 'CUSTOMS_CLEARED':
        return l10n.customsCleared;
      case 'REACHED_DESTINATION_COUNTRY':
        return 'At Destination Country';
      case 'ARRIVED_AT_DESTINATION':
        return l10n.arrivedAtDestination;
      case 'ARRIVED_AT_PORT':
        return l10n.statusArrivedAtPort;
      case 'OUT_FOR_DELIVERY':
        return l10n.statusOutForDelivery;
      case 'DELIVERED':
        return l10n.statusDelivered;
      case 'DELAYED':
        return l10n.delayed;
      case 'CANCELLED':
        return l10n.statusCancelled;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  bool _canLeaveReview(BuildContext context) {
    if (shipment.status.toUpperCase() != 'DELIVERED' || shipment.agentId == null) {
      return false;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState.user?.role == 'AGENT') return false;
    final userId = authState.user?.id;
    if (userId == null) return false;
    return !shipment.reviews.any((r) => r.authorId == userId);
  }

  bool _hasAlreadyReviewed(BuildContext context) {
    if (shipment.status.toUpperCase() != 'DELIVERED' || shipment.agentId == null) {
      return false;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState.user?.role == 'AGENT') return false;
    final userId = authState.user?.id;
    if (userId == null) return false;
    return shipment.reviews.any((r) => r.authorId == userId);
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ReviewDialog(
        onSubmit: (rating, comment) async {
          try {
            await sl<ShipmentRepository>().submitReview(
              shipment.id,
              rating.toInt(),
              comment,
            );
            return true;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Failed: $e')));
            }
            return false;
          }
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Review submitted! Thank you for your feedback.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      context.read<ShipmentListBloc>().add(const LoadShipments());
    }
  }
}

// ── Ship type option tile (bottom sheet) ──────────────────────────────────────

class _ShipOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShipOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
