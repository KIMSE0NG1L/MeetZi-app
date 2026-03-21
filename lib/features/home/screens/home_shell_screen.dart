import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/community/screens/community_tab_screen.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/matching_board/screens/mailbox_screen.dart';
import 'package:nearo_app/features/matching_board/widgets/match_card_avatar.dart';
import 'package:nearo_app/features/messages/screens/messages_screen.dart';
import 'package:nearo_app/features/notifications/screens/notifications_screen.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/ratings/screens/ratings_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/features/matching_board/utils/board_note_sheet_launcher.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/presentation/widgets/meetzy_coach_mark.dart';

/// 설명 주석
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> with RouteAware {
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);
  final _authRepository = AuthRepository();
  final MatchingBoardRepository _matchingBoardRepository = MatchingBoardRepository();
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  final ValueNotifier<int> _boardRefreshTrigger = ValueNotifier<int>(0);
  bool _routeObserverSubscribed = false;
  bool _takeNoteDialogShown = false;
  bool _showCoachMark = false;
  bool _randomMatchLoading = false;
  final List<String> _recentRandomUserIds = <String>[];

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
    _registerPushTokenIfNeeded();
    PendingTakeNoteStore.instance.pending.addListener(_onPendingTakeNote);
    _checkCoachMark();
  }

  /// 로그인 후 홈 진입 시 FCM 토큰을 서버에 등록 (매칭 요청 등 알림 수신용)
  Future<void> _registerPushTokenIfNeeded() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final client = ApiClient();
      await client.dio.post(
        '/users/push-token',
        data: {'token': token, 'platform': 'android'},
      );
    } catch (e) {
      debugPrint('Failed to register push token: $e');
      // 로그인 전이거나 네트워크 오류 시 무시
    }
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
      _showTakeNoteDialog();
    });
  }


  Future<void> _openMatchingInboxModal() async {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width > 400 ? 24 : 16,
      vertical: 48,
    );
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: '닫기',
      pageBuilder: (_, __, ___) => Padding(
        padding: padding,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F2937)
                    : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: const MailboxScreen(isModal: true),
            ),
          ),
        ),
      ),
    );
  }

  void _showTakeNoteDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('매칭 요청'),
          content: const Text('누군가 당신의 프로필을 가져가려 해요.\n매칭 대기함에서 확인해 보세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _takeNoteDialogShown = false;
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _takeNoteDialogShown = false;
                _openMatchingInboxModal();
              },
              child: const Text('확인'),
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
    // 설명 주석
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
        } catch (e) {
          debugPrint('Failed to load school theme color: $e');
        }
      }
      final result = await _authRepository.getProfile();
      final user = (result['user'] as Map?)?.cast<String, dynamic>() ?? result as Map<String, dynamic>;
      setState(() {
        _profile = user;
        _profileLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load theme and profile: $e');
      setState(() => _profileLoading = false);
    }
  }

  String get _affiliationShort {
    final affiliation = _profile?['affiliationText']?.toString();
    if (affiliation == null || affiliation.isEmpty) return '';
    return affiliation.endsWith('대학교')
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
        title = 'My프로필';
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
    const inactiveColor = Color(0xFF9CA3AF); // gray-400 (last)
    // last: active tab = bg-gradient-to-br themeColors.gradient (from-rose-300 via-pink-300 to-rose-400), text white
    final activeGradient = ThemeController.getActiveAccentGradient();
    final labels = ['커뮤니티', '메시지함', '홈', 'My프로필', '상점'];
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_pageController.hasClients && _currentIndex == i) {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      });
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

  void _rememberRandomUser(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final userId = profile['userId']?.toString() ?? user?['id']?.toString();
    if (userId == null || userId.isEmpty) return;
    _recentRandomUserIds.remove(userId);
    _recentRandomUserIds.add(userId);
    if (_recentRandomUserIds.length > 30) {
      _recentRandomUserIds.removeAt(0);
    }
  }

  Future<void> _onTapRandomMatch() async {
    if (_randomMatchLoading || !mounted) return;
    setState(() => _randomMatchLoading = true);
    try {
      final profile = await _matchingBoardRepository.fetchRandomProfile(
        excludeUserIds: _recentRandomUserIds,
      );
      if (!mounted) return;
      await launchBoardNoteSheet(
        context: context,
        repo: _matchingBoardRepository,
        profile: profile,
        buildAvatar: (ctx, p) => buildMatchCardAvatar(p),
        showTertiaryCloseButton: true,
        onPop: () {
          if (mounted) setState(() {});
        },
        onRequestNextProfile: (excludeUserIds) async {
          try {
            final next = await _matchingBoardRepository.fetchRandomProfile(
              excludeUserIds: excludeUserIds,
            );
            _rememberRandomUser(next);
            return next;
          } catch (e) {
            debugPrint('Failed to fetch next random profile: $e');
            return null;
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      String message = '랜덤 매칭 대상을 불러오지 못했어요.';
      if (e is DioException && e.response?.statusCode == 404) {
        final msg = (e.response?.data is Map)
            ? (e.response!.data as Map)['message'] as String?
            : null;
        message = (msg != null && msg.trim().isNotEmpty)
            ? msg.trim()
            : '같은 학교에 매칭 상대가 없습니다.';
        // 게시판은 '전체 대학'이면 다른 학교도 보이지만, 랜덤 매칭은 같은 학교만 대상
        message = '$message 지금 카드는 전체 대학이라 다른 학교일 수 있어요. 랜덤 매칭은 같은 학교만 됩니다.';
      } else if (e is DioException && e.response?.data is Map) {
        final msg = (e.response!.data as Map)['message'];
        if (msg is String && msg.trim().isNotEmpty) message = msg.trim();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _randomMatchLoading = false);
    }
  }

  Widget _buildRandomMatchButton() {
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111827)
        : const Color(0xFFF9FAFB);
    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ThemeController.getActiveAccentGradient(),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _randomMatchLoading ? null : _onTapRandomMatch,
                child: Center(
                  child: _randomMatchLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shuffle, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              '\uB79C\uB364 \uB9E4\uCE6D',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
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
              if (_currentIndex == 2) _buildRandomMatchButton(),
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


