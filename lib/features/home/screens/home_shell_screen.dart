import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/matching/screens/matching_home_screen.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/ui/widgets/avatar_widget.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 2;
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  final List<Widget> _pages = [
    MyProfileScreen(),
    MessagesScreen(),
    MatchingBoardScreen(), // 매칭 게시판
    SettingsScreen(),
    RatingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadThemeAndProfile();
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
          // 오른쪽 상단 아바타 + 대학교명
          Positioned(
            top: 36,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_profileLoading && _profile != null && _profile!['avatarOptions'] != null && _profile!['avatarSeed'] != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _currentIndex = 0); // 내 프로필 탭으로 이동
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: AvatarWidget(
                            faceShape: _profile!['avatarOptions']['faceShape'] ?? 'default',
                            hairBack: _profile!['avatarOptions']['hairBack'] ?? 'default',
                            hairFront: _profile!['avatarOptions']['hairFront'] ?? 'default',
                            hairColor: _profile!['avatarOptions']['hairColor'] ?? '#000000',
                            eyes: _profile!['avatarOptions']['eyes'] ?? 'default',
                            mouth: _profile!['avatarOptions']['mouth'] ?? 'default',
                            clothes: _profile!['avatarOptions']['clothes'] ?? 'default',
                            clothesColor: _profile!['avatarOptions']['clothesColor'] ?? '#000000',
                            accessory: _profile!['avatarOptions']['accessory'] ?? '',
                            skinColor: _profile!['avatarOptions']['skinColor'] ?? '#ffe0bd',
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!_profileLoading && _profile != null && _profile!['affiliationText'] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      _profile!['affiliationText'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                      ),
                    ),
                  ),
              ],
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
