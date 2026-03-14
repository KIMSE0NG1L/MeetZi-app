import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/features/community/screens/community_screen.dart';
import 'package:nearo_app/features/home/screens/university_ranking_screen.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// 커뮤니티 탭: 환경 로드 후 CommunityScreen 표시. 환경 없으면 랭킹 이동 버튼.
class CommunityTabScreen extends StatefulWidget {
  const CommunityTabScreen({super.key});

  @override
  State<CommunityTabScreen> createState() => _CommunityTabScreenState();
}

class _CommunityTabScreenState extends State<CommunityTabScreen> {
  final EnvironmentStatusRepository _statusRepo = EnvironmentStatusRepository();
  String? _environmentId;
  String? _schoolName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final status = await _statusRepo.getMyEnvironmentStatus();
      final envId = status['environmentId']?.toString();
      final env = status['environment'] is Map ? status['environment'] as Map : null;
      final name = env?['name']?.toString() ?? status['affiliationText']?.toString();
      if (mounted) {
        setState(() {
          _environmentId = envId;
          _schoolName = name;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _environmentId = null;
        _schoolName = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_environmentId != null && _environmentId!.isNotEmpty) {
      return CommunityScreen(
        environmentId: _environmentId!,
        schoolName: _schoolName?.trim().isNotEmpty == true ? _schoolName!.trim() : '커뮤니티',
        isRootTab: true,
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: dark ? null : ThemeController.getScreenBgGradient(),
        color: dark ? NearoTheme.designScreenBgDark : null,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.trophy, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const UniversityRankingScreen(),
                          ),
                        ).then((_) => _load());
                      },
                      tooltip: '대학교 랭킹',
                    ),
                    const Expanded(
                      child: Text(
                        '커뮤니티',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.school, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(
                '학교 인증이 필요해요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '대학교 랭킹에서 학교를 확인하고\n커뮤니티에 참여해 보세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UniversityRankingScreen(),
                    ),
                  ).then((_) => _load());
                },
                icon: const Icon(LucideIcons.trophy, size: 20),
                label: const Text('대학교 랭킹 보기'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
        ],
      ),
    );
  }
}
