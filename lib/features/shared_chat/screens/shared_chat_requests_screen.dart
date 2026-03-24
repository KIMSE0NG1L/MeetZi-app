import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/shared_chat/data/shared_chat_repository.dart';

class SharedChatRequestsScreen extends StatefulWidget {
  const SharedChatRequestsScreen({super.key});

  @override
  State<SharedChatRequestsScreen> createState() => _SharedChatRequestsScreenState();
}

class _SharedChatRequestsScreenState extends State<SharedChatRequestsScreen> {
  final SharedChatRepository _repository = SharedChatRepository();
  bool _loading = true;
  String _role = 'all';
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repository.listMine(role: _role, status: 'pending_consent');
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(String id) async {
    Map<String, dynamic> detail;
    try {
      detail = await _repository.getDetail(id);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : '공유 요청을 불러오지 못했어요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final messages = (detail['messages'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final myConsent = detail['myConsent']?.toString();
        final canDecide = myConsent == 'pending' && detail['status'] == 'pending_consent';
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF111827) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail['title']?.toString() ?? '공유 요청',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                if ((detail['summary']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail['summary'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['senderRole']?.toString() ?? 'A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['content']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: dark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (canDecide)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop('no'),
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop('yes'),
                          child: const Text('동의하고 올리기'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        myConsent == 'yes' ? '내 동의는 이미 완료됐어요' : '확인',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'yes' || action == 'no') {
      try {
        await _repository.decideConsent(id, action!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'yes' ? '동의가 완료됐어요.' : '공유 요청을 거절했어요.')),
        );
        _load();
      } on DioException catch (e) {
        if (!mounted) return;
        final message = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : '동의 상태를 저장하지 못했어요.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('대화 공유 요청'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: _role == 'all',
                  onSelected: (_) {
                    setState(() => _role = 'all');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('내가 보냄'),
                  selected: _role == 'requester',
                  onSelected: (_) {
                    setState(() => _role = 'requester');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('내가 받음'),
                  selected: _role == 'partner',
                  onSelected: (_) {
                    setState(() => _role = 'partner');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messagesSquare, size: 42, color: dark ? Colors.grey.shade500 : Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              '대기 중인 대화 공유 요청이 없어요.',
                              style: TextStyle(
                                fontSize: 15,
                                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final partnerConsent = item['partnerConsent']?.toString() ?? 'pending';
                            return Material(
                              color: dark ? const Color(0xFF1F2937) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: () => _openDetail(item['id'].toString()),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title']?.toString() ?? '공유 요청',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: dark ? Colors.white : const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: partnerConsent == 'pending'
                                                  ? Colors.orange.withOpacity(0.14)
                                                  : Colors.green.withOpacity(0.14),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              partnerConsent == 'pending' ? '동의 대기' : '처리됨',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: partnerConsent == 'pending' ? Colors.orange.shade700 : Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['summary']?.toString().isNotEmpty == true
                                            ? item['summary'].toString()
                                            : (item['previewText']?.toString() ?? ''),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
