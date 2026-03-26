import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
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
            title: const Text('약관 및 개인정보 처리방침 동의'),
            content: const Text(
              '원활한 서비스 이용을 위해 서비스 이용약관 및 개인정보 처리방침에 동의해 주세요.\n\n'
              '계정 삭제 시 계정은 즉시 비활성화되며, 3개월 내 동일 카카오 계정으로 다시 로그인하면 복구할 수 있습니다. '
              '3개월이 지나면 프로필성 개인정보는 삭제 또는 익명화되고, 채팅기록을 포함한 잔여 정보는 최대 1년 보관 후 최종 삭제될 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final url = Uri.parse('https://www.notion.so/32a97b83a0ac80f4b7a2ebac146f3113');
                  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: const Text('개인정보 처리방침 보기'),
              ),
              FilledButton(
                onPressed: () async {
                  await PrivacyConsentStorage.markAccepted();
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('동의하고 시작'),
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
