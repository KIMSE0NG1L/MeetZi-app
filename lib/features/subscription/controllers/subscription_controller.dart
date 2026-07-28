import 'package:flutter/foundation.dart';
import 'package:nearo_app/core/payment/revenue_cat_service.dart';

/// 유저의 Premium 구독 Entitlement 상태를 관리하는 전역 반응형 컨트롤러
class SubscriptionController extends ValueNotifier<bool> {
  SubscriptionController._internal() : super(false);
  static final SubscriptionController instance = SubscriptionController._internal();

  bool get isPremium => value;

  /// 유저의 Premium 권한 조회 및 상태 업데이트
  Future<bool> checkEntitlement() async {
    final active = await RevenueCatService.instance.checkPremiumActive();
    value = active;
    return active;
  }

  /// 결제/복원 성공 시 수동 상태 업데이트
  void setPremium(bool active) {
    value = active;
  }
}
