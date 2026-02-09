import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시작하기')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login-email'),
              child: const Text('로그인'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
