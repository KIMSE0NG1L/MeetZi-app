import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/presentation/widgets/meetzy_ticket_chip.dart';

/// last MeetZyBoard Stats Bar: avatar, nickname, 매칭대기함 + 매칭권만 표시.
class MeetzyStatsBar extends StatelessWidget {
  const MeetzyStatsBar({
    super.key,
    required this.nickname,
    required this.avatarWidget,
    required this.matchingTicket,
    this.receivedRequestCount = 0,
    this.onMatchingTap,
    this.onMatchingInboxTap,
  });

  final String nickname;
  final Widget avatarWidget;
  final int matchingTicket;
  /// 매칭대기함 아이콘에 표시할 받은 요청 개수
  final int receivedRequestCount;
  /// 매칭권 칩 탭 시 호출
  final VoidCallback? onMatchingTap;
  /// 매칭대기함 열기
  final VoidCallback? onMatchingInboxTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = isDark ? Colors.white : UniversityTheme.onSurface;
    final bg = isDark ? const Color(0xFF1F2937) : UniversityTheme.surface;

    return Container(
      padding: MeetzyDesignTokens.statsBarPadding,
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, primary.withValues(alpha: 0.06)],
              ),
        color: isDark ? bg : null,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.statsBarRadius),
        boxShadow: MeetzyDesignTokens.statsBarShadow,
      ),
      child: Row(
        children: [
          Container(
            width: MeetzyDesignTokens.statsBarAvatarSize,
            height: MeetzyDesignTokens.statsBarAvatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipOval(child: avatarWidget),
          ),
          SizedBox(width: MeetzyDesignTokens.statsBarGap),
          Expanded(
            child: Text(
              nickname,
              style: AppTextStyles.statsNickname(onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: MeetzyDesignTokens.statsBarGap),
          if (onMatchingInboxTap != null) ...[
            _MatchingInboxChip(onTap: onMatchingInboxTap!, badgeCount: receivedRequestCount),
            const SizedBox(width: MeetzyDesignTokens.space2),
          ],
          _wrapMatchingChip(context),
        ],
      ),
    );
  }

  Widget _wrapMatchingChip(BuildContext context) {
    final chip = MeetzyMatchingTicketChip(count: matchingTicket);
    if (onMatchingTap != null) {
      return GestureDetector(
        onTap: onMatchingTap,
        child: chip,
      );
    }
    return chip;
  }
}

/// 매칭대기함 진입 칩
class _MatchingInboxChip extends StatelessWidget {
  const _MatchingInboxChip({required this.onTap, this.badgeCount = 0});

  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : theme.colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(LucideIcons.mail, size: 26, color: fg),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
