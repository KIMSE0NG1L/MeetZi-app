
import 'package:dio/dio.dart';
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
    try {
      await _client.dio.post('/matching-board/register', data: profile);
    } on DioError catch (e) {
      // 서버에서 온 에러 메시지 추출
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message;
      throw msg ?? '등록 중 오류가 발생했습니다.';
    }
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
