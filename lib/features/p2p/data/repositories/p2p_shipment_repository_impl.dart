import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_offer.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

class P2pShipmentRepositoryImpl implements P2pShipmentRepository {
  final DioClient _client;

  P2pShipmentRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<P2pShipmentRequest> createRequest(
      Map<String, dynamic> requestData) async {
    try {
      final response = await _client.dio
          .post(ApiConstants.p2pShipments, data: requestData);
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pShipmentRequest>> listRequests() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pShipments);
      final list = response.data as List;
      return list
          .map((e) =>
              P2pShipmentRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> getRequest(String requestId) async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pShipmentById(requestId));
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.dio
          .patch(ApiConstants.p2pShipmentById(requestId), data: updates);
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> updateStatus(
    String requestId,
    ShipmentRequestStatus newStatus,
  ) async {
    try {
      final response = await _client.dio.patch(
        ApiConstants.p2pShipmentStatus(requestId),
        data: {'status': newStatus.toJson()},
      );
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pRouteFeedItem>> matchRequest(String requestId) async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pShipmentMatch(requestId));
      final list = response.data as List;
      return list
          .map((e) => P2pRouteFeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pOffer>> listOffers(String requestId) async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pShipmentOffers(requestId));
      final list = response.data as List;
      return list
          .map((e) => P2pOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pOffer> createOffer(
      String requestId, Map<String, dynamic> offerData) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pShipmentOffers(requestId),
        data: offerData,
      );
      return P2pOffer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pOffer> acceptOffer(String offerId) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pOfferAccept(offerId));
      return P2pOffer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pOffer> rejectOffer(String offerId) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pOfferReject(offerId));
      return P2pOffer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> reserveShipment(String requestId) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pShipmentReserve(requestId));
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> recordHandoff(String requestId) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pShipmentHandoff(requestId));
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> recordPickup(
    String shipmentId, {
    required String pickupConfirmationCode,
    required List<String> proofPhotoUrls,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pShipmentPickup(shipmentId),
        data: {
          'pickupConfirmationCode': pickupConfirmationCode,
          'pickupPhotoUrls': proofPhotoUrls,
        },
      );
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> confirmDelivery(
    String requestId, {
    List<String>? proofPhotoUrls,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pShipmentDeliver(requestId),
        data: (proofPhotoUrls != null && proofPhotoUrls.isNotEmpty)
            ? {'proofOfDeliveryUrls': proofPhotoUrls}
            : null,
      );
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> sendCourierRequest(
    String shipmentId,
    String routeId, {
    String? message,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.p2pShipmentCourierRequests(shipmentId),
        data: {
          'routeId': routeId,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        },
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pCourierRequest>> listCourierRequests(String shipmentId) async {
    try {
      final response = await _client.dio
          .get(ApiConstants.p2pShipmentCourierRequests(shipmentId));
      final list = response.data as List;
      return list
          .map((e) => P2pCourierRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pShipmentRequest>> listAssignedShipments() async {
    try {
      final response = await _client.dio.get(
        ApiConstants.p2pShipments,
        queryParameters: {'role': 'courier'},
      );
      final raw = response.data;
      final list = raw is List ? raw : (raw as Map<String, dynamic>)['items'] as List? ?? const [];
      final activeStatuses = {
        'HANDOFF_PENDING',
        'IN_TRANSIT',
        'DELIVERED',
      };
      return list
          .map((e) => P2pShipmentRequest.fromJson(e as Map<String, dynamic>))
          .where((s) => activeStatuses.contains(s.status.toJson()))
          .toList(growable: false);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pShipmentRequest>> listMyDisputedShipments() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMeDisputes);
      final list = response.data as List;
      return list
          .map((e) => P2pShipmentRequest.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pShipmentRequest>> fetchNearbyShipments() async {
    try {
      final response = await _client.dio.get(ApiConstants.p2pCourierMeNearbyShipments);
      final list = response.data as List;
      return list
          .map((e) => P2pShipmentRequest.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> completeShipment(String shipmentId) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pShipmentComplete(shipmentId));
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pShipmentRequest> raiseDispute(
    String shipmentId, {
    required String reason,
    List<String>? evidenceUrls,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.p2pShipmentDispute(shipmentId),
        data: {
          'reason': reason,
          if (evidenceUrls != null && evidenceUrls.isNotEmpty)
            'evidenceUrls': evidenceUrls,
        },
      );
      return P2pShipmentRequest.fromJson(
        response.data as Map<String, dynamic>,
      );
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
        throw P2pException(statusCode: 404, message: message);
      case 409:
        throw P2pException.conflict(message);
      default:
        throw P2pException.unknown(message);
    }
  }
}
