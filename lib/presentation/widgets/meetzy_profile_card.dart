import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';

/// last MeetZyBoard 프로필 카드 1:1 (rounded-3xl, p-[3px], rounded-[22px], p-4, avatar 80px, tag, NEW 뱃지).
class MeetzyProfileCard extends StatelessWidget {
  const MeetzyProfileCard({
    super.key,
    required this.nickname,
    required this.tag,
    required this.avatarWidget,
    this.avatarBgColor,
    this.isNew = false,
    this.onTap,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1F2937) : UniversityTheme.surface;
    final onSurface = isDark ? Colors.white : UniversityTheme.onSurface;
    final onVariant = isDark ? const Color(0xFFD1D5DB) : UniversityTheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.cardOuterRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MeetzyDesignTokens.cardOuterRadius),
            gradient: UniversityTheme.designPinkGradient,
            boxShadow: MeetzyDesignTokens.cardOuterShadow,
          ),
          padding: const EdgeInsets.all(MeetzyDesignTokens.cardBorderWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusCardInner),
              color: surface.withValues(alpha: isDark ? 0.95 : 0.98),
              boxShadow: MeetzyDesignTokens.cardInnerShadow,
            ),
            padding: MeetzyDesignTokens.cardInnerPadding,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar with ring
                    Container(
                      margin: const EdgeInsets.only(bottom: MeetzyDesignTokens.cardAvatarMarginBottom),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MeetzyDesignTokens.cardAvatarSize + MeetzyDesignTokens.cardAvatarRingOffset * 2 + MeetzyDesignTokens.cardAvatarRingWidth * 2,
                            height: MeetzyDesignTokens.cardAvatarSize + MeetzyDesignTokens.cardAvatarRingOffset * 2 + MeetzyDesignTokens.cardAvatarRingWidth * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: MeetzyDesignTokens.cardAvatarSize + MeetzyDesignTokens.cardAvatarRingWidth * 2 + MeetzyDesignTokens.cardAvatarRingOffset * 2,
                            height: MeetzyDesignTokens.cardAvatarSize + MeetzyDesignTokens.cardAvatarRingWidth * 2 + MeetzyDesignTokens.cardAvatarRingOffset * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.white70,
                                width: MeetzyDesignTokens.cardAvatarRingWidth,
                              ),
                              boxShadow: [
                                if (avatarBgColor != null)
                                  BoxShadow(
                                    color: (avatarBgColor!).withValues(alpha: 0.25),
                                    blurRadius: 20,
                                  ),
                                const BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(MeetzyDesignTokens.cardAvatarRingOffset),
                            child: Container(
                              width: MeetzyDesignTokens.cardAvatarSize,
                              height: MeetzyDesignTokens.cardAvatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: avatarBgColor ?? UniversityTheme.bgGradientStart,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: MeetzyDesignTokens.cardAvatarSize,
                                  height: MeetzyDesignTokens.cardAvatarSize,
                                  child: avatarWidget,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      nickname,
                      style: AppTextStyles.cardNickname(onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: MeetzyDesignTokens.cardNicknameMarginBottom),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: onVariant),
                        const SizedBox(width: MeetzyDesignTokens.cardTagGap),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MeetzyDesignTokens.cardTagMaxWidth),
                          child: Text(
                            tag,
                            style: AppTextStyles.cardTag(onVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isNew)
                  Positioned(
                    top: MeetzyDesignTokens.badgeTop,
                    right: MeetzyDesignTokens.badgeRight,
                    child: Container(
                      padding: MeetzyDesignTokens.badgePadding,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusFull),
                        boxShadow: MeetzyDesignTokens.badgeShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨', style: AppTextStyles.badge(Colors.white).copyWith(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text('NEW', style: AppTextStyles.badge()),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
