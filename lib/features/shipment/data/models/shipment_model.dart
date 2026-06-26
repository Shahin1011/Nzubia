import 'package:customer_nzubia_global/features/payment/data/models/payment_model.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/quote_model.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/review_model.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/cargo_item_model.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/shipment_event_model.dart';


class ShipmentModel extends ShipmentEntity {
  const ShipmentModel({
    required super.id,
    required super.originAddress,
    required super.destinationAddress,
    required super.cargoItems,
    required super.serviceLevel,
    required super.status,
    required super.customerId,
    super.estimatedPrice,
    super.agentId,
    super.events,
    super.quotes,
    super.payments,
    super.pickupDate,
    super.deliveryDate,
    super.recipient,
    super.trackingNumber,
    super.insuranceRequested,
    super.totalItemValue,
    super.pickupImages,
    super.podImages,
    super.documents,
    super.recipientInviteSentAt,
    super.recipientAddressVerified,
    super.pickupPin,
    super.reviews,
    super.customerConfirmedDelivery,
    super.additionalServices,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {

    // Helper to extract address from String or Map
    String parseAddress(dynamic value) {
      if (value is String) return value;
      if (value is Map && value['address'] != null) return value['address'].toString();
      return '';
    }

    // Helper to parse Cargo
    List<CargoItemModel> parseCargo(Map<String, dynamic> json) {
      if (json['cargo_details'] is List) {
        return (json['cargo_details'] as List).map((e) => CargoItemModel.fromJson(e)).toList();
      }
      if (json['cargo_meta'] is Map) {
        return [CargoItemModel.fromJson(json['cargo_meta'])];
      }
      return [];
    }

    // Helper to safely parse doubles
    double? safeDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ShipmentModel(
      id: json['id'] ?? '',
      customerId: (json['customer'] is Map) ? (json['customer']['id'] ?? '') : (json['customer_id'] ?? ''),
      originAddress: parseAddress(json['origin']),
      destinationAddress: parseAddress(json['destination'] ?? json['destination_meta']) != '' 
          ? parseAddress(json['destination'] ?? json['destination_meta']) 
          : (json['destination_country'] ?? 'Unknown Destination'),
      cargoItems: parseCargo(json),
      serviceLevel: json['service_level'] ?? '',
      status: json['status'] ?? 'PENDING',
      estimatedPrice: safeDouble(json['quoteAmount']) ?? safeDouble(json['estimated_price']),
      agentId: (json['agent'] is Map) ? (json['agent']['id'] ?? json['agent_id']) : json['agent_id'],
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => ShipmentEventModel.fromJson(e))
          .toList() ?? [],
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => QuoteModel.fromJson(e))
          .toList() ?? [],
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => PaymentModel.fromJson(e))
          .toList() ?? [],
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => ReviewModel.fromJson(e))
          .toList() ?? [],
      pickupDate: json['pickup_date'] != null ? DateTime.tryParse(json['pickup_date']) : null,
      deliveryDate: json['delivery_date'] != null ? DateTime.tryParse(json['delivery_date']) : null,
      trackingNumber: json['tracking_number'],
      insuranceRequested: json['insurance_requested'] ?? 
                         (json['additional_services'] is Map ? (json['additional_services']['insurance'] ?? false) : false),
      totalItemValue: (json['total_item_value'] != null) ? double.parse(json['total_item_value'].toString()) : 0,
      pickupPin: json['pickup_pin'],
      pickupImages: (json['pickup_images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      podImages: (json['pod_images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      documents: (json['documents'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      recipientInviteSentAt: json['recipient_invite_sent_at'] != null ? DateTime.tryParse(json['recipient_invite_sent_at']) : null,
      recipientAddressVerified: json['recipient_address_verified'] ?? false,
      recipient: json['recipient_email'] != null
          ? RecipientEntity(
              name: json['recipient_name'] ?? '',
              email: json['recipient_email'] ?? '',
              phone: json['recipient_phone'] ?? '',
              address: json['recipient_address'] ?? '',
            )
          : null,
      customerConfirmedDelivery: json['customer_confirmed_delivery'] ?? false,
      additionalServices: (json['additional_services'] is Map) 
          ? json['additional_services'] 
          : {},
    );
  }
}

