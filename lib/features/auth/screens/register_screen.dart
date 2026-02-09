import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _univController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isEmailSent = false;
  bool _isEmailVerified = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _univController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    setState(() { _isLoading = true; _error = null; });
    // TODO: 실제 이메일 인증 코드 발송 API 연동
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isLoading = false; _isEmailSent = true; });
  }

  Future<void> _verifyCode() async {
    setState(() { _isLoading = true; _error = null; });
    // TODO: 실제 인증 코드 검증 API 연동
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isLoading = false; _isEmailVerified = true; });
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _error = null; });
    // TODO: 실제 회원가입 API 연동
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isLoading = false; _error = '회원가입 기능은 아직 구현되지 않았습니다.'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _univController,
              decoration: const InputDecoration(
                labelText: '대학교',
                hintText: '예: 세종대학교',
              ),
              enabled: !_isEmailSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '대학 이메일',
                hintText: 'example@univ.ac.kr',
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isEmailSent,
            ),
            const SizedBox(height: 16),
            if (!_isEmailSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _sendEmail,
                child: _isLoading ? const CircularProgressIndicator() : const Text('인증 메일 보내기'),
              ),
            if (_isEmailSent && !_isEmailVerified) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '인증 코드',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading ? const CircularProgressIndicator() : const Text('인증 코드 확인'),
              ),
            ],
            if (_isEmailVerified) ...[
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const CircularProgressIndicator() : const Text('회원가입 완료'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
