import 'package:nearo_app/shared/api/api_client.dart';

class MatchingBoardRepository {
  final ApiClient _client;

  MatchingBoardRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    // TODO: 실제 서버 API 엔드포인트로 변경
    final response = await _client.dio.get('/matching-board');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> registerProfile(Map<String, dynamic> profile) async {
    await _client.dio.post('/matching-board/register', data: profile);
  }

  Future<void> takeNote(String profileId) async {
    await _client.dio.post('/matching-board/take-note', data: {'profileId': profileId});
  }

  Future<int> fetchMyCredit() async {
    final response = await _client.dio.get('/users/me/credit');
    return response.data['credit'] as int;
  }

  Future<void> buyCredit(int coins) async {
    await _client.dio.post('/users/me/credit/increase', data: {'amount': coins});
  }
}
