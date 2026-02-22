import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';

/// AppDesign ShopScreen: 보유 코인 박스 + 패키지 카드 (로즈/다크 스타일)
class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  static const List<Map<String, dynamic>> _packages = [
    {'coins': 10, 'price': 1100, 'bonus': null, 'badge': null, 'popular': false},
    {'coins': 50, 'price': 5500, 'bonus': 5, 'badge': null, 'popular': false},
    {'coins': 100, 'price': 11000, 'bonus': 15, 'badge': null, 'popular': true},
    {'coins': 300, 'price': 33000, 'bonus': 50, 'badge': null, 'popular': false},
    {'coins': 500, 'price': 55000, 'bonus': 100, 'badge': null, 'popular': false},
  ];

  final MatchingBoardRepository _repository = MatchingBoardRepository();
  bool _loading = false;
  int? _myCredit;

  @override
  void initState() {
    super.initState();
    _fetchCredit();
  }

  Future<void> _fetchCredit() async {
    try {
      final credit = await _repository.fetchMyCredit();
      if (mounted) setState(() => _myCredit = credit);
    } catch (_) {
      if (mounted) setState(() => _myCredit = null);
    }
  }

  Future<void> _buyCredit(int coins) async {
    setState(() => _loading = true);
    try {
      await _repository.buyCredit(coins);
      await _fetchCredit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$coins 코인 구매 완료!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('구매 실패: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 코인으로 열람권/등록권 구매 (1코인=1열람권, 5코인=1등록권)
  Future<void> _buyTicket(String product, int cost, String label, {int quantity = 1}) async {
    if ((_myCredit ?? 0) < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코인이 부족해요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _repository.purchaseTicket(product, quantity: quantity);
      await _fetchCredit();
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

  Widget _ticketCard(
    bool dark,
    Color surface,
    Color onSurface,
    Color onSurfaceVariant,
    Color rose,
    int cost,
    String label,
    String costStr,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: dark ? Colors.grey.shade300 : rose),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
                    Text('$costStr코인', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                '$costStr 코인',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: rose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    const rose = Color(0xFFF43F5E);

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // 보유 코인 (로즈 헤더 아래 흰색 반투명 스타일)
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
                          child: Icon(LucideIcons.coins, color: dark ? Colors.amber.shade200 : Colors.amber.shade700, size: 26),
                        ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('보유 코인', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                      Text(
                        _myCredit != null ? '${_myCredit!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}' : '-',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용내역은 준비 중이에요')));
                    },
                    child: Text('사용내역', style: TextStyle(color: rose, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // 코인으로 구매: 1코인=열람권 1장, 5코인=등록권 1장
                      Text('코인으로 구매', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                      const SizedBox(height: 8),
                      _ticketCard(dark, surface, onSurface, onSurfaceVariant, rose, 1, '열람권 1장', '1', LucideIcons.eye, () => _buyTicket('view_ticket', 1, '열람권 1장')),
                      const SizedBox(height: 8),
                      _ticketCard(dark, surface, onSurface, onSurfaceVariant, rose, 100, '열람권 100장', '100', LucideIcons.eye, () => _buyTicket('view_ticket', 100, '열람권 100장', quantity: 100)),
                      const SizedBox(height: 8),
                      _ticketCard(dark, surface, onSurface, onSurfaceVariant, rose, 5, '등록권 1장', '5', LucideIcons.clipboardList, () => _buyTicket('register_ticket', 5, '등록권 1장')),
                      const SizedBox(height: 8),
                      _ticketCard(dark, surface, onSurface, onSurfaceVariant, rose, 500, '등록권 100장', '500', LucideIcons.clipboardList, () => _buyTicket('register_ticket', 500, '등록권 100장', quantity: 100)),
                      const SizedBox(height: 24),
                      ...List.generate(_packages.length, (index) {
                        final pkg = _packages[index];
                        final coins = pkg['coins'] as int;
                        final price = pkg['price'] as int;
                        final bonus = pkg['bonus'] as int?;
                        final badge = pkg['badge'] as String?;
                        final popular = pkg['popular'] as bool? ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.06),
                            child: InkWell(
                              onTap: () => _buyCredit(coins),
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
                                        LucideIcons.coins,
                                        size: 34,
                                        color: dark ? Colors.grey.shade300 : rose,
                                      ),
                                    ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                                textBaseline: TextBaseline.alphabetic,
                                                children: [
                                                  Text(
                                                    '${coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                                                  ),
                                                  if (bonus != null) ...[
                                                    const SizedBox(width: 8),
                                                    Text('+$bonus', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text('코인', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                                              if (badge != null) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: rose, borderRadius: BorderRadius.circular(999)),
                                                  child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                                            ),
                                            if (bonus != null && coins > 0)
                                              Text(
                                                '${((bonus / coins) * 100).round()}% 보너스',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E), fontWeight: FontWeight.w500),
                                              ),
                                          ],
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
        ],
      ),
    );
  }
}
