import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_card.dart';
import 'package:nearo_app/presentation/widgets/meetzy_stats_bar.dart';
import 'package:nearo_app/presentation/widgets/meetzy_primary_button.dart';

/// Shell 상단바/하단 네비가 따로 있을 때 사용. 스탯 바 + 그리드 + FAB만 표시.
class MeetzyBoardContent extends StatelessWidget {
  const MeetzyBoardContent({
    super.key,
    this.myNickname,
    this.myAvatarWidget,
    this.viewTicket = 0,
    this.registerTicket = 0,
    this.matchingTicket = 0,
    this.profiles = const [],
    this.onProfileTap,
    this.onRegister,
    this.onRefresh,
    this.onMatchingInboxTap,
    this.isLoading = false,
    this.isRegistering = false,
  });

  final String? myNickname;
  final Widget? myAvatarWidget;
  final int viewTicket;
  final int registerTicket;
  final int matchingTicket;
  final List<MeetzyBoardProfileItem> profiles;
  final void Function(int index, MeetzyBoardProfileItem item)? onProfileTap;
  final VoidCallback? onRegister;
  final Future<void> Function()? onRefresh;
  /// 매칭대기함 열기 (열람권 왼쪽 칩)
  final VoidCallback? onMatchingInboxTap;
  final bool isLoading;
  final bool isRegistering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bgGradient = isDark ? null : ThemeController.getScreenBgGradient();
    final surface = isDark ? const Color(0xFF111827) : UniversityTheme.surface;

    Widget body = LayoutBuilder(
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
                  nickname: myNickname ?? '닉네임',
                  avatarWidget: myAvatarWidget ?? _defaultAvatar(),
                  viewTicket: viewTicket,
                  registerTicket: registerTicket,
                  matchingTicket: matchingTicket,
                  onMatchingInboxTap: onMatchingInboxTap,
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
                            '게시판이 비어 있어요',
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
                        isNew: p.isNew,
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
    );

    if (onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: body,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? surface : null,
        gradient: bgGradient,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : body),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MeetzyDesignTokens.bottomFab,
            child: Center(
              child: MeetzyPrimaryButton(
                label: '등록',
                onTap: onRegister,
                backgroundColor: primary,
                isLoading: isRegistering,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _defaultAvatar() {
    return Container(
      color: UniversityTheme.bgGradientStart,
      child: const Icon(LucideIcons.user, size: 32, color: Colors.grey),
    );
  }
}

/// last MeetZyBoard 1:1 레이아웃: Header(px-5 pt-14 pb-5), Content(px-5 py-6), Grid gap-4, FAB bottom-24, Bottom nav.
class MeetzyBoardPage extends StatelessWidget {
  const MeetzyBoardPage({
    super.key,
    this.schoolName = '세종대',
    this.currentTab = 'board',
    this.onTabChange,
    this.onSettings,
    this.onNotification,
    this.onRegister,
    this.myNickname,
    this.myAvatarWidget,
    this.viewTicket = 0,
    this.registerTicket = 0,
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
  final VoidCallback? onRegister;
  final String? myNickname;
  final Widget? myAvatarWidget;
  final int viewTicket;
  final int registerTicket;
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
      child: Stack(
        children: [
          Column(
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
                              nickname: myNickname ?? '닉네임',
                              avatarWidget: myAvatarWidget ?? _defaultAvatar(),
                              viewTicket: viewTicket,
                              registerTicket: registerTicket,
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
                                        '게시판이 비어 있어요',
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
                                    isNew: p.isNew,
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
                    _navItem(context, 'board', LucideIcons.layoutGrid, '게시판', primary),
                    _navItem(context, 'profile', LucideIcons.user, '프로필', primary),
                    _navItem(context, 'shop', LucideIcons.shoppingBag, '상점', primary),
                  ],
                ),
              ),
            ],
          ),
          // FAB (last: absolute bottom-24 center)
          Positioned(
            left: 0,
            right: 0,
            bottom: MeetzyDesignTokens.bottomFab,
            child: Center(
              child: MeetzyPrimaryButton(
                label: '등록',
                onTap: onRegister,
                backgroundColor: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String tab, IconData icon, String label, Color primaryColor) {
    final isActive = currentTab == tab;
    final theme = Theme.of(context);
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

/// Board에 표시할 프로필 한 건 (Prisma Profile/User 필드명 참고: nickname, idealType 등).
class MeetzyBoardProfileItem {
  const MeetzyBoardProfileItem({
    required this.nickname,
    required this.tag,
    required this.avatarWidget,
    this.avatarBgColor,
    this.isNew = false,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final bool isNew;
}
