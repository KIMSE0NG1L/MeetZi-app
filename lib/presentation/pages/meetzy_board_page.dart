import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_card.dart';
import 'package:nearo_app/presentation/widgets/meetzy_stats_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nearo_app/features/settings/screens/notice_list_screen.dart';

/// 설명 주석
class MeetzyBoardContent extends StatefulWidget {
  const MeetzyBoardContent({
    super.key,
    this.profiles = const [],
    this.onProfileTap,
    this.onRefresh,
    this.onDeveloperMatchTap,
    this.onSwipeLike,
    this.onMatchButtonTap,
    this.isLoading = false,
    this.scrollController,
    this.isLoadingMore = false,
  });

  final List<MeetzyBoardProfileItem> profiles;
  final void Function(int index, MeetzyBoardProfileItem item)? onProfileTap;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDeveloperMatchTap;
  /// 오른쪽 스와이프(또는 하트 버튼) 시 실제 매칭 신청을 전송한다.
  /// 성공하면 null, 실패하면 사용자에게 보여줄 에러 메시지를 반환한다.
  final Future<String?> Function(int index, MeetzyBoardProfileItem item)? onSwipeLike;
  final Future<String?> Function(int index, MeetzyBoardProfileItem item)? onMatchButtonTap;
  final bool isLoading;
  final ScrollController? scrollController;
  final bool isLoadingMore;

  @override
  State<MeetzyBoardContent> createState() => _MeetzyBoardContentState();
}

class _MeetzyBoardContentState extends State<MeetzyBoardContent>
    with SingleTickerProviderStateMixin {
  int _currentProfileIndex = 0;
  double _dragX = 0;
  bool _cardBusy = false;
  late final AnimationController _cardAnimController;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant MeetzyBoardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentProfileIndex >= widget.profiles.length) {
      _currentProfileIndex = 0;
    }
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  void _advanceCard() {
    if (widget.profiles.isEmpty) return;
    if (_currentProfileIndex < widget.profiles.length - 1) {
      _currentProfileIndex++;
    } else {
      _currentProfileIndex = 0;
    }
  }

  Future<void> _flyTo(double target) async {
    final start = _dragX;
    _cardAnimController.reset();
    final anim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeIn),
    );
    void tick() => setState(() => _dragX = anim.value);
    anim.addListener(tick);
    await _cardAnimController.forward();
    anim.removeListener(tick);
  }

  Future<void> _springBack() async {
    final start = _dragX;
    _cardAnimController.reset();
    final anim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutCubic),
    );
    void tick() => setState(() => _dragX = anim.value);
    anim.addListener(tick);
    await _cardAnimController.forward();
    anim.removeListener(tick);
  }

  void _onCardDragUpdate(DragUpdateDetails details) {
    if (_cardBusy) return;
    setState(() => _dragX += details.delta.dx);
  }

  Future<void> _onCardDragEnd(DragEndDetails details) async {
    if (_cardBusy || widget.profiles.isEmpty) return;
    final width = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = width * 0.28;
    if (_dragX > threshold || velocity > 900) {
      await _onMatchButtonTap();
    } else if (_dragX < -threshold || velocity < -900) {
      await _commitSwipeLeft();
    } else {
      await _springBack();
    }
  }

  Future<void> _commitSwipeLeft() async {
    if (widget.profiles.isEmpty || _cardBusy) return;
    setState(() => _cardBusy = true);
    final width = MediaQuery.of(context).size.width;
    await _flyTo(-width * 1.3);
    _advanceCard();
    if (!mounted) return;
    setState(() {
      _dragX = 0;
      _cardBusy = false;
    });
  }

  Future<void> _commitSwipeRight() async {
    if (widget.profiles.isEmpty || _cardBusy) return;
    if (widget.onSwipeLike == null) {
      await _springBack();
      return;
    }
    setState(() => _cardBusy = true);
    final idx = _currentProfileIndex < widget.profiles.length ? _currentProfileIndex : 0;
    final item = widget.profiles[idx];
    final width = MediaQuery.of(context).size.width;
    final errorFuture = widget.onSwipeLike!(idx, item);
    await _flyTo(width * 1.3);
    final error = await errorFuture;
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
      );
      setState(() {
        _dragX = 0;
        _cardBusy = false;
      });
      return;
    }
    _advanceCard();
    setState(() {
      _dragX = 0;
      _cardBusy = false;
    });
  }

  Future<void> _onMatchButtonTap() async {
    if (widget.profiles.isEmpty || _cardBusy) return;
    if (widget.onMatchButtonTap == null) {
      await _commitSwipeRight();
      return;
    }
    setState(() => _cardBusy = true);
    final idx = _currentProfileIndex < widget.profiles.length ? _currentProfileIndex : 0;
    final item = widget.profiles[idx];
    final error = await widget.onMatchButtonTap!(idx, item);
    if (!mounted) return;

    if (error == null) {
      final width = MediaQuery.of(context).size.width;
      await _flyTo(width * 1.3);
      _advanceCard();
      setState(() {
        _dragX = 0;
        _cardBusy = false;
      });
    } else {
      if (error != 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
        );
      }
      await _springBack();
      setState(() {
        _dragX = 0;
        _cardBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        return SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MeetzyDesignTokens.contentPadding,
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNoticeBanner(context),
                const SizedBox(height: 16),
                
                // 추천 프로필 Title
                Text(
                  '추천 프로필',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),

                // 대표 추천 카드 (틴더식 스와이프: 오른쪽 = 매칭 신청, 왼쪽 = 패스)
                if (widget.profiles.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final idx = _currentProfileIndex < widget.profiles.length ? _currentProfileIndex : 0;
                      final currentProfile = widget.profiles[idx];
                      final likeOpacity = (_dragX / 100).clamp(0.0, 1.0);
                      final nopeOpacity = (-_dragX / 100).clamp(0.0, 1.0);

                      return GestureDetector(
                        onTap: _cardBusy ? null : () => widget.onProfileTap?.call(idx, currentProfile),
                        onHorizontalDragUpdate: _onCardDragUpdate,
                        onHorizontalDragEnd: _onCardDragEnd,
                        child: Transform.translate(
                          offset: Offset(_dragX, 0),
                          child: Transform.rotate(
                            angle: (_dragX / 1200).clamp(-0.2, 0.2),
                            child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: ThemeController.getActiveAccentGradient(),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 배경 이미지 또는 Svg
                                  if (currentProfile.photoUrl != null && currentProfile.photoUrl!.isNotEmpty)
                                    Image.network(
                                      currentProfile.photoUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  else if (currentProfile.avatarUrl != null && currentProfile.avatarUrl!.isNotEmpty)
                                    SvgPicture.network(
                                      currentProfile.avatarUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Container(
                                      color: currentProfile.avatarBgColor ?? Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: Center(
                                        child: SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: currentProfile.avatarWidget,
                                        ),
                                      ),
                                    ),

                                  // 하단 그라데이션 오버레이
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.85),
                                            Colors.black.withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.45, 0.85],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 이름 & 20대 초반 표시
                                  Positioned(
                                    left: 16,
                                    bottom: 128,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentProfile.nickname,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '20대 초반',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 태그 칩
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 88,
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: (currentProfile.tags ?? [
                                        if (currentProfile.school != null && currentProfile.school!.isNotEmpty) currentProfile.school!,
                                        currentProfile.tag,
                                      ]).map((t) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            t,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  // LIKE 스탬프 (오른쪽으로 드래그할수록 진해짐)
                                  Positioned(
                                    top: 20,
                                    left: 20,
                                    child: Opacity(
                                      opacity: likeOpacity,
                                      child: Transform.rotate(
                                        angle: -0.3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFF22C55E), width: 3),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.black.withOpacity(0.1),
                                          ),
                                          child: const Text(
                                            'LIKE',
                                            style: TextStyle(
                                              color: Color(0xFF22C55E),
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // NOPE 스탬프 (왼쪽으로 드래그할수록 진해짐)
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: Opacity(
                                      opacity: nopeOpacity,
                                      child: Transform.rotate(
                                        angle: 0.3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFFEF4444), width: 3),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.black.withOpacity(0.1),
                                          ),
                                          child: const Text(
                                            'NOPE',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 넘기기 / 매칭 — 사진 하단을 가리는 글래스모피즘 액션 바
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(21),
                                        bottomRight: Radius.circular(21),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.16),
                                            border: Border(
                                              top: BorderSide(color: Colors.white.withOpacity(0.28)),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: _cardBusy ? null : _commitSwipeLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: const [
                                                        Icon(LucideIcons.x, color: Colors.white, size: 18),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          '넘기기',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 24,
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: _cardBusy ? null : _onMatchButtonTap,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: const [
                                                        Icon(LucideIcons.heart, color: Colors.white, size: 18),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          '매칭',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                  ),
                ] else
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        '추천 프로필이 없습니다.',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: MeetzyDesignTokens.gridBottomSpace),
              ],
            ),
          ),
        );
      },
    );

    if (widget.onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: body,
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: widget.isLoading ? const Center(child: CircularProgressIndicator()) : body),
        ],
    );
  }

  Widget _buildNoticeBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NoticeListScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFDF4FF), Color(0xFFFAF5FF)],
                  ),
            color: isDark ? const Color(0xFF1F2937) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE9D5FF),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE879F9), Color(0xFFA855F7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.megaphone,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MeetZi 이벤트 및 업데이트',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF6B21A8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFFA855F7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 설명 주석
class MeetzyBoardPage extends StatelessWidget {
  const MeetzyBoardPage({
    super.key,
    this.schoolName = '미지정',
    this.currentTab = 'board',
    this.onTabChange,
    this.onSettings,
    this.onNotification,
    this.myNickname,
    this.myAvatarWidget,
    this.matchingTicket = 0,
    this.profiles = const [],
    this.onProfileTap,
    this.onRefresh,
  });

  final String schoolName;
  final String currentTab;
  final ValueChanged<String>? onTabChange;
  final VoidCallback? onSettings;
  final VoidCallback? onNotification;
  final String? myNickname;
  final Widget? myAvatarWidget;
  final int matchingTicket;
  final List<MeetzyBoardProfileItem> profiles;
  final void Function(int index, MeetzyBoardProfileItem item)? onProfileTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bgGradient = isDark ? null : ThemeController.getScreenBgGradient();
    final surface = isDark ? const Color(0xFF111827) : UniversityTheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? surface : null,
        gradient: bgGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              // Header (last: px-5 pt-14 pb-5, gradient)
              Container(
                padding: MeetzyDesignTokens.headerPadding,
                decoration: BoxDecoration(
                  gradient: UniversityTheme.headerGradient(primary),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('MeetZy', style: AppTextStyles.headerTitle(Colors.white)),
                          const SizedBox(width: MeetzyDesignTokens.space2),
                          Text(schoolName, style: AppTextStyles.headerSubtitle(Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onNotification,
                      icon: const Icon(LucideIcons.bell, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusLg)),
                      ),
                    ),
                    const SizedBox(width: MeetzyDesignTokens.space2),
                    IconButton(
                      onPressed: onSettings,
                      icon: const Icon(LucideIcons.settings, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusLg)),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content (last: px-5 py-6)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = constraints.maxWidth;
                    return SingleChildScrollView(
                      padding: MeetzyDesignTokens.contentPadding,
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MeetzyStatsBar(
                              nickname: myNickname ?? '나',
                              avatarWidget: myAvatarWidget ?? _defaultAvatar(),
                              matchingTicket: matchingTicket,
                            ),
                            const SizedBox(height: MeetzyDesignTokens.space6),
                            if (profiles.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 48, bottom: 24),
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.users, size: 56, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 20),
                                      Text(
                                        '아직 카드가 없어요.',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MeetzyDesignTokens.gridCrossAxisCount,
                                  childAspectRatio: MeetzyDesignTokens.gridChildAspectRatio,
                                  crossAxisSpacing: MeetzyDesignTokens.gridGap,
                                  mainAxisSpacing: MeetzyDesignTokens.gridGap,
                                ),
                                itemCount: profiles.length,
                                itemBuilder: (context, index) {
                                  final p = profiles[index];
                                  return MeetzyProfileCard(
                                    nickname: p.nickname,
                                    tag: p.tag,
                                    avatarWidget: p.avatarWidget,
                                    avatarBgColor: p.avatarBgColor,
                                    onTap: () => onProfileTap?.call(index, p),
                                  );
                                },
                              ),
                            const SizedBox(height: MeetzyDesignTokens.gridBottomSpace),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom nav (last: border-t px-3 py-2, grid-cols-5, active = bg-gradient-to-br gradient text-white)
              Container(
                padding: MeetzyDesignTokens.bottomNavPadding,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.9),
                  border: Border(top: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.white24)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    _navItem(context, 'ranking', LucideIcons.trophy, '대학교 랭킹', primary),
                    _navItem(context, 'messages', LucideIcons.messageCircle, '메시지함', primary),
                    _navItem(context, 'board', LucideIcons.house, '홈', primary),
                    _navItem(context, 'profile', LucideIcons.user, 'My프로필', primary),
                    _navItem(context, 'shop', LucideIcons.shoppingBag, '상점', primary),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _navItem(BuildContext context, String tab, IconData icon, String label, Color primaryColor) {
    final isActive = currentTab == tab;
    // last: active = gradient + white text/icon, inactive = gray-400
    const inactiveColor = Color(0xFF9CA3AF);
    final activeGradient = ThemeController.getActiveAccentGradient();

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.radius2xl),
        child: InkWell(
          onTap: () => onTabChange?.call(tab),
          borderRadius: BorderRadius.circular(MeetzyDesignTokens.radius2xl),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: MeetzyDesignTokens.bottomNavItemPadding),
            decoration: BoxDecoration(
              gradient: isActive ? activeGradient : null,
              color: isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(MeetzyDesignTokens.radius2xl),
              boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: MeetzyDesignTokens.bottomNavIconSize, color: isActive ? Colors.white : inactiveColor),
                const SizedBox(height: MeetzyDesignTokens.bottomNavGap),
                Text(
                  label,
                  style: (isActive ? AppTextStyles.bottomNavLabelActive(Colors.white) : AppTextStyles.bottomNavLabel(inactiveColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: UniversityTheme.bgGradientStart,
      child: const Icon(LucideIcons.user, size: 32, color: Colors.grey),
    );
  }
}

/// 설명 주석
class MeetzyBoardProfileItem {
  const MeetzyBoardProfileItem({
    required this.nickname,
    required this.tag,
    required this.avatarWidget,
    this.avatarBgColor,
    this.borderColor,
    this.school,
    this.photoUrl,
    this.avatarUrl,
    this.tags,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final Color? borderColor;
  final String? school;
  final String? photoUrl;
  final String? avatarUrl;
  final List<String>? tags;
}



