import 'dart:convert';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    required super.role,
    super.companyName,
    super.businessAddress,
    super.profileImageUrl,
    super.agentType,
    super.serviceRegions,
    super.rating,
    super.ratingCount,
    super.yearsInBusiness,
    super.fleetSize,
    super.licenseNumber,
    super.kycStatus,
    super.businessName,
    super.preferredPayoutMethod,
    super.zelleEmail,
    super.zellePhone,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final agentProfileRaw = json['agentProfile'];
    final Map<String, dynamic>? agentProfile = agentProfileRaw is Map<String, dynamic>
        ? agentProfileRaw
        : agentProfileRaw is String && agentProfileRaw.trim().isNotEmpty
            ? (jsonDecode(agentProfileRaw) as Map<String, dynamic>?)
            : null;

    // Parse service_regions from agentProfile
    List<String> regions = [];
    if (agentProfile?['service_regions'] != null) {
      final raw = agentProfile!['service_regions'];
      if (raw is List) {
        regions = raw.map((e) => e.toString()).toList();
      }
    }

    String parsedFullName = json['full_name'] ?? json['fullName'] ?? '';
    if (parsedFullName.isEmpty) {
      final fName = json['first_name'] ?? '';
      final lName = json['last_name'] ?? '';
      parsedFullName = '$fName $lName'.trim();
    }

    return UserProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: parsedFullName,
      phoneNumber: json['phone'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      companyName: agentProfile?['company_name'],
      businessAddress: agentProfile?['address'] as String? ?? json['address'] as String?,
      profileImageUrl: json['profile_image_url'] ?? '',
      agentType: agentProfile?['agent_type'],
      serviceRegions: regions,
      rating: double.tryParse(agentProfile?['rating']?.toString() ?? '0') ?? 0.0,
      ratingCount: agentProfile?['rating_count'] ?? 0,
      yearsInBusiness: agentProfile?['years_in_business'],
      fleetSize: agentProfile?['fleet_size'],
      licenseNumber: agentProfile?['license_number'],
      kycStatus: json['kyc_status'],
      businessName: json['business_name'],
      preferredPayoutMethod: agentProfile?['preferred_payout_method'],
      zelleEmail: agentProfile?['zelle_email'],
      zellePhone: agentProfile?['zelle_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phoneNumber,
      'profile_image_url': profileImageUrl,
      'preferred_payout_method': preferredPayoutMethod,
      'zelle_email': zelleEmail,
      'zelle_phone': zellePhone,
      'company_name': companyName,
      'business_address': businessAddress,
    };
  }
}
