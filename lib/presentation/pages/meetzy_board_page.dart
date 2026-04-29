import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_card.dart';
import 'package:nearo_app/presentation/widgets/meetzy_stats_bar.dart';
import 'package:nearo_app/features/settings/screens/notice_list_screen.dart';

/// 설명 주석
class MeetzyBoardContent extends StatelessWidget {
  const MeetzyBoardContent({
    super.key,
    this.profiles = const [],
    this.onProfileTap,
    this.onRefresh,
    this.onDeveloperMatchTap,
    this.onRandomMatchTap,
    this.isLoading = false,
    this.scrollController,
    this.isLoadingMore = false,
  });

  final List<MeetzyBoardProfileItem> profiles;
  final void Function(int index, MeetzyBoardProfileItem item)? onProfileTap;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDeveloperMatchTap;
  final VoidCallback? onRandomMatchTap;
  final bool isLoading;
  final ScrollController? scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgGradient = isDark ? null : ThemeController.getScreenBgGradient();
    final surface = isDark ? const Color(0xFF111827) : UniversityTheme.surface;

    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        return SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MeetzyDesignTokens.contentPadding,
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNoticeBanner(context),
                const SizedBox(height: MeetzyDesignTokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        onTap: onDeveloperMatchTap,
                        color: Colors.white,
                        borderColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        label: '개발자와\n매칭 신청',
                        textColor: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        onTap: onRandomMatchTap,
                        gradient: ThemeController.getActiveAccentGradient(),
                        icon: LucideIcons.shuffle,
                        label: '랜덤\n매칭',
                        textColor: Colors.white,
                      ),
                    ),
                  ],
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
                else ...[
                  Row(
                    children: [
                      Text(
                        '추천 프로필',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: ThemeController.getActiveAccentGradient(),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${profiles.length}명',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                        borderColor: p.borderColor,
                        onTap: () => onProfileTap?.call(index, p),
                      );
                    },
                  ),
                ],
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : body),
        ],
      ),
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
                  '[공지] Meetzi 업데이트 및 이용 안내',
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    this.icon,
    required this.label,
    required this.textColor,
    this.gradient,
    this.color,
    this.borderColor,
  });

  final VoidCallback? onTap;
  final IconData? icon;
  final String label;
  final Color textColor;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color : null,
          borderRadius: BorderRadius.circular(18),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: const [
            BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
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

/// 설명 주석
class MeetzyBoardProfileItem {
  const MeetzyBoardProfileItem({
    required this.nickname,
    required this.tag,
    required this.avatarWidget,
    this.avatarBgColor,
    this.borderColor,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final Color? borderColor;
}



