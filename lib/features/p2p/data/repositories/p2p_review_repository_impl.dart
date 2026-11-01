import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_review.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_review_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

class P2pReviewRepositoryImpl implements P2pReviewRepository {
  final DioClient _client;

  P2pReviewRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<P2pReview> createReview({
    required String reviewedUserId,
    required String shipmentRequestId,
    required int rating,
    String? comment,
    Map<String, dynamic>? trustFlags,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pReviews,
        data: {
          'reviewedUserId': reviewedUserId,
          'shipmentRequestId': shipmentRequestId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (trustFlags != null) 'trustFlags': trustFlags,
        },
      );
      return P2pReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pReview>> getCourierReviews(String courierId) async {
    try {
      final response = await _client.dio
          .get(ApiConstants.p2pReviewsForCourier(courierId));
      final raw = response.data;
      final list = raw is List
          ? raw
          : (raw is Map
              ? (raw['items'] ?? raw['reviews'] ?? raw['data']) as List? ?? const []
              : const []);
      return list
          .whereType<Map>()
          .map((e) => P2pReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pReview>> listReviews({
    String? reviewedUserId,
    String? reviewerUserId,
    String? shipmentRequestId,
    int? minRating,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.p2pReviews,
        queryParameters: {
          if (reviewedUserId != null) 'reviewedUserId': reviewedUserId,
          if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
          if (shipmentRequestId != null) 'shipmentRequestId': shipmentRequestId,
          if (minRating != null) 'minRating': minRating,
        },
      );
      final list = response.data as List;
      return list
          .map((e) => P2pReview.fromJson(e as Map<String, dynamic>))
          .toList();
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
        throw P2pException.notFound('Review');
      case 409:
        throw P2pException.conflict(message);
      default:
        throw P2pException.unknown(message);
    }
  }
}
