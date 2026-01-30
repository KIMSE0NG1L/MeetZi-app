import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ApiDashboardScreen extends StatelessWidget {
  const ApiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              PrimaryButton(
                label: '사진 API',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.photo),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '구독 API',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.subscription),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '헬스 체크 API',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.health),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '내 프로필 API',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.authProfile),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '유저 API',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.users),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
