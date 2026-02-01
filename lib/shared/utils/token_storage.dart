import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) {
    // DEBUG: print token when saved (remove in production)
    // ignore: avoid_print
    print('DEBUG: Token saved -> $token');
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
