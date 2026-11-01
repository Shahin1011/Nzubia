import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/features/profile/data/models/user_profile_model.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final DioClient _dioClient;
  Box get _settingsBox => Hive.box('settings');

  ProfileRepositoryImpl(this._dioClient);

  @override
  Future<UserProfileEntity> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      final rawData = response.data;
      final Map<String, dynamic> raw;
      if (rawData is Map<String, dynamic>) {
        raw = Map<String, dynamic>.from(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        raw = Map<String, dynamic>.from(jsonDecode(rawData) as Map);
      } else {
        throw Exception('Unexpected response format from profile endpoint');
      }

      // Merge with locally cached profile if backend returned empty fields
      final cachedProfileStr = _settingsBox.get('cached_profile_details');
      if (cachedProfileStr != null) {
        try {
          final cached = jsonDecode(cachedProfileStr) as Map<String, dynamic>;
          final hasName = (raw['full_name'] ?? raw['fullName'] ?? raw['first_name'] ?? '').toString().trim().isNotEmpty;
          if (!hasName && (cached['fullName'] ?? '').toString().trim().isNotEmpty) {
            raw['full_name'] = cached['fullName'];
          }
          final hasPhone = (raw['phone'] ?? '').toString().trim().isNotEmpty;
          if (!hasPhone && (cached['phoneNumber'] ?? '').toString().trim().isNotEmpty) {
            raw['phone'] = cached['phoneNumber'];
          }
          final hasPic = (raw['profile_image_url'] ?? raw['profile_picture_url'] ?? raw['avatar_url'] ?? '').toString().trim().isNotEmpty;
          if (!hasPic && (cached['profileImageUrl'] ?? '').toString().trim().isNotEmpty) {
            raw['profile_image_url'] = cached['profileImageUrl'];
          }
        } catch (_) {}
      }

      return UserProfileModel.fromJson(raw);
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': 'avatars',
      });
      final response = await _dioClient.dio.post('/files/upload', data: formData);
      if (response.data is Map && response.data['url'] != null) {
        final url = response.data['url'] as String;
        await _settingsBox.put('local_avatar_path', filePath);
        return url;
      }
      throw Exception('Upload response missing url');
    } catch (e) {
      throw Exception('Profile photo upload failed: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfileEntity profile) async {
    try {
      // 0. Cache locally immediately so user updates persist in UI
      final cacheData = {
        'fullName': profile.fullName,
        'phoneNumber': profile.phoneNumber,
        'profileImageUrl': profile.profileImageUrl,
      };
      await _settingsBox.put('cached_profile_details', jsonEncode(cacheData));

      // 1. Send basic user fields to /users/profile
      final parts = profile.fullName.trim().split(' ');
      final fName = parts.isNotEmpty ? parts.first : '';
      final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final basicData = {
        'fullName': profile.fullName,
        'full_name': profile.fullName,
        'first_name': fName,
        'last_name': lName,
        'phone': profile.phoneNumber,
        'profile_image_url': profile.profileImageUrl,
        'profile_picture_url': profile.profileImageUrl,
      };
      
      await _dioClient.dio.patch(ApiConstants.profile, data: basicData);
      if (profile.id.isNotEmpty) {
        try {
          await _dioClient.dio.patch('/users/${profile.id}', data: basicData);
        } catch (_) {}
      }
      
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
