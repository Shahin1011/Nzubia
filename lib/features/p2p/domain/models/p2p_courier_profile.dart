import 'package:equatable/equatable.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';

/// Minimal user summary embedded in P2P responses by the backend mapper.
class P2pUserSummary extends Equatable {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? profilePictureUrl;

  const P2pUserSummary({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.profilePictureUrl,
  });

  factory P2pUserSummary.fromJson(Map<String, dynamic> json) {
    return P2pUserSummary(
      id: (json['id'] ?? '').toString(),
      email: json['email'] as String?,
      fullName: (json['full_name'] ?? json['fullName']) as String?,
      phone: json['phone'] as String?,
      profilePictureUrl: (json['profile_picture_url'] ??
              json['profile_image_url'] ??
              json['profilePictureUrl'] ??
              json['profileImageUrl'] ??
              json['avatar_url'] ??
              json['avatar']) as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, phone, profilePictureUrl];
}

class P2pCourierProfile extends Equatable {
  final String id;
  final String userId;
  final P2pUserSummary? user;
  final CourierVerificationState verificationState;
  final double rating;
  final bool isActive;
  final double? homeLatitude;
  final double? homeLongitude;
  final double? serviceRadiusKm;
  final List<ItemCategory> acceptedCategories;
  final bool payoutReady;
  final String? reputationSummary;
  final String? destinationRoute;
  final String? pickupOrigin;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final double? capacityKg;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const P2pCourierProfile({
    required this.id,
    required this.userId,
    this.user,
    required this.verificationState,
    required this.rating,
    required this.isActive,
    this.homeLatitude,
    this.homeLongitude,
    this.serviceRadiusKm,
    this.acceptedCategories = const [],
    required this.payoutReady,
    this.reputationSummary,
    this.destinationRoute,
    this.pickupOrigin,
    this.departureDate,
    this.returnDate,
    this.capacityKg,
    this.createdAt,
    this.updatedAt,
  });

  factory P2pCourierProfile.fromJson(Map<String, dynamic> json) {
    // If backend wraps profile inside a 'courier' or 'profile' key
    final data = json['courier'] is Map<String, dynamic>
        ? json['courier'] as Map<String, dynamic>
        : (json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : json);

    final rawCats = data['accepted_categories'] as List? ??
        data['acceptedCategories'] as List? ??
        const [];

    final idStr = (data['id'] ?? data['courier_id'] ?? data['courierId'] ?? '').toString();
    final userIdStr = (data['user_id'] ?? data['userId'] ?? idStr).toString();

    final vStateStr = (data['verification_state'] ??
            data['verificationState'] ??
            data['kyc_status'] ??
            data['kycStatus'])
        ?.toString();

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final createdAtStr = data['created_at'] ?? data['createdAt'];
    final updatedAtStr = data['updated_at'] ?? data['updatedAt'];
    final loc = data['current_location'] is Map
        ? Map<String, dynamic>.from(data['current_location'] as Map)
        : null;

    final depDate = loc?['departure_date'] != null
        ? DateTime.tryParse(loc!['departure_date'].toString())
        : (data['departure_date'] != null
            ? DateTime.tryParse(data['departure_date'].toString())
            : null);
    final retDate = loc?['return_date'] != null
        ? DateTime.tryParse(loc!['return_date'].toString())
        : (data['return_date'] != null
            ? DateTime.tryParse(data['return_date'].toString())
            : null);
    final capKg = parseDouble(loc?['capacity_kg'] ?? data['capacity_kg']);
    final pickOrigin = (loc?['pickup_origin'] ?? data['pickup_origin'] ?? data['origin'])?.toString();

    return P2pCourierProfile(
      id: idStr,
      userId: userIdStr,
      user: data['user'] is Map<String, dynamic>
          ? P2pUserSummary.fromJson(data['user'] as Map<String, dynamic>)
          : P2pUserSummary(
              id: userIdStr,
              email: data['email'] as String?,
              fullName: (data['full_name'] ?? data['fullName']) as String?,
              phone: data['phone'] as String?,
              profilePictureUrl: (data['profile_picture_url'] ??
                      data['profile_image_url'] ??
                      data['profilePictureUrl'] ??
                      data['profileImageUrl'] ??
                      data['avatar_url'] ??
                      data['avatar']) as String?,
            ),
      verificationState: CourierVerificationState.fromJson(vStateStr),
      rating: parseDouble(data['rating']) ?? 0.0,
      isActive: (data['is_active'] ??
              data['isActive'] ??
              data['is_available'] ??
              data['isAvailable']) as bool? ??
          false,
      homeLatitude: parseDouble(data['home_latitude'] ?? data['homeLatitude']),
      homeLongitude: parseDouble(data['home_longitude'] ?? data['homeLongitude']),
      serviceRadiusKm: parseDouble(data['service_radius_km'] ?? data['serviceRadiusKm']),
      acceptedCategories: rawCats
          .map((e) => ItemCategory.fromJson(e?.toString()))
          .toList(growable: false),
      payoutReady: (data['payout_ready'] ??
              data['payoutReady'] ??
              data['payouts_enabled'] ??
              data['payoutsEnabled']) as bool? ??
          false,
      reputationSummary:
          (data['reputation_summary'] ?? data['reputationSummary']) as String?,
      destinationRoute: (data['destination_route'] ??
              data['destinationRoute'] ??
              loc?['destination_route'])
          ?.toString(),
      pickupOrigin: pickOrigin,
      departureDate: depDate,
      returnDate: retDate,
      capacityKg: capKg,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr.toString()) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr.toString()) : null,
    );
  }

  P2pCourierProfile copyWith({
    String? id,
    String? userId,
    P2pUserSummary? user,
    CourierVerificationState? verificationState,
    double? rating,
    bool? isActive,
    double? homeLatitude,
    double? homeLongitude,
    double? serviceRadiusKm,
    List<ItemCategory>? acceptedCategories,
    bool? payoutReady,
    String? reputationSummary,
    String? destinationRoute,
    String? pickupOrigin,
    DateTime? departureDate,
    DateTime? returnDate,
    double? capacityKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return P2pCourierProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      verificationState: verificationState ?? this.verificationState,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      acceptedCategories: acceptedCategories ?? this.acceptedCategories,
      payoutReady: payoutReady ?? this.payoutReady,
      reputationSummary: reputationSummary ?? this.reputationSummary,
      destinationRoute: destinationRoute ?? this.destinationRoute,
      pickupOrigin: pickupOrigin ?? this.pickupOrigin,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      capacityKg: capacityKg ?? this.capacityKg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convenience: human-readable display name (full name when available).
  String get displayName => user?.fullName ?? user?.email ?? 'Courier';

  /// Convenience: profile picture url
  String? get profilePictureUrl => user?.profilePictureUrl;

  @override
  List<Object?> get props => [
        id,
        userId,
        user,
        verificationState,
        rating,
        isActive,
        homeLatitude,
        homeLongitude,
        serviceRadiusKm,
        acceptedCategories,
        payoutReady,
        reputationSummary,
        destinationRoute,
        pickupOrigin,
        departureDate,
        returnDate,
        capacityKg,
        createdAt,
        updatedAt,
      ];
}

/// Lightweight status response from `/p2p/couriers/me/status`.
class P2pCourierStatus extends Equatable {
  final CourierVerificationState verificationState;
  final bool isActive;
  final bool payoutReady;

  const P2pCourierStatus({
    required this.verificationState,
    required this.isActive,
    required this.payoutReady,
  });

  factory P2pCourierStatus.fromJson(Map<String, dynamic> json) {
    return P2pCourierStatus(
      verificationState:
          CourierVerificationState.fromJson(json['verification_state'] as String?),
      isActive: json['is_active'] as bool? ?? false,
      payoutReady: json['payout_ready'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [verificationState, isActive, payoutReady];
}

/// Aggregated reputation response from `/p2p/couriers/:id/reputation`.
class P2pCourierReputation extends Equatable {
  final double averageRating;
  final int reviewCount;
  final List<Map<String, dynamic>> recentReviews;

  const P2pCourierReputation({
    required this.averageRating,
    required this.reviewCount,
    required this.recentReviews,
  });

  factory P2pCourierReputation.fromJson(Map<String, dynamic> json) {
    final raw = json['recent_reviews'] as List? ?? const [];
    return P2pCourierReputation(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      recentReviews:
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  @override
  List<Object?> get props => [averageRating, reviewCount, recentReviews];
}
