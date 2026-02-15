import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
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
          '정말로 계정을 삭제하시겠습니까? 삭제 후 다시 카카오 로그인이 필요합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5E3D0),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 헤더
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFD08C7F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '설정',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.light_mode),
                    title: const Text('일반 모드'),
                    trailing: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.themeMode,
                      builder: (context, mode, _) => Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: mode,
                        onChanged: (val) {
                          ThemeController.setThemeMode(ThemeMode.light);
                          ThemeController.setSecretMode(false);
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('다크 모드'),
                    trailing: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.themeMode,
                      builder: (context, mode, _) => Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: mode,
                        onChanged: (val) {
                          ThemeController.setThemeMode(ThemeMode.dark);
                          ThemeController.setSecretMode(false);
                        },
                      ),
                    ),
                  ),
                  // ... 추가 설정 항목 ...
                ],
              ),
            ),
          ],
        ),
      ),
    );
                    trailing: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.themeMode,
                      builder: (context, mode, _) => Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: mode,
                        onChanged: (val) {
                          ThemeController.setThemeMode(ThemeMode.light);
                          ThemeController.setSecretMode(false);
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('다크 모드'),
                    trailing: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.themeMode,
                      builder: (context, mode, _) => Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: mode,
                        onChanged: (val) {
                          ThemeController.setThemeMode(ThemeMode.dark);
                          ThemeController.setSecretMode(false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('로그아웃'),
                    onTap: () => _logout(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      '계정 삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'v 1.0.1.3',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
