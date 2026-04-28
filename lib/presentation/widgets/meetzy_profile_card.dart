import 'package:flutter/material.dart';
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
    this.borderColor,
    this.isNew = false,
    this.onTap,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final Color? borderColor;
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
            gradient: borderColor != null ? null : UniversityTheme.designPinkGradient,
            color: borderColor,
            boxShadow: MeetzyDesignTokens.cardOuterShadow,
          ),
          padding: const EdgeInsets.all(MeetzyDesignTokens.cardBorderWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusCardInner),
              color: isDark ? const Color(0xFF1B2230) : const Color(0xFFFFF7F8),
              boxShadow: MeetzyDesignTokens.cardInnerShadow,
            ),
            padding: MeetzyDesignTokens.cardInnerPadding,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const double avatarHeight = 96 + 12; // avatar + marginBottom
                    const double nicknameHeight = 24;   // 16px 폰트 + 여유
                    const double tagGapHeight = 6;
                    const double tagHeightEstimate = 90; // 4줄 12px + line height
                    const double safetyMargin = 12;      // 오버플로우 방지
                    final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;
                    final fixedPart = nicknameHeight + tagGapHeight;
                    final scalablePart = avatarHeight + tagHeightEstimate;
                    final scale = maxH > fixedPart + scalablePart + safetyMargin
                        ? 1.0
                        : ((maxH - fixedPart - safetyMargin) / scalablePart).clamp(0.4, 1.0);

                    final avatarSection = Container(
                      margin: const EdgeInsets.only(bottom: MeetzyDesignTokens.cardAvatarMarginBottom),
                      child: Stack(
                        alignment: Alignment.centerLeft,
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
                                color: isDark ? Colors.white24 : primary.withValues(alpha: 0.38),
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
                                fit: BoxFit.cover,
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
                    );

                    final maxTagWidth = (constraints.maxWidth - 16).clamp(60.0, 200.0);
                    final tagSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxTagWidth),
                          child: Text(
                            tag,
                            style: AppTextStyles.cardTag(onVariant),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: avatarHeight * scale,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topLeft,
                            child: avatarSection,
                          ),
                        ),
                        Text(
                          nickname,
                          style: AppTextStyles.cardNickname(onSurface),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: MeetzyDesignTokens.cardNicknameMarginBottom),
                        SizedBox(
                          height: tagHeightEstimate * scale,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topLeft,
                            child: tagSection,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (isNew)
                  Positioned(
                    top: MeetzyDesignTokens.badgeTop,
                    right: MeetzyDesignTokens.badgeRight,
                    child: Container(
                      padding: MeetzyDesignTokens.badgePadding,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusFull),
                        boxShadow: MeetzyDesignTokens.badgeShadow,
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MeetzyDesignTokens.badgeFontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
