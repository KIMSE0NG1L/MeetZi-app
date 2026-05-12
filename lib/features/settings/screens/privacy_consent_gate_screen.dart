import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

class _PrivacyConsentGateScreenState extends State<PrivacyConsentGateScreen>
    with SingleTickerProviderStateMixin {
  bool _agreed = false;
  String? _openDoc; // 'terms' | 'privacy' | null

  // ── 약관 내용 ──
  static const _termsSections = [
    {
      'heading': '제1조 (목적)',
      'body': [
        '본 약관은 MeetZy(이하 "회사")가 제공하는 대학생 매칭 서비스의 이용 조건과 절차, 회원과 회사의 권리·의무·책임을 규정함을 목적으로 합니다.',
      ],
    },
    {
      'heading': '제2조 (회원가입)',
      'body': [
        '회원가입은 본인 명의의 카카오 또는 네이버 계정으로만 가능하며, 학교 이메일 인증을 완료해야 합니다.',
        '타인의 정보를 도용하거나 허위로 가입한 경우 즉시 이용이 제한될 수 있습니다.',
      ],
    },
    {
      'heading': '제3조 (서비스 이용)',
      'body': [
        '회사는 24시간 서비스 제공을 원칙으로 하며, 시스템 점검 시 일시 중단될 수 있습니다.',
        '회원은 타인을 비방하거나 부적절한 콘텐츠를 게시할 수 없습니다.',
      ],
    },
    {
      'heading': '제4조 (계정 해지)',
      'body': [
        '회원은 언제든지 설정 화면에서 계정을 해지할 수 있습니다.',
        '계정 삭제 시 즉시 비활성화되며, 3개월 이내 동일 계정으로 재로그인하면 복구할 수 있습니다.',
      ],
    },
  ];

  static const _privacySections = [
    {
      'heading': '1. 수집 항목',
      'body': [
        '필수: 이름, 닉네임, 학교명, 학교 이메일, 성별, 학년, 카카오/네이버 식별자',
        '선택: 프로필 사진, 자기소개, 키, MBTI, 관심사, 이상형',
      ],
    },
    {
      'heading': '2. 이용 목적',
      'body': [
        '회원 식별 및 본인 확인 (학교 이메일 인증)',
        '매칭 추천 알고리즘 운영 및 서비스 품질 개선',
        '부정 이용 방지 및 분쟁 해결',
      ],
    },
    {
      'heading': '3. 보유 기간',
      'body': [
        '회원 탈퇴 시 즉시 비활성화되며, 3개월 이내 복구하지 않을 경우 프로필 정보는 삭제 또는 익명화됩니다.',
        '관계 법령에 따라 보존이 필요한 채팅 기록 등은 최대 1년간 별도 보관 후 파기됩니다.',
      ],
    },
    {
      'heading': '4. 제3자 제공',
      'body': [
        'MeetZy는 회원의 개인정보를 외부에 제공하지 않습니다. 다만 법령에 근거한 수사기관의 요청이 있는 경우 해당 절차를 따릅니다.',
      ],
    },
    {
      'heading': '5. 이용자의 권리',
      'body': [
        '회원은 언제든지 본인의 개인정보를 조회·수정·삭제·처리정지를 요청할 수 있습니다.',
      ],
    },
  ];

  Future<void> _onAgree() async {
    await PrivacyConsentStorage.markAccepted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  void _showDocModal(String docType) {
    setState(() => _openDoc = docType);
  }

  void _closeDocModal() {
    setState(() => _openDoc = null);
  }

  @override
  Widget build(BuildContext context) {
    const pink300 = Color(0xFFFDA4AF);
    const pink400 = Color(0xFFFB7185);
    const pinkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFB7185)],
    );
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFFFE4E6)],
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            // ── 배경 장식 블롭들 ──
            Positioned(
              top: -60,
              right: -60,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 3),
                builder: (_, val, child) => Opacity(
                  opacity: 0.25 + 0.15 * val,
                  child: child,
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: pinkGradient,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 4),
                builder: (_, val, child) => Opacity(
                  opacity: 0.2 + 0.15 * val,
                  child: child,
                ),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: pinkGradient,
                  ),
                ),
              ),
            ),

            // ── 메인 콘텐츠 ──
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // ── 카드 ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            const Text(
                              '약관 및 개인정보\n처리방침 동의',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 설명
                            Text(
                              '원활한 서비스 이용을 위해 서비스 이용약관 및 개인정보 처리방침에 동의해 주세요.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '계정 삭제 시 계정은 즉시 비활성화되며, 3개월 내 동일 카카오 계정으로 다시 로그인하면 복구할 수 있습니다. '
                              '3개월이 지나면 프로필성 개인정보는 삭제 또는 익명화되고, 채팅기록을 포함한 잔여 정보는 최대 1년 보관 후 최종 삭제될 수 있습니다.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── 약관 보기 버튼들 ──
                            _DocButton(
                              icon: LucideIcons.fileText,
                              label: '서비스 이용약관 보기',
                              onTap: () => launchUrl(
                                Uri.parse('https://www.notion.so/32a97b83a0ac80f4b7a2ebac146f3113'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DocButton(
                              icon: LucideIcons.shield,
                              label: '개인정보 처리방침 보기',
                              onTap: () => launchUrl(
                                Uri.parse('https://www.notion.so/32a97b83a0ac80d098ccd09e715df3d2'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── 동의 체크 ──
                            GestureDetector(
                              onTap: () => setState(() => _agreed = !_agreed),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _agreed ? pinkGradient : null,
                                      border: _agreed
                                          ? null
                                          : Border.all(
                                              color: const Color(0xFFD1D5DB),
                                              width: 2,
                                            ),
                                      boxShadow: _agreed
                                          ? [
                                              BoxShadow(
                                                color: pink400.withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: _agreed
                                        ? const Icon(
                                            LucideIcons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                        children: const [
                                          TextSpan(text: '위 내용을 모두 확인했고 '),
                                          TextSpan(
                                            text: '동의',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          TextSpan(text: '합니다.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── CTA 버튼 ──
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: _agreed ? pinkGradient : null,
                                  color: _agreed ? null : const Color(0xFFD1D5DB),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _agreed
                                      ? [
                                          BoxShadow(
                                            color: pink400.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _agreed ? _onAgree : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: const Center(
                                      child: Text(
                                        '동의하고 시작하기',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 하단 카피라이트
                      Text(
                        '© 2026 MeetZy · 세종대학교',
                        style: TextStyle(
                          color: pink400.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 약관 상세 모달 ──
            if (_openDoc != null) _buildDocModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocModal() {
    final isTerms = _openDoc == 'terms';
    final title = isTerms ? '서비스 이용약관' : '개인정보 처리방침';
    final sections = isTerms ? _termsSections : _privacySections;

    return Stack(
      children: [
        // 배경 딤
        GestureDetector(
          onTap: _closeDocModal,
          child: Container(color: Colors.black54),
        ),
        // 바텀 시트
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _closeDocModal,
                        icon: Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                // 본문
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (_, i) {
                      final section = sections[i];
                      final heading = section['heading'] as String;
                      final body = section['body'] as List<String>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...body.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                // 확인 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFB7185)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _closeDocModal,
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              '확인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 약관/개인정보 처리방침 보기 버튼
class _DocButton extends StatelessWidget {
  const _DocButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFE11D48)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const Text(
                '›',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
