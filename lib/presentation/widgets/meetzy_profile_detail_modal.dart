import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// last ProfileDetailModal 1:1 — gradient header, avatar, info rows, 닫기/가져가기.
class MeetzyProfileDetailModal extends StatelessWidget {
  const MeetzyProfileDetailModal({
    super.key,
    required this.profile,
    required this.onClose,
    required this.onMatch,
    this.darkMode = false,
    this.avatarWidget,
  });

  final MeetzyProfileDetailData profile;
  final VoidCallback onClose;
  final VoidCallback onMatch;
  final bool darkMode;
  final Widget? avatarWidget;

  @override
  Widget build(BuildContext context) {
    final surface = darkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = darkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 168,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  gradient: ThemeController.getSheetGradient(),
                ),
                child: Center(
                  child: Padding(
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
                            boxShadow: const [
                              BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarWidget ??
                                Icon(LucideIcons.user, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                _InfoRow(label: '학과', value: profile.major, darkMode: darkMode),
                _InfoRow(label: '성별', value: profile.gender, darkMode: darkMode),
                _InfoRow(label: '소속', value: profile.school, darkMode: darkMode),
                _InfoRow(label: '키', value: profile.height, darkMode: darkMode),
                _InfoRow(label: '학년', value: profile.grade, darkMode: darkMode),
                _InfoRow(label: 'MBTI', value: profile.mbti, darkMode: darkMode),
                _InfoRow(label: '흡연', value: profile.smoking, darkMode: darkMode),
                _InfoRow(label: '음주', value: profile.drinking, darkMode: darkMode),
                _InfoRow(label: '자기 소개', value: profile.intro, darkMode: darkMode),
                _InfoRow(label: '취미', value: profile.interest, darkMode: darkMode),
                _InfoRow(label: '이상형', value: profile.idealType, darkMode: darkMode),
                _InfoRow(label: '패션 스타일', value: profile.fashionStyle, darkMode: darkMode),
                _InfoRow(label: '선호 데이트', value: profile.datePreference, darkMode: darkMode),
                _InfoRow(label: '활동 시간대', value: profile.activeTime, darkMode: darkMode),
                if (profile.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          '나를 소개하는...',
                          style: TextStyle(
                            fontSize: 14,
                            color: darkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: darkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      t,
                                      style: TextStyle(fontSize: 14, color: darkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                      side: BorderSide(color: darkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                      foregroundColor: darkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onMatch,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                    ),
                    child: const Text('가져가기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.darkMode});

  final String label;
  final String value;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final onVariant = darkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final onSurface = darkMode ? Colors.white : const Color(0xFF111827);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: TextStyle(fontSize: 14, color: onVariant)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(fontSize: 14, color: onSurface),
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
