import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _supabaseAccessTokenKey = 'supabase_access_token';
  static const _cachedRouteKey = 'cached_route';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? supabaseAccessToken,
  }) {
    return Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      if (supabaseAccessToken != null && supabaseAccessToken.isNotEmpty)
        _storage.write(key: _supabaseAccessTokenKey, value: supabaseAccessToken),
    ]).then((_) => null);
  }

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String refreshToken) {
    return _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Supabase 직접 호출용 브리지 토큰 (서버가 발급, RLS의 auth.uid()가 이 사용자를 가리키게 함)
  Future<void> saveSupabaseAccessToken(String token) {
    return _storage.write(key: _supabaseAccessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<String?> readSupabaseAccessToken() {
    return _storage.read(key: _supabaseAccessTokenKey);
  }

  /// 마지막 성공 라우트 캐시 (앱 재시작 시 빠른 진입용)
  Future<void> saveCachedRoute(String route) {
    return _storage.write(key: _cachedRouteKey, value: route);
  }

  Future<String?> readCachedRoute() {
    return _storage.read(key: _cachedRouteKey);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _supabaseAccessTokenKey),
      _storage.delete(key: _cachedRouteKey),
    ]);
  }
}
