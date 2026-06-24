import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/courier_dashboard/courier_dashboard_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_location_sheet.dart';

class CourierDashboardScreen extends StatelessWidget {
  const CourierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<CourierDashboardBloc>()
        ..add(const CourierDashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourierDashboardBloc, CourierDashboardState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final canPostRoutes =
            state.profile?.verificationState.canTakeWork ?? false;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            title: const Text('Courier Dashboard'),
            actions: [
              if (canPostRoutes)
                IconButton(
                  icon: const Icon(Icons.add_road_outlined),
                  onPressed: () async {
                    final result =
                        await context.push<bool>('/p2p/courier/post-route');
                    if (result == true && context.mounted) {
                      context
                          .read<CourierDashboardBloc>()
                          .add(const CourierDashboardLoadRequested());
                    }
                  },
                  tooltip: 'Post a new route',
                ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () => context
                    .read<CourierDashboardBloc>()
                    .add(const CourierDashboardLoadRequested()),
              ),
            ],
          ),
          body: switch (state.status) {
            CourierDashboardStatus.initial ||
            CourierDashboardStatus.loading =>
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            CourierDashboardStatus.failure => _ErrorPanel(
                message: state.errorMessage ?? 'Failed to load dashboard',
                onRetry: () => context
                    .read<CourierDashboardBloc>()
                    .add(const CourierDashboardLoadRequested()),
                onApply: state.errorMessage?.contains('profile') == true
                    ? () => context.push('/p2p/courier/apply')
                    : null,
              ),
            CourierDashboardStatus.success => () {
                final profile = state.profile!;
                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async => context
                      .read<CourierDashboardBloc>()
                      .add(const CourierDashboardLoadRequested()),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile header card
                      _ProfileCard(
                        profile: profile,
                        onToggle: (val) => context
                            .read<CourierDashboardBloc>()
                            .add(CourierDashboardAvailabilityToggled(
                                isActive: val)),
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Active routes',
                              value: state.myRoutes
                                  .where((r) =>
                                      r.status == RouteStatus.published)
                                  .length
                                  .toString(),
                              icon: Icons.alt_route_outlined,
                              color: Colors.green[600]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Rating',
                              value: profile.rating >= 0.1
                                  ? '${profile.rating.toStringAsFixed(1)}/5'
                                  : '—',
                              icon: Icons.star_outline,
                              color: Colors.amber[700]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Status',
                              value: profile.verificationState.label,
                              icon: Icons.verified_user_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active route card
                      _ActiveRouteCard(route: state.activeRoute),
                      const SizedBox(height: 16),

                      // Show route CTA only for ACTIVE couriers; otherwise
                      // show a verification status banner so non-active couriers
                      // understand why the option is unavailable (the backend
                      // rejects route creation for any state other than ACTIVE).
                      if (!canPostRoutes)
                        _VerificationStatusBanner(
                          verificationState: profile.verificationState,
                          onSubmitForReview: profile.verificationState ==
                                  CourierVerificationState.draft
                              ? () => context
                                  .read<CourierDashboardBloc>()
                                  .add(const CourierDashboardSubmitForReviewRequested())
                              : null,
                        )
                      else if (state.activeRoute == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await context
                                  .push<bool>('/p2p/courier/post-route');
                              if (result == true && context.mounted) {
                                context.read<CourierDashboardBloc>().add(
                                    const CourierDashboardLoadRequested());
                              }
                            },
                            icon: const Icon(Icons.add_road),
                            label: const Text('Post a New Route'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Quick-action buttons
                      if (canPostRoutes) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: const Text('Browse Shipments'),
                                onPressed: () => context
                                    .push('/p2p/courier/matched-shipments'),
                              ),
                            ),
                            /*
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                    Icons.mark_email_unread_outlined),
                                label: Text(
                                  state.pendingRequests.isNotEmpty
                                      ? 'Requests (${state.pendingRequests.length})'
                                      : 'Requests',
                                ),
                                onPressed: () =>
                                    context.push('/p2p/courier/requests'),
                              ),
                            ),
                            */
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // All routes list (so couriers can publish drafts)
                      if (state.myRoutes.isNotEmpty)
                        _MyRoutesSection(routes: state.myRoutes),

                      const SizedBox(height: 16),

                      // Incoming offer list
                      _IncomingRequestsSection(
                          requests: state.pendingRequests),

                      const SizedBox(height: 16),

                      // Active shipments assigned to this courier
                      _ActiveShipmentsSection(
                          shipments: state.activeShipments),
                    ],
                  ),
                );
              }(),
          },
        );
      },
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

void _showLocationSheet(BuildContext context, P2pCourierProfile profile) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CourierDashboardBloc>(),
      child: CourierLocationSheet(
        currentLatitude: profile.homeLatitude,
        currentLongitude: profile.homeLongitude,
      ),
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  final P2pCourierProfile profile;
  final ValueChanged<bool> onToggle;

  const _ProfileCard({required this.profile, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeColor, badgeText) = _verificationBadge(profile.verificationState);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor.withAlpha(30),
              child: Text(
                profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showLocationSheet(context, profile),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.homeLatitude != null
                              ? Icons.location_on
                              : Icons.add_location_outlined,
                          size: 13,
                          color: profile.homeLatitude != null
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.homeLatitude != null
                              ? 'Location set'
                              : 'Set home location',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: profile.homeLatitude != null
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onSurface.withOpacity(0.45),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: profile.homeLatitude != null
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  profile.isActive ? 'Available' : 'Offline',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: profile.isActive
                        ? Colors.green[700]
                        : theme.colorScheme.onSurface.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch.adaptive(
                  value: profile.isActive,
                  onChanged: profile.verificationState.isApproved
                      ? onToggle
                      : null,
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withAlpha(80),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _verificationBadge(CourierVerificationState state) {
    switch (state) {
      case CourierVerificationState.active:
        return (Colors.green[700]!, 'Active Courier');
      case CourierVerificationState.approved:
        return (Colors.green[600]!, 'Verified Courier');
      case CourierVerificationState.pendingReview:
        return (Colors.blue[600]!, 'Pending Review');
      case CourierVerificationState.submitted:
        return (Colors.blue[400]!, 'Application Submitted');
      case CourierVerificationState.draft:
        return (Colors.orange[600]!, 'Draft — Complete Application');
      case CourierVerificationState.rejected:
        return (Colors.red[600]!, 'Application Rejected');
      case CourierVerificationState.suspended:
        return (Colors.red[800]!, 'Suspended');
    }
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
                fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Active route card ────────────────────────────────────────────────────────

class _ActiveRouteCard extends StatelessWidget {
  final P2pRoute? route;

  const _ActiveRouteCard({this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Active Route',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (route != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (route == null)
              _EmptyRoute()
            else
              _RouteDetails(route: route!),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No active route yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55)),
        ),
        const SizedBox(height: 6),
        Text(
          'Post your travel route to start receiving shipment requests.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.45)),
        ),
      ],
    );
  }
}

class _RouteDetails extends StatelessWidget {
  final P2pRoute route;
  const _RouteDetails({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RoutePoint(
                label: 'From',
                city: route.pickupOrigin,
                country: '',
                icon: Icons.flight_takeoff,
              ),
            ),
            Icon(Icons.arrow_forward, size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.45)),
            Expanded(
              child: _RoutePoint(
                label: 'To',
                city: route.destinationCity,
                country: route.destinationCountry,
                icon: Icons.flight_land,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.45)),
            const SizedBox(width: 4),
            Text(
              dateFmt.format(route.departureDate),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
            const SizedBox(width: 16),
            Icon(Icons.scale_outlined, size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.45)),
            const SizedBox(width: 4),
            Text(
              '${route.capacityKg.toStringAsFixed(1)} kg capacity',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String city;
  final String country;
  final IconData icon;

  const _RoutePoint({
    required this.label,
    required this.city,
    required this.country,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          city,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          country,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.45)),
        ),
      ],
    );
  }
}

// ─── Incoming requests section ────────────────────────────────────────────────

class _IncomingRequestsSection extends StatelessWidget {
  final List<P2pCourierRequest> requests;

  const _IncomingRequestsSection({required this.requests});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Shipment Requests for You',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (requests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  requests.length.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined,
                    color: theme.colorScheme.outline, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No pending requests yet. Post an active route to attract senders.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45)),
                  ),
                ),
              ],
            ),
          )
        else
          ...requests.map((req) => _RequestTile(request: req)),
      ],
    );
  }
}

class _RequestTile extends StatefulWidget {
  final P2pCourierRequest request;

  const _RequestTile({required this.request});

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _expanded = false;
  final _declineReasonController = TextEditingController();

  @override
  void dispose() {
    _declineReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final req = widget.request;
    final senderLabel = req.seekerName ?? req.seekerEmail ?? 'Sender';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (req.message != null && req.message!.isNotEmpty)
                        Text(
                          req.message!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.55)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            // Expanded accept/decline actions
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Decline reason input
              TextField(
                controller: _declineReasonController,
                decoration: InputDecoration(
                  labelText: 'Decline reason (optional)',
                  hintText: 'e.g. Route is full',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                style: theme.textTheme.bodySmall,
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<CourierDashboardBloc>().add(
                              CourierDashboardRequestDeclined(
                                requestId: req.id,
                                reason: _declineReasonController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : _declineReasonController.text.trim(),
                              ),
                            );
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<CourierDashboardBloc>().add(
                              CourierDashboardRequestAccepted(
                                requestId: req.id,
                              ),
                            );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Verification status banner ──────────────────────────────────────────────

class _VerificationStatusBanner extends StatelessWidget {
  final CourierVerificationState verificationState;
  final VoidCallback? onSubmitForReview;

  const _VerificationStatusBanner({
    required this.verificationState,
    this.onSubmitForReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, title, body) = _content(verificationState);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                if (onSubmitForReview != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubmitForReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit for Review',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _content(
      CourierVerificationState state) {
    switch (state) {
      case CourierVerificationState.draft:
        return (
          Icons.edit_note_outlined,
          Colors.orange[700]!,
          'Application incomplete',
          'Complete your courier application to post routes.',
        );
      case CourierVerificationState.submitted:
        return (
          Icons.hourglass_top_outlined,
          Colors.blue[600]!,
          'Application submitted',
          'Your application is being processed. We\'ll notify you when reviewed.',
        );
      case CourierVerificationState.pendingReview:
        return (
          Icons.manage_search_outlined,
          Colors.blue[700]!,
          'Under review',
          'Our team is reviewing your application. This usually takes up to 24 hours.',
        );
      case CourierVerificationState.approved:
        return (
          Icons.toggle_on_outlined,
          Colors.green[600]!,
          'Verified — go active to post routes',
          'Your account is approved. Toggle your availability above to go Active, then you can post routes.',
        );
      case CourierVerificationState.suspended:
        return (
          Icons.block_outlined,
          Colors.red[700]!,
          'Account suspended',
          'Your courier account is suspended. Please contact support.',
        );
      case CourierVerificationState.rejected:
        return (
          Icons.cancel_outlined,
          Colors.red[700]!,
          'Application rejected',
          'Your application was not approved. Please contact support for more information.',
        );
      case CourierVerificationState.active:
        return (
          Icons.check_circle_outline,
          Colors.green[700]!,
          'Active',
          '',
        );
    }
  }
}

// ─── My routes section ────────────────────────────────────────────────────────

class _MyRoutesSection extends StatelessWidget {
  final List<P2pRoute> routes;
  const _MyRoutesSection({required this.routes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Routes',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...routes.map((route) => _RouteManageTile(route: route)),
      ],
    );
  }
}

class _RouteManageTile extends StatelessWidget {
  final P2pRoute route;
  const _RouteManageTile({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    final (statusColor, statusLabel) = _statusStyle(route.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${route.pickupOrigin} → ${route.destinationCity}, ${route.destinationCountry}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.45)),
              const SizedBox(width: 4),
              Text(
                dateFmt.format(route.departureDate),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55)),
              ),
              const SizedBox(width: 14),
              Icon(Icons.scale_outlined,
                  size: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.45)),
              const SizedBox(width: 4),
              Text(
                '${route.capacityKg.toStringAsFixed(1)} kg',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55)),
              ),
            ],
          ),
          if (route.status == RouteStatus.draft) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<CourierDashboardBloc>().add(
                      CourierDashboardRoutePublishRequested(
                          routeId: route.id),
                    ),
                icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                label: const Text('Publish Route',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          if (route.status == RouteStatus.published &&
              route.departureDate.isBefore(DateTime.now())) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Archive Route'),
                      content: const Text(
                        'The travel date for this route has passed. Archive it to remove it from the marketplace?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Archive'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<CourierDashboardBloc>().add(
                          CourierDashboardRouteArchiveRequested(
                              routeId: route.id),
                        );
                  }
                },
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: const Text('Archive Route',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, String) _statusStyle(RouteStatus status) {
    switch (status) {
      case RouteStatus.published:
        return (Colors.green[700]!, 'Published');
      case RouteStatus.draft:
        return (Colors.orange[700]!, 'Draft');
      case RouteStatus.paused:
        return (Colors.blue[600]!, 'Paused');
      case RouteStatus.expired:
        return (Colors.grey[600]!, 'Expired');
      case RouteStatus.removed:
        return (Colors.red[700]!, 'Removed');
    }
  }
}

// ─── Error panel ──────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onApply;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
            if (onApply != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onApply,
                child: const Text('Apply as Courier'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Active shipments section ─────────────────────────────────────────────────

class _ActiveShipmentsSection extends StatelessWidget {
  final List<P2pShipmentRequest> shipments;

  const _ActiveShipmentsSection({required this.shipments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Active Shipments',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (shipments.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shipments.length.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (shipments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: theme.colorScheme.outline, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No active deliveries. Accepted shipments will appear here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45)),
                  ),
                ),
              ],
            ),
          )
        else
          ...shipments.map((s) => _ActiveShipmentTile(shipment: s)),
      ],
    );
  }
}

class _ActiveShipmentTile extends StatelessWidget {
  final P2pShipmentRequest shipment;

  const _ActiveShipmentTile({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusColor, statusLabel) = _statusStyle(shipment.status);

    return GestureDetector(
      onTap: () {
        final s = shipment.status;
        if (s == ShipmentRequestStatus.handoffPending) {
          context.push(
              '/p2p/courier/shipment/${shipment.id}/pickup');
        } else {
          context.push(
              '/p2p/courier/shipment/${shipment.id}/in-transit');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_outlined,
                      color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '→ ${shipment.destinationCity}, ${shipment.destinationCountry}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        shipment.itemDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(22),
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.scale_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 4),
                Text(
                  '${shipment.weightKg} kg',
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
              ],
            ),
            if (shipment.status == ShipmentRequestStatus.handoffPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primaryColor.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meet sender to collect package',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shipment.originAddress,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, String) _statusStyle(ShipmentRequestStatus s) {
    switch (s) {
      case ShipmentRequestStatus.handoffPending:
        return (Colors.orange[700]!, 'Handoff Pending');
      case ShipmentRequestStatus.inTransit:
        return (AppTheme.primaryColor, 'In Transit');
      case ShipmentRequestStatus.delivered:
        return (Colors.green[700]!, 'Delivered');
      default:
        return (Colors.grey[600]!, s.label);
    }
  }
}
