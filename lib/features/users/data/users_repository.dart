import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class UsersRepository {
  final ApiClient _client;

  UsersRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> createProfile({
    required String nickname,
    required String gender,
    required int birthYear,
    required String baseType,
  }) async {
    final response = await _client.dio.post(
      '/users/profile',
      data: {
        'nickname': nickname,
        'gender': gender,
        'birthYear': birthYear,
        'baseType': baseType,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPartnerProfile({
    required String matchId,
  }) async {
    final response = await _client.dio.get(
      '/users/match/$matchId/partner',
    );
    return response.data as Map<String, dynamic>;
  }
}
