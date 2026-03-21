import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:nearo_app/shared/api/endpoints.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

typedef LogoutCallback = FutureOr<void> Function();

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final LogoutCallback? onLogout;
  bool _refreshing = false;

  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    this.onLogout,
  })  : _dio = dio ?? Dio(),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // ngrok 무료 플랜: 브라우저 경고 페이지 스킵 (없으면 HandShakeConnection terminated 발생할 수 있음)
        'ngrok-skip-browser-warning': 'true',
      },
    );

    // ngrok 등 개발 환경에서 HandshakeException 방지 (Android 등)
    if (AppConfig.baseUrl.contains('ngrok')) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final context = SecurityContext(withTrustedRoots: false);
          final client = HttpClient(context: context);
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          client.connectionTimeout = const Duration(seconds: 25);
          client.idleTimeout = const Duration(seconds: 15);
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ngrok 경고 페이지 스킵 (매 요청마다 확실히 붙임)
          if (AppConfig.baseUrl.contains('ngrok')) {
            options.headers['ngrok-skip-browser-warning'] = 'true';
          }

          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401: access token expired or invalid.
          final hasRetried = error.requestOptions.extra['retry'] == true;
          if (error.response?.statusCode == 401 && !hasRetried) {
            error.requestOptions.extra['retry'] = true;
            try {
              final success = await _tryRefreshToken();
              if (success) {
                final accessToken = await _tokenStorage.readAccessToken();
                if (accessToken != null && accessToken.isNotEmpty) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $accessToken';
                }
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              debugPrint('[ApiClient] token refresh failed: $e');
              // ignore, fallback to logout handler below
            }

            // refresh 실패 시 로그아웃/강제 로그인 이동
            await _handleLogout();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshing) return false;
    _refreshing = true;

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _dio.post(
        ApiEndpoints.authRefresh,
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final accessToken =
            (data['accessToken'] ?? data['access_token'])?.toString();
        final refreshTokenNew =
            (data['refreshToken'] ?? data['refresh_token'])?.toString();
        if (accessToken != null &&
            accessToken.isNotEmpty &&
            refreshTokenNew != null &&
            refreshTokenNew.isNotEmpty) {
          await _tokenStorage.saveTokens(
              accessToken: accessToken, refreshToken: refreshTokenNew);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] refresh token request failed: $e');
      // ignore
    } finally {
      _refreshing = false;
    }

    return false;
  }

  Future<void> _handleLogout() async {
    await _tokenStorage.clear();
    if (onLogout != null) {
      await onLogout!();
    }
  }

  Dio get dio => _dio;
}
