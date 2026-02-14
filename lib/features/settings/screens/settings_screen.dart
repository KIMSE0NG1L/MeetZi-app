import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
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
        content: const Text('정말로 계정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // 계정 삭제 로직 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('시크릿 모드'),
              trailing: ValueListenableBuilder<bool>(
                valueListenable: ThemeController.secretMode,
                builder: (context, secret, _) => Radio<bool>(
                  value: true,
                  groupValue: secret,
                  onChanged: (val) {
                    ThemeController.setSecretMode(true);
                  },
                ),
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
