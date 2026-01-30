import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class HealthRepository {
  final ApiClient _client;

  HealthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> check() async {
    final response = await _client.dio.get(ApiEndpoints.health);
    return response.data as Map<String, dynamic>;
  }
}
