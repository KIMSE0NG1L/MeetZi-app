import 'package:flutter/material.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/core/theme/university_theme.dart';

class MeetzyProfileCard extends StatelessWidget {
  const MeetzyProfileCard({
    super.key,
    required this.nickname,
    required this.tag,
    required this.avatarWidget,
    this.avatarBgColor,
    this.borderColor,
    this.school,
    this.onTap,
  });

  final String nickname;
  final String tag;
  final Widget avatarWidget;
  final Color? avatarBgColor;
  final Color? borderColor;
  final String? school;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : UniversityTheme.onSurface;
    final onVariant =
        isDark ? const Color(0xFFD1D5DB) : UniversityTheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(MeetzyDesignTokens.cardOuterRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(MeetzyDesignTokens.cardOuterRadius),
            gradient:
                borderColor != null ? null : UniversityTheme.designPinkGradient,
            color: borderColor,
            boxShadow: MeetzyDesignTokens.cardOuterShadow,
          ),
          padding: const EdgeInsets.all(MeetzyDesignTokens.cardBorderWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(MeetzyDesignTokens.radiusCardInner),
              color: isDark ? const Color(0xFF1B2230) : const Color(0xFFFFF7F8),
              boxShadow: MeetzyDesignTokens.cardInnerShadow,
            ),
            padding: MeetzyDesignTokens.cardInnerPadding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxTagWidth = (constraints.maxWidth - 8).clamp(88.0, 220.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: MeetzyDesignTokens.cardAvatarSize +
                              MeetzyDesignTokens.cardAvatarRingOffset * 2 +
                              MeetzyDesignTokens.cardAvatarRingWidth * 2,
                          height: MeetzyDesignTokens.cardAvatarSize +
                              MeetzyDesignTokens.cardAvatarRingOffset * 2 +
                              MeetzyDesignTokens.cardAvatarRingWidth * 2,
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
                          width: MeetzyDesignTokens.cardAvatarSize +
                              MeetzyDesignTokens.cardAvatarRingWidth * 2 +
                              MeetzyDesignTokens.cardAvatarRingOffset * 2,
                          height: MeetzyDesignTokens.cardAvatarSize +
                              MeetzyDesignTokens.cardAvatarRingWidth * 2 +
                              MeetzyDesignTokens.cardAvatarRingOffset * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : primary.withValues(alpha: 0.38),
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
                          padding: const EdgeInsets.all(
                            MeetzyDesignTokens.cardAvatarRingOffset,
                          ),
                          child: Container(
                            width: MeetzyDesignTokens.cardAvatarSize,
                            height: MeetzyDesignTokens.cardAvatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  avatarBgColor ?? UniversityTheme.bgGradientStart,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox.expand(child: avatarWidget),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: MeetzyDesignTokens.cardAvatarMarginBottom,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        nickname,
                        style: AppTextStyles.cardNickname(onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: MeetzyDesignTokens.cardNicknameMarginBottom,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxTagWidth),
                      child: Text(
                        tag,
                        style: AppTextStyles.cardTag(onVariant),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (school != null && school!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTagWidth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            school!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: primary.withOpacity(0.85),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
