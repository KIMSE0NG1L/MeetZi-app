import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class MatchingResultScreen extends StatelessWidget {
  const MatchingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 완료'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.favorite,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '매칭이 성사됐어요!\n익명 대화로 먼저 연결돼요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '상호 동의 전까지는\n프로필 사진이 공개되지 않아요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: '대화 미리보기로 이동',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatPreview);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
