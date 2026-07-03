import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/shipment_model.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:customer_nzubia_global/core/network/paginated_result.dart';
import 'package:intl/intl.dart';

class ShipmentRepositoryImpl implements ShipmentRepository {
  final DioClient _dioClient;

  ShipmentRepositoryImpl(this._dioClient);


  @override
  Future<ShipmentEntity> createShipment({
    required String origin,
    required String destination,
    required List<CargoItemEntity> items,
    required String serviceLevel,
    required List<String> serviceTypes,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    String dimensionUnit = 'cm',
    String? agentId,
    String? recipientName,
    String? recipientEmail,
    String? recipientPhone,
    String? recipientAddress,
    bool isInsuranceRequested = false,
    double totalItemValue = 0,
    required bool legalGoodsTermsAccepted,
  }) async {
    try {
      final originCountry = origin.contains(',') ? origin.split(',').last.trim() : '';
      final destCountry = destination.contains(',') ? destination.split(',').last.trim() : '';

      final data = {
        'origin': {
          'address': origin,
          'country': originCountry,
        },
        'destination_country': destCountry,
        'destination_meta': {
          'address': destination,
          'country': destCountry,
        },
        // cargo_meta matches CreateShipmentDto
        'cargo_meta': {
           'description': items.isNotEmpty ? items.first.description : 'General Cargo',
           'weight': items.isNotEmpty ? items.first.weight : 0,
           'dimensions': items.isNotEmpty ? {
             'length': items.first.length,
             'width': items.first.width,
             'height': items.first.height,
             'unit': dimensionUnit,
           } : null,
           'service_types': serviceTypes,
           'category': items.isNotEmpty ? items.first.category : 'GENERAL',
           'is_hazardous': items.isNotEmpty ? items.first.isFragile || items.first.isPerishable : false,
           'quantity': items.isNotEmpty ? items.first.quantity : 1,
           'images': items.isNotEmpty ? items.first.imageUrls : [],
        },
        'service_level': serviceLevel,
        'pickup_date': pickupDate != null ? DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(pickupDate.toUtc()) : null,
        'delivery_date': deliveryDate != null ? DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(deliveryDate.toUtc()) : null,
        'recipient_name': recipientName,
        'recipient_email': recipientEmail,
        'recipient_phone': recipientPhone,
        'recipient_address': recipientAddress,
        'insurance_requested': isInsuranceRequested, // Added field
        'total_item_value': totalItemValue,
        'legal_goods_terms_accepted': legalGoodsTermsAccepted,
      };

      final response = await _dioClient.dio.post(ApiConstants.shipments, data: data);
      return ShipmentModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Create shipment failed: $e');
    }
  }

  @override
  Future<ShipmentEntity> updateShipment(String id, {
    List<CargoItemEntity>? items,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (items != null && items.isNotEmpty) {
        data['cargo_meta'] = {
           'description': items.first.description,
           'weight': items.first.weight,
           // service_types likely needed if validated, but creating optional in backend update?
           // Backend DTO `UpdateShipmentDto` extends `CreateShipmentDto` via PartialType.
           // `cargo_meta` is ValidateNested. If we send partial cargo_meta it might fail validation if nested fields are required.
           // `CargoMetaDto` has required `service_types`. We should probably fetch existing or pass it if known.
           // For now, let's assume we preserve service_types if possible or default.
           // Since `items` in frontend don't store `service_types` directly (it's on shipment level),
           // we might need to change signature or just send defaults.
          //  'service_types': ['SEA'], // Fallback or strict requirement
           'category': items.first.category,
           'images': items.first.imageUrls,
        };
      }

      final response = await _dioClient.dio.patch('${ApiConstants.shipments}/$id', data: data);
      return ShipmentModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Update shipment failed: $e');
    }
  }

  @override
  Future<PaginatedResult<ShipmentEntity>> getShipments({
    String? status,
    String? searchQuery,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _dioClient.dio.get(
        ApiConstants.shipments,
        queryParameters: queryParams,
      );

      // Robust Parsing: Handle legacy List response or new Paginated Map response
      List<ShipmentModel> dataList;
      PaginationMeta meta;

      if (response.data is List) {
        // Legacy: API returned just a list
        final list = response.data as List;
        dataList = list.map((e) => ShipmentModel.fromJson(e)).toList();
        meta = PaginationMeta(
          total: list.length,
          page: page,
          limit: limit,
          lastPage: 1, // Assume single page
        );
      } else {
        // New: API returned { data: [...], meta: {...} }
        // If data is just the map itself or inside 'data' key?
        // Based on backend service: { data: [...], meta: {...} }
        final responseData = response.data;
        if (responseData['data'] is List) {
           dataList = (responseData['data'] as List)
              .map((e) => ShipmentModel.fromJson(e))
              .toList();
           meta = PaginationMeta.fromJson(responseData['meta']);
        } else {
           // Fallback/Error?
           throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }
      }

      return PaginatedResult(data: dataList, meta: meta);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Get shipments failed: $e');
    }
  }
  @override
  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      // Ensure ApiConstants.shipments doesn't end with slash, usually 'shipments'
      final response = await _dioClient.dio.post('${ApiConstants.shipments}/upload/image', data: formData);

      if (response.data != null && response.data is Map && response.data.containsKey('url')) {
        return response.data['url'];
      }
      throw Exception('Invalid response from upload endpoint');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  @override
  Future<void> uploadDocument(String shipmentId, String filePath, String type) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'type': type,
      });

      await _dioClient.dio.post('${ApiConstants.shipments}/$shipmentId/documents', data: formData);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Document upload failed: $e');
    }
  }

  @override
  Future<ShipmentEntity> getShipment(String id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.shipments}/$id');
      return ShipmentModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Get shipment details failed: $e');
    }
  }

  @override
  Future<void> deleteShipment(String id) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.shipments}/$id');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Delete shipment failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> trackShipment(String trackingNumber) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.shipments}/track/$trackingNumber');
      return response.data;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Track shipment failed: $e');
    }
  }
  @override
  Future<void> updateStatus(String id, String status, {String? description, List<String>? imageUrls, String? pickupPin, String? actor}) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
        if (description != null && description.isNotEmpty) 'description': description,
        if (pickupPin != null && pickupPin.isNotEmpty) 'pickup_pin': pickupPin,
        if (actor != null && actor.isNotEmpty) 'actor': actor,
      };

      if (imageUrls != null && imageUrls.isNotEmpty) {
        if (status == 'PICKED_UP') {
          data['pickup_images'] = imageUrls;
        } else if (status == 'DELIVERED') {
          data['pod_images'] = imageUrls;
        } else {
          data['image_urls'] = imageUrls; // Default for others
        }
      }

      // Use events endpoint to support image URLs and robust tracking
      await _dioClient.dio.post('${ApiConstants.shipments}/$id/events', data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update shipment status: $e');
    }
  }

  @override
  Future<void> requestInfo(String id, String message) async {
    try {
      final data = {'message': message};
      await _dioClient.dio.post('${ApiConstants.shipments}/$id/request-info', data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to send info request: $e');
    }
  }

  @override
  Future<void> submitReview(String shipmentId, int rating, String comment) async {
    try {
      final data = {
        'shipment_id': shipmentId,
        'rating': rating,
        'comment': comment,
      };
      // Endpoint exposed in ReviewsController is POST /reviews
      await _dioClient.dio.post('/reviews', data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  @override
  Future<void> confirmReceipt(String id) async {
    try {
      await _dioClient.dio.post('${ApiConstants.shipments}/$id/confirm-receipt');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to confirm receipt: $e');
    }
  }
}
