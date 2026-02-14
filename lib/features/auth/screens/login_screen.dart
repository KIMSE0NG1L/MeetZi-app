import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
 
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시작하기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  'MeetZy',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              const SizedBox(height: 12),
              Text(
                '같은 공간에서 자연스럽게\n이어지는 자만추 매칭',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '카카오 계정으로 간편하게 시작해요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NearoTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '매칭이 성사되면 상호 동의 후에만\n카카오톡으로 연결됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: NearoTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: '카카오로 계속하기',
                onPressed: () async {
                  final uri = Uri.parse('${AppConfig.baseUrl}/auth/kakao');
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오 로그인 연결 실패')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
