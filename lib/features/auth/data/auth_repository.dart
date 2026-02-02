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
    final response = await _client.dio.get(ApiEndpoints.authProfile);
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

  Future<void> saveAccessToken(String token) {
    return _tokenStorage.saveAccessToken(token);
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }

  Future<void> deleteAccount() async {
    await _client.dio.delete(ApiEndpoints.accountDelete);
  }
}
