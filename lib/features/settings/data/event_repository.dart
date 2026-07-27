import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class EventRepository {
  EventRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 출석 체크
  Future<Map<String, dynamic>> checkIn() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      ApiEndpoints.eventAttendance,
    );
    return res.data ?? {};
  }

  /// 출석 현황 조회 (오늘 여부 + 이번 달 날짜 목록)
  Future<Map<String, dynamic>> getAttendanceStatus() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.eventAttendanceStatus,
    );
    return res.data ?? {};
  }

  /// 내 추천인 코드 조회 (없으면 자동 생성)
  Future<Map<String, dynamic>> getMyReferralCode() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.eventReferralMyCode,
    );
    return res.data ?? {};
  }

  /// 추천인 코드 적용
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      ApiEndpoints.eventReferralApply,
      data: {'code': code.toUpperCase().trim()},
    );
    return res.data ?? {};
  }

  /// 추천인 코드 사용 여부 확인
  Future<bool> hasUsedReferralCode() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.eventReferralStatus,
    );
    return res.data?['hasUsedReferralCode'] == true;
  }

  /// 리워드 광고 시청 완료 → 매칭권 1장 지급 요청 (하루 5회 제한)
  Future<Map<String, dynamic>> claimAdReward() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      ApiEndpoints.adRewardClaim,
    );
    return res.data ?? {};
  }

  /// 오늘 남은 리워드 광고 시청 가능 횟수 조회
  Future<Map<String, dynamic>> getAdRewardStatus() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.adRewardStatus,
    );
    return res.data ?? {};
  }
}
