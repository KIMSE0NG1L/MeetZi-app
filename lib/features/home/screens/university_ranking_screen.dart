import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

/// 바텀 탭 "대학교 랭킹" 전용 화면. 온보딩 대학 랭킹과 동일한 디자인.
class UniversityRankingScreen extends StatefulWidget {
  const UniversityRankingScreen({super.key});

  @override
  State<UniversityRankingScreen> createState() => _UniversityRankingScreenState();
}

class _UniversityRankingScreenState extends State<UniversityRankingScreen> {
  final EnvironmentRepository _envRepo = EnvironmentRepository();
  List<Map<String, dynamic>> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() => _loading = true);
    try {
      final list = await _envRepo.getRanking();
      if (mounted) setState(() {
        _ranking = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            '대학별 가입자 수',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '지금 함께하는 캠퍼스를 확인해 보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_ranking.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '랭킹 데이터가 없습니다.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _ranking.length,
                itemBuilder: (context, index) {
                  final item = _ranking[index];
                  final rank = item['rank'] ?? (index + 1);
                  final rankInt = rank is int ? rank : int.tryParse(rank.toString()) ?? (index + 1);
                  final name = item['name']?.toString() ?? '-';
                  final count = item['count'] is int
                      ? item['count'] as int
                      : int.tryParse(item['count']?.toString() ?? '0') ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rankInt <= 3
                                ? NearoTheme.primary.withOpacity(0.2)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$rankInt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rankInt <= 3 ? NearoTheme.primary : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${count}명',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
