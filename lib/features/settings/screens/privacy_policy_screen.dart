import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({
    super.key,
    this.showConsentAction = false,
  });

  final bool showConsentAction;

  static const List<_PolicySection> _sections = [
    _PolicySection(
      title: '개인정보 처리방침',
      body:
          '본 서비스는 회원 식별, 서비스 제공, 고객지원, 알림 발송, 안전한 커뮤니티 운영을 위해 필요한 범위 내에서 개인정보를 처리합니다.\n\n'
          '수집 항목, 이용 목적, 보관 기간, 제3자 제공 및 처리위탁 여부는 실제 서비스 운영 방식에 맞춰 최신 상태로 유지되어야 합니다.',
    ),
    _PolicySection(
      title: '개인정보 수집·이용 동의',
      body: '회원가입 또는 서비스 이용 과정에서 다음과 같은 개인정보를 수집·이용할 수 있습니다.\n\n'
          '1. 수집 항목: 닉네임, 학교 또는 소속 정보, 프로필 정보, 기기 정보, 푸시 토큰, 고객지원 문의 내용\n'
          '2. 이용 목적: 회원관리, 매칭 및 커뮤니티 기능 제공, 알림 발송, 문의 응대, 서비스 품질 개선\n'
          '3. 보유 및 이용 기간: 회원 탈퇴 시까지 또는 관계 법령에 따른 보관 기간까지\n'
          '4. 동의 거부 권리 및 불이익: 이용자는 동의를 거부할 권리가 있으나, 필수 항목에 대한 동의를 거부할 경우 서비스 이용이 제한될 수 있습니다.',
    ),
    _PolicySection(
      title: '이용자 권리',
      body: '이용자는 언제든지 자신의 개인정보에 대해 열람, 정정, 삭제, 처리정지 요청을 할 수 있습니다.\n\n'
          '관련 요청은 고객지원 또는 별도 안내된 문의 채널을 통해 접수할 수 있으며, 서비스 운영자는 관계 법령에 따라 지체 없이 필요한 조치를 진행합니다.',
    ),
    _PolicySection(
      title: '안내',
      body:
          '현재 화면의 내용은 앱 내 고지용 초안입니다. 실제 배포 전에는 서비스에서 실제로 수집하는 항목, 외부 서비스 연동 내역, 법정 보관 의무를 반영해 최종 검토가 필요합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCard = dark ? const Color(0xFF374151) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (topInset > 0 ? topInset : 56.0) + 20 + 36;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: ThemeController.getHeaderGradient(),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '개인정보 안내',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Text(
                    '회원가입 화면의 동의 문구와 실제 운영 정책이 이 화면과 동일하게 유지되도록 관리해 주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final section in _sections) ...[
                  _SectionCard(
                    title: section.title,
                    body: section.body,
                    surfaceCard: surfaceCard,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: showConsentAction
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('동의하고 계속'),
                ),
              ),
            )
          : null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    required this.surfaceCard,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  final String title;
  final String body;
  final Color surfaceCard;
  final Color onSurface;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
