import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_state.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/agent/quote_submission_screen.dart'; // Created next
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

class AgentOpportunitiesScreen extends StatelessWidget {
  const AgentOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ShipmentListBloc>()
        ..add(const LoadShipments(statusFilter: 'PENDING_AGENTS,BIDDING_ACTIVE')),
      child: Scaffold(
        appBar: AppBar(title: const Text('Available Opportunities')),
        body: BlocBuilder<ShipmentListBloc, ShipmentListState>(
          builder: (context, state) {
            if (state.status == ShipmentListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == ShipmentListStatus.failure) {
              return OfflineErrorWidget(
                errorMessage: state.errorMessage ?? 'An error occurred',
                onRetry: () {
                  context.read<ShipmentListBloc>().add(const LoadShipments(statusFilter: 'PENDING_AGENTS,BIDDING_ACTIVE'));
                },
              );
            } else if (state.shipments.isEmpty) {
              return const Center(child: Text('No shipments available for bidding.'));
            }

            return ListView.builder(
              itemCount: state.shipments.length,
              itemBuilder: (context, index) {
                final shipment = state.shipments[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('${shipment.originCity} -> ${shipment.destinationCountry}'),
                    subtitle: Text('Cargo: ${shipment.cargoDescription} \nReady: ${shipment.pickupDate}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuoteSubmissionScreen(shipment: shipment),
                          ),
                        ).then((_) {
                           // Refresh on return
                           context.read<ShipmentListBloc>().add(const LoadShipments(statusFilter: 'PENDING_AGENTS,BIDDING_ACTIVE'));
                        });
                      },
                      child: const Text('Quote'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
