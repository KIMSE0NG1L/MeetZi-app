import 'package:nearo_app/shared/api/api_client.dart';

class EnvironmentStatusRepository {
  final ApiClient _client;

  EnvironmentStatusRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getMyEnvironmentStatus() async {
    final response = await _client.dio.get('/environments/me');
    return response.data as Map<String, dynamic>;
  }
}
