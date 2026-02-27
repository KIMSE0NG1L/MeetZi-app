import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ?? Dio(),
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
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          client.connectionTimeout = const Duration(seconds: 25);
          // 15초 기본값이면 유휴 후 연결 끊김 → ngrok 터널과 겹쳐 30초 내외에 데이터 못 받는 현상 발생 가능. 60초로 유지.
          client.idleTimeout = const Duration(seconds: 60);
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
      ),
    );
  }

  Dio get dio => _dio;
}
