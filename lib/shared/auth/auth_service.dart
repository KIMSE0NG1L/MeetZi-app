import 'package:flutter/foundation.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// 앱 전역에서 인증 상태를 알리는 간단한 서비스.
/// - 토큰 저장/삭제를 담당
/// - 로그아웃 시 콜백으로 네비게이션 처리 가능
class AuthService extends ChangeNotifier {
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  AuthService({TokenStorage? tokenStorage, ApiClient? apiClient, LogoutCallback? onLogout})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _apiClient = apiClient ?? ApiClient(onLogout: onLogout);

  Future<void> init() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> markAuthenticated() async {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  ApiClient get apiClient => _apiClient;
}
