import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

class AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthRepository({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> payload) async {
    final response = await _client.dio.patch(
      ApiEndpoints.authProfile,
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  /// 게시판에 보일 프로필: avatar(아바타) | photo(본인 사진)
  Future<Map<String, dynamic>> setBoardDisplayType(String boardDisplayType) async {
    final response = await _client.dio.patch('/users/me/board-display', data: {'boardDisplayType': boardDisplayType});
    return response.data as Map<String, dynamic>;
  }

  /// 대학 인증 성공 후 아바타 초기 생성(seed 발급)
  Future<Map<String, dynamic>> initAvatar() async {
    final response = await _client.dio.post(ApiEndpoints.avatarInit);
    return response.data as Map<String, dynamic>;
  }

  Future<void> saveAccessToken(String token) {
    return _tokenStorage.saveAccessToken(token);
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }

  Future<void> deleteAccount() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      await _tokenStorage.clear();
      throw Exception('로그인 정보가 없습니다. 다시 로그인 후 시도해 주세요.');
    }
    try {
      // 헤더만으로 401 나는 경우 대비, 쿼리에도 토큰 전달
      final uri = '${ApiEndpoints.accountDelete}?access_token=${Uri.encodeComponent(token)}';
      await _client.dio.delete(
        uri,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } finally {
      await _tokenStorage.clear();
    }
  }
}
