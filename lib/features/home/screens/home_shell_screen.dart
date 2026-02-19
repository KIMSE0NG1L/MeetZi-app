import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/home/screens/university_ranking_screen.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/notifications/screens/notifications_screen.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  /// 대학교 랭킹(0) / 메시지함(1) / 게시판(2) / 프로필(3) / 상점(4) — 스와이프 가능한 5개
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  final List<Widget> _pages = [
    const UniversityRankingScreen(),
    const MessagesScreen(),
    MatchingBoardScreen(),
    const MyProfileScreen(),
    RatingsScreen(),
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
    final universityColor = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 120, // 기존 75에서 120으로 크게
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                universityColor,
                universityColor.withOpacity(0.85),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/noise.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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
                        IconButton(
                          style: IconButton.styleFrom(shape: const CircleBorder()),
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                          tooltip: '알림',
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
            ],
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
          if (_currentIndex != 1) _buildTopBar(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => _pages[index],
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
            icon: Icon(Icons.chat_bubble_outline),
            label: '메시지함',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '프로필',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: '상점',
          ),
        ],
      ),
    );
  }
}
