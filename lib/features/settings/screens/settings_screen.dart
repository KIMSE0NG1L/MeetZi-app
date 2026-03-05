import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/settings/screens/customer_support_screen.dart';

/// AppDesign SettingsScreen: 로즈 그라데이션 헤더 + 카드형 메뉴 (일반/다크 모드, 로그아웃, 계정 삭제)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


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
        content: const Text(
          '계정을 삭제하면 프로필, 매칭 정보, 대화 내용 등 모든 데이터가 삭제되며 복구할 수 없습니다. 삭제 후 다시 이용하려면 카카오 로그인이 필요합니다. 정말 삭제하시겠습니까?',
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
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (topInset > 0 ? topInset : 56.0) + 20 + 36;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // AppDesign 헤더: 메시지함 등과 동일 높이 (pt + 20 + 36)
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: ThemeController.getHeaderGradient(),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '설정',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              children: [
                // 테마 색상: 핑크색 / 교색
                ValueListenableBuilder<String>(
                  valueListenable: ThemeController.themeColorMode,
                  builder: (context, colorMode, _) {
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
                          color: Theme.of(context).colorScheme.primary,
                          selected: colorMode == 'school',
                          onTap: () async {
                            try {
                              final status = await EnvironmentStatusRepository().getMyEnvironmentStatus();
                              final primaryHex = (status['environment'] as Map?)?['primaryColor']?.toString();
                              final primary = ThemeController.parsePrimaryColor(primaryHex);
                              if (primary != null && context.mounted) {
                                await ThemeController.setThemeColorModeSchool(primary);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('교색을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.')),
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
                  title: '고객센터 문의',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomerSupportScreen()),
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
                Divider(height: 1, color: dark ? const Color(0xFF374151) : Colors.grey.shade300),
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
            border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
            boxShadow: selected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 8, spreadRadius: 0)] : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
                ),
              ),
              // 라디오 스타일: 선택 시 로즈 원 + 흰 점, 미선택 시 테두리만
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                    width: 2,
                  ),
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
                child: selected
                    ? const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
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
            boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 0)] : null,
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
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? color : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
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
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
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
    this.selected = false,
    this.titleColor,
    this.iconColor,
  });

  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
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
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
          ),
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
              if (selected)
                Icon(LucideIcons.circleCheck, color: Theme.of(context).colorScheme.primary, size: 24)
              else
                Icon(LucideIcons.chevronRight, color: onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
