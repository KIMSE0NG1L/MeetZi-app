import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

/// Google Sign In 인증 서비스
class GoogleAuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  GoogleAuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Google Sign In 수행
  /// 성공 시 백엔드에 ID Token을 전송하여 JWT를 받아 저장
  /// 반환값: 성공 여부 (사용자가 취소한 경우 false)
  Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConfig.googleServerClientId,
        scopes: ['email'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        debugPrint('[GoogleAuth] User cancelled');
        return false;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('[GoogleAuth] No ID token received');
        return false;
      }

      debugPrint('[GoogleAuth] idToken received, email: ${account.email}');

      final response = await _apiClient.dio.post(
        '/auth/google/callback',
        data: {
          'idToken': idToken,
          'email': account.email,
          'name': account.displayName,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = (data['accessToken'] ?? data['access_token']) as String?;
        final refreshToken = (data['refreshToken'] ?? data['refresh_token']) as String?;
        final supabaseAccessToken = data['supabaseAccessToken'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenStorage.saveAccessToken(accessToken);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(refreshToken);
          }
          if (supabaseAccessToken != null && supabaseAccessToken.isNotEmpty) {
            await _tokenStorage.saveSupabaseAccessToken(supabaseAccessToken);
          }
          debugPrint('[GoogleAuth] Login success, tokens saved');
          return true;
        }
        debugPrint('[GoogleAuth] Missing accessToken in response: ${response.data}');
      } else {
        debugPrint('[GoogleAuth] Backend error response: ${response.statusCode} - ${response.data}');
      }

      return false;
    } on DioException catch (e) {
      debugPrint('[GoogleAuth] Network/Server error during backend callback:');
      debugPrint('  - Status: ${e.response?.statusCode}');
      debugPrint('  - Data: ${e.response?.data}');
      debugPrint('  - Message: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('[GoogleAuth] Unexpected error: $e');
      debugPrint('[GoogleAuth] StackTrace: $stackTrace');
      return false;
    }
  }
}
