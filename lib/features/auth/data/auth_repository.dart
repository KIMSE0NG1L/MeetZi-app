import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

class AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _cachedProfileAt;
  static Future<Map<String, dynamic>>? _inFlightProfileRequest;
  static const Duration _profileCacheTtl = Duration(seconds: 10);

  AuthRepository({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) {
    return _tokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> reviewerLogin({
    required String loginId,
    required String password,
  }) async {
    final response = await _client.dio.post(
      '/auth/reviewer-login',
      data: {
        'loginId': loginId,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final accessToken = (data['accessToken'] ?? data['access_token'])?.toString();
    final refreshToken = (data['refreshToken'] ?? data['refresh_token'])?.toString();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception('리뷰어 로그인 응답이 올바르지 않습니다.');
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedProfileAt != null &&
        now.difference(_cachedProfileAt!) < _profileCacheTtl) {
      return _cachedProfile!;
    }

    if (!forceRefresh && _inFlightProfileRequest != null) {
      return _inFlightProfileRequest!;
    }

    final request = _client.dio.get('/users/me').then((response) {
      final data = response.data as Map<String, dynamic>;
      _cachedProfile = data;
      _cachedProfileAt = DateTime.now();
      return data;
    }).whenComplete(() {
      _inFlightProfileRequest = null;
    });

    _inFlightProfileRequest = request;
    return request;
  }

  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await _client.dio.get(
      '/users/me/nickname-availability',
      queryParameters: {'nickname': nickname},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['available'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> payload) async {
    final response = await _client.dio.patch(
      ApiEndpoints.authProfile,
      data: payload,
    );
    _invalidateProfileCache();
    return response.data as Map<String, dynamic>;
  }

  /// 게시판에 보일 프로필: avatar(아바타) | photo(본인 사진)
  Future<Map<String, dynamic>> setBoardDisplayType(String boardDisplayType) async {
    final response = await _client.dio.patch('/users/me/board-display', data: {'boardDisplayType': boardDisplayType});
    _invalidateProfileCache();
    return response.data as Map<String, dynamic>;
  }

  /// 대학 인증 성공 후 아바타 초기 생성(seed 발급)
  Future<Map<String, dynamic>> initAvatar() async {
    final response = await _client.dio.post(ApiEndpoints.avatarInit);
    _invalidateProfileCache();
    return response.data as Map<String, dynamic>;
  }

  Future<void> saveAccessToken(String token) {
    return _tokenStorage.saveAccessToken(token);
  }

  Future<void> logout() {
    _invalidateProfileCache();
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
      await _client.dio.delete(
        ApiEndpoints.accountDelete,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } finally {
      _invalidateProfileCache();
      await _tokenStorage.clear();
    }
  }

  static void _invalidateProfileCache() {
    _cachedProfile = null;
    _cachedProfileAt = null;
    _inFlightProfileRequest = null;
  }
}
