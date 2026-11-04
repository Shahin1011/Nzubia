import 'dart:io';
import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';

class P2pCourierRepositoryImpl implements P2pCourierRepository {
  final DioClient _client;
  final AuthRepository? _authRepository;

  P2pCourierRepositoryImpl({
    required DioClient client,
    AuthRepository? authRepository,
  })  : _client = client,
        _authRepository = authRepository;

  @override
  Future<P2pCourierProfile?> getMyProfile() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMe);
      if (response.data == null) return null;
      if (response.data is! Map<String, dynamic>) return null;

      final data = response.data as Map<String, dynamic>;

      // Check if backend wrapped courier profile inside 'courier' or 'profile'
      final hasCourierWrapper =
          data['courier'] is Map<String, dynamic> || data['profile'] is Map<String, dynamic>;

      // Check if there are courier-specific attributes in the payload
      final hasCourierSpecificField = data['courier_id'] != null ||
          data['courierId'] != null ||
          data['service_radius_km'] != null ||
          data['serviceRadiusKm'] != null ||
          data['accepted_categories'] != null ||
          data['acceptedCategories'] != null;

      // Check role from API data or current auth session
      final rawRole = (data['role'] ??
              data['user']?['role'] ??
              _authRepository?.currentUser?.role)
          ?.toString()
          .toUpperCase()
          .trim();

      // If it's a standard User entity with role != 'COURIER' (e.g. CUSTOMER, AGENT, ADMIN)
      // and lacks any courier profile/fields, this user is NOT a courier.
      if (!hasCourierWrapper && !hasCourierSpecificField) {
        if (rawRole != null && rawRole != 'COURIER') {
          return null;
        }
      }

      return P2pCourierProfile.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierProfile> applyAsCourier(
      Map<String, dynamic> applicationData) async {
    try {
      final response = await _client.dio
          .post(ApiConstants.p2pCourierMe, data: applicationData);
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierProfile> submitForReview() async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pCourierMeSubmit);
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<String> uploadDocument(String localPath, String folder) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath,
            filename: File(localPath).uri.pathSegments.last),
        'folder': folder,
      });
      final response = await _client.dio.post('/files/upload', data: formData);
      return (response.data as Map<String, dynamic>)['url'] as String;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> submitKyc({
    required Map<String, dynamic> identity,
    required List<Map<String, dynamic>> documentUrls,
  }) async {
    try {
      await _client.dio.patch(ApiConstants.p2pCourierMeKyc, data: {
        'identity': identity,
        'document_urls': documentUrls,
      });
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyBackgroundCheck({
    String? firstName,
    String? lastName,
    String? dob,
    String? state,
    Map<String, dynamic>? documentUrls,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        if (dob != null && dob.isNotEmpty) 'dob': dob,
        if (state != null && state.isNotEmpty) 'state': state,
        if (documentUrls != null && documentUrls.isNotEmpty)
          'documentUrls': documentUrls,
      };

      final response = await _client.dio.post(
        ApiConstants.p2pCourierBackgroundCheck,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == 'CLEARED' || data['success'] == true) {
          try {
            await _authRepository?.getCurrentUser();
          } catch (_) {}
        }
        return data;
      }
      return {'success': false, 'status': 'UNKNOWN', 'message': 'Unexpected response format'};
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierProfile> updateProfile(
      Map<String, dynamic> updates) async {
    try {
      final response = await _client.dio
          .patch(ApiConstants.p2pCourierMe, data: updates);
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierProfile> setAvailability({required bool isActive}) async {
    Response? response;
    // Sync with backend courier location & availability endpoint
    try {
      await _client.dio.patch(
        ApiConstants.courierLocation,
        data: {'is_available': isActive},
      );
    } catch (_) {}

    try {
      response = await _client.dio.patch(
        ApiConstants.p2pCourierMe,
        data: {'is_available': isActive},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to /users/profile
        try {
          response = await _client.dio.patch(
            ApiConstants.profile,
            data: {'is_available': isActive},
          );
        } on DioException catch (e2) {
          _handleDioError(e2);
        }
      } else {
        _handleDioError(e);
      }
    }

    if (response.data is Map<String, dynamic>) {
      final resData = response.data as Map<String, dynamic>;
      return P2pCourierProfile.fromJson(resData);
    }

    final current = await getMyProfile();
    if (current != null) {
      return current.copyWith(isActive: isActive);
    }

    throw const P2pException(
      statusCode: 500,
      message: 'Failed to update courier availability',
    );
  }

  @override
  Future<P2pCourierStatus> getMyStatus() async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pCourierMeStatus);
      return P2pCourierStatus.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pCourierProfile>> listPublicCouriers({
    String? destinationCountry,
    String? destinationCity,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.p2pCouriers,
        queryParameters: {
          if (destinationCountry != null && destinationCountry.isNotEmpty)
            'destinationCountry': destinationCountry,
          if (destinationCity != null && destinationCity.isNotEmpty)
            'destinationCity': destinationCity,
          'limit': limit,
        },
      );
      final list = response.data as List;
      return list
          .map((e) => P2pCourierProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierProfile> getPublicProfile(String courierId) async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pCourierById(courierId));
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback 1: Query user endpoint: GET /users/$courierId
        try {
          final userRes = await _client.dio.get('/users/$courierId');
          if (userRes.data is Map) {
            return P2pCourierProfile.fromJson(
              Map<String, dynamic>.from(userRes.data as Map),
            );
          }
        } catch (_) {}

        // Fallback 2: Check listPublicCouriers
        try {
          final couriers = await listPublicCouriers();
          final found = couriers.firstWhere(
            (c) => c.id == courierId || c.userId == courierId,
          );
          return found;
        } catch (_) {}
      }
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierReputation> getReputation(String courierId) async {
    try {
      final response = await _client.dio
          .get(ApiConstants.p2pCourierReputation(courierId));
      return P2pCourierReputation.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const P2pCourierReputation(
          averageRating: 0.0,
          reviewCount: 0,
          recentReviews: [],
        );
      }
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pCourierRequest>> listIncomingRequests() async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pCourierMeRequests);
      final list = response.data as List;
      return list
          .map((e) => P2pCourierRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierRequest> acceptCourierRequest(
    String requestId, {
    double? offerAmountUsd,
    String? message,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pCourierRequestAccept(requestId),
        data: {
          if (offerAmountUsd != null) 'offerAmountUsd': offerAmountUsd,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      // Accept returns { courier_request: {...}, offer: {...} }
      final body = response.data as Map<String, dynamic>;
      return P2pCourierRequest.fromJson(
          body['courier_request'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pCourierRequest> declineCourierRequest(
    String requestId, {
    String? reason,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pCourierRequestDecline(requestId),
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return P2pCourierRequest.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pStripeConnectResult> initiateStripeConnect({
    String? country,
    String? returnUrl,
    String? refreshUrl,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.paymentsConnectOnboarding,
        data: {
          if (country != null && country.isNotEmpty) 'country': country,
          if (returnUrl != null && returnUrl.isNotEmpty) 'return_url': returnUrl,
          if (refreshUrl != null && refreshUrl.isNotEmpty) 'refresh_url': refreshUrl,
        },
      );
      return P2pStripeConnectResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pStripeConnectStatus> getStripeConnectStatus() async {
    try {
      final response =
          await _client.dio.get(ApiConstants.paymentsConnectStatus);
      return P2pStripeConnectStatus.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<String> getStripeDashboardLink() async {
    try {
      final result = await initiateStripeConnect();
      return result.onboardingUrl;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    final code = e.response?.statusCode ?? 0;
    final raw = e.response?.data;
    final message = (raw is Map && raw['message'] is String)
        ? raw['message'] as String
        : (raw is Map && raw['message'] is List)
            ? (raw['message'] as List).join(', ')
            : e.message ?? 'Unknown error';

    switch (code) {
      case 400:
        throw P2pException.badRequest(message);
      case 401:
        throw P2pException.unauthorized();
      case 403:
        throw P2pException.forbidden(message);
      case 404:
        throw P2pException.notFound('Courier');
      case 409:
        throw P2pException.conflict(message);
      default:
        throw P2pException.unknown(message);
    }
  }
}
