import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// AppDesign ShopScreen: 보유 매칭권 박스 + 매칭권 패키지 카드 (로즈/다크 스타일)
class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  /// 매칭권 패키지: { tickets: 수량, price: 가격(원) }
  static const List<Map<String, dynamic>> _packages = [
    {'tickets': 1, 'price': 1100},
    {'tickets': 10, 'price': 5500},
    {'tickets': 50, 'price': 22000},
    {'tickets': 100, 'price': 44000},
  ];

  final MatchingBoardRepository _repository = MatchingBoardRepository();
  bool _loading = false;
  int? _myMatchingTicket;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _repository.fetchMyTickets();
      if (mounted) setState(() => _myMatchingTicket = tickets.matchingTicket);
    } catch (_) {
      if (mounted) setState(() => _myMatchingTicket = null);
    }
  }

  Future<void> _buyMatchingTickets(int quantity, String label) async {
    setState(() => _loading = true);
    try {
      await _repository.buyMatchingTickets(quantity: quantity);
      await _fetchTickets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label 구매 완료!')));
    } catch (e) {
      if (!mounted) return;
      String msg = '구매에 실패했어요.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: Column(
          children: [
            // 보유 매칭권 (로즈 헤더 아래 흰색 반투명 스타일)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.heart, color: dark ? Colors.pink.shade200 : Colors.pink.shade600, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('보유 매칭권', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                        Text(
                          _myMatchingTicket != null ? _formatNumber(_myMatchingTicket!) : '-',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용내역은 준비 중이에요')));
                      },
                      child: Text('사용내역', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchTickets,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          Text('매칭권 구매', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                          const SizedBox(height: 12),
                          ...List.generate(_packages.length, (index) {
                            final pkg = _packages[index];
                            final tickets = pkg['tickets'] as int;
                            final price = pkg['price'] as int;
                            final label = '매칭권 ${_formatNumber(tickets)}장';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: surface,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 2,
                                shadowColor: Colors.black.withOpacity(0.06),
                                child: InkWell(
                                  onTap: () => _buyMatchingTickets(tickets, label),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: dark ? [Colors.grey.shade700, Colors.grey.shade600] : [const Color(0xFFFFE4E6), const Color(0xFFFCE7F3)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            LucideIcons.heart,
                                            size: 34,
                                            color: dark ? Colors.grey.shade300 : primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                label,
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
                                              ),
                                              const SizedBox(height: 4),
                                              Text('매칭권', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${_formatNumber(price)}원',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 96),
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
