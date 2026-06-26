import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  UserEntity? get currentUser;
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String phone, String password, {String role = 'CUSTOMER', String? businessName});
  Future<bool> verifyOtp(String code);
  Future<void> resendOtp();
  Future<void> updateProfile({required String fullName, String? companyName, String? ein, bool isBusiness = false});
  Future<void> submitAgentKYC({
    required String agentType, // 'INDIVIDUAL' or 'BUSINESS'
    // Business Fields
    String? companyName,
    String? businessRegNumber,
    String? taxId,
    String? licenseNumber,
    String? insuranceCertificateUrl, // File path or URL
    
    // Individual Fields
    String? idType,
    String? idNumber,
    String? idDocumentUrl, // File path or URL
    String? selfieUrl, // File path or URL

    // Common
    String? address, // Or structured address
    int? yearsInBusiness,
    int? fleetSize,
    List<String>? cargoSpecializations,
    List<String>? serviceRegions,
    double? baseLat,
    double? baseLng,
    int? serviceRadiusKm,
  });
  Future<void> logout();
  Future<void> deleteAccount();
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> findUserByEmail(String email);
  Future<UserEntity?> findUserByPhone(String phone);
  Future<List<UserEntity>> getAgents();
  Future<String?> getToken();
  Future<void> changePassword(String oldPassword, String newPassword);
  
  // Biometrics
  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);
  Future<void> saveBiometricCredentials(String email, String password);
  Future<UserEntity> loginWithBiometrics();
  
  Future<Map<String, dynamic>> checkStripeStatus();
  Future<String> getStripeOnboardingLink();
  Future<void> updateAgentProfile({
    String? preferredPayoutMethod,
    String? zelleEmail,
    String? zellePhone,
    String? businessName,
  });
}
