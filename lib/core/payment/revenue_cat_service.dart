import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nearo_app/shared/api/api_client.dart';

/// RevenueCat 통합 결제 및 구독 서비스
/// - 소모성 아이템 (단일 매칭권 구매 & 서버 동기화)
/// - 월간 무제한 구독 (premium / matching_unlimited)
/// - Entitlement 검증 & 구독 복원 (Restore Purchases)
class RevenueCatService {
  final ApiClient? _apiClient;

  RevenueCatService([this._apiClient]);

  static final RevenueCatService instance = RevenueCatService();

  /// ──────────────────────────────────────────────
  /// RevenueCat API Keys & 식별자 정보
  /// ──────────────────────────────────────────────
  static const String androidApiKey = 'goog_uXqxzRKIRNWqyRfRCzyNSwmDvCC';
  static const String iosApiKey = 'appl_AIOeNTEmsiHEbdmzVpmDXyRkEJe';
  static String get apiKey => Platform.isIOS ? iosApiKey : androidApiKey;

  /// RevenueCat 대시보드 설정 식별자
  static const String entitlementPremium = 'premium';
  static const String entitlementMatchingAccess = 'matching_access';
  static const String offeringDefault = 'default';
  static const String packageSingleTicket = 'single_ticket';
  static const String packageMonthlyUnlimited = 'monthly_unlimited';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // ──────────────────────────────────────────────
  // 1. RevenueCat 초기화 & 유저 세션 관리
  // ──────────────────────────────────────────────
  static Future<void> initialize([String? appUserId]) async {
    try {
      final config = PurchasesConfiguration(apiKey);
      if (appUserId != null && appUserId.isNotEmpty) {
        config.appUserID = appUserId;
      }
      await Purchases.configure(config);
      _isInitialized = true;
      debugPrint('[RevenueCatService] RevenueCat initialized for user: $appUserId');
    } catch (e) {
      debugPrint('[RevenueCatService] Initialization failed: $e');
    }
  }

  Future<void> logIn(String appUserId) async {
    try {
      if (!_isInitialized) {
        await initialize(appUserId);
      } else {
        await Purchases.logIn(appUserId);
      }
    } catch (e) {
      debugPrint('[RevenueCatService] logIn error: $e');
    }
  }

  Future<void> logOut() async {
    try {
      if (_isInitialized) {
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('[RevenueCatService] logOut error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // 2. Entitlement / 권한 검사
  // ──────────────────────────────────────────────
  /// 유저의 'premium' Entitlement 활성화 여부 확인
  Future<bool> checkPremiumActive() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementPremium];
      final isActive = entitlement != null && entitlement.isActive;
      debugPrint('[RevenueCatService] Premium entitlement active: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('[RevenueCatService] checkPremiumActive error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // 3. 상품 목록 (Offerings & Packages) 조회
  // ──────────────────────────────────────────────
  /// 'default' Offering에서 월간(Monthly) 패키지 가져오기
  Future<Package?> fetchMonthlyPackage() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current ?? offerings.all[offeringDefault];
      if (current == null) {
        debugPrint('[RevenueCatService] Offering "$offeringDefault" not found');
        return null;
      }

      if (current.monthly != null) {
        return current.monthly;
      }

      for (final pkg in current.availablePackages) {
        if (pkg.packageType == PackageType.monthly ||
            pkg.identifier == '\$rc_monthly' ||
            pkg.identifier == 'monthly' ||
            pkg.identifier == packageMonthlyUnlimited ||
            pkg.identifier.contains('monthly')) {
          return pkg;
        }
      }

      return current.availablePackages.isNotEmpty ? current.availablePackages.first : null;
    } catch (e) {
      debugPrint('[RevenueCatService] fetchMonthlyPackage error: $e');
      return null;
    }
  }

  /// 사용 가능한 상품 목록(StoreProduct) 가져오기
  Future<List<StoreProduct>> getTicketProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        debugPrint('[RevenueCatService] No current offering found');
        return [];
      }
      return current.availablePackages
          .map((pkg) => pkg.storeProduct)
          .toList();
    } catch (e) {
      debugPrint('[RevenueCatService] getOfferings error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 4. 결제 (Purchase) 및 구독 복원 (Restore)
  // ──────────────────────────────────────────────
  /// 월간 패키지 결제 실행
  /// - 성공: CustomerInfo 반환
  /// - 사용자 취소: null 반환
  /// - 에러: Exception 발생
  Future<CustomerInfo?> purchaseMonthlyPackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      debugPrint('[RevenueCatService] Monthly purchase complete');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[RevenueCatService] Monthly purchase error: $errorCode, message: ${e.message}');
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      throw Exception(_friendlyErrorMessage(errorCode));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('결제 처리 중 알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  /// 단일 매칭권 패키지 구매
  Future<CustomerInfo?> purchaseTicket() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        throw Exception('구매 가능한 상품을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }

      Package? targetPackage;
      for (final pkg in current.availablePackages) {
        if (pkg.identifier == packageSingleTicket) {
          targetPackage = pkg;
          break;
        }
      }
      targetPackage ??= current.availablePackages.first;

      final customerInfo = await Purchases.purchasePackage(targetPackage);
      debugPrint('[RevenueCatService] Single ticket purchase complete');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      throw Exception(_friendlyErrorMessage(errorCode));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('결제를 진행하는 중 알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  /// 월 무제한 구독 상품 결제 (ShopScreen 호환용)
  Future<CustomerInfo?> purchaseUnlimitedSubscription() async {
    try {
      final monthlyPkg = await fetchMonthlyPackage();
      if (monthlyPkg == null) {
        throw Exception('구독 상품을 찾을 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }
      return await purchaseMonthlyPackage(monthlyPkg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('구독 진행 중 오류가 발생했습니다.');
    }
  }

  /// 구매 내역 복원 (Restore Purchases)
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('[RevenueCatService] Purchases restored successfully');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception(_friendlyErrorMessage(errorCode));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('구독 내역 복원 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  // ──────────────────────────────────────────────
  // 5. 백엔드 서버 연동 (API Client)
  // ──────────────────────────────────────────────
  /// 서버에서 구독 활성화 여부 확인
  Future<bool> isSubscriptionActive() async {
    if (_apiClient == null) return false;
    try {
      final response = await _apiClient.dio.get('/subscription/is-active');
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map<String, dynamic>)['isActive'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[RevenueCatService] isSubscriptionActive error: $e');
      return false;
    }
  }

  /// 서버에서 보유 매칭권 개수 조회
  Future<int> getTicketCount() async {
    if (_apiClient == null) return 0;
    try {
      final response = await _apiClient.dio.get('/subscription/matching-ticket');
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map<String, dynamic>)['matchingTicket'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('[RevenueCatService] getTicketCount error: $e');
      return 0;
    }
  }

  /// 단일 매칭권 결제 후 서버 동기화
  Future<int> purchaseAndSync() async {
    final customerInfo = await purchaseTicket();
    if (customerInfo == null) return -1;

    if (_apiClient != null) {
      final nonSubTransactions = customerInfo.nonSubscriptionTransactions;
      if (nonSubTransactions.isNotEmpty) {
        final latestTx = nonSubTransactions.last;
        final transactionId = latestTx.transactionIdentifier;
        final productId = latestTx.productIdentifier;

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
              return updatedCount;
            }
          }
        } catch (e) {
          debugPrint('[RevenueCatService] Server verification error: $e');
        }
      }
    }

    return await getTicketCount();
  }

  // ──────────────────────────────────────────────
  // 6. 에러 메시지 헬퍼
  // ──────────────────────────────────────────────
  String _friendlyErrorMessage(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.networkError:
        return '네트워크 연결 상태가 좋지 않습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return '이 기기에서는 결제가 허용되지 않았습니다. 앱 내 구입 차단 설정을 확인해 주세요.';
      case PurchasesErrorCode.paymentPendingError:
        return '결제가 대기 중입니다. 완료될 때까지 잠시만 기다려 주세요.';
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
}
