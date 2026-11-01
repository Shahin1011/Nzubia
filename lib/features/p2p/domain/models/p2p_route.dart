import 'package:equatable/equatable.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';

class P2pRoute extends Equatable {
  final String id;
  final String courierProfileId;
  final P2pCourierProfile? courierProfile;
  final String destinationCountry;
  final String destinationCity;
  final DateTime departureDate;
  final DateTime? returnDate;
  final String pickupOrigin;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final double capacityKg;
  final List<ItemCategory> acceptedItemCategories;
  final String? routeNotes;
  final RouteStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const P2pRoute({
    required this.id,
    required this.courierProfileId,
    this.courierProfile,
    required this.destinationCountry,
    required this.destinationCity,
    required this.departureDate,
    this.returnDate,
    required this.pickupOrigin,
    this.pickupLatitude,
    this.pickupLongitude,
    this.currentLatitude,
    this.currentLongitude,
    required this.capacityKg,
    this.acceptedItemCategories = const [],
    this.routeNotes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory P2pRoute.fromJson(Map<String, dynamic> json) {
    final loc = json['current_location'] is Map
        ? Map<String, dynamic>.from(json['current_location'] as Map)
        : null;

    final rawCats = (json['accepted_item_categories'] ??
            json['acceptedItemCategories'] ??
            loc?['accepted_categories'] ??
            loc?['acceptedCategories'] ??
            loc?['acceptedItemCategories'] ??
            json['accepted_categories']) as List? ??
        const [];

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    String destCountry = (json['destination_country'] ??
            json['destinationCountry'] ??
            loc?['destination_country'] ??
            loc?['destinationCountry'] ??
            '')
        .toString();
    String destCity = (json['destination_city'] ??
            json['destinationCity'] ??
            loc?['destination_city'] ??
            loc?['destinationCity'] ??
            '')
        .toString();
    final destRoute = (json['destination_route'] ??
            json['destinationRoute'] ??
            loc?['destination_route'] ??
            loc?['destinationRoute'] ??
            '')
        .toString();

    if (destCountry.isEmpty && destRoute.isNotEmpty) {
      if (destRoute.contains(',')) {
        final parts = destRoute.split(',');
        destCity = parts.first.trim();
        destCountry = parts.sublist(1).join(',').trim();
      } else {
        destCountry = destRoute;
      }
    }

    String pickup = (json['pickup_origin'] ??
            json['pickupOrigin'] ??
            loc?['pickup_origin'] ??
            loc?['pickupOrigin'] ??
            json['origin'] ??
            loc?['origin'] ??
            '')
        .toString();
    if (pickup.isEmpty) {
      pickup = 'Current Location';
    }

    final rawStatus = json['status']?.toString();
    RouteStatus status = RouteStatus.fromJson(rawStatus);
    if (rawStatus == null && (json['is_available'] == true || destRoute.isNotEmpty)) {
      status = RouteStatus.published;
    }

    final departureDate = parseDate(
      json['departure_date'] ??
          json['departureDate'] ??
          loc?['departure_date'] ??
          loc?['departureDate'],
    );

    final rawReturn = json['return_date'] ??
        json['returnDate'] ??
        loc?['return_date'] ??
        loc?['returnDate'];
    final returnDate = rawReturn != null ? DateTime.tryParse(rawReturn.toString()) : null;

    final capacityKg = parseDouble(
      json['capacity_kg'] ??
          json['capacityKg'] ??
          loc?['capacity_kg'] ??
          loc?['capacityKg'],
    ) ?? 0.0;

    return P2pRoute(
      id: (json['id'] ?? '').toString(),
      courierProfileId: (json['courier_profile_id'] ??
              json['courierProfileId'] ??
              json['courier_id'] ??
              json['courierId'] ??
              json['id'] ??
              '')
          .toString(),
      courierProfile: json['courier_profile'] is Map
          ? P2pCourierProfile.fromJson(
              Map<String, dynamic>.from(json['courier_profile'] as Map),
            )
          : ((json['role'] == 'COURIER' || json['email'] != null || json['full_name'] != null)
              ? P2pCourierProfile.fromJson(json)
              : null),
      destinationCountry: destCountry,
      destinationCity: destCity,
      departureDate: departureDate,
      returnDate: returnDate,
      pickupOrigin: pickup,
      pickupLatitude: parseDouble(json['pickup_latitude'] ?? json['pickupLatitude'] ?? loc?['pickup_latitude'] ?? loc?['lat']),
      pickupLongitude: parseDouble(json['pickup_longitude'] ?? json['pickupLongitude'] ?? loc?['pickup_longitude'] ?? loc?['lng']),
      currentLatitude: parseDouble(json['current_latitude'] ?? json['currentLatitude'] ?? loc?['lat']),
      currentLongitude: parseDouble(json['current_longitude'] ?? json['currentLongitude'] ?? loc?['lng']),
      capacityKg: capacityKg,
      acceptedItemCategories: rawCats
          .map((e) => ItemCategory.fromJson(e?.toString()))
          .toList(growable: false),
      routeNotes: (json['route_notes'] ?? json['routeNotes'] ?? loc?['notes'] ?? loc?['route_notes']) as String?,
      status: status,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString())
          : null,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.tryParse((json['updated_at'] ?? json['updatedAt']).toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        courierProfileId,
        courierProfile,
        destinationCountry,
        destinationCity,
        departureDate,
        returnDate,
        pickupOrigin,
        pickupLatitude,
        pickupLongitude,
        currentLatitude,
        currentLongitude,
        capacityKg,
        acceptedItemCategories,
        routeNotes,
        status,
        createdAt,
        updatedAt,
      ];

  P2pRoute copyWith({
    String? id,
    String? courierProfileId,
    P2pCourierProfile? courierProfile,
    String? destinationCountry,
    String? destinationCity,
    DateTime? departureDate,
    DateTime? returnDate,
    String? pickupOrigin,
    double? pickupLatitude,
    double? pickupLongitude,
    double? currentLatitude,
    double? currentLongitude,
    double? capacityKg,
    List<ItemCategory>? acceptedItemCategories,
    String? routeNotes,
    RouteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return P2pRoute(
      id: id ?? this.id,
      courierProfileId: courierProfileId ?? this.courierProfileId,
      courierProfile: courierProfile ?? this.courierProfile,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationCity: destinationCity ?? this.destinationCity,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      pickupOrigin: pickupOrigin ?? this.pickupOrigin,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      capacityKg: capacityKg ?? this.capacityKg,
      acceptedItemCategories: acceptedItemCategories ?? this.acceptedItemCategories,
      routeNotes: routeNotes ?? this.routeNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// One item from `/p2p/routes/feed` — a route paired with a relevance score.
class P2pRouteFeedItem extends Equatable {
  final P2pRoute route;
  final double score;

  const P2pRouteFeedItem({required this.route, required this.score});

  factory P2pRouteFeedItem.fromJson(Map<String, dynamic> json) {
    final routeJson = json['route'] is Map
        ? Map<String, dynamic>.from(json['route'] as Map)
        : json;
    return P2pRouteFeedItem(
      route: P2pRoute.fromJson(routeJson),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [route, score];
}
