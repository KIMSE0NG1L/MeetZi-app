import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';

/// AppDesign ShopScreen: 보유 코인 박스 + 패키지 카드 (로즈/다크 스타일)
class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  static const List<Map<String, dynamic>> _packages = [
    {'coins': 10, 'price': 1100, 'bonus': null, 'badge': '첫 구매', 'popular': false},
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
                          child: Icon(Icons.monetization_on, color: dark ? Colors.amber.shade200 : Colors.amber.shade700, size: 26),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1E3A5F).withOpacity(0.5) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dark ? Colors.blue.shade800 : Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.card_giftcard, color: dark ? Colors.blue.shade300 : Colors.blue.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('첫 구매 특별 혜택!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
                                  const SizedBox(height: 4),
                                  Text('처음 구매 시 추가 코인을 드려요', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                        Icons.monetization_on,
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
