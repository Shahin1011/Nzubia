import 'dart:convert';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.isVerified,
    super.kycStatus,
    super.kycNotes,
    super.firstName,
    super.lastName,
    super.profilePictureUrl,
    super.phone,
    super.companyName,
    super.agentType,
    super.address,
    super.businessRegNumber,
    super.taxId,
    super.licenseNumber,
    super.idType,
    super.idNumber,
    super.kycLevel,
    super.kycProvider,
    super.kycVerifiedAt,
    super.yearsInBusiness,
    super.fleetSize,
    super.serviceRadiusKm,
    super.idDocumentUrl,
    super.selfieUrl,
    super.insuranceCertificateUrl,
    super.rating,
    super.reviewCount,
    super.ordersFulfilled,
    super.specialization,
    super.serviceRegions,
    super.preferredPayoutMethod,
    super.zelleEmail,
    super.zellePhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse doubles/ints from potential strings
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    // Check if agent profile is nested (from API) or flat (from cache).
    // The API may return agentProfile as a JSON-encoded string or a Map.
    final agentProfileRaw = json['agentProfile'];
    final Map<String, dynamic>? agentProfile = agentProfileRaw is Map<String, dynamic>
        ? agentProfileRaw
        : agentProfileRaw is String && agentProfileRaw.trim().isNotEmpty
            ? (jsonDecode(agentProfileRaw) as Map<String, dynamic>?)
            : null;
    final hasNestedProfile = agentProfile != null;

    // Helper to extract names
    String? fName = json['first_name'];
    String? lName = json['last_name'];

    if (fName == null && (json['full_name'] != null || json['fullName'] != null)) {
      final fullName = (json['full_name'] ?? json['fullName']) as String;
      final parts = fullName.trim().split(' ');
      if (parts.isNotEmpty) {
        fName = parts.first;
        if (parts.length > 1) {
          lName = parts.sublist(1).join(' ');
        }
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
      // Check both camelCase and snake_case for isVerified
      isVerified: (json['isVerified'] as bool?) ?? (json['is_verified'] as bool?) ?? false,
      kycStatus: json['kyc_status'] as String? ?? 'NOT_SUBMITTED',
      kycNotes: json['kyc_notes'] as String?,
      kycLevel: int.tryParse('${json['kyc_level'] ?? 1}') ?? 1,
      kycProvider: json['kyc_provider'] as String?,
      kycVerifiedAt: json['kyc_verified_at'] == null ? null : DateTime.tryParse(json['kyc_verified_at'].toString()),
      firstName: fName,
      lastName: lName,
      profilePictureUrl: json['profile_picture_url'],
      phone: json['phone'] as String? ?? '',
      // Try nested agentProfile first (API response), then root level (cached data)
      companyName: hasNestedProfile ? agentProfile['company_name'] : json['company_name'],
      agentType: hasNestedProfile ? agentProfile['agent_type'] : json['agent_type'],
      address: hasNestedProfile ? agentProfile['address'] : json['address'],
      businessRegNumber: hasNestedProfile ? agentProfile['business_reg_number'] : json['business_reg_number'],
      taxId: json['tax_id'] as String?,
      licenseNumber: hasNestedProfile ? agentProfile['license_number'] : json['license_number'],
      idType: hasNestedProfile ? agentProfile['id_type'] : json['id_type'],
      idNumber: hasNestedProfile ? agentProfile['id_number'] : json['id_number'],
      yearsInBusiness: parseInt(hasNestedProfile ? agentProfile['years_in_business'] : json['years_in_business']),
      fleetSize: parseInt(hasNestedProfile ? agentProfile['fleet_size'] : json['fleet_size']),
      serviceRadiusKm: parseInt(hasNestedProfile ? agentProfile['service_radius_km'] : json['service_radius_km']),
      idDocumentUrl: hasNestedProfile ? agentProfile['id_document_url'] : json['id_document_url'],
      selfieUrl: hasNestedProfile ? agentProfile['selfie_url'] : json['selfie_url'],
      insuranceCertificateUrl: hasNestedProfile ? agentProfile['insurance_certificate_url'] : json['insurance_certificate_url'],
      rating: parseDouble(hasNestedProfile ? agentProfile['rating'] : json['rating']),
      reviewCount: parseInt(hasNestedProfile ? agentProfile['review_count'] : json['review_count']),
      ordersFulfilled: parseInt(hasNestedProfile ? agentProfile['orders_fulfilled'] : json['orders_fulfilled']),
      specialization: ((hasNestedProfile ? agentProfile['cargo_specializations'] : json['specialization']) as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      serviceRegions: ((hasNestedProfile ? agentProfile['service_regions'] : json['service_regions']) as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preferredPayoutMethod: hasNestedProfile ? agentProfile['preferred_payout_method'] : json['preferred_payout_method'],
      zelleEmail: hasNestedProfile ? agentProfile['zelle_email'] : json['zelle_email'],
      zellePhone: hasNestedProfile ? agentProfile['zelle_phone'] : json['zelle_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'kyc_status': kycStatus,
      'kyc_notes': kycNotes,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture_url': profilePictureUrl,
      'phone': phone,
      'company_name': companyName,
      'agent_type': agentType,
      'address': address,
      'business_reg_number': businessRegNumber,
      'tax_id': taxId,
      'license_number': licenseNumber,
      'id_type': idType,
      'id_number': idNumber,
      'kyc_level': kycLevel,
      'kyc_provider': kycProvider,
      'kyc_verified_at': kycVerifiedAt?.toIso8601String(),
      'years_in_business': yearsInBusiness,
      'fleet_size': fleetSize,
      'service_radius_km': serviceRadiusKm,
      'id_document_url': idDocumentUrl,
      'selfie_url': selfieUrl,
      'insurance_certificate_url': insuranceCertificateUrl,
      'rating': rating,
      'review_count': reviewCount,
      'orders_fulfilled': ordersFulfilled,
      'specialization': specialization,
      'service_regions': serviceRegions,
      'preferred_payout_method': preferredPayoutMethod,
      'zelle_email': zelleEmail,
      'zelle_phone': zellePhone,
    };
  }
}
