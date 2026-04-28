import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// ad ProfileDetailModal 디자인 — 그라데이션 헤더, 기본정보 태그 팔, 한줄소개/취미/이상형 박스, #키워드 태그, 닫기/매칭하기.
class MeetzyProfileDetailModal extends StatelessWidget {
  const MeetzyProfileDetailModal({
    super.key,
    required this.profile,
    required this.onClose,
    this.onMatch,
    this.darkMode = false,
    this.avatarWidget,
    this.hideMatchButton = false,
  this.photoUrlForEnlarge,
  this.avatarUrlForEnlarge,
  this.hideBottomBar = false,
  this.topCornerRadius,
  });

  final MeetzyProfileDetailData profile;
  final VoidCallback onClose;
  final VoidCallback? onMatch;
  final bool darkMode;
  final Widget? avatarWidget;
  final bool hideMatchButton;
  /// 탭 시 크게 보기할 사진 URL (프로필 사진)
  final String? photoUrlForEnlarge;
  /// 탭 시 크게 보기할 아바타 URL (dicebear 등)
  final String? avatarUrlForEnlarge;
  /// true면 하단 닫기/매칭하기 영역 비표시 (다른 위젯에서 하단 버튼을 그릴 때 사용)
  final bool hideBottomBar;
  /// 헤더 상단 곡률 (시트에 넣을 때 상단 하얀 귀 터짐 방지용, null이면 32)
  final double? topCornerRadius;

  /// 사진/아바타 크게 보기 다이얼로그 표시 (외부에서 재사용)
  static void showPhotoEnlarge(
    BuildContext context, {
    String? photoUrl,
    String? avatarUrl,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    if (!hasPhoto && !hasAvatar) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          behavior: HitTestBehavior.opaque,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(ctx).size.width - 48,
                      maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                    ),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: hasPhoto
                            ? Image.network(
                                photoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(LucideIcons.user, size: 120, color: Colors.white54),
                              )
                            : hasAvatar
                                ? SvgPicture.network(
                                    avatarUrl!,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) =>
                                        const Icon(LucideIcons.user, size: 120, color: Colors.white54),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '탭하면 닫기 · 핀치로 확대',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 탭 시 사진/아바타 크게 보기 (photoUrlForEnlarge 또는 avatarUrlForEnlarge 있을 때만)
  Widget _wrapAvatarWithEnlarge(BuildContext context, Widget child) {
    final hasEnlarge = (photoUrlForEnlarge != null && photoUrlForEnlarge!.isNotEmpty) ||
        (avatarUrlForEnlarge != null && avatarUrlForEnlarge!.isNotEmpty);
    if (!hasEnlarge) return child;

    return GestureDetector(
      onTap: () => showPhotoEnlarge(
        context,
        photoUrl: photoUrlForEnlarge,
        avatarUrl: avatarUrlForEnlarge,
      ),
      child: child,
    );
  }

  /// ad InfoTag: gradient pill, white text
  Widget _infoTag(String value, BuildContext context) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    final gradient = ThemeController.getSheetGradient();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: darkMode ? null : gradient,
        color: darkMode ? const Color(0xFF374151) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkMode ? const Color(0xFFE5E7EB) : Colors.white,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = darkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = darkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final contentBg = darkMode ? const Color(0xFF374151).withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final onContent = darkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151);

    final radius = topCornerRadius ?? 32.0;
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // ad: Header with gradient, h-40, drag handle, X, avatar 96, nickname
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(topCornerRadius ?? 32),
                  ),
                  gradient: ThemeController.getSheetGradient(),
                ),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final content = Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: profile.avatarBgColor ?? UniversityTheme.bgGradientStart,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                  const BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
                                ],
                              ),
                              child: ClipOval(
                                child: SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: _wrapAvatarWithEnlarge(
                                      context,
                                      avatarWidget ??
                                          Icon(LucideIcons.user, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                                decorationColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      );
                      return FittedBox(
                        alignment: Alignment.topCenter,
                        fit: BoxFit.scaleDown,
                        child: content,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onClose,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ad: Scrollable content — Basic Info Tags, intro/interest/idealType boxes, 추가 Tags, # 키워드
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Basic Info Tags (ad flex-wrap gap-2)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (profile.major.isNotEmpty && profile.major != '-') _infoTag(profile.major, context),
                    if (profile.gender.isNotEmpty && profile.gender != '-') _infoTag(profile.gender, context),
                    if (profile.school.isNotEmpty && profile.school != '-') _infoTag(profile.school, context),
                    if (profile.height.isNotEmpty && profile.height != '-') _infoTag(profile.height, context),
                    if (profile.grade.isNotEmpty && profile.grade != '-') _infoTag(profile.grade, context),
                    if (profile.mbti.isNotEmpty && profile.mbti != '-') _infoTag(profile.mbti, context),
                    if (profile.smoking.isNotEmpty && profile.smoking != '-') _infoTag(profile.smoking, context),
                    if (profile.drinking.isNotEmpty && profile.drinking != '-') _infoTag(profile.drinking, context),
                  ],
                ),
                const SizedBox(height: 16),
                // 한 줄 소개 (ad rounded-2xl bg-gray-50)
                if (profile.intro.isNotEmpty && profile.intro != '-') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: contentBg,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '💬 ${profile.intro}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: onContent,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ) ?? TextStyle(fontSize: 14, height: 1.5, color: onContent, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              gradient: ThemeController.getSheetGradient(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // 취미 / 요즘 빠진 것
                if (profile.interest.isNotEmpty && profile.interest != '-') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: contentBg,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '✨ 요즘 빠진 것: ${profile.interest}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: onContent,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ) ?? TextStyle(fontSize: 14, height: 1.5, color: onContent, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              gradient: ThemeController.getSheetGradient(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // 이상형
                if (profile.idealType.isNotEmpty && profile.idealType != '-') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: contentBg,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '💕 이상형: ${profile.idealType}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: onContent,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ) ?? TextStyle(fontSize: 14, height: 1.5, color: onContent, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              gradient: ThemeController.getSheetGradient(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // 추가 정보 Tags (ad 👔 ☕ 🕐)
                if (profile.fashionStyle.isNotEmpty || profile.datePreference.isNotEmpty || profile.activeTime.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.fashionStyle.isNotEmpty && profile.fashionStyle != '-')
                        _infoTag('👔 ${profile.fashionStyle}', context),
                      if (profile.datePreference.isNotEmpty && profile.datePreference != '-')
                        _infoTag('☕ ${profile.datePreference}', context),
                      if (profile.activeTime.isNotEmpty && profile.activeTime != '-')
                        _infoTag('🕐 ${profile.activeTime}', context),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // # 나를 소개하는 키워드 (ad)
                if (profile.tags.isNotEmpty) ...[
                  Text(
                    '# 나를 소개하는 키워드',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: darkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: ThemeController.getSheetGradient(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$t',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (!hideBottomBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: darkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        foregroundColor: darkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('닫기', style: TextStyle(decoration: TextDecoration.none, decorationColor: Colors.transparent)),
                    ),
                  ),
                  if (!hideMatchButton && onMatch != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ThemeController.getSheetGradient(),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onMatch,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  '매칭하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                    decorationColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class MeetzyProfileDetailData {
  const MeetzyProfileDetailData({
    required this.nickname,
    this.avatarBgColor,
    this.major = '',
    this.gender = '',
    this.school = '',
    this.height = '',
    this.grade = '',
    this.mbti = '',
    this.smoking = '',
    this.drinking = '',
    this.intro = '',
    this.interest = '',
    this.idealType = '',
    this.fashionStyle = '',
    this.datePreference = '',
    this.activeTime = '',
    this.tags = const [],
  });

  final String nickname;
  final Color? avatarBgColor;
  final String major;
  final String gender;
  final String school;
  final String height;
  final String grade;
  final String mbti;
  final String smoking;
  final String drinking;
  final String intro;
  final String interest;
  final String idealType;
  final String fashionStyle;
  final String datePreference;
  final String activeTime;
  final List<String> tags;
}
