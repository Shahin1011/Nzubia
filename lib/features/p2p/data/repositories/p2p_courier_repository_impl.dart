import 'dart:io';
import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

class P2pCourierRepositoryImpl implements P2pCourierRepository {
  final DioClient _client;

  P2pCourierRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<P2pCourierProfile?> getMyProfile() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMe);
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
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
    try {
      final response = await _client.dio.patch(
        ApiConstants.p2pCourierMeAvailability,
        data: {'isActive': isActive},
      );
      return P2pCourierProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
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
  Future<P2pStripeConnectResult> initiateStripeConnect() async {
    try {
      final response = await _client.dio.post(ApiConstants.p2pCourierMeStripeConnect);
      return P2pStripeConnectResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pStripeConnectStatus> getStripeConnectStatus() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMeStripeStatus);
      return P2pStripeConnectStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<String> getStripeDashboardLink() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMeStripeDashboard);
      final body = response.data as Map<String, dynamic>;
      return body['url'] as String;
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
