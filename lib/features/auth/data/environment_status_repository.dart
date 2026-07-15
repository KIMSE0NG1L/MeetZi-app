import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearo_app/core/supabase/supabase_service.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

class EnvironmentStatusRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  EnvironmentStatusRepository({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// supabaseAccessToken이 refresh 응답에 없으면 이전 값이 그대로 남아있을 수 있다
  /// (TokenStorage.saveTokens는 null/empty면 덮어쓰지 않음). 그 토큰이 만료된 채로
  /// RLS 조회에 쓰이면 auth.uid()가 비어 0건이 반환되어 "인증 안 됨"으로 오판하게 되므로,
  /// 만료 여부를 먼저 확인해 신선할 때만 Supabase 우회 경로를 사용한다.
  Future<bool> _hasFreshSupabaseToken() async {
    final token = await _tokenStorage.readSupabaseAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 30)));
    } catch (e) {
      debugPrint('[EnvironmentStatus] supabase 토큰 만료 확인 실패: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMyEnvironmentStatus() async {
    if (SupabaseService.isInitialized && await _hasFreshSupabaseToken()) {
      try {
        final rows = await SupabaseService.client
            .from('UserEnvironment')
            .select(
                '"environmentId", "verifiedAt", environment:Environment(id, name, "emailDomain", "primaryColor")')
            .eq('status', 'verified')
            .order('verifiedAt', ascending: false)
            .limit(1);

        final list = List<Map<String, dynamic>>.from(rows);
        debugPrint('[EnvironmentStatus] Supabase 직접 조회 성공 (verified: ${list.isNotEmpty})');
        if (list.isEmpty) {
          return {'verified': false};
        }
        final row = list.first;
        return {
          'verified': true,
          'environmentId': row['environmentId'],
          'environment': row['environment'],
        };
      } catch (e) {
        debugPrint('[EnvironmentStatus] Supabase 직접 조회 실패, fallback 사용: $e');
      }
    }

    final response = await _client.dio.get('/environments/me');
    return response.data as Map<String, dynamic>;
  }
}
