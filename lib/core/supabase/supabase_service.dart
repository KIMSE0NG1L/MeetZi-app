import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearo_app/shared/utils/app_config.dart';

/// Supabase 직접 호출 서비스 (경량 읽기 API 전용)
///
/// Cloud Run 서버를 거치지 않고 Supabase에 직접 쿼리하여
/// 콜드스타트 지연을 피하고 응답 속도를 개선합니다.
///
/// 현재 전환 대상: 공지사항 목록 (인증 불필요, 공개 데이터)
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Supabase 클라이언트 (초기화 후 사용)
  static SupabaseClient get client => Supabase.instance.client;

  /// 초기화 여부
  static bool get isInitialized => _initialized;

  /// 앱 시작 시 1회 호출 (main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] 초기화 성공');
    } catch (e) {
      debugPrint('[SupabaseService] 초기화 실패 (Cloud Run fallback 사용): $e');
      // 초기화 실패해도 앱은 정상 동작 (Cloud Run fallback)
    }
  }
}
