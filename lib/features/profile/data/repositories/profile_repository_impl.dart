import 'dart:convert';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/features/profile/data/models/user_profile_model.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final DioClient _dioClient;

  ProfileRepositoryImpl(this._dioClient);

  @override
  Future<UserProfileEntity> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      final rawData = response.data;
      final Map<String, dynamic> raw;
      if (rawData is Map<String, dynamic>) {
        raw = rawData;
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        raw = jsonDecode(rawData) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response format from profile endpoint');
      }
      return UserProfileModel.fromJson(raw);
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfileEntity profile) async {
    try {
      // 1. Send basic user fields to /users/profile
      final basicData = {
        'fullName': profile.fullName,
        'phone': profile.phoneNumber,
      };
      
        basicData['profile_image_url'] = profile.profileImageUrl;
      
      await _dioClient.dio.patch(ApiConstants.profile, data: basicData);
      
      // 2. Send agent-specific fields (payout info) to /users/agent/profile
      // Only do this if we actually have agent fields to avoid errors for pure customers.
      // Easiest is to always try, or check if they are provided. For agents, these usually exist.
      if (profile.preferredPayoutMethod != null || profile.zelleEmail != null || profile.zellePhone != null) {
          final agentData = {
              if (profile.preferredPayoutMethod != null) 'preferred_payout_method': profile.preferredPayoutMethod,
              if (profile.zelleEmail != null) 'zelle_email': profile.zelleEmail,
              if (profile.zellePhone != null) 'zelle_phone': profile.zellePhone,
          };
          
          await _dioClient.dio.patch('${ApiConstants.baseUrl}/users/agent/profile', data: agentData);
      }
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  @override
  Future<void> submitChangeRequest(Map<String, dynamic> changes) async {
    try {
      await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/users/profile/change-request',
        data: {'changes': changes},
      );
    } catch (e) {
      throw Exception('Submit change request failed: $e');
    }
  }
}
