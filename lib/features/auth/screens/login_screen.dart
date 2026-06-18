import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/apple_auth_service.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/settings/screens/open_source_licenses_screen.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepository = AuthRepository();
  int _logoTapCount = 0;
  bool _showReviewerLogin = true;
  bool _isReviewerLoginLoading = false;

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': LucideIcons.users,
      'title': '우리 학교만',
      'description': '검증된 학교 친구와',
      'color': Color(0xFF3B82F6),
    },
    {
      'icon': LucideIcons.heart,
      'title': '실시간 매칭',
      'description': '즉시 대화를 시작',
      'color': NearoTheme.designPink500,
    },
    {
      'icon': LucideIcons.shieldCheck,
      'title': '안전한 만남',
      'description': '신뢰할 수 있는 연결',
      'color': Color(0xFF8B5CF6),
    },
  ];

  Future<void> _openPrivacyNotice() async {
    final url = Uri.parse('https://www.notion.so/32a97b83a0ac80f4b7a2ebac146f3113');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _openTermsOfService() async {
    final url = Uri.parse('https://www.notion.so/32a97b83a0ac80d098ccd09e715df3d2');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  void _openOpenSourceNotice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenSourceLicensesScreen()),
    );
  }

  void _handleLogoTap() {
    if (_showReviewerLogin) return;
    setState(() {
      _logoTapCount += 1;
      if (_logoTapCount >= 3) {
        _showReviewerLogin = true;
      }
    });
  }

  Future<void> _openReviewerLoginDialog() async {
    final idController = TextEditingController();
    final passwordController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                final dialogNavigator = Navigator.of(dialogContext);
                final rootNavigator = Navigator.of(this.context);
                final rootMessenger = ScaffoldMessenger.of(this.context);
                final loginId = idController.text.trim();
                final password = passwordController.text;

                if (loginId.isEmpty || password.isEmpty) {
                  rootMessenger.showSnackBar(
                    const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
                  );
                  return;
                }

                setDialogState(() => _isReviewerLoginLoading = true);
                try {
                  await _authRepository.reviewerLogin(
                    loginId: loginId,
                    password: password,
                  );
                  if (!mounted) return;
                  dialogNavigator.pop();
                  rootNavigator.pushNamedAndRemoveUntil(
                    AppRoutes.onboarding,
                    (route) => false,
                  );
                } on DioException catch (e) {
                  final message =
                      (e.response?.data is Map<String, dynamic>)
                          ? (e.response?.data['message']?.toString() ??
                              '리뷰어 로그인에 실패했습니다.')
                          : '리뷰어 로그인에 실패했습니다.';
                  if (!mounted) return;
                  rootMessenger.showSnackBar(SnackBar(content: Text(message)));
                } catch (_) {
                  if (!mounted) return;
                  rootMessenger.showSnackBar(
                    const SnackBar(content: Text('리뷰어 로그인에 실패했습니다.')),
                  );
                } finally {
                  if (mounted) {
                    setDialogState(() => _isReviewerLoginLoading = false);
                  }
                }
              }

              return AlertDialog(
                title: const Text('리뷰어 로그인'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: '아이디'),
                      enabled: !_isReviewerLoginLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: '비밀번호'),
                      obscureText: true,
                      enabled: !_isReviewerLoginLoading,
                      onSubmitted: (_) => submit(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        _isReviewerLoginLoading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: _isReviewerLoginLoading ? null : submit,
                    child:
                        _isReviewerLoginLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('로그인'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      idController.dispose();
      passwordController.dispose();
      _isReviewerLoginLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Colors.white,
              Color(0xFFFDF2F8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _handleLogoTap,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              final clamped = value.clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: clamped,
                                  child: Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/icon.png',
                                      fit: BoxFit.cover,
                                      width: 112,
                                      height: 112,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.white,
                                        child: const Icon(
                                          LucideIcons.heart,
                                          size: 56,
                                          color: NearoTheme.designPink500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) {
                            final opacity = value.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: Column(
                                  children: [
                                    const Text(
                                      'MeetZy',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '대학생을 위한 연결된 만남',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            _features.length,
                            (index) {
                              final f = _features[index];
                              final color = f['color'] as Color;
                              return Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 500 + (index * 100)),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.05),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  f['icon'] as IconData,
                                                  size: 32,
                                                  color: color,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                f['title'] as String,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF111827),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                f['description'] as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 24,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFEFF6FF),
                                      Color(0xFFFDF2F8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Color(0xFF374151),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '전국 24개 대학에서\n',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      TextSpan(
                                        text: '12,000명 이상',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDB2777),
                                        ),
                                      ),
                                      TextSpan(text: '이 함께하고 있어요'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Material(
                                  color: const Color(0xFFFEE500),
                                  borderRadius: BorderRadius.circular(24),
                                  elevation: 8,
                                  shadowColor: Colors.black.withValues(alpha: 0.2),
                                  child: InkWell(
                                    onTap: _handleKakaoLogin,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '카카오로 3초만에 시작하기',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // ── Apple 로그인 버튼 (iOS 전용) ──
                        if (Platform.isIOS)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Material(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(24),
                                    elevation: 8,
                                    shadowColor: Colors.black.withValues(alpha: 0.3),
                                    child: InkWell(
                                      onTap: _handleAppleLogin,
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(LucideIcons.apple, color: Colors.white, size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'Apple로 계속하기',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_showReviewerLogin) ...[
                          const SizedBox(height: 4),
                          Text(
                            'App Review Login',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: _openReviewerLoginDialog,
                            child: const Text('리뷰어 로그인'),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            children: [
                              const TextSpan(text: '로그인하면 '),
                              TextSpan(
                                text: '서비스 이용약관',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const TextSpan(text: ' 및 '),
                              TextSpan(
                                text: '개인정보 처리방침',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const TextSpan(text: '에 동의하게 됩니다.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _LegalLink(label: '이용약관', onTap: _openTermsOfService),
                            _LegalLink(
                              label: '개인정보 처리방침',
                              onTap: _openPrivacyNotice,
                            ),
                            _LegalLink(
                              label: '오픈소스 라이선스',
                              onTap: _openOpenSourceNotice,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleKakaoLogin() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/kakao');

    // Apple Guideline 4: 항상 인앱 브라우저(SFSafariViewController)를 사용하여
    // 사용자가 앱 내에서 로그인할 수 있도록 함.
    // SFSafariViewController는 URL과 SSL 인증서를 표시하여 보안성을 보장.
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched && mounted) {
      // inAppBrowserView 실패 시 외부 브라우저로 fallback
      final fallbackLaunched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!fallbackLaunched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인 연결에 실패했습니다.')),
        );
      }
    }
  }

  bool _isAppleLoginLoading = false;

  Future<void> _handleAppleLogin() async {
    if (_isAppleLoginLoading) return;
    setState(() => _isAppleLoginLoading = true);
    try {
      final appleAuthService = AppleAuthService();
      final success = await appleAuthService.signInWithApple();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.onboarding,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple 로그인에 실패했습니다. 다시 시도해 주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[AppleLogin] Unexpected error in handler: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple 로그인 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAppleLoginLoading = false);
    }
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
