import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_bloc.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_event.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_state.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class GuestTrackingScreen extends StatefulWidget {
  const GuestTrackingScreen({super.key});

  @override
  State<GuestTrackingScreen> createState() => _GuestTrackingScreenState();
}

class _GuestTrackingScreenState extends State<GuestTrackingScreen> {
  final _trackingIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _trackingIdController.dispose();
    super.dispose();
  }

  void _trackShipment() {
    if (_formKey.currentState!.validate()) {
      context.read<TrackingDetailBloc>().add(LoadTrackingDetails(_trackingIdController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TrackingDetailBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.trackShipment),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login'),
          ),
        ),
        body: BlocConsumer<TrackingDetailBloc, TrackingDetailState>(
          listener: (context, state) {
            if (state.status == TrackingDetailStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Tracking failed')),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.primaryColor),
                    const SizedBox(height: 24),
                    const Text(
                      'Track Your Package',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your shipment ID to see current status.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _trackingIdController,
                      decoration: const InputDecoration(
                        labelText: 'Shipment ID / Tracking Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tracking ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.status == TrackingDetailStatus.loading ? null : _trackShipment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: state.status == TrackingDetailStatus.loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Track Now', style: TextStyle(fontSize: 16)),
                    ),

                    if (state.status == TrackingDetailStatus.success && state.trackingEntity != null) ...[
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildResultCard(state.trackingEntity!),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(tracking) {
    // Determine status from tracking entity logic (might differ based on TrackingEntity structure)
    // Assuming TrackingEntity has status, origin, destination similar to Shipment
    final status = tracking.currentStatus ?? 'UNKNOWN';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('Status', style: TextStyle(color: Colors.grey[600])),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.blue.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(8)
                 ),
                 child: Text(
                   status.toUpperCase(),
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                 ),
               )
            ],
          ),
          const SizedBox(height: 12),
          // Add more details if available in TrackingEntity
          Text('Last Update: ${tracking.lastUpdateDescription ?? "N/A"}'),
        ],
      ),
    );
  }
}
