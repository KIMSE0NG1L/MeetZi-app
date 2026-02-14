import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class UsersRepository {
  final ApiClient _client;

  UsersRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> createProfile({
    required String nickname,
    required String gender,
    required String baseType,
    String? affiliationText,
    int? heightCm,
    String? smoking,
    String? drinking,
    String? mbti,
    String? instagramHandle,
    String? bio,
    List<String>? preferredGenders,
    int? minBirthYear,
    int? maxBirthYear,
  }) async {
    final payload = <String, dynamic>{
      'nickname': nickname,
      'gender': gender,
      'baseType': baseType,
      if (affiliationText != null) 'affiliationText': affiliationText,
      if (heightCm != null) 'heightCm': heightCm,
      if (smoking != null) 'smoking': smoking,
      if (drinking != null) 'drinking': drinking,
      if (mbti != null) 'mbti': mbti,
      if (instagramHandle != null) 'instagramHandle': instagramHandle,
      if (bio != null) 'bio': bio,
      if (preferredGenders != null) 'preferredGenders': preferredGenders,
      if (minBirthYear != null) 'minBirthYear': minBirthYear,
      if (maxBirthYear != null) 'maxBirthYear': maxBirthYear,
    };

    final response = await _client.dio.post('/users/profile', data: payload);
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
