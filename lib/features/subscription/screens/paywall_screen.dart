import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nearo_app/core/payment/revenue_cat_service.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/features/subscription/controllers/subscription_controller.dart';

/// MeetZi 프리미엄 월 구독 결제 화면 (Paywall)
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = true;
  Package? _monthlyPackage;
  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    setState(() => _loading = true);
    final pkg = await RevenueCatService.instance.fetchMonthlyPackage();
    if (!mounted) return;
    setState(() {
      _monthlyPackage = pkg;
      _loading = false;
    });
  }

  /// 구독하기 클릭 로직
  Future<void> _onSubscribe() async {
    if (_purchasing || _monthlyPackage == null) return;
    setState(() => _purchasing = true);

    try {
      final customerInfo = await RevenueCatService.instance.purchaseMonthlyPackage(_monthlyPackage!);
      if (!mounted) return;

      if (customerInfo == null) {
        // 사용자가 결제 창에서 직접 취소한 경우 → 팝업 없이 리턴
        return;
      }

      final entitlement = customerInfo.entitlements.all[RevenueCatService.entitlementPremium];
      final isPremium = entitlement != null && entitlement.isActive;

      if (isPremium) {
        SubscriptionController.instance.setPremium(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MeetZi 프리미엄 구독이 시작되었습니다! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독 처리가 진행 중입니다. 잠시 후 확인해 주세요.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '결제 진행 중 오류가 발생했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  /// 구독 복원 클릭 로직
  Future<void> _onRestore() async {
    if (_restoring) return;
    setState(() => _restoring = true);

    try {
      final customerInfo = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;

      if (customerInfo == null) return;

      final entitlement = customerInfo.entitlements.all[RevenueCatService.entitlementPremium];
      final isPremium = entitlement != null && entitlement.isActive;

      if (isPremium) {
        SubscriptionController.instance.setPremium(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독 내역이 성공적으로 복원되었습니다! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('활성화된 프리미엄 구독 내역을 찾을 수 없습니다.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '구독 복원 중 오류가 발생했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final priceString = _monthlyPackage?.storeProduct.priceString ?? '₩4,900';

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0F172A) : const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: dark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ── 헤더 왕관 아이콘 ──
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: UniversityTheme.designPinkGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.crown,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 타이틀 & 설명
                      Text(
                        'MeetZi Premium',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: dark ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '매칭권 제한 없이 마음껏 인연을 찾아보세요!',
                        style: TextStyle(
                          fontSize: 15,
                          color: dark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // ── 혜택 목록 ──
                      _buildFeatureTile(
                        dark,
                        icon: LucideIcons.infinity,
                        title: '무제한 매칭 신청',
                        subtitle: '매칭권 차감 없이 자유롭게 매칭 신청이 가능해요.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureTile(
                        dark,
                        icon: LucideIcons.sparkles,
                        title: '프로필 무제한 열람',
                        subtitle: '모든 상대방의 카드 및 상세 프로필을 열람할 수 있어요.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureTile(
                        dark,
                        icon: LucideIcons.zap,
                        title: '우선 매칭 매칭권 제공',
                        subtitle: '상대방에게 나의 매칭 신청이 먼저 노출됩니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureTile(
                        dark,
                        icon: LucideIcons.shieldCheck,
                        title: '광고 없는 클린 환경',
                        subtitle: '앱 이용 중 등장하는 배너 및 전면 광고가 모두 제거됩니다.',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── 결제 하단 영역 ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // 가격 정보
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '월간 구독 플랜',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF43F5E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '언제든지 취소 가능',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  '$priceString / 월',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: dark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 구독하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_loading || _purchasing || _restoring) ? null : _onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _purchasing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                '월 구독 시작하기',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 구독 복원 버튼
                    TextButton(
                      onPressed: (_loading || _purchasing || _restoring) ? null : _onRestore,
                      style: TextButton.styleFrom(
                        foregroundColor: dark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                      child: _restoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '기존 구독 복원하기 (Restore Purchases)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    bool dark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF43F5E), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
