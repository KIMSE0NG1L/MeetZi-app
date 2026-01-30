import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentSuccessScreen extends StatelessWidget {
  const ConsentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동의 완료'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.chat_bubble_outline,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '서로 동의가 완료됐어요!\n카카오톡으로 이동할게요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '이제 익명 대화가 아니라\n실제 연결로 넘어갑니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: '카카오톡 열기',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카카오톡 이동은 연동 후 적용됩니다.')),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.apiDashboard);
                },
                child: const Text('API 테스트 화면으로 이동'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
