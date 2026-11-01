import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity> getProfile();
  Future<void> updateProfile(UserProfileEntity profile);
  Future<void> submitChangeRequest(Map<String, dynamic> changes);
  Future<String> uploadProfileImage(String filePath);
}
