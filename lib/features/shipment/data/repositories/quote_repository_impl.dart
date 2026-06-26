import 'package:flutter/foundation.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/features/shipment/data/models/quote_model.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/quote_repository.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final DioClient _dioClient;

  QuoteRepositoryImpl(this._dioClient);

  @override
  Future<List<QuoteEntity>> getQuotesForShipment(String shipmentId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.quotes,
        queryParameters: {'shipmentId': shipmentId},
      );

      final dynamic rawData = response.data;
      List<dynamic> list;

      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData.containsKey('data') && rawData['data'] is List) {
        list = rawData['data'];
      } else {
        if (kDebugMode) debugPrint('Quotes API returned unexpected format: $rawData');
        return [];
      }

      return list.map((e) {
        try {
          return QuoteModel.fromJson(e);
        } catch (parseError) {
          if (kDebugMode) debugPrint('Error parsing individual quote: $parseError\nData: $e');
          return null; // Skip invalid
        }
      }).whereType<QuoteModel>().toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Get quotes failed: $e');
      throw Exception('Get quotes failed: $e');
    }
  }

  @override
  Future<List<QuoteEntity>> getQuotes() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.quotes);

      if (response.data is! List) {
        if (kDebugMode) debugPrint('Quotes API returned non-list data: ${response.data}');
        return [];
      }

      return (response.data as List).map((e) {
        try {
          return QuoteModel.fromJson(e);
        } catch (parseError) {
          if (kDebugMode) debugPrint('Error parsing individual quote: $parseError\nData: $e');
          return null;
        }
      }).whereType<QuoteModel>().toList();
      } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('Error fetching quotes: $e');
      if (kDebugMode) debugPrint(stackTrace);
      return [];
    }
  }

  @override
  Future<void> acceptQuote(String quoteId) async {
    try {
      await _dioClient.dio.post(
        '${ApiConstants.quotes}/$quoteId/accept',
      );
    } catch (e) {
      throw Exception('Accept quote failed: $e');
    }
  }

  @override
  Stream<List<QuoteEntity>> watchQuotes(String shipmentId) {
    // Polling every 10 seconds for MVP
    return Stream.periodic(const Duration(seconds: 10), (_) {
      return getQuotesForShipment(shipmentId);
    }).asyncMap((event) async => await event);
  }

  @override
  Future<void> createQuote({
    required String shipmentId,
    required double amount,
    required String notes,
    required String method,
    required DateTime deliveryDate,
    String? payoutMethod,
    String? insuranceType,
    String? insuranceName,
    double? insuranceFee,
    required bool legalGoodsTermsAccepted,
  }) async {
    try {
      final data = {
        "shipment_id": shipmentId,
        "amount": amount,
        "currency": "USD",
        "shipping_method": method,
        "estimated_delivery_date": deliveryDate.toIso8601String(),
        "notes": notes,
        "payout_method": payoutMethod,
        "insurance_type": insuranceType,
        "insurance_name": insuranceName,
        "insurance_fee": insuranceFee,
        "legal_goods_terms_accepted": legalGoodsTermsAccepted,
      };

      await _dioClient.dio.post(ApiConstants.quotes, data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('Create quote failed: $e');
      throw Exception('Create quote failed: $e');
    }
  }
  @override
  Future<void> updateQuote({
    required String quoteId,
    required double amount,
    required String notes,
    required String method,
    required DateTime deliveryDate,
    String? payoutMethod,
    String? insuranceType,
    String? insuranceName,
    double? insuranceFee,
  }) async {
    try {
      final data = {
        "amount": amount,
        "currency": "USD",
        "shipping_method": method,
        "estimated_delivery_date": deliveryDate.toIso8601String(),
        "notes": notes,
        "payout_method": payoutMethod,
        "insurance_type": insuranceType,
        "insurance_name": insuranceName,
        "insurance_fee": insuranceFee,
      };

      await _dioClient.dio.patch('${ApiConstants.quotes}/$quoteId', data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('Update quote failed: $e');
      throw Exception('Update quote failed: $e');
    }
  }
}
