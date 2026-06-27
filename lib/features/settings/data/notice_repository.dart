import 'package:flutter/foundation.dart';
import 'package:nearo_app/core/supabase/supabase_service.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class NoticeRepository {
  NoticeRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 공지사항 목록 가져오기
  /// 1차: Supabase 직접 호출 (빠르고 Cloud Run 부하 없음)
  /// 2차: Cloud Run API fallback (Supabase 실패 시)
  Future<List<Map<String, dynamic>>> getNotices({int limit = 50}) async {
    // Supabase 초기화 성공 시 직접 호출 시도
    if (SupabaseService.isInitialized) {
      try {
        final data = await SupabaseService.client
            .from('Notice')
            .select('id, title, content, "imageUrl", type, "createdAt", "updatedAt"')
            .eq('isPublished', true)
            .order('createdAt', ascending: false)
            .limit(limit);
        debugPrint('[Notice] Supabase 직접 조회 성공 (${data.length}건)');
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        debugPrint('[Notice] Supabase 직접 조회 실패, Cloud Run fallback: $e');
      }
    }

    // Fallback: 기존 Cloud Run API
    return _getNoticesFromServer(limit: limit);
  }

  /// Cloud Run 서버 경유 조회 (fallback)
  Future<List<Map<String, dynamic>>> _getNoticesFromServer({int limit = 50}) async {
    try {
      final res = await _client.dio.get<List>(
        ApiEndpoints.notices,
        queryParameters: {'limit': limit},
      );
      final list = res.data;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }
}
