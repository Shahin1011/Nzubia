import 'package:customer_nzubia_global/core/network/dio_client.dart';

class LegalRepository {
  final DioClient _dioClient;

  LegalRepository(this._dioClient);

  Future<Map<String, dynamic>> getLegalDoc(String slug) async {
    try {
      final response = await _dioClient.dio.get('/legal/$slug');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load $slug: $e');
    }
  }
}
