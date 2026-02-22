import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/home/screens/university_ranking_screen.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/notifications/screens/notifications_screen.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// AppDesign 기준: 탭별 헤더 그라데이션 + 하단 5탭 네비 (대학교 랭킹 / 메시지함 / 게시판 / 프로필 / 상점)
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> with RouteAware {
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  final ValueNotifier<int> _boardRefreshTrigger = ValueNotifier<int>(0);
  bool _routeObserverSubscribed = false;

  List<Widget> get _pages => [
    const UniversityRankingScreen(),
    const MessagesScreen(),
    MatchingBoardScreen(refreshTrigger: _boardRefreshTrigger),
    const MyProfileScreen(),
    RatingsScreen(),
  ];

  static const _roseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)], // rose-400 to rose-500
  );
  static const _purpleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)], // purple-500 to indigo-500
  );

  @override
  void initState() {
    super.initState();
    _loadThemeAndProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        _routeObserverSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _boardRefreshTrigger.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 화면(프로필 수정 등)에서 홈으로 돌아왔을 때 게시판 목록 갱신
    _boardRefreshTrigger.value++;
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

  String get _affiliationShort {
    final affiliation = _profile?['affiliationText']?.toString();
    if (affiliation == null || affiliation.isEmpty) return '';
    return affiliation.endsWith('학교')
        ? affiliation.substring(0, affiliation.length - 2)
        : affiliation;
  }

  Widget _buildTopBar() {
    final isRanking = _currentIndex == 0;
    final gradient = isRanking ? _purpleGradient : _roseGradient;
    String title = '';
    String? subtitle;
    switch (_currentIndex) {
      case 0:
        title = '대학교 랭킹';
        subtitle = null;
        break;
      case 1:
        title = '메시지함';
        subtitle = null;
        break;
      case 2:
        title = 'Meetzi';
        subtitle = _affiliationShort.isNotEmpty ? _affiliationShort : null;
        break;
      case 3:
        title = '프로필';
        subtitle = null;
        break;
      case 4:
        title = '코인 상점';
        subtitle = null;
        break;
      default:
        title = 'Meetzi';
        subtitle = _affiliationShort.isNotEmpty ? _affiliationShort : null;
        break;
    }

    // AppDesign: px-5 pt-14 pb-5 shadow-md; pt-14=56, pb-5=20, px-5=20
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    return Container(
      height: pt + 20 + 36,
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: pt, bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                tooltip: '알림',
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                tooltip: '설정',
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildBottomNav() {
    const activeColor = Color(0xFFF43F5E); // rose-500
    const inactiveColor = Color(0xFF9CA3AF); // gray-400
    final labels = ['대학교 랭킹', '메시지함', '게시판', '프로필', '상점'];
    final icons = [
      LucideIcons.trophy,
      LucideIcons.messageCircle,
      LucideIcons.grid3x3,
      LucideIcons.user,
      LucideIcons.shoppingBag,
    ];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final active = _currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == _currentIndex) return;
                    setState(() => _currentIndex = i);
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 24,
                          color: active ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                            color: active ? activeColor : inactiveColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111827)
          : const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (_, index) => _pages[index],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }
}
