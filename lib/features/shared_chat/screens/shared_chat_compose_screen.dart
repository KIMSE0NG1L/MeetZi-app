import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/shared_chat/data/shared_chat_repository.dart';

class SharedChatComposeScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;
  final List<Map<String, dynamic>> messages;

  const SharedChatComposeScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
    required this.messages,
  });

  @override
  State<SharedChatComposeScreen> createState() => _SharedChatComposeScreenState();
}

class _SharedChatComposeScreenState extends State<SharedChatComposeScreen> {
  final SharedChatRepository _repository = SharedChatRepository();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  int? _startIndex;
  int? _endIndex;
  bool _sending = false;

  List<Map<String, dynamic>> get _messages => widget.messages
      .where((message) => message['isSystem'] != true)
      .map((message) => Map<String, dynamic>.from(message))
      .toList();

  List<Map<String, dynamic>> get _selectedMessages {
    if (_startIndex == null || _endIndex == null) return const [];
    return _messages.sublist(_startIndex!, _endIndex! + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _onTapMessage(int index) {
    setState(() {
      if (_startIndex == null) {
        _startIndex = index;
        _endIndex = index;
        return;
      }

      if (_startIndex != null && _endIndex != null && _startIndex == _endIndex) {
        if (index < _startIndex!) {
          _startIndex = index;
        } else {
          _endIndex = index;
        }
      } else {
        _startIndex = index;
        _endIndex = index;
      }

      if (_selectedMessages.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연속 메시지는 최대 10개까지만 고를 수 있어요.')),
        );
        _startIndex = index;
        _endIndex = index;
      }
    });
  }

  Future<void> _submit() async {
    final selected = _selectedMessages;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해 주세요.')),
      );
      return;
    }
    if (selected.length < 2 || selected.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연속된 대화 2개 이상 10개 이하를 선택해 주세요.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _repository.createDraft(
        roomId: widget.roomId,
        startMessageId: selected.first['id'].toString(),
        endMessageId: selected.last['id'].toString(),
        title: title,
        summary: _summaryController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유 요청을 보냈어요. 상대가 동의하면 커뮤니티에 올라갑니다.')),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : '공유 요청을 보내지 못했어요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isSelected(int index) {
    if (_startIndex == null || _endIndex == null) return false;
    return index >= _startIndex! && index <= _endIndex!;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final messages = _messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('대화 구간 공유'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: dark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.partnerName}님과의 대화 중 연속된 구간을 골라 주세요.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '처음 탭은 시작점, 두 번째 탭은 끝점이에요. 최대 10개까지 공유할 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예: 첫 텐션은 좋았는데 갑자기 싸해진 대화',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _summaryController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '한줄 설명',
                    hintText: '예: 매칭 종료 후 양측 동의로 공개되는 대화입니다.',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMine = message['isMine'] == true;
                final selected = _isSelected(index);
                return InkWell(
                  onTap: () => _onTapMessage(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.16)
                          : (dark ? const Color(0xFF1F2937) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : (dark ? Colors.grey.shade800 : Colors.grey.shade200),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : (dark ? Colors.grey.shade800 : Colors.grey.shade100),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: selected
                              ? const Icon(LucideIcons.check, color: Colors.white, size: 15)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMine ? '나' : widget.partnerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isMine
                                      ? Theme.of(context).colorScheme.primary
                                      : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['text']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMessages.isEmpty
                        ? '아직 선택된 대화가 없어요.'
                        : '선택된 메시지 ${_selectedMessages.length}개',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('상대에게 동의 요청 보내기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
