import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/presentation/widgets/meetzy_ticket_chip.dart';

/// last MeetZyBoard Stats Bar: rounded-2xl p-4, avatar 48px, gap-3, 열람권/등록권/매칭권 칩.
class MeetzyStatsBar extends StatelessWidget {
  const MeetzyStatsBar({
    super.key,
    required this.nickname,
    required this.avatarWidget,
    required this.viewTicket,
    required this.registerTicket,
    required this.matchingTicket,
    this.onMatchingTap,
    this.onMatchingInboxTap,
  });

  final String nickname;
  final Widget avatarWidget;
  final int viewTicket;
  final int registerTicket;
  final int matchingTicket;
  /// 매칭권 칩 탭 시 호출 (매칭대기함으로 이동 등)
  final VoidCallback? onMatchingTap;
  /// 매칭대기함 열기 (열람권 왼쪽에 표시)
  final VoidCallback? onMatchingInboxTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : UniversityTheme.onSurface;
    final bg = isDark ? const Color(0xFF1F2937) : UniversityTheme.surface;

    return Container(
      padding: MeetzyDesignTokens.statsBarPadding,
      decoration: BoxDecoration(
        color: bg,
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
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
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
            _MatchingInboxChip(onTap: onMatchingInboxTap!),
            const SizedBox(width: MeetzyDesignTokens.space2),
          ],
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MeetzyReadingTicketChip(count: viewTicket),
                  const SizedBox(width: MeetzyDesignTokens.space2),
                  MeetzyRegisterTicketChip(count: registerTicket),
                  const SizedBox(width: MeetzyDesignTokens.space2),
                  _wrapMatchingChip(context),
                ],
              ),
            ),
          ),
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

/// 매칭대기함 진입 칩 (열람권 왼쪽에 표시)
class _MatchingInboxChip extends StatelessWidget {
  const _MatchingInboxChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
    final bg = isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.3) : const Color(0xFFEDE9FE);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(MeetzyDesignTokens.ticketChipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.ticketChipRadius),
        child: Padding(
          padding: MeetzyDesignTokens.ticketChipPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.messageCircle, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                '매칭대기함',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
