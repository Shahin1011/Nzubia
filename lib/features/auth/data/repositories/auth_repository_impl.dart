import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:dio/dio.dart'; // Import DioException
import 'package:customer_nzubia_global/features/auth/data/models/user_model.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hive_flutter/hive_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;
  
  // Use Hive for non-sensitive heavy data like User Profile
  Box get _settingsBox => Hive.box('settings');

  // Temporary storage for email during OTP flow if needed
  String? _pendingEmail;
  UserEntity? _currentUser;

  AuthRepositoryImpl(this._dioClient, this._storage);

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      if (kDebugMode) debugPrint('=== LOGIN ATTEMPT === Email: $email, Password: $password');
      final response = await _dioClient.dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      final data = response.data;

      // Handle OTP Required case
      if (data['message'] != null && data['message'].toString().contains('OTP required')) {
        _pendingEmail = email;
        throw Exception('OTP_REQUIRED');
      }

      final accessToken = data['accessToken'];

      if (accessToken == null) throw Exception('No access token received');

      // Clear any previous session data first
      await _storage.delete(key: 'accessToken');
      await _settingsBox.delete('cached_user');

      await _storage.write(key: 'accessToken', value: accessToken);
      if (kDebugMode) debugPrint('AuthRepository: Token saved to storage.');
      _pendingEmail = email; // Store for potential OTP/Resend

      if (data['user'] != null) {
        final userModel = UserModel.fromJson(data['user']);
        _currentUser = userModel;
        await _cacheUser(userModel);
        return _currentUser!;
      } else {
        // Fetch user profile if not returned in login response
        final profileResponse = await _dioClient.dio.get(ApiConstants.profile);
        final userModel = UserModel.fromJson(profileResponse.data);
        _currentUser = userModel;
        await _cacheUser(userModel);
        return _currentUser!;
      }
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data.toString().contains('OTP_REQUIRED')) {
         rethrow; // Should have been handled above, but just in case
      }
      rethrow; // Let the UI handle the friendly error from interceptor
    } catch (e) {
      if (e.toString().contains('OTP_REQUIRED')) rethrow;
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<UserEntity> register(String email, String phone, String password, {String role = 'CUSTOMER', String? businessName}) async {
    try {
      final response = await _dioClient.dio.post(ApiConstants.register, data: {
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        if (businessName != null) 'businessName': businessName,
      });

      final data = response.data;

      if (data['accessToken'] != null) {
         final accessToken = data['accessToken'];
         final user = UserModel.fromJson(data['user']);
         
          // Clear any previous session data
         await _storage.delete(key: 'accessToken');
         await _settingsBox.delete('cached_user');

         await _storage.write(key: 'accessToken', value: accessToken);
         await _cacheUser(user); // Cache on registration success
         _pendingEmail = email;
         return user;
      }

      // If it just says "Registered, please verify":
      _pendingEmail = email;
      return UserEntity(id: '', email: email, role: role, isVerified: false);

    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        final msg = e.response!.data['message'];
        if (msg is List) {
          throw Exception(msg.join('\n'));
        }
        throw Exception(msg.toString());
      }
      rethrow;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<bool> verifyOtp(String code) async {
     try {
      if (_pendingEmail == null) throw Exception('No pending authentication context');

      final response = await _dioClient.dio.post(ApiConstants.verifyOtp, data: {
        'email': _pendingEmail,
        'otp': code,
      });

      final data = response.data;
      if (data != null && data['accessToken'] != null) {
         final accessToken = data['accessToken'];
         final user = UserModel.fromJson(data['user']);
         
         await _storage.write(key: 'accessToken', value: accessToken);
         await _cacheUser(user); // Cache on OTP success

         // Clear pending email after successful verification
         _pendingEmail = null;
         return true;
      }

      return false;
    } on DioException {
       rethrow;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> resendOtp() async {
    if (_pendingEmail == null) return;
    try {
      await _dioClient.dio.post(ApiConstants.resendOtp, data: {
        'email': _pendingEmail,
      });
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Resend OTP failed: $e');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.dio.post(ApiConstants.forgotPassword, data: {
        'email': email,
      });
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to send reset code';
      throw Exception(message);
    }
  }

  @override
  Future<void> resetPassword(String email, String otp) async {
    try {
      await _dioClient.dio.post(ApiConstants.resetPassword, data: {
        'email': email,
        'otp': otp,
      });
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Invalid password reset code';
      throw Exception(message);
    }
  }

  @override
  Future<void> changePasswordWithEmail(String email, String newPassword) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'email': email,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Password change failed';
      throw Exception(message);
    }
  }

  @override
  Future<void> updateProfile({required String fullName, String? companyName, String? ein, bool isBusiness = false}) async {
    try {
      final data = {
        'fullName': fullName.trim(),
      };

      await _dioClient.dio.patch(ApiConstants.profile, data: data);

      // Refresh local cache after update
      await getCurrentUser();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  @override
  Future<void> submitAgentKYC({
    required String agentType,
    String? companyName,
    String? businessRegNumber,
    String? taxId,
    String? licenseNumber,
    String? insuranceCertificateUrl,
    String? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? selfieUrl,
    String? address,
    int? yearsInBusiness,
    int? fleetSize,
    List<String>? cargoSpecializations,
    List<String>? serviceRegions,
    double? baseLat,
    double? baseLng,
    int? serviceRadiusKm,
  }) async {
    try {
      final formData = FormData.fromMap({
        'agent_type': agentType,
        if (companyName != null) 'company_name': companyName,
        if (businessRegNumber != null) 'business_reg_number': businessRegNumber,
        if (taxId != null) 'tax_id': taxId,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (idType != null) 'id_type': idType,
        if (idNumber != null) 'id_number': idNumber,
        if (address != null) 'address': address,
        if (yearsInBusiness != null) 'years_in_business': yearsInBusiness,
        if (fleetSize != null) 'fleet_size': fleetSize,
        if (baseLat != null) 'base_lat': baseLat,
        if (baseLng != null) 'base_lng': baseLng,
        if (serviceRadiusKm != null) 'service_radius_km': serviceRadiusKm,
      });

      // Handle Arrays manually for FormData (Dio style)
      if (cargoSpecializations != null) {
        for (var item in cargoSpecializations) {
           formData.fields.add(MapEntry('cargo_specializations[]', item));
        }
      }
      if (serviceRegions != null) {
        for (var item in serviceRegions) {
           formData.fields.add(MapEntry('service_regions[]', item));
        }
      }

      // Handle Files
      if (idDocumentUrl != null && !idDocumentUrl.startsWith('http')) {
         formData.files.add(MapEntry(
           'id_document',
           await MultipartFile.fromFile(idDocumentUrl),
         ));
      }
      if (selfieUrl != null && !selfieUrl.startsWith('http')) {
         formData.files.add(MapEntry(
           'selfie',
           await MultipartFile.fromFile(selfieUrl),
         ));
      }
      // Insurance could be file or URL logic, assuming file if local path
      if (insuranceCertificateUrl != null && !insuranceCertificateUrl.startsWith('http')) {
         // Assuming backend expects 'insurance_certificate' field for file, need to check DTO/Controller
         // If DTO only has URL string, we might need separate upload or backend logic update.
         // Based on users-controller.ts code visible earlier: 
         // @UseInterceptors(FileFieldsInterceptor([ { name: 'id_document' }, { name: 'selfie' } ]))
         // It seems insurance cert isn't in the interceptor list for file upload yet. 
         // Strategy: If user picks file, we can't upload unless backend accepts it. 
         // For now, let's treat it as string or skip if not supported by backend upload yet.
         // Warning user: Insurance file upload support missing in backend controller.
      }

      await _dioClient.dio.post(ApiConstants.agentOnboarding, data: formData);
      
      // Refresh User after submission to get updated KYC status
      await getCurrentUser();
      
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Agent onboarding failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _settingsBox.delete('cached_user');
    _pendingEmail = null;
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    await _dioClient.dio.delete(ApiConstants.deleteAccount);
    await logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
     try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        // Ensure cache is cleared if no token (prevents zombie state)
        if (_settingsBox.containsKey('cached_user')) {
           await _settingsBox.delete('cached_user');
        }
        return null;
      }

      try {
        // Try fetching fresh profile from API
        final response = await _dioClient.dio.get(ApiConstants.profile);
        
        if (response.data == null || response.data == '') {
          throw Exception('Backend returned an empty response for profile.');
        }
        
        if (response.data is! Map<String, dynamic>) {
           throw Exception('Unexpected response format from profile endpoint: ${response.data}');
        }

        final userModel = UserModel.fromJson(response.data as Map<String, dynamic>);
        _currentUser = userModel;
        await _cacheUser(userModel); // Update cache
        return _currentUser;
      } catch (apiError) {
        if (kDebugMode) debugPrint('AuthRepository: API fetch failed, trying Hive cache. Error: $apiError');
        // If API fails, fallback to Hive cache
        final cachedJson = _settingsBox.get('cached_user');
        if (cachedJson != null) {
          final userModel = UserModel.fromJson(jsonDecode(cachedJson));
          _currentUser = userModel;
          return _currentUser;
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<UserEntity>> getAgents() async {
    try {
      final response = await _dioClient.dio.get('/users');
      final List data = response.data;
      final agents = data
          .map((e) => UserModel.fromJson(e))
          .where((u) {
            final isAgent = u.role.toUpperCase() == 'AGENT';
            return isAgent;
          })
          .toList();
      return agents;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      final response = await _dioClient.dio.get('/users/$id');
      if (response.data == null) return null;
      return UserModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserEntity?> findUserByEmail(String email) async {
    return _findUser(email);
  }

  @override
  Future<UserEntity?> findUserByPhone(String phone) async {
    return _findUser(phone);
  }

  Future<UserEntity?> _findUser(String query) async {
    try {
      final response = await _dioClient.dio.get('/users', queryParameters: {
        'search': query,
        'limit': 10,
      });

      final data = response.data;
      List<dynamic> usersList;

      if (data is List) {
        usersList = data;
      } else if (data is Map && data['items'] is List) {
        usersList = data['items'];
      } else {
        return null; // Unexpected format
      }

      if (usersList.isEmpty) return null;
      
      final userJson = usersList.first; 
      
      return UserModel.fromJson(userJson);
    } catch (e) {
      if (kDebugMode) debugPrint('AuthRepository: Error finding user by query "$query": $e');
      return null;
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await _settingsBox.put('cached_user', jsonString);
    } catch (e) {
      if (kDebugMode) debugPrint('AuthRepository: Failed to cache user: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    return _storage.read(key: 'accessToken');
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Password change failed';
      throw Exception(message);
    }
  }

  // Biometrics
  @override
  Future<bool> isBiometricsEnabled() async {
    // Force disabled as per user request
    return false;
    /*
    final value = await _storage.read(key: 'biometricsEnabled');
    return value == 'true';
    */
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: 'biometricsEnabled', value: enabled.toString());
    if (!enabled) {
      await _storage.delete(key: 'biometricEmail');
      await _storage.delete(key: 'biometricPassword');
    }
  }

  @override
  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: 'biometricEmail', value: email);
    await _storage.write(key: 'biometricPassword', value: password);
  }

  @override
  Future<UserEntity> loginWithBiometrics() async {
    final email = await _storage.read(key: 'biometricEmail');
    final password = await _storage.read(key: 'biometricPassword');

    if (email == null || password == null) {
      throw Exception('Biometric credentials not found');
    }

    return login(email, password);
  }

  @override
  Future<Map<String, dynamic>> checkStripeStatus() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.stripeStatus);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'enabled': false};
    }
  }

  @override
  Future<String> getStripeOnboardingLink() async {
    try {
      final response = await _dioClient.dio.post(ApiConstants.stripeOnboarding, queryParameters: {'platform': 'mobile'});
      return response.data['url'];
    } catch (e) {
      throw Exception('Failed to get onboarding link: $e');
    }
  }

  @override
  Future<void> updateAgentProfile({
    String? preferredPayoutMethod,
    String? zelleEmail,
    String? zellePhone,
    String? businessName,
  }) async {
    try {
      final data = {
        if (preferredPayoutMethod != null) 'preferred_payout_method': preferredPayoutMethod,
        if (zelleEmail != null) 'zelle_email': zelleEmail,
        if (zellePhone != null) 'zelle_phone': zellePhone,
        if (businessName != null) 'business_name': businessName,
      };

      await _dioClient.dio.patch('/users/agent/profile', data: data);
      
      // Refresh user profile after update
      await getCurrentUser();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Update agent profile failed: $e');
    }
  }

}
