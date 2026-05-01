import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

/// Apple Sign In 인증 서비스
/// iOS 앱스토어 심사 통과를 위해 Sign in with Apple 필수 구현
class AppleAuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AppleAuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// SHA-256 해시된 nonce 생성 (Apple 인증에 필요)
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// nonce를 SHA-256으로 해싱
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple Sign In 수행
  /// 성공 시 백엔드에 ID Token을 전송하여 JWT를 받아 저장
  /// 반환값: 성공 여부
  Future<bool> signInWithApple() async {
    try {
      // nonce 생성
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Apple 로그인 창 표시
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      debugPrint('[AppleAuth] identityToken received');
      debugPrint('[AppleAuth] email: ${credential.email}');
      debugPrint('[AppleAuth] givenName: ${credential.givenName}');
      debugPrint('[AppleAuth] familyName: ${credential.familyName}');

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null || identityToken.isEmpty) {
        debugPrint('[AppleAuth] No identity token received');
        return false;
      }

      // ──────────────────────────────────────────
      // 백엔드에 Apple ID Token 전송 → JWT 토큰 수령
      // ──────────────────────────────────────────
      final response = await _apiClient.dio.post(
        '/auth/apple/callback',
        data: {
          'identityToken': identityToken,
          'authorizationCode': authorizationCode,
          'nonce': rawNonce,
          'email': credential.email,
          'fullName': credential.givenName != null || credential.familyName != null
              ? '${credential.familyName ?? ''}${credential.givenName ?? ''}'.trim()
              : null,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenStorage.saveAccessToken(accessToken);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(refreshToken);
          }
          debugPrint('[AppleAuth] Login success, tokens saved');
          return true;
        }
      }

      debugPrint('[AppleAuth] Backend returned unexpected response');
      return false;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AppleAuth] User cancelled');
      } else {
        debugPrint('[AppleAuth] Authorization error: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('[AppleAuth] Unexpected error: $e');
      return false;
    }
  }
}
