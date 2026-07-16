import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/settings/screens/customer_support_screen.dart';
import 'package:nearo_app/features/settings/screens/open_source_licenses_screen.dart';
import 'package:nearo_app/shared/widgets/meetzy_sub_page_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

/// AppDesign SettingsScreen: 로즈 그라데이션 헤더 + 카드형 메뉴 (일반/다크 모드, 로그아웃, 계정 삭제)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color? _schoolColor;

  @override
  void initState() {
    super.initState();
    _loadSchoolColor();
  }

  Future<void> _loadSchoolColor() async {
    try {
      // 프로필 소속(affiliationText)과 일치하는 환경의 교색 사용. 없으면 /environments/me fallback.
      String? schoolName;
      try {
        final profileRes = await AuthRepository().getProfile();
        final user = profileRes['user'] as Map<String, dynamic>?;
        if (user != null) {
          schoolName =
              (user['affiliationText'] ?? user['school'])?.toString().trim();
          if (schoolName != null && schoolName.isEmpty) schoolName = null;
        }
      } catch (e) {
        debugPrint('Failed to get profile for school color: $e');
      }
      if (schoolName != null) {
        final list = await EnvironmentRepository().getEnvironments();
        for (final e in list) {
          if (e is! Map) continue;
          final name = (e['name'] as String?)?.trim();
          if (name != null && name == schoolName) {
            final primaryHex = e['primaryColor']?.toString();
            final primary = ThemeController.parsePrimaryColor(primaryHex);
            if (mounted && primary != null) {
              setState(() => _schoolColor = primary);
            }
            return;
          }
        }
      }
      final status =
          await EnvironmentStatusRepository().getMyEnvironmentStatus();
      final primaryHex =
          (status['environment'] as Map?)?['primaryColor']?.toString();
      final primary = ThemeController.parsePrimaryColor(primaryHex);
      if (mounted && primary != null) setState(() => _schoolColor = primary);
    } catch (e) {
      debugPrint('Failed to load school color: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text(
          '로그아웃하면 로그인 화면으로 이동하며, 기기에 저장된 대화 기록이 삭제됩니다. 로그아웃할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ChatHistoryStore.instance.clear();
    final storage = TokenStorage();
    await storage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const SingleChildScrollView(
          child: Text(
            '계정을 삭제하면 즉시 비활성화되며 앱에서 로그아웃됩니다.\n\n'
            '탈퇴 후 3개월 동안은 같은 카카오 계정으로 다시 로그인하면 계정을 복구할 수 있습니다.\n\n'
            '3개월이 지나면 닉네임, 학교/소속, 키, MBTI, 자기소개, 취향 정보, 아바타 설정 등 프로필성 개인정보는 삭제 또는 익명화됩니다.\n\n'
            '채팅기록은 분쟁 대응 및 운영 이력 관리 목적상 최종 삭제 시점까지 보관될 수 있으며, 계정은 탈퇴 후 최대 1년 보관 뒤 최종 삭제됩니다.\n\n'
            '정말 계정을 삭제하시겠습니까?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthRepository().deleteAccount();
      await ChatHistoryStore.instance.clear();
      await TokenStorage().clear();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final isNoLogin = msg.contains('로그인 정보가 없습니다') || msg.contains('다시 로그인');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNoLogin
                ? '로그인 세션이 만료되었습니다. 다시 로그인한 뒤 계정 삭제를 시도해 주세요.'
                : '계정 삭제 실패: $msg',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return MeetzySubPageScaffold(
      title: '설정',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              children: [
                // 테마 색상: 핑크색 / 교색
                ValueListenableBuilder<String>(
                  valueListenable: ThemeController.themeColorMode,
                  builder: (context, colorMode, _) {
                    // 교색 행의 원은 로딩 전에는 회색, 로드되면 해당 학교 교색 표시 (빨강 플래시 방지)
                    final schoolColorForDisplay = _schoolColor ??
                        (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            '테마 색상',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ),
                        _ThemeColorRow(
                          surface: surface,
                          onSurface: onSurface,
                          label: '핑크색',
                          color: ThemeController.designPink,
                          selected: colorMode == 'pink',
                          onTap: () async {
                            await ThemeController.setThemeColorModePink();
                          },
                        ),
                        const SizedBox(height: 12),
                        _ThemeColorRow(
                          surface: surface,
                          onSurface: onSurface,
                          label: '교색',
                          color: schoolColorForDisplay,
                          selected: colorMode == 'school',
                          onTap: () async {
                            if (_schoolColor != null && context.mounted) {
                              await ThemeController.setThemeColorModeSchool(
                                  _schoolColor!);
                              return;
                            }
                            try {
                              final status = await EnvironmentStatusRepository()
                                  .getMyEnvironmentStatus();
                              final primaryHex = (status['environment']
                                      as Map?)?['primaryColor']
                                  ?.toString();
                              final primary =
                                  ThemeController.parsePrimaryColor(primaryHex);
                              if (primary != null && context.mounted) {
                                await ThemeController.setThemeColorModeSchool(
                                    primary);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '교색을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // 일반 / 다크 모드
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.themeMode,
                  builder: (context, mode, _) {
                    return Column(
                      children: [
                        _ThemeModeRow(
                          surface: surface,
                          onSurface: onSurface,
                          icon: LucideIcons.sun,
                          title: '일반 모드',
                          selected: mode == ThemeMode.light,
                          onTap: () {
                            ThemeController.setThemeMode(ThemeMode.light);
                            ThemeController.setSecretMode(false);
                          },
                        ),
                        const SizedBox(height: 16),
                        _ThemeModeRow(
                          surface: surface,
                          onSurface: onSurface,
                          icon: LucideIcons.moon,
                          title: '다크 모드',
                          selected: mode == ThemeMode.dark,
                          onTap: () {
                            ThemeController.setThemeMode(ThemeMode.dark);
                            ThemeController.setSecretMode(false);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // 고객센터 문의
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.messageCircle,
                  title: '문의하기',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CustomerSupportScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.shieldCheck,
                  title: '개인정보 처리방침',
                  onTap: () async {
                    // TODO: 노션 개인정보 처리방침 링크로 변경
                    final url = Uri.parse('https://www.notion.so/32a97b83a0ac80f4b7a2ebac146f3113');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.fileText,
                  title: '이용약관',
                  onTap: () async {
                    // TODO: 노션 이용약관 링크로 변경
                    final url = Uri.parse('https://www.notion.so/32a97b83a0ac80d098ccd09e715df3d2');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.badgeInfo,
                  title: '오픈소스 라이선스',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OpenSourceLicensesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          // 로그아웃 / 계정 삭제 / 버전 — 화면 아래 고정
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                    height: 1,
                    color:
                        dark ? const Color(0xFF374151) : Colors.grey.shade300),
                const SizedBox(height: 16),
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.logOut,
                  title: '로그아웃',
                  onTap: () => _logout(context),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  surface: surface,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  icon: LucideIcons.trash2,
                  title: '계정 삭제',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'v1.0.1.3',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
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

/// AppDesign: 테마 행 — 아이콘 + 라벨, 오른쪽 라디오 스타일 원(선택 시 ring-2 ring-rose-500, 원 내부 로즈 채움 + 흰 점)
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.surface,
    required this.onSurface,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final Color surface;
  final Color onSurface;
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurface),
                ),
              ),
              // 라디오 스타일: 선택 시 로즈 원 + 흰 점, 미선택 시 테두리만
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB)),
                    width: 2,
                  ),
                  color:
                      selected ? Theme.of(context).colorScheme.primary : null,
                ),
                child: selected
                    ? const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 테마 색상 행: 색상 원 + 라벨(핑크색/교색), 선택 시 라디오 표시
class _ThemeColorRow extends StatelessWidget {
  const _ThemeColorRow({
    required this.surface,
    required this.onSurface,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color surface;
  final Color onSurface;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: color, width: 2) : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurface),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? color
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB)),
                    width: 2,
                  ),
                  color: selected ? color : null,
                ),
                child: selected
                    ? const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final useTitleColor = titleColor ?? onSurface;
    final useIconColor = iconColor ?? onSurfaceVariant;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, size: 24, color: useIconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: useTitleColor,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
