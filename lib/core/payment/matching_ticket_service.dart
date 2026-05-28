import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nearo_app/shared/api/api_client.dart';

/// RevenueCat 매칭권 결제 서비스
/// 소모성 아이템(매칭권) 구매 및 matchingTicket 조회
class MatchingTicketService {
  /// ──────────────────────────────────────────────
  /// RevenueCat 설정값
  /// ──────────────────────────────────────────────
  static const _androidApiKey = 'goog_uXqxzRKIRNWqyRfRCzyNSwmDvCC';
  static const _iosApiKey = 'appl_AIOeNTEmsiHEbdmzVpmDXyRkEJe';
  static String get _revenueCatApiKey =>
      Platform.isIOS ? _iosApiKey : _androidApiKey;

  /// RevenueCat 대시보드 설정:
  ///   Offering ID  : default
  ///   Package ID   : single_ticket
  ///   Entitlement  : matching_access
  ///   Google Play 제품 ID : matching_ticket
  static const _packageId = 'single_ticket';
  static const _entitlementId = 'matching_access';

  final ApiClient _apiClient;

  MatchingTicketService(this._apiClient);

  // ──────────────────────────────────────────────
  // 1. RevenueCat 초기화 (앱 시작 시 1회 호출)
  // ──────────────────────────────────────────────
  static Future<void> initialize(String appUserId) async {
    final config = PurchasesConfiguration(_revenueCatApiKey)
      ..appUserID = appUserId;
    await Purchases.configure(config);
    debugPrint('[MatchingTicketService] RevenueCat initialized for user: $appUserId');
  }

  // ──────────────────────────────────────────────
  // 2. 상품 목록(Offerings) 가져오기
  // ──────────────────────────────────────────────
  Future<List<StoreProduct>> getTicketProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        debugPrint('[MatchingTicketService] No current offering found');
        return [];
      }
      return current.availablePackages
          .map((pkg) => pkg.storeProduct)
          .toList();
    } catch (e) {
      debugPrint('[MatchingTicketService] getOfferings error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 3. 매칭권 구매
  // ──────────────────────────────────────────────
  /// 구매 성공 시 true 반환
  /// RevenueCat이 자동으로 서버 웹훅을 보냄 → 서버에서 matchingTicket +1 처리
  Future<bool> purchaseTicket() async {
    try {
      // 'default' offering에서 'single_ticket' 패키지 찾기
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        debugPrint('[MatchingTicketService] No offerings available');
        throw Exception('구매 가능한 상품을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }

      // Package ID가 'single_ticket'인 패키지를 우선 탐색
      Package? targetPackage;
      for (final pkg in current.availablePackages) {
        if (pkg.identifier == _packageId) {
          targetPackage = pkg;
          break;
        }
      }
      // 못 찾으면 첫 번째 패키지 사용 (fallback)
      targetPackage ??= current.availablePackages.first;

      final customerInfo = await Purchases.purchasePackage(targetPackage);

      debugPrint('[MatchingTicketService] Purchase complete');

      // matching_access 권한 활성화 확인
      final entitlement = customerInfo.entitlements.all[_entitlementId];
      if (entitlement != null && entitlement.isActive) {
        debugPrint('[MatchingTicketService] Entitlement "$_entitlementId" is ACTIVE');
      } else {
        debugPrint('[MatchingTicketService] Entitlement "$_entitlementId" not active (소모성 아이템이므로 정상)');
      }

      // 웹훅 처리 대기 (보통 1~3초)
      await Future.delayed(const Duration(seconds: 2));

      return true;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[MatchingTicketService] User cancelled purchase');
        return false; // 사용자 취소 → false 반환 (정상 흐름)
      }
      debugPrint('[MatchingTicketService] Purchase error: $e');
      throw Exception('구매에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    } catch (e) {
      if (e is Exception) rethrow; // 직접 throw한 Exception은 그대로 전파
      debugPrint('[MatchingTicketService] Unexpected error: $e');
      throw Exception('구매 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  // ──────────────────────────────────────────────
  // 4. 서버에서 매칭권 개수 조회
  // ──────────────────────────────────────────────
  Future<int> getTicketCount() async {
    try {
      final response = await _apiClient.dio.get('/subscription/matching-ticket');
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map<String, dynamic>)['matchingTicket'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('[MatchingTicketService] getTicketCount error: $e');
      return 0;
    }
  }

  // ──────────────────────────────────────────────
  // 5. 구매 + 서버 갱신 확인 (한 번에)
  // ──────────────────────────────────────────────
  /// 구매 → 웹훅 대기 → 최신 matchingTicket 반환
  /// 실패 시 -1 반환
  Future<int> purchaseAndSync() async {
    // 구매 전 현재 보유 개수 미리 조회
    final initialCount = await getTicketCount();

    final success = await purchaseTicket();
    if (!success) return -1;

    // 웹훅 처리 후 서버에서 최신 matchingTicket 가져오기
    // 최대 3회 폴링 (총 ~6초)
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final count = await getTicketCount();
      if (count > initialCount) return count;
    }

    return await getTicketCount();
  }
}
