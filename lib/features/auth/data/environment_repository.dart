import 'package:flutter/foundation.dart';
import 'package:nearo_app/core/supabase/supabase_service.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class EnvironmentRepository {
  final ApiClient _client;

  EnvironmentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<dynamic>> getEnvironments() async {
    if (SupabaseService.isInitialized) {
      try {
        final data = await SupabaseService.client
            .from('Environment')
            .select('id, name, type, "emailDomain", "verificationMethod", "primaryColor"')
            .eq('isActive', true);

        final list = List<Map<String, dynamic>>.from(data);
        
        // 한글(가나다) 우선 정렬 (NestJS와 정렬 기준 동일하게 적용)
        bool startsWithHangul(String s) => RegExp(r'^[가-힣]').hasMatch(s);
        list.sort((a, b) {
          final aName = a['name']?.toString() ?? '';
          final bName = b['name']?.toString() ?? '';
          final aFirst = startsWithHangul(aName) ? 0 : 1;
          final bFirst = startsWithHangul(bName) ? 0 : 1;
          if (aFirst != bFirst) return aFirst - bFirst;
          return aName.compareTo(bName);
        });

        debugPrint('[Environment] Supabase 직접 조회 성공 (${list.length}건)');
        return list;
      } catch (e) {
        debugPrint('[Environment] Supabase 직접 조회 실패, fallback 사용: $e');
      }
    }

    final response = await _client.dio.get('/environments');
    return response.data as List<dynamic>;
  }

  /// 대학별 가입자 수 랭킹 (온보딩용)
  Future<List<Map<String, dynamic>>> getRanking() async {
    final response = await _client.dio.get('/environments/ranking');
    final list = response.data as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> requestEmailVerification({
    required String environmentId,
    required String email,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.emailVerificationRequest(environmentId),
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmEmailVerification({
    required String environmentId,
    required String code,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.emailVerificationConfirm(environmentId),
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }
}
