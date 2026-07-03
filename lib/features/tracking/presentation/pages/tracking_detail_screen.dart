import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_bloc.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_event.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/bloc/tracking_detail/tracking_detail_state.dart';
import 'package:customer_nzubia_global/features/tracking/domain/entities/tracking_entity.dart';

class TrackingDetailScreen extends StatelessWidget {
  final String shipmentId;

  const TrackingDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackingDetailBloc(trackingRepository: sl())
        ..add(LoadTrackingDetails(shipmentId)),
      child: const TrackingDetailView(),
    );
  }
}

class TrackingDetailView extends StatelessWidget {
  const TrackingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Shipment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<TrackingDetailBloc, TrackingDetailState>(
        listener: (context, state) {
           if (state.status == TrackingDetailStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error loading tracking details')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TrackingDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.trackingEntity == null && state.status == TrackingDetailStatus.success) {
             return const Center(child: Text('No tracking details found.'));
          }

          if (state.trackingEntity != null) {
            return _TrackingContent(tracking: state.trackingEntity!);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  final TrackingEntity tracking;

  const _TrackingContent({required this.tracking});

  @override
  Widget build(BuildContext context) {
    // Sort events by timestamp descending for vertical list usually, 
    // but EasyStepper usually goes top-down. 
    // Let's assume index 0 is start, last is current/end.
    // Actually, for a history log, newest first is common, but for a progress stepper, 
    // oldest first (start -> end) makes sense.
    // The mock data is oldest to newest.

    // Calculate active step
    int activeStep = tracking.events.where((e) => e.isCompleted).length - 1;
    if (activeStep < 0) activeStep = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(tracking: tracking),
          const SizedBox(height: 32),
          Text(
            'Shipment Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Using a custom vertical list with connectors instead of EasyStepper horizontal 
          // or forcing EasyStepper vertical which can be finicky.
          // Let's build a custom vertical timeline for better control and "Wow" factor.
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracking.events.length,
            itemBuilder: (context, index) {
              final event = tracking.events[tracking.events.length - 1 - index]; // Reverse for UI (Newest top)
              final isFirst = index == 0;
              final isLast = index == tracking.events.length - 1;
              
              return _TimelineItem(
                event: event, 
                isFirst: isFirst, 
                isLast: isLast
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TrackingEntity tracking;

  const _StatusCard({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('Status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                     Text(
                       tracking.currentStatus,
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         color: AppTheme.primaryColor, 
                         fontWeight: FontWeight.bold
                       ),
                     ),
                   ],
                 ),
                 CircularProgressIndicator(
                   value: tracking.progress,
                   backgroundColor: Colors.grey[200],
                   color: AppTheme.primaryColor,
                   strokeWidth: 6,
                 ),
               ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Delivery'),
                Text(
                  DateFormat('MMM d, y').format(tracking.estimatedDelivery),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TrackingEventEntity event;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                 // Top line
                 Expanded(
                   child: Container(
                     width: 2,
                     color: isFirst ? Colors.transparent : Colors.grey[300],
                   ),
                 ),
                 // Dot
                 Container(
                   width: 16,
                   height: 16,
                   decoration: BoxDecoration(
                     color: event.isCompleted ? AppTheme.primaryColor : Colors.grey[300],
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white, width: 2),
                     boxShadow: [
                       if (event.isCompleted)
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                     ]
                   ),
                 ),
                 // Bottom line
                 Expanded(
                   child: Container(
                     width: 2,
                     color: isLast ? Colors.transparent : Colors.grey[300],
                   ),
                 ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: event.isCompleted ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        event.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                       Text(
                        DateFormat('MMM d, HH:mm').format(event.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
  }
}
