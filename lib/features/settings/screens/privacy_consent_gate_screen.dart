import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/settings/screens/privacy_policy_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/privacy_consent_storage.dart';

class PrivacyConsentGateScreen extends StatefulWidget {
  const PrivacyConsentGateScreen({super.key});

  @override
  State<PrivacyConsentGateScreen> createState() =>
      _PrivacyConsentGateScreenState();
}

class _PrivacyConsentGateScreenState extends State<PrivacyConsentGateScreen> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dialogShown) return;
    _dialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConsentDialog();
    });
  }

  Future<void> _showConsentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('개인정보 안내 확인'),
            content: const Text(
              '메인으로 이동하려면 개인정보 수집·이용 안내를 열어보고, 안내 화면 하단의 동의 버튼을 눌러야 합니다.',
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  final accepted = await Navigator.of(dialogContext).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PrivacyPolicyScreen(showConsentAction: true),
                    ),
                  );
                  if (accepted == true) {
                    await PrivacyConsentStorage.markAccepted();
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('개인정보 안내 보기'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeController.getHeaderGradient(),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
