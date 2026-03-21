import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/screens/open_source_licenses_screen.dart';
import 'package:nearo_app/features/settings/screens/privacy_policy_screen.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Onboarding Flow Design - 기능 3종 (MeetZy 디자인)
  static const List<Map<String, dynamic>> _features = [
    {
      'icon': LucideIcons.users,
      'title': '우리 학교만',
      'description': '검증된 동기들과',
      'color': Color(0xFF3B82F6),
    },
    {
      'icon': LucideIcons.heart,
      'title': '실시간 매칭',
      'description': '즉시 대화 시작',
      'color': NearoTheme.designPink500,
    },
    {
      'icon': LucideIcons.shieldCheck,
      'title': '안전한 만남',
      'description': '신뢰할 수 있는',
      'color': Color(0xFF8B5CF6),
    },
  ];

  void _openPrivacyNotice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _openOpenSourceNotice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenSourceLicensesScreen()),
    );
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
                  // 상단: 로고 및 캐치프레이즈
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
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
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
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
                                      '대학생을 위한 특별한 만남',
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
                  // 중간: 주요 기능 3개 (고정 높이 제거, 스크롤 대응)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
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
                                  duration: Duration(
                                      milliseconds: 500 + (index * 100)),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                      alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.05),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
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
                        // 추가 정보 박스
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 24),
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
                                        text: '전국 24개 대학',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      TextSpan(text: '에서\n'),
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
                  // 하단: 카카오 로그인 버튼
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
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.2),
                                  child: InkWell(
                                    onTap: _handleKakaoLogin,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
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
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            children: [
                              const TextSpan(text: '로그인 시 '),
                              TextSpan(
                                text: '서비스 약관',
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
                              const TextSpan(text: '에 동의하게 됩니다'),
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
                            _LegalLink(
                              label: '서비스 약관',
                              onTap: _openPrivacyNotice,
                            ),
                            _LegalLink(
                              label: '개인정보 안내',
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
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인 연결 실패')),
      );
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
