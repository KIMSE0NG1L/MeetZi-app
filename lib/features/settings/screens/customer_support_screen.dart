import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// AppDesign CustomerSupport: 고객센터 헤더 + 빠른 도움말 + 문의 유형/이메일/내용 폼 + 제출 완료 화면
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  String _selectedCategory = '';
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  static const _roseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
  );

  static const _categories = [
    {'id': 'account', 'label': '계정 문제', 'icon': '👤'},
    {'id': 'payment', 'label': '결제 문의', 'icon': '💳'},
    {'id': 'bug', 'label': '버그 신고', 'icon': '🐛'},
    {'id': 'feature', 'label': '기능 제안', 'icon': '💡'},
    {'id': 'other', 'label': '기타', 'icon': '📝'},
  ];

  void _submit() {
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();
    if (email.isEmpty || message.isEmpty || _selectedCategory.isEmpty) return;
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _submitted = false;
        _emailController.clear();
        _messageController.clear();
        _selectedCategory = '';
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    const pb = 24.0;
    const titleHeight = 36.0;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 20, right: 20, top: pt, bottom: pb),
              decoration: const BoxDecoration(
                gradient: _roseGradient,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const Expanded(
                    child: Text(
                      '고객센터',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: _submitted ? _buildSubmittedView(dark) : _buildForm(dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedView(bool dark) {
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onVariant = dark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✉️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            '문의가 접수되었습니다',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '빠른 시일 내에 답변 드리겠습니다',
            style: TextStyle(fontSize: 16, color: onVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool dark) {
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onVariant = dark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    final canSubmit = _emailController.text.trim().isNotEmpty &&
        _messageController.text.trim().isNotEmpty &&
        _selectedCategory.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '빠른 도움말',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
        ),
        const SizedBox(height: 12),
        _QuickHelpTile(
          dark: dark,
          icon: LucideIcons.helpCircle,
          title: '자주 묻는 질문',
          subtitle: 'FAQ에서 답변을 찾아보세요',
        ),
        const SizedBox(height: 8),
        _QuickHelpTile(
          dark: dark,
          icon: LucideIcons.messageCircle,
          title: '채팅 상담',
          subtitle: '평일 9시~18시 운영',
        ),
        const SizedBox(height: 24),
        Text(
          '문의하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          '문의 유형',
          style: TextStyle(fontSize: 14, color: onVariant),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: _categories.map((c) {
            final id = c['id']! as String;
            final label = c['label']! as String;
            final icon = c['icon']! as String;
            final selected = _selectedCategory == id;
            return Material(
              color: selected
                  ? const Color(0xFFF43F5E)
                  : (dark ? const Color(0xFF1F2937) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('이메일 주소', style: TextStyle(fontSize: 14, color: onVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            prefixIcon: const Icon(LucideIcons.mail, size: 22),
            filled: true,
            fillColor: dark ? const Color(0xFF1F2937) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(fontSize: 16, color: onSurface),
        ),
        const SizedBox(height: 16),
        Text('문의 내용', style: TextStyle(fontSize: 14, color: onVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: _messageController,
          onChanged: (_) => setState(() {}),
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '문의 내용을 상세히 작성해주세요...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: dark ? const Color(0xFF1F2937) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(fontSize: 16, color: onSurface),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canSubmit ? _submit : null,
            icon: const Icon(LucideIcons.send, size: 20),
            label: const Text('문의 보내기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: canSubmit ? const Color(0xFFF43F5E) : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              foregroundColor: canSubmit ? Colors.white : (dark ? Colors.grey.shade500 : Colors.grey.shade600),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📧 이메일: support@meetzy.com', style: TextStyle(fontSize: 14, color: onVariant)),
              const SizedBox(height: 6),
              Text('⏰ 운영시간: 평일 9:00 - 18:00', style: TextStyle(fontSize: 14, color: onVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickHelpTile extends StatelessWidget {
  const _QuickHelpTile({
    required this.dark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool dark;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onVariant = dark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFFF43F5E)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: onVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
