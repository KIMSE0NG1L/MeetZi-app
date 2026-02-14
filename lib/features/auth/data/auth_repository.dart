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
    try {
      await _client.dio.delete(ApiEndpoints.accountDelete);
    } finally {
      // 계정 삭제 완료 후 토큰 삭제 (로그아웃)
      await _tokenStorage.clear();
    }
  }
}
