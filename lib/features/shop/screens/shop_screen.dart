import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/payment/matching_ticket_service.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
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
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _ticketService = MatchingTicketService(ApiClient());
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
      final msg = (e is Exception)
          ? e.toString().replaceFirst('Exception: ', '')
          : '구매에 실패했습니다. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? null
            : UniversityTheme.screenBgGradient,
        color: dark ? const Color(0xFF111827) : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: UniversityTheme.designPinkGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.store, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        '상점',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // 보유 매칭권 표시
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.ticket, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.currentTickets}개',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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

            const SizedBox(height: 24),

            // ── 매칭권 상품 카드 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
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
                            '• 매칭권은 매칭 신청 시 1개씩 소모됩니다.\n• 구매한 매칭권은 환불이 불가합니다.\n• 문의사항은 설정 > 문의하기를 이용해 주세요.',
                            style: TextStyle(
                              color: dark ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
