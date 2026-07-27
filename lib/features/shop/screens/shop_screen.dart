import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/ads/ad_service.dart';
import 'package:nearo_app/core/ads/banner_ad_widget.dart';
import 'package:nearo_app/core/payment/matching_ticket_service.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/features/settings/data/event_repository.dart';
import 'package:nearo_app/shared/api/api_client.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.currentTickets,
    required this.onTicketUpdated,
  });

  final int currentTickets;
  final Future<void> Function() onTicketUpdated;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final MatchingTicketService _ticketService;
  final _eventRepository = EventRepository();
  final _rewardedAd = RewardedAdService();
  bool _purchasing = false;

  int? _adRewardRemaining;
  bool _claimingAdReward = false;

  bool _subscriptionActive = false;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _ticketService = MatchingTicketService(ApiClient());
    _rewardedAd.load();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final results = await Future.wait([
      _eventRepository.getAdRewardStatus(),
      _ticketService.isSubscriptionActive(),
    ]);
    if (!mounted) return;
    final adStatus = results[0] as Map<String, dynamic>;
    setState(() {
      _adRewardRemaining = adStatus['remainingToday'] as int? ?? 0;
      _subscriptionActive = results[1] as bool;
    });
  }

  @override
  void dispose() {
    _rewardedAd.dispose();
    super.dispose();
  }

  Future<void> _onPurchase() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final result = await _ticketService.purchaseAndSync();
      if (!mounted) return;
      if (result >= 0) {
        await widget.onTicketUpdated(); // 부모 화면의 전역 상태 갱신
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매칭권 구매 완료! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        // result == -1: 사용자가 직접 취소한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매가 취소되었습니다.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String msg = '구매에 실패했습니다. 잠시 후 다시 시도해 주세요.';
      if (e is Exception) {
        final errorStr = e.toString();
        // PlatformException 또는 개발자용 시스템 에러 문구가 포함된 경우 필터링
        if (errorStr.contains('PlatformException') ||
            errorStr.contains('CONFIGURATION_ERROR') ||
            errorStr.contains('PurchasesErrorCode') ||
            errorStr.contains('purchases_flutter')) {
          msg = '결제를 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.';
        } else {
          msg = errorStr.replaceFirst('Exception: ', '');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  /// 리워드 광고 시청 후 매칭권 1장 무료 지급 (하루 5회 제한)
  Future<void> _onWatchAd() async {
    if (_claimingAdReward) return;
    if ((_adRewardRemaining ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 시청 가능한 보상 횟수를 모두 사용했어요. 내일 다시 시도해 주세요.')),
      );
      return;
    }
    setState(() => _claimingAdReward = true);

    // 최대 5초 대기하며 광고 로드 확인 (messages_screen.dart의 리워드 광고 패턴과 동일)
    const timeout = Duration(seconds: 5);
    const interval = Duration(milliseconds: 200);
    var waited = Duration.zero;
    while (!_rewardedAd.isLoaded && waited < timeout) {
      await Future.delayed(interval);
      waited += interval;
    }

    if (!_rewardedAd.isLoaded) {
      if (mounted) {
        setState(() => _claimingAdReward = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
      return;
    }

    await _rewardedAd.show(
      onRewarded: (_) => _claimAdReward(),
      onDismissed: () {
        if (mounted) setState(() => _claimingAdReward = false);
      },
    );
  }

  Future<void> _claimAdReward() async {
    try {
      final result = await _eventRepository.claimAdReward();
      if (!mounted) return;
      setState(() => _adRewardRemaining = result['remainingToday'] as int? ?? 0);
      await widget.onTicketUpdated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭권 1장이 지급되었어요! 🎉'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보상 지급에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _onSubscribe() async {
    if (_subscribing) return;
    setState(() => _subscribing = true);
    try {
      final customerInfo = await _ticketService.purchaseUnlimitedSubscription();
      if (!mounted) return;
      if (customerInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구독이 취소되었습니다.')),
        );
        return;
      }
      final active = await _ticketService.isSubscriptionActive();
      if (!mounted) return;
      setState(() => _subscriptionActive = active);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? '구독이 시작되었어요! 이제 매칭권 걱정 없이 신청해 보세요 🎉' : '구독 처리 중이에요. 잠시 후 다시 확인해 주세요.'),
          backgroundColor: active ? const Color(0xFF10B981) : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '구독에 실패했어요. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── 보유 매칭권 카드 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: UniversityTheme.designPinkGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.ticket, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '보유 매칭권',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.currentTickets}개',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '매칭권을 구매해서 마음에 드는 상대에게 매칭을 신청해 보세요!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_subscriptionActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '무제한 구독 이용중 — 매칭권 없이도 자유롭게 매칭 신청할 수 있어요',
                          style: TextStyle(
                            color: dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── 매칭권 상품 카드 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20, 0, 20, MeetzyDesignTokens.bottomNavClearance,
                ),
                child: Column(
                  children: [
                    // ── 광고 보고 무료로 받기 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dark ? Colors.white12 : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: dark ? Colors.white10 : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(LucideIcons.circlePlay, color: Color(0xFFF43F5E), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '광고 보고 무료로 받기',
                                  style: TextStyle(
                                    color: dark ? Colors.white : const Color(0xFF111827),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '오늘 남은 횟수: ${_adRewardRemaining ?? 5}/5',
                                  style: TextStyle(
                                    color: dark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: (_claimingAdReward || (_adRewardRemaining ?? 0) <= 0)
                                ? null
                                : _onWatchAd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF43F5E),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: _claimingAdReward
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('시청', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 무제한 구독 카드 ──
                    if (!_subscriptionActive)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F2937) : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(LucideIcons.crown, color: Color(0xFFFBBF24), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        '월 구독 무제한',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '매칭권 걱정 없이 자유롭게 매칭 신청',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _subscribing ? null : _onSubscribe,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBBF24),
                                foregroundColor: const Color(0xFF111827),
                                disabledBackgroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: _subscribing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Color(0xFF111827), strokeWidth: 2),
                                    )
                                  : const Text('구독하기', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),

                    if (!_subscriptionActive) const SizedBox(height: 16),

                    // 상품 카드
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFB7185)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFB7185).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // 아이콘
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFDA4AF), Color(0xFFFB7185)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFB7185).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.ticket,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 상품명
                            Text(
                              '매칭권 1개',
                              style: TextStyle(
                                color: dark ? Colors.white : const Color(0xFF111827),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 설명
                            Text(
                              '마음에 드는 상대에게\n매칭을 신청할 수 있는 매칭권이에요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dark ? Colors.grey.shade300 : const Color(0xFF6B7280),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 가격
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white10 : const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '₩990',
                                style: TextStyle(
                                  color: dark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 구매 버튼
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _purchasing ? null : _onPurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF43F5E),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _purchasing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.shoppingCart, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            '구매하기',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 안내 문구
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark ? Colors.white12 : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 16,
                                color: dark ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '안내',
                                style: TextStyle(
                                  color: dark ? Colors.grey.shade300 : const Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 매칭권은 매칭 신청 시 1개씩 소모되며, 상대가 거절해도 환불되지 않습니다.\n• 구매한 매칭권은 환불이 불가합니다.\n• 광고 시청 보상은 하루 5회까지 받을 수 있어요.\n• 월 구독 중에는 매칭권 소모 없이 자유롭게 매칭 신청할 수 있어요.\n• 문의사항은 설정 > 문의하기를 이용해 주세요.',
                            style: TextStyle(
                              color: dark ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const BannerAdWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}
