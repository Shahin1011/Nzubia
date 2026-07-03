import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_state.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Injecting Bloc directly here using Service Locator
    return BlocProvider(
      create: (context) => ShipmentListBloc(
        shipmentRepository: sl(),
        socketClient: sl<SocketClient>(),
      )..add(const LoadShipments()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NZUBIA'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AuthBloc>().add(UserRefreshRequested());
              context.read<ShipmentListBloc>().add(const LoadShipments());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing shipments...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<ShipmentListBloc, ShipmentListState>(
        builder: (context, state) {
          if (state.status == ShipmentListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ShipmentListStatus.failure) {
             return OfflineErrorWidget(
                errorMessage: state.errorMessage ?? 'An error occurred',
                onRetry: () {
                  context.read<ShipmentListBloc>().add(const LoadShipments());
                },
             );
          }

          if (state.shipments.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ShipmentListBloc>().add(const LoadShipments());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.shipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final shipment = state.shipments[index];
                return _ShipmentCard(shipment: shipment);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-shipment');
          if (context.mounted) {
            context.read<ShipmentListBloc>().add(const LoadShipments());
          }
        },
        label: const Text('Ship Now'),
        icon: const Icon(Icons.local_shipping),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No shipments yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text('Create your first shipment to get started!'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await context.push('/create-shipment');
              if (context.mounted) {
                context.read<ShipmentListBloc>().add(const LoadShipments());
              }
            },
            child: const Text('Create Shipment'),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentEntity shipment;

  const _ShipmentCard({required this.shipment});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED': return Colors.green;
      case 'IN_TRANSIT': return Colors.blue;
      case 'BOOKED': return Colors.orange;
      case 'REQUESTED': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/shipment-details', extra: shipment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(shipment.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(shipment.status).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      shipment.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(shipment.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    shipment.serviceLevel.replaceAll('_', ' '),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(shipment.originAddress, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 5),
                height: 16,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey, width: 1)),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(shipment.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text('${shipment.cargoItems.length} items'),
                    if (shipment.estimatedPrice != null)
                      Text('\$${shipment.estimatedPrice!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
