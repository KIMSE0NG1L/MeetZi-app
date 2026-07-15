import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/data/support_repository.dart';
import 'package:nearo_app/features/settings/screens/faq_screen.dart';
import 'package:nearo_app/shared/widgets/meetzy_sub_page_scaffold.dart';

/// AppDesign CustomerSupport: 로즈 그라데이션 헤더 + 빠른 도움말 + 문의하기 폼 + 연락처
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  String _selectedCategory = '';
  final _messageController = TextEditingController();
  bool _submitted = false;
  bool _sending = false;
  List<Map<String, dynamic>> _myInquiries = [];
  bool _loadingInquiries = false;
  final _supportRepo = SupportRepository();


  static const _categories = [
    {'id': 'account', 'label': '계정 문제', 'icon': '👤'},
    {'id': 'payment', 'label': '결제 문의', 'icon': '💳'},
    {'id': 'bug', 'label': '버그 신고', 'icon': '🐛'},
    {'id': 'feature', 'label': '기능 제안', 'icon': '💡'},
    {'id': 'other', 'label': '기타', 'icon': '🎸'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInquiries() async {
    setState(() => _loadingInquiries = true);
    try {
      final list = await _supportRepo.getMyInquiries();
      if (mounted) setState(() { _myInquiries = list; _loadingInquiries = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingInquiries = false; });
    }
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedCategory.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _supportRepo.sendInquiry(
        category: _selectedCategory,
        message: message,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _submitted = true;
      });
      _loadInquiries();
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _submitted = false;
          _selectedCategory = '';
          _messageController.clear();
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      String msg = '문의 전송에 실패했어요.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final surfaceCard = dark ? const Color(0xFF374151) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;

    return MeetzySubPageScaffold(
      title: '고객센터',
      body: _submitted ? _buildSuccessContent(dark, onSurface, onSurfaceVariant) : _buildFormContent(context, dark, surface, surfaceCard, onSurface, onSurfaceVariant, primary),
    );
  }

  Widget _buildSuccessContent(bool dark, Color onSurface, Color onSurfaceVariant) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
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
                '앱 내 문의함에서 답변을 확인해 주세요.',
                style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    bool dark,
    Color surface,
    Color surfaceCard,
    Color onSurface,
    Color onSurfaceVariant,
    Color primary,
  ) {
    final message = _messageController.text.trim();
    final canSubmit = !_sending && message.isNotEmpty && _selectedCategory.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('빠른 도움말', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 12),
          _QuickHelpCard(
            surface: surfaceCard,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            icon: LucideIcons.info,
            title: '자주 묻는 질문',
            subtitle: 'FAQ에서 답변을 찾아보세요',
            primary: primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('문의하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 12),
          Text('문의 유형', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final id = c['id']! as String;
              final label = c['label']! as String;
              final icon = c['icon']! as String;
              final selected = _selectedCategory == id;
              return Material(
                color: selected ? primary : surfaceCard,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : onSurface,
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
          Text('문의 내용', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            onChanged: (_) => setState(() {}),
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '문의 내용을 상세히 작성해주세요...',
              filled: true,
              fillColor: surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(color: onSurface, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: canSubmit ? primary : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: canSubmit ? _submit : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _sending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.send, size: 20, color: canSubmit ? Colors.white : Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(
                              '문의 보내기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: canSubmit ? Colors.white : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('내 문의함', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 2),
          Text('답변은 앱에서 확인해 주세요.', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
          const SizedBox(height: 12),
          if (_loadingInquiries)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_myInquiries.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.inbox, size: 28, color: onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '아직 문의 내역이 없어요.',
                      style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._myInquiries.map((q) => _InquiryTile(
                  inquiry: q,
                  surfaceCard: surfaceCard,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  primary: primary,
                  categories: _categories,
                  onTap: () => _showInquiryDetail(context, q, dark, surfaceCard, onSurface, onSurfaceVariant),
                )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📧 이메일: lne857057@gmail.com', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('⏰ 운영시간: 평일 9:00 - 18:00 (매일 수시로 확인해요 😊)', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInquiryDetail(
    BuildContext context,
    Map<String, dynamic> q,
    bool dark,
    Color surfaceCard,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    final categories = _categories;
    final catId = q['category'] as String? ?? '';
    final catList = categories.cast<Map<String, dynamic>>().where((c) => c['id'] == catId).toList();
    final cat = catList.isNotEmpty ? catList.first : null;
    final catLabel = cat?['label'] as String? ?? catId;
    final message = q['message'] as String? ?? '';
    final reply = q['reply'] as String?;
    final repliedAt = q['repliedAt'] as String?;
    final createdAt = q['createdAt'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('문의 유형: $catLabel', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
                if (createdAt.isNotEmpty)
                  Text('접수일: ${createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt}', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                const SizedBox(height: 12),
                Text('문의 내용', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: surfaceCard, borderRadius: BorderRadius.circular(12)),
                  child: Text(message, style: TextStyle(fontSize: 14, color: onSurface)),
                ),
                if (reply != null && reply.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('답변', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                  if (repliedAt != null && repliedAt.toString().length >= 10)
                    Text('답변일: ${repliedAt.toString().substring(0, 10)}', style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(reply, style: TextStyle(fontSize: 14, color: onSurface)),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text('답변 대기 중이에요. 빠른 시일 내에 답변 드릴게요.', style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({
    required this.inquiry,
    required this.surfaceCard,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.categories,
    required this.onTap,
  });

  final Map<String, dynamic> inquiry;
  final Color surfaceCard;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final List<Map<String, String>> categories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catId = inquiry['category'] as String? ?? '';
    final catList = categories.cast<Map<String, dynamic>>().where((c) => c['id'] == catId).toList();
    final cat = catList.isNotEmpty ? catList.first : null;
    final catLabel = cat?['label'] as String? ?? catId;
    final message = inquiry['message'] as String? ?? '';
    final hasReply = inquiry['reply'] != null && (inquiry['reply'] as String).isNotEmpty;
    final createdAt = inquiry['createdAt'] as String? ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(catLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface)),
                          if (hasReply) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text('답변 있음', style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.length > 60 ? '${message.substring(0, 60)}...' : message,
                        style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: TextStyle(fontSize: 11, color: onSurfaceVariant.withOpacity(0.8))),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickHelpCard extends StatelessWidget {
  const _QuickHelpCard({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
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
