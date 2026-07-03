import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/widgets/animated_scale_button.dart';
import 'package:customer_nzubia_global/core/widgets/update_status_button.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/pages/agent_finance_screen.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/pages/chat_list_screen.dart';
import 'package:customer_nzubia_global/features/profile/presentation/pages/profile_screen.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';

class AgentDashboardScreen extends StatelessWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DashboardBloc>()..add(LoadDashboardStats())),
        BlocProvider(
          create: (context) => ShipmentListBloc(
            shipmentRepository: sl(),
            socketClient: sl<SocketClient>(),
          )..add(const LoadShipments()),
        ),
      ],
      child: const _AgentDashboardView(),
    );
  }
}

class _AgentDashboardView extends StatefulWidget {
  const _AgentDashboardView();

  @override
  State<_AgentDashboardView> createState() => _AgentDashboardViewState();
}

class _AgentDashboardViewState extends State<_AgentDashboardView> {
  int _selectedIndex = 0;

  String _getDisplayName(UserEntity? user) {
    if (user == null) return AppLocalizations.of(context)!.hello;
    if (user.fullName.isNotEmpty) return user.fullName;
    final emailName = user.email.split('@').first;
    if (emailName.isNotEmpty) return emailName;
    return AppLocalizations.of(context)!.hello;
  }

  String _getInitials(UserEntity? user) {
    if (user == null) return '?';
    final name = _getDisplayName(user);
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  void _refreshAll(BuildContext context) {
    context.read<AuthBloc>().add(UserRefreshRequested());
    context.read<ShipmentListBloc>().add(const LoadShipments());
    context.read<DashboardBloc>().add(LoadDashboardStats());
  }

  Widget _buildKycBanner(BuildContext context, UserEntity? user) {
    final status = user?.kycStatus ?? 'NOT_SUBMITTED';
    final notes = user?.kycNotes;

    Color bannerColor;
    String title;
    String subtitle;
    IconData icon;
    bool tappable = false;

    if (status == 'REJECTED') {
      bannerColor = Colors.red;
      title = 'Application Rejected';
      subtitle =
          'Your agent application has been rejected. You do not have access to the platform services at this time.';
      icon = Icons.block_rounded;
    } else if (status == 'INFO_REQUESTED') {
      bannerColor = Colors.blue;
      title = 'More Info Required';
      subtitle = notes ?? 'Admin needs more details from you. Tap to update.';
      icon = Icons.info_outline_rounded;
      tappable = true;
    } else {
      bannerColor = AppTheme.primaryColor;
      title = 'Complete Onboarding';
      subtitle = 'Finish your profile to start quoting on shipments and earning.';
      icon = Icons.assignment_late_outlined;
      tappable = true;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: tappable ? () => context.push('/agent-onboarding') : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: bannerColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: bannerColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: bannerColor.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (tappable) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, color: bannerColor, size: 13),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final primaryColor = theme.colorScheme.primary;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildHeader(context, user),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      _buildTabBar(context, primaryColor, subtitleColor),
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _ShipmentList(
                    filter: (s) => ['REQUESTED', 'PENDING_AGENTS', 'BIDDING_ACTIVE', 'QUOTED']
                        .contains(s.status),
                    emptyLabel: 'No open requests',
                    emptyIcon: Icons.inbox_outlined,
                  ),
                  _ShipmentList(
                    filter: (s) => [
                      'QUOTATION_ACCEPTED',
                      'PAYMENT_PENDING',
                      'BOOKED',
                      'PICKED_UP',
                      'RECEIVED_AT_WAREHOUSE',
                      'LEAVING_ORIGIN_COUNTRY',
                      'IN_TRANSIT',
                      'IN_CUSTOMS',
                      'CUSTOMS_CLEARED',
                      'REACHED_DESTINATION_COUNTRY',
                      'ARRIVED_AT_DESTINATION',
                      'OUT_FOR_DELIVERY',
                      'READY_FOR_PICKUP',
                      'DELAYED',
                    ].contains(s.status),
                    emptyLabel: 'No active shipments',
                    emptyIcon: Icons.local_shipping_outlined,
                  ),
                  _ShipmentList(
                    filter: (s) => ['DELIVERED', 'CANCELLED'].contains(s.status),
                    emptyLabel: 'No completed shipments',
                    emptyIcon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          ChatListScreen(),
          const AgentFinanceScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, user, theme, primaryColor, subtitleColor),
    );
  }

  TabBar _buildTabBar(BuildContext context, Color primaryColor, Color subtitleColor) {
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
      tabs: [
        Tab(text: AppLocalizations.of(context)!.requested),
        Tab(text: AppLocalizations.of(context)!.active),
        Tab(text: AppLocalizations.of(context)!.delivered),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    UserEntity? user,
    ThemeData theme,
    Color primaryColor,
    Color subtitleColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: subtitleColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard_rounded),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: const Icon(Icons.chat_bubble_rounded),
            label: AppLocalizations.of(context)!.chat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: AppLocalizations.of(context)!.finance,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
        onTap: (index) {
          if (user?.kycStatus != 'VERIFIED' && (index == 1 || index == 2)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.verificationRequiredForThisFeature),
              ),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity? user) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final textColor = theme.colorScheme.onSurface;
        final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
        final primaryColor = theme.colorScheme.primary;
        final isLoading = state.status == DashboardStatus.loading;

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: avatar + greeting + refresh
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
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
                          _getInitials(user),
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
                            AppLocalizations.of(context)!.helloWithName(_getDisplayName(user)),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.agentPortal,
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
                        onTap: () => _refreshAll(context),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.refresh_rounded, color: subtitleColor, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // KYC banner
              if (user?.kycStatus != 'VERIFIED') _buildKycBanner(context, user),

              // Earnings card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.totalEarnings,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLoading ? '—' : state.totalEarnings,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _EarningsStat(
                            icon: Icons.inbox_rounded,
                            value: isLoading ? '…' : '${state.pendingQuotesCount}',
                            label: AppLocalizations.of(context)!.requested,
                          ),
                          const SizedBox(width: 24),
                          _EarningsStat(
                            icon: Icons.local_shipping_rounded,
                            value: isLoading ? '…' : '${state.activeShipmentsCount}',
                            label: AppLocalizations.of(context)!.active,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _EarningsStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 5),
        Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ShipmentList extends StatelessWidget {
  final bool Function(ShipmentEntity) filter;
  final String emptyLabel;
  final IconData emptyIcon;

  const _ShipmentList({
    required this.filter,
    required this.emptyLabel,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShipmentListBloc>().add(const LoadShipments());
        context.read<DashboardBloc>().add(LoadDashboardStats());
      },
      child: BlocBuilder<ShipmentListBloc, ShipmentListState>(
        builder: (context, state) {
          if (state.status == ShipmentListStatus.loading && state.shipments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ShipmentListStatus.failure) {
            return OfflineErrorWidget(
              errorMessage: state.errorMessage ?? 'An error occurred',
              onRetry: () {
                context.read<ShipmentListBloc>().add(const LoadShipments());
                context.read<DashboardBloc>().add(LoadDashboardStats());
              },
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
                    emptyLabel,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AgentShipmentCard(shipment: filtered[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _AgentShipmentCard extends StatelessWidget {
  final ShipmentEntity shipment;

  const _AgentShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final primaryColor = theme.colorScheme.primary;

    final statusColor = _statusColor(shipment.status, colors);
    final statusLabel = _localizedStatus(context, shipment.status);
    final statusIcon = _statusIcon(shipment.status);
    final cargoCount = shipment.cargoItems.length;

    return Hero(
      tag: 'agent-shipment-${shipment.id}',
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
              // Header row: status + service level
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                    // Service level
                    Text(
                      shipment.serviceLevel.replaceAll('_', ' '),
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (cargoCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$cargoCount item${cargoCount > 1 ? 's' : ''}',
                          style: TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Route
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    // Origin dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 5, spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shipment.originAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
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
                        color: colors?.neonPurple ?? theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (colors?.neonPurple ?? theme.colorScheme.secondary).withValues(alpha: 0.4),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shipment.destinationAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Tracking number (if available)
              if (shipment.trackingNumber != null && shipment.trackingNumber!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded, size: 13, color: subtitleColor),
                      const SizedBox(width: 5),
                      Text(
                        shipment.trackingNumber!,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Status update button (only for in-progress shipments)
              if (!['DELIVERED', 'CANCELLED', 'REQUESTED', 'PENDING_AGENTS', 'BIDDING_ACTIVE', 'QUOTED']
                  .contains(shipment.status.toUpperCase())) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.15), height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: UpdateStatusButton(
                    shipment: shipment,
                    onRefresh: () => context.read<ShipmentListBloc>().add(const LoadShipments()),
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

  Color _statusColor(String status, AppColorsExtension? colors) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return colors?.success ?? Colors.green;
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return colors?.neonCyan ?? Colors.blue;
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
}

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
    return Container(
      color: _color,
      padding: const EdgeInsets.only(bottom: 0),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
