import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:dio/dio.dart';

import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class AgentStatusUpdateService {
  static void showUpdateStatusDialog({
    required BuildContext context,
    required ShipmentEntity shipment,
    required VoidCallback onRefresh,
  }) {
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.updateStatus),
        contentPadding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
              hintText: 'e.g. "Arrived at warehouse"',
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text(l10n.selectNewStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._getValidStatusOptions(context, dialogContext, shipment, descriptionController, onRefresh),
        ],
      ),
    );
  }

  static List<Widget> _getValidStatusOptions(
    BuildContext context, 
    BuildContext dialogContext, 
    ShipmentEntity shipment, 
    TextEditingController controller,
    VoidCallback onRefresh,
  ) {
    const List<Map<String, String>> statusFlow = [
       {'key': 'QUOTATION_ACCEPTED', 'label': 'Quotation Accepted'},
       {'key': 'PAYMENT_PENDING', 'label': 'Payment Pending'},
       {'key': 'BOOKED', 'label': 'Booked'},
       {'key': 'READY_FOR_PICKUP', 'label': 'Ready for Pickup'},
       {'key': 'PICKED_UP', 'label': 'Picked Up'},
       {'key': 'RECEIVED_AT_WAREHOUSE', 'label': 'Received at Warehouse'},
       {'key': 'LEAVING_ORIGIN_COUNTRY', 'label': 'Leaving Origin Country'},
       {'key': 'IN_TRANSIT', 'label': 'In Transit'},
       {'key': 'IN_CUSTOMS', 'label': 'In Customs'},
       {'key': 'CUSTOMS_CLEARED', 'label': 'Customs Cleared'},
       {'key': 'REACHED_DESTINATION_COUNTRY', 'label': 'Reached Destination Country'},
       {'key': 'ARRIVED_AT_DESTINATION', 'label': 'Arrived at Destination'},
       {'key': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery'},
       {'key': 'DELIVERED', 'label': 'Delivered'},
       {'key': 'DELAYED', 'label': 'Delayed'},
    ];

    final currentStatus = shipment.status;
    final int currentIndex = statusFlow.indexWhere((s) => s['key'] == currentStatus);
    final int startFromIndex = currentIndex == -1 ? 0 : currentIndex;

    List<Widget> options = [];
    for (int i = startFromIndex; i < statusFlow.length; i++) {
      final status = statusFlow[i];
      final isCurrent = status['key'] == currentStatus;
      
      final label = _getLocalizedStatus(context, status['key']!);
      
      options.add(_buildStatusOption(
        context, 
        dialogContext, 
        shipment,
        status['key']!, 
        isCurrent ? '$label (Current)' : label, 
        controller, 
        onRefresh,
        isDisabled: isCurrent && status['key'] != 'DELAYED',
      ));
    }
    return options;
  }

  static String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'REQUESTED': return l10n.statusRequested;
      case 'PENDING_AGENTS': return l10n.statusPendingAgents;
      case 'BIDDING_ACTIVE': return l10n.statusBiddingActive;
      case 'QUOTED': return l10n.statusQuoted;
      case 'QUOTATION_ACCEPTED': return 'Quotation Accepted';
      case 'PAYMENT_PENDING': return 'Payment Pending';
      case 'ACCEPTED': return l10n.statusAccepted;
      case 'BOOKED': return l10n.statusBooked;
      case 'READY_FOR_PICKUP': return l10n.readyForPickup;
      case 'PICKED_UP': return 'Picked Up';
      case 'RECEIVED_AT_WAREHOUSE': return 'Received at Warehouse';
      case 'LEAVING_ORIGIN_COUNTRY': return 'Leaving Origin Country';
      case 'IN_TRANSIT': return l10n.statusInTransit;
      case 'IN_CUSTOMS': return l10n.inCustoms;
      case 'CUSTOMS_CLEARED': return l10n.customsCleared;
      case 'REACHED_DESTINATION_COUNTRY': return 'Reached Destination Country';
      case 'ARRIVED_AT_DESTINATION': return l10n.arrivedAtDestination;
      case 'OUT_FOR_DELIVERY': return l10n.statusOutForDelivery;
      case 'DELIVERED': return l10n.statusDelivered;
      case 'DELAYED': return l10n.delayed;
      case 'CANCELLED': return l10n.statusCancelled;
      default: return status.replaceAll('_', ' ');
    }
  }

  static Widget _buildStatusOption(
    BuildContext context, 
    BuildContext dialogContext, 
    ShipmentEntity shipment, 
    String statusKey, 
    String label, 
    TextEditingController controller,
    VoidCallback onRefresh,
    {bool isDisabled = false}
  ) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: isDisabled ? null : () async {
        final confirmed = await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Status Change'),
            content: Text('Update status to "$label"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
            ],
          ),
        );

        if (confirmed == true) {
          if (statusKey == 'PICKED_UP') {
            Navigator.pop(dialogContext); // Close simple dialog first
            _showVerifiedPickupModal(context, shipment, statusKey, controller.text, onRefresh);
          } else {
            Navigator.pop(dialogContext);
            _performUpdateStatus(context, shipment, statusKey, description: controller.text, onRefresh: onRefresh);
          }
        }
      },
      child: Text(
        label, 
        style: TextStyle(
          fontSize: 16, 
          fontWeight: label.contains('(Current)') ? FontWeight.bold : FontWeight.normal,
          color: isDisabled ? Colors.grey : Theme.of(context).colorScheme.onSurface,
        )
      ),
    );
  }

  static void _showVerifiedPickupModal(
    BuildContext context, 
    ShipmentEntity shipment, 
    String statusKey, 
    String description,
    VoidCallback onRefresh,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) => _VerifiedPickupWidget(
        shipment: shipment,
        onConfirm: (pin, photos) {
          Navigator.pop(modalContext);
          _performUpdateStatus(context, shipment, statusKey, description: description, imagePaths: photos, pickupPin: pin, onRefresh: onRefresh);
        },
      ),
    );
  }

  static Future<void> _performUpdateStatus(
    BuildContext context, 
    ShipmentEntity shipment, 
    String newStatus, 
    {String? description, List<String>? imageUrls, List<String>? imagePaths, String? pickupPin, required VoidCallback onRefresh}
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating status...'), duration: Duration(seconds: 1)));

      if (imageUrls == null && imagePaths != null && imagePaths.isNotEmpty) {
        imageUrls = [];
        for (final path in imagePaths) {
          final url = await sl<ShipmentRepository>().uploadImage(path);
          imageUrls.add(url);
        }
      }

      final authState = context.read<AuthBloc>().state;
      final actorName = authState.user?.fullName ?? authState.user?.businessName ?? 'User';

      await sl<ShipmentRepository>().updateStatus(shipment.id, newStatus, description: description, imageUrls: imageUrls, pickupPin: pickupPin, actor: actorName);

      if (context.mounted) {
        context.read<ShipmentListBloc>().add(const LoadShipments());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        _handleError(context, e, () => _performUpdateStatus(context, shipment, newStatus, description: description, imageUrls: imageUrls, imagePaths: imagePaths, pickupPin: pickupPin, onRefresh: onRefresh));
      }
    }
  }

  static void _handleError(BuildContext context, dynamic error, VoidCallback onRetry) {
    String message = error.toString();
    if (error is DioException) {
      final backendMessage = error.response?.data?['message'];
      if (backendMessage != null) message = backendMessage.toString();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: onRetry),
      )
    );
  }
}

class _VerifiedPickupWidget extends StatefulWidget {
  final ShipmentEntity shipment;
  final Function(String pin, List<String> photos) onConfirm;
  const _VerifiedPickupWidget({required this.shipment, required this.onConfirm});
  @override State<_VerifiedPickupWidget> createState() => _VerifiedPickupWidgetState();
}

class _VerifiedPickupWidgetState extends State<_VerifiedPickupWidget> {
  final List<String> _photos = [];
  final _pin = TextEditingController();
  @override Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Verified Pickup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('3 photos of item condition required.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => GestureDetector(
        onTap: _photos.length > i ? null : () async {
          final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
          if (img != null) setState(() => _photos.add(img.path));
        },
        child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: _photos.length > i ? Colors.green : Colors.transparent, width: 2)), child: _photos.length > i ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(File(_photos[i]), fit: BoxFit.cover)) : const Icon(Icons.add_a_photo)),
      ))),
      const SizedBox(height: 16),
      TextField(
        controller: _pin, 
        keyboardType: TextInputType.number, 
        maxLength: 6,
        onChanged: (val) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Customer 6-Digit PIN', 
          border: OutlineInputBorder(),
          counterText: "",
        )
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, 
        child: ElevatedButton(
          onPressed: (_photos.length < 3 || _pin.text.length < 6) 
            ? null 
            : () => widget.onConfirm(_pin.text, _photos), 
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: Colors.grey.shade300,
          ), 
          child: const Text('Confirm Pickup')
        )
      ),
    ]));
  }
}
