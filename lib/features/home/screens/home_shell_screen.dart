import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/community/screens/community_tab_screen.dart';
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
import 'package:nearo_app/presentation/widgets/meetzy_coach_mark.dart';

/// AppDesign 湲곗?: ??퀎 ?ㅻ뜑 洹몃씪?곗씠??+ ?섎떒 5???ㅻ퉬 (??숆탳 ??궧 / 硫붿떆吏??/ 寃뚯떆??/ ?꾨줈??/ ?곸젏)
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
  bool _showCoachMark = false;

  List<Widget> get _pages => [
    const CommunityTabScreen(),
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
    _checkCoachMark();
  }

  Future<void> _checkCoachMark() async {
    final shouldShow = await MeetzyCoachMark.shouldShow();
    if (mounted && shouldShow) setState(() => _showCoachMark = true);
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
          title: const Text('媛?멸?湲??붿껌'),
          content: const Text('?꾧뎔媛 ??移대뱶瑜?媛?멸??ㅺ퀬 ?댁슂.\n吏湲??뺤씤??蹂쇨퉴??'),
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
              child: const Text('蹂닿린'),
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
    // ?ㅻⅨ ?붾㈃(?꾨줈???섏젙 ???먯꽌 ?덉쑝濡??뚯븘?붿쓣 ??寃뚯떆??紐⑸줉 媛깆떊
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
    return affiliation.endsWith('?숆탳')
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
        title = '커뮤니티';
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
        title = '상점';
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
                tooltip: '?뚮┝',
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                tooltip: '?ㅼ젙',
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildBottomNav() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const inactiveColor = Color(0xFF9CA3AF); // gray-400 (last)
    // last: active tab = bg-gradient-to-br themeColors.gradient (from-rose-300 via-pink-300 to-rose-400), text white
    final activeGradient = ThemeController.getActiveAccentGradient();
    final labels = ['커뮤니티', '메시지함', '홈', '프로필', '상점'];
    final icons = [
      LucideIcons.users,
      LucideIcons.messageCircle,
      LucideIcons.house,
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
                        gradient: active ? activeGradient : null,
                        color: active ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))] : null,
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
    final hideTopBarForCommunity = _currentIndex == 0;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111827)
          : const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hideTopBarForCommunity) _buildTopBar(),
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
          if (_showCoachMark)
            MeetzyCoachMark(
              onComplete: () => setState(() => _showCoachMark = false),
              onSkip: () => setState(() => _showCoachMark = false),
            ),
        ],
      ),
    );
  }
}


