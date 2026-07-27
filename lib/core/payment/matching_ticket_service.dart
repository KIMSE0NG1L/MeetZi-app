import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// 월 구독(무제한 매칭권) 상품
  ///   Package ID   : monthly_unlimited
  ///   Entitlement  : matching_unlimited
  static const _subscriptionPackageId = 'monthly_unlimited';

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
  Future<CustomerInfo?> purchaseTicket() async {
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

      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[MatchingTicketService] PlatformException error code: ${e.code}, message: ${e.message}, details: ${e.details}');
      debugPrint('[MatchingTicketService] Mapped PurchasesErrorCode: $errorCode');

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[MatchingTicketService] User cancelled purchase');
        return null; // 사용자 취소 → null 반환 (정상 흐름, 에러 팝업 띄우지 않음)
      }

      throw Exception(_friendlyErrorMessage(errorCode));
    } catch (e) {
      if (e is Exception) rethrow; // 직접 throw한 Exception은 그대로 전파
      debugPrint('[MatchingTicketService] Unexpected error: $e');
      throw Exception('결제를 진행하는 중 알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  /// 그 외의 에러는 친절한 한글 메시지로 변환 (UI 노출용)
  String _friendlyErrorMessage(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.networkError:
        return '네트워크 연결 상태가 좋지 않습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return '이 기기에서는 결제가 허용되지 않았습니다. 앱 내 구입 차단 설정을 확인해 주세요.';
      case PurchasesErrorCode.paymentPendingError:
        return '이전 결제가 아직 대기 중입니다. 완료될 때까지 잠시만 기다려 주세요.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return '이미 구매 완료된 상품입니다.';
      case PurchasesErrorCode.configurationError:
        return '앱 스토어 설정 오류로 결제를 진행할 수 없습니다. 고객센터로 문의해 주세요.';
      case PurchasesErrorCode.storeProblemError:
        return '앱 스토어 연결에 실패했습니다. App Store 또는 Google Play 서비스 상태를 확인해 주세요.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return '현재 이 상품은 구매할 수 없습니다. 잠시 후 다시 시도해 주세요.';
      default:
        return '결제를 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  // ──────────────────────────────────────────────
  // 6. 월 구독(무제한 매칭권) 구매
  // ──────────────────────────────────────────────
  /// 구매 성공 시 CustomerInfo 반환, 취소 시 null.
  /// 구독은 소모품이 아니므로 서버 영수증 수동 검증(verify-purchase) 불필요 —
  /// RevenueCat 웹훅이 자동으로 Subscription 상태를 갱신함.
  /// 구매 직후 최신 상태 확인은 [isSubscriptionActive] 폴링 사용.
  Future<CustomerInfo?> purchaseUnlimitedSubscription() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        debugPrint('[MatchingTicketService] No offerings available');
        throw Exception('구독 상품을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }

      Package? targetPackage;
      for (final pkg in current.availablePackages) {
        if (pkg.identifier == _subscriptionPackageId) {
          targetPackage = pkg;
          break;
        }
      }
      if (targetPackage == null) {
        debugPrint('[MatchingTicketService] Subscription package not found');
        throw Exception('구독 상품을 찾을 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }

      final customerInfo = await Purchases.purchasePackage(targetPackage);
      debugPrint('[MatchingTicketService] Subscription purchase complete');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[MatchingTicketService] Subscription PlatformException: ${e.code}, ${e.message}');

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      throw Exception(_friendlyErrorMessage(errorCode));
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('[MatchingTicketService] Unexpected subscription error: $e');
      throw Exception('구독을 진행하는 중 알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  /// 서버에서 구독 활성 여부 조회 (구매 후 웹훅 반영 확인용)
  Future<bool> isSubscriptionActive() async {
    try {
      final response = await _apiClient.dio.get('/subscription/is-active');
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map<String, dynamic>)['isActive'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[MatchingTicketService] isSubscriptionActive error: $e');
      return false;
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
  /// 구매 → 즉시 서버 영수증 검증 → 최신 matchingTicket 반환
  /// 실패 시 -1 반환
  Future<int> purchaseAndSync() async {
    final customerInfo = await purchaseTicket();
    if (customerInfo == null) return -1; // 취소됨

    final nonSubTransactions = customerInfo.nonSubscriptionTransactions;
    if (nonSubTransactions.isNotEmpty) {
      final latestTx = nonSubTransactions.last;
      final transactionId = latestTx.transactionIdentifier;
      final productId = latestTx.productIdentifier;

      debugPrint('[MatchingTicketService] Starting synchronous verification on server: $transactionId');

      try {
        final response = await _apiClient.dio.post(
          '/subscription/verify-purchase',
          data: {
            'transactionId': transactionId,
            'productId': productId,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data is Map) {
            final updatedCount = (response.data as Map<String, dynamic>)['matchingTicket'] as int? ?? 0;
            debugPrint('[MatchingTicketService] Synchronous verification success. New ticket count: $updatedCount');
            return updatedCount;
          }
        }
      } catch (e) {
        debugPrint('[MatchingTicketService] Server verification failed: $e. Fallback to general count query.');
      }
    } else {
      debugPrint('[MatchingTicketService] No non-subscription transactions found. Falling back.');
    }

    // 서버 API 호출 실패 시 또는 트랜잭션이 비어있는 경우, Fallback으로 일반 조회 결과 반환
    return await getTicketCount();
  }
}
