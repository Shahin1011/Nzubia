import 'package:equatable/equatable.dart';

enum AgentOnboardingStatus { initial, loading, success, failure }

class AgentOnboardingState extends Equatable {
  final AgentOnboardingStatus status;
  final String? errorMessage;
  
  // Form Fields
  final String agentType;
  final String companyName;
  final String businessRegNumber;
  final String taxId;
  final String licenseNumber;
  final String insuranceCertificateUrl;
  final String idType;
  final String idNumber;
  final String idDocumentPath;
  final String selfiePath;
  final String address;
  final int yearsInBusiness;
  final int fleetSize;
  final List<String> cargoSpecializations;
  final List<String> serviceRegions;
  final double? baseLat;
  final double? baseLng;
  final int? serviceRadiusKm;

  const AgentOnboardingState({
    this.status = AgentOnboardingStatus.initial,
    this.errorMessage,
    this.agentType = 'INDIVIDUAL',
    this.companyName = '',
    this.businessRegNumber = '',
    this.taxId = '',
    this.licenseNumber = '',
    this.insuranceCertificateUrl = '',
    this.idType = 'NATIONAL_ID',
    this.idNumber = '',
    this.idDocumentPath = '',
    this.selfiePath = '',
    this.address = '',
    this.yearsInBusiness = 0,
    this.fleetSize = 0,
    this.cargoSpecializations = const [],
    this.serviceRegions = const [],
    this.baseLat,
    this.baseLng,
    this.serviceRadiusKm,
  });

  factory AgentOnboardingState.initial(dynamic user) {
    if (user == null) return const AgentOnboardingState();
    return AgentOnboardingState(
      agentType: user.agentType ?? 'INDIVIDUAL',
      companyName: user.companyName ?? '',
      address: user.address ?? '',
      businessRegNumber: user.businessRegNumber ?? '',
      taxId: user.taxId ?? '',
      licenseNumber: user.licenseNumber ?? '',
      idType: user.idType ?? 'NATIONAL_ID',
      idNumber: user.idNumber ?? '',
      idDocumentPath: user.idDocumentUrl ?? '',
      selfiePath: user.selfieUrl ?? '',
      insuranceCertificateUrl: user.insuranceCertificateUrl ?? '',
      yearsInBusiness: user.yearsInBusiness ?? 0,
      fleetSize: user.fleetSize ?? 0,
      serviceRadiusKm: user.serviceRadiusKm ?? 0,
      cargoSpecializations: user.specialization ?? const [],
      serviceRegions: user.serviceRegions ?? const [],
    );
  }

  AgentOnboardingState copyWith({
    AgentOnboardingStatus? status,
    String? errorMessage,
    String? agentType,
    String? companyName,
    String? businessRegNumber,
    String? taxId,
    String? licenseNumber,
    String? insuranceCertificateUrl,
    String? idType,
    String? idNumber,
    String? idDocumentPath,
    String? selfiePath,
    String? address,
    int? yearsInBusiness,
    int? fleetSize,
    List<String>? cargoSpecializations,
    List<String>? serviceRegions,
    double? baseLat,
    double? baseLng,
    int? serviceRadiusKm,
  }) {
    return AgentOnboardingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      agentType: agentType ?? this.agentType,
      companyName: companyName ?? this.companyName,
      businessRegNumber: businessRegNumber ?? this.businessRegNumber,
      taxId: taxId ?? this.taxId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      insuranceCertificateUrl: insuranceCertificateUrl ?? this.insuranceCertificateUrl,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      idDocumentPath: idDocumentPath ?? this.idDocumentPath,
      selfiePath: selfiePath ?? this.selfiePath,
      address: address ?? this.address,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      fleetSize: fleetSize ?? this.fleetSize,
      cargoSpecializations: cargoSpecializations ?? this.cargoSpecializations,
      serviceRegions: serviceRegions ?? this.serviceRegions,
      baseLat: baseLat ?? this.baseLat,
      baseLng: baseLng ?? this.baseLng,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        agentType,
        companyName,
        businessRegNumber,
        taxId,
        licenseNumber,
        insuranceCertificateUrl,
        idType,
        idNumber,
        idDocumentPath,
        selfiePath,
        address,
        yearsInBusiness,
        fleetSize,
        cargoSpecializations,
        serviceRegions,
        baseLat,
        baseLng,
        serviceRadiusKm,
      ];
}
