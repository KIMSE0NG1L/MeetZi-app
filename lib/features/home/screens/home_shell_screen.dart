import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:nearo_app/features/notifications/data/pending_match_accept_store.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/features/profile/screens/my_profile_screen.dart';
import 'package:nearo_app/features/settings/screens/settings_screen.dart';
import 'package:nearo_app/features/matching_board/utils/board_note_sheet_launcher.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/presentation/widgets/meetzy_coach_mark.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearo_app/core/payment/matching_ticket_service.dart';
import 'package:nearo_app/features/shop/screens/shop_screen.dart';

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
  final MatchingBoardRepository _matchingBoardRepository =
      MatchingBoardRepository();
  Map<String, dynamic>? _profile;
  final ValueNotifier<int> _boardRefreshTrigger = ValueNotifier<int>(0);
  bool _routeObserverSubscribed = false;
  bool _takeNoteDialogShown = false;
  bool _matchAcceptedDialogShown = false;
  bool _showCoachMark = false;
  bool _randomMatchLoading = false;
  final List<String> _recentRandomUserIds = <String>[];
  final MatchingRepository _matchingRepository = MatchingRepository();
  int _matchingTicket = 0;
  int _inboxCount = 0;
  bool _isSheetOpen = false; // 바텀시트(프로필 카드)가 열려있는 동안 didPopNext 새로고침 방지

  // setState() 호출 때마다 재생성되지 않도록 고정 필드로 관리
  // (getter로 선언하면 setState마다 새 인스턴스가 생겨 화면이 새로고침됨)
  late final List<Widget> _fixedPages;


  @override
  void initState() {
    super.initState();
    _fixedPages = [
      const CommunityTabScreen(),
      const MessagesScreen(),
      MatchingBoardScreen(
        refreshTrigger: _boardRefreshTrigger,
        onRandomMatchTap: _onTapRandomMatch,
      ),
      const MyProfileScreen(),
      // index 4: ShopScreen — currentTickets가 변하므로 build()에서 동적 생성
    ];
    _loadThemeAndProfile();
    _fetchMatchingStats();
    _initRevenueCat();
    PendingTakeNoteStore.instance.pending.addListener(_onPendingTakeNote);
    PendingMatchAcceptStore.instance.pending
        .addListener(_onPendingMatchAccepted);
    _checkCoachMark();
    _checkAcceptedMatchesOnLaunch();
  }

  Future<void> _fetchMatchingStats() async {
    try {
      final summary = await _matchingBoardRepository.fetchMySummary();
      if (!mounted) return;
      setState(() => _matchingTicket = summary.tickets.matchingTicket);
    } catch (e) {
      debugPrint('Failed to fetch matching ticket: $e');
    }
    try {
      final list = await _matchingBoardRepository.fetchMyTakeNoteRequests();
      if (!mounted) return;
      final count = list.where((r) => r['status']?.toString() == 'pending').length;
      setState(() => _inboxCount = count);
    } catch (e) {
      debugPrint('Failed to fetch inbox count: $e');
    }
  }

  /// RevenueCat 초기화 (매칭권 결제용)
  Future<void> _initRevenueCat() async {
    try {
      final profile = await _authRepository.getProfile();
      final userId = (profile['user'] as Map?)?['id']?.toString() ??
          profile['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        await MatchingTicketService.initialize(userId);
      }
    } catch (e) {
      debugPrint('[HomeShell] RevenueCat init failed: $e');
    }
  }

  /// FCM 토큰 등록은 NotificationService.initialize()에서 이미 처리하므로 중복 제거됨

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

  void _onPendingMatchAccepted() {
    final accepted = PendingMatchAcceptStore.instance.pending.value;
    if (accepted == null || _matchAcceptedDialogShown || !mounted) return;
    PendingMatchAcceptStore.instance.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showAcceptedMatchDialog(
        count: 1,
        roomId: accepted.roomId,
        requestIds: [accepted.requestId],
      );
    });
  }

  Future<List<String>> _getSeenAcceptedRequestIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('seen_accepted_take_note_request_ids') ??
        <String>[];
  }

  Future<void> _markAcceptedRequestIdsSeen(List<String> requestIds) async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getStringList('seen_accepted_take_note_request_ids') ??
            <String>[];
    final merged = <String>{
      ...current,
      ...requestIds.where((id) => id.isNotEmpty)
    };
    await prefs.setStringList(
        'seen_accepted_take_note_request_ids', merged.toList());
  }

  Future<void> _checkAcceptedMatchesOnLaunch() async {
    try {
      final seenIds = await _getSeenAcceptedRequestIds();
      final requests =
          await _matchingBoardRepository.fetchMySentTakeNoteRequests();
      final accepted = requests.where((request) {
        final requestId = request['id']?.toString() ?? '';
        return request['status']?.toString() == 'accepted' &&
            requestId.isNotEmpty &&
            !seenIds.contains(requestId);
      }).toList();

      if (accepted.isEmpty || !mounted) return;

      final firstRoomId = accepted.first['roomId']?.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAcceptedMatchDialog(
          count: accepted.length,
          roomId: firstRoomId,
          requestIds: accepted
              .map((request) => request['id']?.toString() ?? '')
              .toList(),
        );
      });
    } catch (e) {
      debugPrint('Failed to check accepted matches on launch: $e');
    }
  }

  Future<void> _openAcceptedMatchChat({String? roomId}) async {
    String? targetRoomId = roomId;
    if (targetRoomId == null || targetRoomId.isEmpty) {
      try {
        final activeMatch = await _matchingRepository.getActiveMatch();
        targetRoomId = activeMatch['roomId']?.toString() ??
            (activeMatch['chatRoom'] as Map?)?['id']?.toString();
      } catch (e) {
        debugPrint('Failed to resolve active match room: $e');
      }
    }

    if (!mounted) return;

    if (targetRoomId != null && targetRoomId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: {'roomId': targetRoomId, 'partnerNickname': '상대'},
      );
      return;
    }

    _openMatchingInboxModal();
  }

  void _showAcceptedMatchDialog({
    required int count,
    String? roomId,
    required List<String> requestIds,
  }) {
    if (_matchAcceptedDialogShown || !mounted) return;
    _matchAcceptedDialogShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final title = count > 1 ? '$count명과 매칭되었어요!' : '매칭이 성사되었어요!';
        final body =
            count > 1 ? '지금 바로 채팅을 시작해보세요.' : '상대가 요청을 수락했어요. 바로 채팅방으로 이동할까요?';
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () async {
                await _markAcceptedRequestIdsSeen(requestIds);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () async {
                await _markAcceptedRequestIdsSeen(requestIds);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                await _openAcceptedMatchChat(roomId: roomId);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    ).then((_) {
      _matchAcceptedDialogShown = false;
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
      barrierColor: Colors.black.withOpacity(0.22),
      barrierLabel: '닫기',
      pageBuilder: (_, __, ___) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final tint = ThemeController.seedColor.value;
        return Padding(
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
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark
                          ? Color.lerp(const Color(0xFF1F2937), tint, 0.15)!
                          : Color.lerp(Colors.white, tint, 0.08)!,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: const MailboxScreen(isModal: true),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    PendingMatchAcceptStore.instance.pending
        .removeListener(_onPendingMatchAccepted);
    routeObserver.unsubscribe(this);
    _boardRefreshTrigger.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 바텀시트(showGeneralDialog)가 닫힌 경우는 무시 — 실제 화면 전환 시에만 새로고침
    if (_isSheetOpen) {
      _isSheetOpen = false;
      return;
    }
    _boardRefreshTrigger.value++;
    _fetchMatchingStats();
  }

  Future<void> _loadThemeAndProfile() async {
    try {
      await ThemeController.loadThemeColorMode();
      if (ThemeController.themeColorMode.value == 'school') {
        try {
          final status =
              await EnvironmentStatusRepository().getMyEnvironmentStatus();
          final primaryHex =
              (status['environment'] as Map?)?['primaryColor']?.toString();
          final primary = ThemeController.parsePrimaryColor(primaryHex);
          if (primary != null) ThemeController.setSeedColor(primary);
        } catch (e) {
          debugPrint('Failed to load school theme color: $e');
        }
      }
      final result = await _authRepository.getProfile();
      final user = (result['user'] as Map?)?.cast<String, dynamic>() ??
          result as Map<String, dynamic>;
      setState(() {
        _profile = user;
      });
    } catch (e) {
      debugPrint('Failed to load theme and profile: $e');
    }
  }

  String get _affiliationShort {
    final affiliation = _profile?['affiliationText']?.toString();
    if (affiliation == null || affiliation.isEmpty) return '';
    return affiliation.endsWith('대학교')
        ? affiliation.substring(0, affiliation.length - 2)
        : affiliation;
  }

  /// 5개 탭 공통 상단바. 홈 탭과 동일한 스타일(로고 + 알림벨 + 설정)을 모든 탭에 적용한다.
  Widget _buildTopBar() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    return Container(
      height: pt + 20 + 36,
      width: double.infinity,
      color: dark ? const Color(0xFF111827) : Colors.white,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: pt, bottom: 12),
        child: NavigationToolbar(
          centerMiddle: true,
          middle: Image.asset(
            'assets/images/meetzi_logo.png',
            height: 28,
            fit: BoxFit.contain,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.bell,
                      color: dark ? Colors.white : const Color(0xFF1F2937),
                      size: 24,
                    ),
                    onPressed: _openMatchingInboxModal,
                  ),
                  if (_inboxCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            _inboxCount > 99 ? '99+' : '$_inboxCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.settings,
                  color: dark ? Colors.white : const Color(0xFF1F2937),
                  size: 24,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const inactiveColor = Color(0xFF9CA3AF); // gray-400 (last)
    final activeColor = ThemeController.seedColor.value;
    final labels = ['커뮤니티', '메시지함', '홈', 'My프로필', '상점'];
    final icons = [
      LucideIcons.users,
      LucideIcons.messageCircle,
      LucideIcons.house,
      LucideIcons.user,
      LucideIcons.store,
    ];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(dark ? 0.14 : 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final active = _currentIndex == i;
                  final color = active ? activeColor : inactiveColor;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (i == _currentIndex) return;
                          setState(() => _currentIndex = i);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_pageController.hasClients &&
                                _currentIndex == i) {
                              _pageController.jumpToPage(i);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? Colors.white
                                      : Colors.transparent,
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(icons[i], size: 22, color: color),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: color,
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
      _isSheetOpen = true; // 시트 열림 플래그 — didPopNext 새로고침 억제
      await launchBoardNoteSheet(
        context: context,
        repo: _matchingBoardRepository,
        profile: profile,
        buildAvatar: (ctx, p) => buildMatchCardAvatar(p),
        showTertiaryCloseButton: true,
        myMatchingTicket: _matchingTicket, // 이미 알고 있는 티켓 수 전달 → 추가 API 호출 생략
        onPop: () {},  // setState 제거 — 불필요한 rebuild 방지
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ThemeController.getActiveAccentGradient(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _randomMatchLoading ? null : _onTapRandomMatch,
              child: Center(
                child: _randomMatchLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.zap,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Icon(LucideIcons.shuffle,
                              color: Colors.white, size: 17),
                          SizedBox(width: 8),
                          Text(
                            '\uB79C\uB364 \uB9E4\uCE6D',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('종료'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111827)
          : const Color(0xFFFFF1F2),
      body: Stack(
        children: [
          Positioned.fill(
            // 5개 탭 공통 배경. 각 탭 화면은 투명 배경으로 이 위에 얹힌다.
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : NearoTheme.tabScreenBgGradient,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF111827)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 5,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (_, index) {
                        // ShopScreen만 티켓 수가 바뀌므로 동적 생성; 나머지는 고정 인스턴스 사용
                        if (index == 4) {
                          return ShopScreen(
                            currentTickets: _matchingTicket,
                            onTicketUpdated: _fetchMatchingStats,
                          );
                        }
                        return _fixedPages[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
          if (_showCoachMark)
            MeetzyCoachMark(
              onComplete: () => setState(() => _showCoachMark = false),
              onSkip: () => setState(() => _showCoachMark = false),
            ),
        ],
      ),
      ),
    );
  }
}
