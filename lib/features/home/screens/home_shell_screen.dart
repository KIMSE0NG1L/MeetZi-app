import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/home/screens/university_ranking_screen.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/notifications/screens/notifications_screen.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/features/matching_board/screens/take_note_request_response_screen.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';

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
  bool _takeNoteDialogShown = false;

  List<Widget> get _pages => [
    const UniversityRankingScreen(),
    const MessagesScreen(),
    MatchingBoardScreen(refreshTrigger: _boardRefreshTrigger),
    const MyProfileScreen(),
    RatingsScreen(),
  ];

  static const _purpleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)], // purple-500 to indigo-500
  );

  @override
  void initState() {
    super.initState();
    _loadThemeAndProfile();
    PendingTakeNoteStore.instance.pending.addListener(_onPendingTakeNote);
  }

  void _onPendingTakeNote() {
    final req = PendingTakeNoteStore.instance.pending.value;
    if (req == null || _takeNoteDialogShown || !mounted) return;
    _takeNoteDialogShown = true;
    PendingTakeNoteStore.instance.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTakeNoteDialog(requestId: req.requestId, requesterProfile: req.requesterProfile);
    });
  }

  void _showTakeNoteDialog({required String requestId, Map<String, dynamic>? requesterProfile}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('가져가기 요청'),
          content: const Text('누군가 내 카드를 가져가려고 해요.\n지금 확인해 볼까요?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _takeNoteDialogShown = false;
              },
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _takeNoteDialogShown = false;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TakeNoteRequestResponseScreen(
                      requestId: requestId,
                      requesterProfile: requesterProfile,
                    ),
                  ),
                );
              },
              child: const Text('보기'),
            ),
          ],
        );
      },
    ).then((_) => _takeNoteDialogShown = false);
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
    PendingTakeNoteStore.instance.pending.removeListener(_onPendingTakeNote);
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
      await ThemeController.loadThemeColorMode();
      if (ThemeController.themeColorMode.value == 'school') {
        try {
          final status = await EnvironmentStatusRepository().getMyEnvironmentStatus();
          final primaryHex = (status['environment'] as Map?)?['primaryColor']?.toString();
          final primary = ThemeController.parsePrimaryColor(primaryHex);
          if (primary != null) ThemeController.setSeedColor(primary);
        } catch (_) {}
      }
      final result = await _authRepository.getProfile();
      final user = (result['user'] as Map?)?.cast<String, dynamic>() ?? result as Map<String, dynamic>;
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
    final gradient = isRanking ? _purpleGradient : ThemeController.getHeaderGradient();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    const inactiveColor = Color(0xFF9CA3AF); // grey
    const activePink = NearoTheme.designPink500;
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
        color: dark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final active = _currentIndex == i;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? activePink : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 24,
                            color: active ? Colors.white : inactiveColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                              color: active ? Colors.white : inactiveColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
