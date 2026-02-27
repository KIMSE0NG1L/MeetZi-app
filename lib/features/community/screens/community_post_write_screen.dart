import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';

class CommunityPostWriteScreen extends StatefulWidget {
  final String environmentId;
  final String schoolName;

  const CommunityPostWriteScreen({
    super.key,
    required this.environmentId,
    required this.schoolName,
  });

  @override
  State<CommunityPostWriteScreen> createState() => _CommunityPostWriteScreenState();
}

class _CommunityPostWriteScreenState extends State<CommunityPostWriteScreen> {
  final CommunityRepository _repo = CommunityRepository();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _sending = false;
  bool _addPoll = false;

  @override
  void dispose() {
    _contentController.dispose();
    _pollQuestionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    _optionControllers[index].dispose();
    setState(() => _optionControllers.removeAt(index));
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    Map<String, dynamic>? poll;
    if (_addPoll) {
      final question = _pollQuestionController.text.trim();
      final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      if (question.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 질문을 입력해 주세요.')),
        );
        return;
      }
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택지는 최소 2개 이상 필요해요.')),
        );
        return;
      }
      poll = {'question': question, 'options': options};
    }
    setState(() => _sending = true);
    try {
      await _repo.createPost(widget.environmentId, content, poll: poll);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        String message = '글 등록에 실패했어요. 잠시 후 다시 시도해 주세요.';
        if (e is DioException) {
          final code = e.response?.statusCode;
          if (code == 401) {
            message = '로그인이 필요해요. 앱을 다시 실행하거나 다시 로그인해 주세요.';
          } else if (code == 404) {
            message = '커뮤니티를 찾을 수 없어요.';
          } else if (code != null && code >= 500) {
            message = '서버 오류가 났어요. 잠시 후 다시 시도해 주세요.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기'),
        actions: [
          TextButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('등록'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 6,
              decoration: const InputDecoration(
                hintText: '무슨 생각을 하고 있나요?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.vote, size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('투표 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _addPoll,
                  onChanged: (v) => setState(() => _addPoll = v),
                ),
              ],
            ),
            if (_addPoll) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pollQuestionController,
                decoration: const InputDecoration(
                  labelText: '투표 질문',
                  hintText: '예: 오늘 점심 뭐 먹을까요?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('선택지 (2~10개)', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: '선택지 ${index + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 20),
                          onPressed: () => _removeOption(index),
                          tooltip: '삭제',
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('선택지 추가'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
