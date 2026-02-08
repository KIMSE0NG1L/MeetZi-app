import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class PartnerProfileRepository {
  final ApiClient _client;

  PartnerProfileRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getPartnerProfile({required String matchId}) async {
    final response = await _client.dio.get('/users/match/$matchId/partner');
    return response.data as Map<String, dynamic>;
  }
}
