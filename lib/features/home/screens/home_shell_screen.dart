import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/matching/screens/matching_home_screen.dart';
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
  int _currentIndex = 2;
  final _authRepository = AuthRepository();

  static const _pages = [
      MyProfileScreen(),
      MessagesScreen(),
      MatchingBoardScreen(), // 매칭 게시판
      SettingsScreen(),
      RatingsScreen(),
    ];

  @override
  void initState() {
    super.initState();
    _loadThemeFromProfile();
  }

  Future<void> _loadThemeFromProfile() async {
    try {
      final result = await _authRepository.getProfile();
      final user = (result['user'] as Map?) ?? result;
      final affiliation = user['affiliationText']?.toString();
      if (affiliation == null || affiliation.isEmpty) return;

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
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.background,
                ],
                stops: const [0.0, 0.12, 0.22],
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! > 200 && _currentIndex > 0) {
                setState(() => _currentIndex = _currentIndex - 1);
              }
              if (details.primaryVelocity! < -200 && _currentIndex < _pages.length - 1) {
                setState(() => _currentIndex = _currentIndex + 1);
              }
            },
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '내 프로필',
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
            icon: Icon(Icons.settings_outlined),
            label: '설정',
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
