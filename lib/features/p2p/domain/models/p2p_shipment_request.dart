import 'package:equatable/equatable.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';

class P2pShipmentRequest extends Equatable {
  final String id;
  final String seekerUserId;
  final P2pUserSummary? seeker;
  final String originAddress;
  final double? originLatitude;
  final double? originLongitude;
  final String destinationCountry;
  final String destinationCity;
  final String? destinationAddress;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientAddress;
  final ItemCategory itemCategory;
  final String itemDescription;

  /// `{ length, width, height }` in cm. Empty map when the seeker skipped it.
  final Map<String, double> dimensionsCm;

  final double weightKg;
  final double declaredValueUsd;
  final List<String> photoUrls;
  final ShipmentRequestStatus status;
  final Map<String, dynamic>? matchMetadata;

  /// Set by the backend at HANDOFF_PENDING; before then we fall back to the
  /// shipment ID as the deterministic room name in the messaging UI.
  final String? chatThreadId;

  /// 6-digit code generated when handoff is recorded; emailed to the seeker.
  final String? pickupConfirmationCode;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const P2pShipmentRequest({
    required this.id,
    required this.seekerUserId,
    this.seeker,
    required this.originAddress,
    this.originLatitude,
    this.originLongitude,
    required this.destinationCountry,
    required this.destinationCity,
    this.destinationAddress,
    this.recipientName,
    this.recipientPhone,
    this.recipientAddress,
    required this.itemCategory,
    required this.itemDescription,
    this.dimensionsCm = const {},
    required this.weightKg,
    required this.declaredValueUsd,
    this.photoUrls = const [],
    required this.status,
    this.matchMetadata,
    this.chatThreadId,
    this.pickupConfirmationCode,
    this.createdAt,
    this.updatedAt,
  });

  factory P2pShipmentRequest.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions_cm'];
    final Map<String, double> parsedDims;
    if (dims is Map) {
      parsedDims = {
        for (final entry in dims.entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0.0,
      };
    } else {
      parsedDims = const {};
    }

    return P2pShipmentRequest(
      id: json['id'] as String? ?? '',
      seekerUserId: json['seeker_user_id'] as String? ?? '',
      seeker: json['seeker'] is Map<String, dynamic>
          ? P2pUserSummary.fromJson(json['seeker'] as Map<String, dynamic>)
          : null,
      originAddress: json['origin_address'] as String? ?? '',
      originLatitude: json['origin_latitude'] != null 
          ? double.tryParse(json['origin_latitude'].toString()) 
          : null,
      originLongitude: json['origin_longitude'] != null 
          ? double.tryParse(json['origin_longitude'].toString()) 
          : null,
      destinationCountry: json['destination_country'] as String? ?? '',
      destinationCity: json['destination_city'] as String? ?? '',
      destinationAddress: json['destination_address'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      recipientAddress: json['recipient_address'] as String?,
      itemCategory: ItemCategory.fromJson(json['item_category'] as String?),
      itemDescription: json['item_description'] as String? ?? '',
      dimensionsCm: parsedDims,
      weightKg: json['weight_kg'] != null 
          ? double.tryParse(json['weight_kg'].toString()) ?? 0.0 
          : 0.0,
      declaredValueUsd: json['declared_value_usd'] != null 
          ? double.tryParse(json['declared_value_usd'].toString()) ?? 0.0 
          : 0.0,
      photoUrls: (json['photo_urls'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: ShipmentRequestStatus.fromJson(json['status'] as String?),
      matchMetadata: json['match_metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['match_metadata'] as Map)
          : null,
      chatThreadId: json['chat_thread_id'] as String?,
      pickupConfirmationCode: json['pickup_confirmation_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    seekerUserId,
    seeker,
    originAddress,
    originLatitude,
    originLongitude,
    destinationCountry,
    destinationCity,
    destinationAddress,
    recipientName,
    recipientPhone,
    recipientAddress,
    itemCategory,
    itemDescription,
    dimensionsCm,
    weightKg,
    declaredValueUsd,
    photoUrls,
    status,
    matchMetadata,
    chatThreadId,
    pickupConfirmationCode,
    createdAt,
    updatedAt,
  ];

  String get displayDestination {
    if (destinationAddress != null &&
        destinationAddress!.isNotEmpty &&
        destinationAddress != 'null') {
      return destinationAddress!;
    }
    final city =
        destinationCity.isNotEmpty ? destinationCity : 'Not Specified';
    final country =
        destinationCountry.isNotEmpty ? destinationCountry : 'Not Specified';

    if (city == 'Not Specified' && country == 'Not Specified') {
      return 'Not Specified';
    }
    if (city == 'Not Specified') return country;
    if (country == 'Not Specified') return city;
    return '$city, $country';
  }
}
