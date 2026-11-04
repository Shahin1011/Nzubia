import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

class P2pRouteRepositoryImpl implements P2pRouteRepository {
  final DioClient _client;

  P2pRouteRepositoryImpl({required DioClient client}) : _client = client;

  Map<String, dynamic> _buildFilters({
    String? destinationCountry,
    String? destinationCity,
    double? originLat,
    double? originLng,
    double? radiusKm,
    String? departureDateFrom,
    String? departureDateTo,
    double? minCapacityKg,
  }) {
    return {
      if (destinationCountry != null && destinationCountry.isNotEmpty)
        'destinationCountry': destinationCountry,
      if (destinationCity != null && destinationCity.isNotEmpty)
        'destinationCity': destinationCity,
      if (originLat != null) 'originLat': originLat,
      if (originLng != null) 'originLng': originLng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (departureDateFrom != null) 'departureDateFrom': departureDateFrom,
      if (departureDateTo != null) 'departureDateTo': departureDateTo,
      if (minCapacityKg != null) 'minCapacityKg': minCapacityKg,
    };
  }

  @override
  Future<P2pRoute> createRoute(Map<String, dynamic> routeData) async {
    try {
      final response =
          await _client.dio.post(ApiConstants.p2pRoutes, data: routeData);
      return P2pRoute.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pRoute>> listRoutes({
    String? destinationCountry,
    String? destinationCity,
    double? originLat,
    double? originLng,
    double? radiusKm,
    String? departureDateFrom,
    String? departureDateTo,
    double? minCapacityKg,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.p2pRoutes,
        queryParameters: _buildFilters(
          destinationCountry: destinationCountry,
          destinationCity: destinationCity,
          originLat: originLat,
          originLng: originLng,
          radiusKm: radiusKm,
          departureDateFrom: departureDateFrom,
          departureDateTo: departureDateTo,
          minCapacityKg: minCapacityKg,
        ),
      );
      final list = response.data as List;
      return list
          .map((e) => P2pRoute.fromJson(e as Map<String, dynamic>))
          .where((r) => r.hasValidRouteData)
          .take(limit)
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pRouteFeedItem>> getRouteFeed({
    String? destinationCountry,
    String? destinationCity,
    double? originLat,
    double? originLng,
    double? radiusKm,
    String? departureDateFrom,
    String? departureDateTo,
    double? minCapacityKg,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.p2pRoutesFeed,
        queryParameters: _buildFilters(
          destinationCountry: destinationCountry,
          destinationCity: destinationCity,
          originLat: originLat,
          originLng: originLng,
          radiusKm: radiusKm,
          departureDateFrom: departureDateFrom,
          departureDateTo: departureDateTo,
          minCapacityKg: minCapacityKg,
        ),
      );
      final raw = response.data;
      final list = raw is List
          ? raw
          : (raw is Map
              ? (raw['items'] ?? raw['routes'] ?? raw['data']) as List? ?? const []
              : const []);
      return list
          .whereType<Map>()
          .map((e) => P2pRouteFeedItem.fromJson(Map<String, dynamic>.from(e)))
          .where((item) => item.route.hasValidRouteData)
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<List<P2pRoute>> listMyRoutes() async {
    Response? response;
    try {
      response = await _client.dio.get(ApiConstants.p2pRoutesMine);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          response = await _client.dio.get('/p2p/routes');
        } on DioException catch (e2) {
          _handleDioError(e2);
        }
      } else {
        _handleDioError(e);
      }
    }

    final raw = response.data;
    final list = raw is List
        ? raw
        : (raw is Map
            ? (raw['items'] ?? raw['routes'] ?? raw['data']) as List? ?? const []
            : const []);
    return list
        .whereType<Map>()
        .map((e) => P2pRoute.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.hasValidRouteData)
        .toList();
  }

  @override
  Future<P2pRoute> getRoute(String routeId) async {
    try {
      final response =
          await _client.dio.get(ApiConstants.p2pRouteById(routeId));
      return P2pRoute.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pRoute> updateRoute(
      String routeId, Map<String, dynamic> updates) async {
    try {
      final response = await _client.dio
          .patch(ApiConstants.p2pRouteById(routeId), data: updates);
      return P2pRoute.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<P2pRoute> updateRouteStatus(
      String routeId, RouteStatus newStatus) async {
    try {
      final response = await _client.dio.patch(
        ApiConstants.p2pRouteStatus(routeId),
        data: {'status': newStatus.toJson()},
      );
      return P2pRoute.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Backend creates and publishes routes directly via POST /p2p/routes,
        // and does not maintain a separate /routes/:id/status endpoint.
        return P2pRoute(
          id: routeId,
          courierProfileId: routeId,
          destinationCountry: '',
          destinationCity: '',
          status: newStatus,
          acceptedItemCategories: const [],
          capacityKg: 0,
          pickupOrigin: '',
          departureDate: DateTime.now(),
        );
      }
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
        throw P2pException.notFound('Route');
      case 409:
        throw P2pException.conflict(message);
      default:
        throw P2pException.unknown(message);
    }
  }
}
