import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/features/community/screens/community_screen.dart';

/// AppDesign RankingScreen: 보라 테마, 트로피 섹션, 카드형 랭킹 리스트
class UniversityRankingScreen extends StatefulWidget {
  const UniversityRankingScreen({super.key});

  @override
  State<UniversityRankingScreen> createState() => _UniversityRankingScreenState();
}

class _UniversityRankingScreenState extends State<UniversityRankingScreen> with SingleTickerProviderStateMixin {
  final EnvironmentRepository _envRepo = EnvironmentRepository();
  List<Map<String, dynamic>> _ranking = [];
  bool _loading = true;
  static const _purple = Color(0xFFA855F7);
  late AnimationController _liveController;
  late Animation<double> _livePulse;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRanking();
    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _livePulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _liveController, curve: Curves.easeInOut),
    );
    // 실시간처럼: 60초마다 랭킹 다시 불러와서 숫자 갱신
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshRankingQuiet());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _liveController.dispose();
    super.dispose();
  }

  Future<void> _loadRanking() async {
    setState(() => _loading = true);
    try {
      final list = await _envRepo.getRanking();
      if (mounted) setState(() {
        _ranking = list.isNotEmpty ? list : _defaultRanking;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _ranking = _defaultRanking;
        _loading = false;
      });
    }
  }

  /// 로딩 인디케이터 없이 조용히 새 데이터만 반영 (실시간 갱신용)
  Future<void> _refreshRankingQuiet() async {
    if (!mounted) return;
    try {
      final list = await _envRepo.getRanking();
      if (mounted && list.isNotEmpty) {
        setState(() => _ranking = list);
      }
    } catch (_) {}
  }

  static const _defaultRanking = [
    {'rank': 1, 'name': '서울대학교', 'users': 3240, 'count': 3240},
    {'rank': 2, 'name': '연세대학교', 'users': 2891, 'count': 2891},
    {'rank': 3, 'name': '고려대학교', 'users': 2756, 'count': 2756},
    {'rank': 4, 'name': '성균관대학교', 'users': 2103, 'count': 2103},
    {'rank': 5, 'name': '한양대학교', 'users': 1987, 'count': 1987},
    {'rank': 6, 'name': '중앙대학교', 'users': 1654, 'count': 1654},
    {'rank': 7, 'name': '경희대학교', 'users': 1532, 'count': 1532},
    {'rank': 8, 'name': '이화여자대학교', 'users': 1421, 'count': 1421},
    {'rank': 9, 'name': '세종대학교', 'users': 1203, 'count': 1203},
    {'rank': 10, 'name': '건국대학교', 'users': 1105, 'count': 1105},
  ];

  int _users(dynamic item) {
    if (item['users'] is int) return item['users'] as int;
    if (item['count'] is int) return item['count'] as int;
    return int.tryParse(item['users']?.toString() ?? item['count']?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFAF5FF), Colors.white, Color(0xFFF5F0FF)],
              ),
        color: dark ? const Color(0xFF111827) : null,
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // 트로피 섹션 (AppDesign)
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: dark ? _purple.withOpacity(0.3) : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(LucideIcons.trophy, size: 48, color: dark ? const Color(0xFFC084FC) : _purple),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '전국 대학생들이\n함께하고 있어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : const Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '실시간 활성 유저 랭킹',
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_ranking.isEmpty)
                  Center(
                    child: Text(
                      '랭킹 데이터가 없습니다.',
                      style: TextStyle(color: dark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  )
                else
                  ...List.generate(_ranking.length, (index) {
                    final item = _ranking[index];
                    final rank = item['rank'] is int ? item['rank'] as int : (index + 1);
                    final name = item['name']?.toString() ?? '-';
                    final users = _users(item);
                    final isTop3 = rank <= 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: dark ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        shadowColor: Colors.black.withOpacity(0.06),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (item['environmentId'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => CommunityScreen(
                                            environmentId: item['environmentId'] as String,
                                            schoolName: name,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      LucideIcons.messageCircle,
                                      color: isTop3 ? _purple : (dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                      size: 24,
                                    ),
                                    tooltip: '커뮤니티',
                                    style: IconButton.styleFrom(
                                      backgroundColor: dark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                    ),
                                  ),
                                ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isTop3
                                      ? (dark ? _purple.withOpacity(0.3) : _purple.withOpacity(0.2))
                                      : (dark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isTop3 ? _purple : (dark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: dark ? Colors.white : const Color(0xFF111827),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedBuilder(
                                      animation: _livePulse,
                                      builder: (context, _) {
                                        final opacity = 0.45 + 0.55 * _livePulse.value;
                                        return Opacity(
                                          opacity: opacity.clamp(0.0, 1.0),
                                          child: Text(
                                            '${users.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}명 활동중',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (isTop3)
                                Text(
                                  rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                                  style: const TextStyle(fontSize: 28),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 96),
              ],
            ),
    );
  }
}
