import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class MatchingRepository {
  final ApiClient _client;

  MatchingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> requestMatch() async {
    final response = await _client.dio.post(ApiEndpoints.matchingRequest);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelMatch({String? matchId}) async {
    final response = await _client.dio.delete(
      ApiEndpoints.matchingCancel,
      queryParameters:
          matchId != null && matchId.isNotEmpty ? {'matchId': matchId} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getActiveMatch() async {
    final response = await _client.dio.get(ApiEndpoints.matchingActive);
    return response.data as Map<String, dynamic>;
  }
}
