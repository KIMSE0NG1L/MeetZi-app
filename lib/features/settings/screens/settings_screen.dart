import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/features/settings/screens/customer_support_screen.dart';

/// AppDesign SettingsScreen: 로즈 그라데이션 헤더 + 카드형 메뉴 (일반/다크 모드, 로그아웃, 계정 삭제)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _roseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
  );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 삭제 실패: $e')),
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
            decoration: const BoxDecoration(
              gradient: _roseGradient,
              boxShadow: [
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
                // AppDesign: 테마 행
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

  static const _rose500 = Color(0xFFF43F5E);

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
            border: selected ? Border.all(color: _rose500, width: 2) : null,
            boxShadow: selected ? [BoxShadow(color: _rose500.withOpacity(0.2), blurRadius: 8, spreadRadius: 0)] : null,
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
                    color: selected ? _rose500 : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                    width: 2,
                  ),
                  color: selected ? _rose500 : null,
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
            border: selected ? Border.all(color: const Color(0xFFF43F5E), width: 2) : null,
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
                const Icon(LucideIcons.circleCheck, color: Color(0xFFF43F5E), size: 24)
              else
                Icon(LucideIcons.chevronRight, color: onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
