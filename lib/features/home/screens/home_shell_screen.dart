import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/home/screens/game_placeholder_screen.dart';
import 'package:nearo_app/features/home/screens/university_ranking_screen.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  /// 대학교 랭킹(0) / 게임(1) / 게시판(2) / 상점(3) / 프로필(4) — 스와이프 가능한 5개
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  final List<Widget> _pages = [
    const UniversityRankingScreen(),
    const GamePlaceholderScreen(),
    MatchingBoardScreen(),
    RatingsScreen(),
    const MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadThemeAndProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadThemeAndProfile() async {
    try {
      final result = await _authRepository.getProfile();
      final user = (result['user'] as Map?)?.cast<String, dynamic>() ?? result as Map<String, dynamic>;
      final affiliation = user['affiliationText']?.toString();
      if (affiliation != null && affiliation.isNotEmpty) {
        switch (affiliation) {
          case '세종대학교':
            ThemeController.setSeedColor(const Color(0xFFB93234));
            break;
          case '건국대학교':
            ThemeController.setSeedColor(const Color(0xFF036B3F));
            break;
          case '한양대학교':
            ThemeController.setSeedColor(const Color(0xFF1D2475));
            break;
        }
      }
      setState(() {
        _profile = user;
        _profileLoading = false;
      });
    } catch (_) {
      setState(() => _profileLoading = false);
    }
  }

  Widget _buildTopBar() {
    final affiliation = _profile != null ? _profile!['affiliationText']?.toString() : null;
    final affiliationShort = affiliation != null && affiliation.isNotEmpty
        ? (affiliation.endsWith('학교')
            ? affiliation.substring(0, affiliation.length - 2)
            : affiliation)
        : '';
    final primary = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.background;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 75,
          decoration: BoxDecoration(
            color: primary,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 왼쪽: MeetZi + 소속대학(작게)
                  Text(
                    'MeetZi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
              if (affiliationShort.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  affiliationShort,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                  ),
                ),
              ],
              const Spacer(),
              // 오른쪽: 종이비행기 → 메시지함(라우트), 톱니바퀴 → 설정(라우트)
              IconButton(
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Transform.rotate(
                  angle: -math.pi / 4,
                  child: const Icon(Icons.send_outlined, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MessagesScreen(),
                    ),
                  );
                },
                tooltip: '메시지함',
              ),
              IconButton(
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: '설정',
              ),
                ],
              ),
            ),
          ),
        ),
        // 상단바 아래 8px 그라데이션 (primary → background)
        Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primary, background],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                if (index == 1) {
                  // 게임 탭: GestureDetector 없이 단순 위젯만 사용해
                  // PageView의 스크롤 제스처가 경쟁에서 이기도록 함
                  return ColoredBox(
                    color: Theme.of(context).colorScheme.background,
                    child: Center(
                      child: Text(
                        '게임',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }
                return _pages[index];
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) return;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: '대학교 랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_outlined),
            label: '게임',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: '상점',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
