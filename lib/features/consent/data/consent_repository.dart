import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class ConsentRepository {
  final ApiClient _client;

  ConsentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> giveConsent({
    required String matchId,
    required bool decision,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.matchingConsent(matchId),
      data: {'decision': decision ? 'yes' : 'no'},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getConsentStatus({
    required String matchId,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.matchingConsentStatus(matchId),
    );
    return response.data as Map<String, dynamic>;
  }
}
