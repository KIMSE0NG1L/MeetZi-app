import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.createPost(widget.environmentId, content);
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
            child: _sending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('등록'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          minLines: 8,
          decoration: const InputDecoration(
            hintText: '무슨 생각을 하고 있나요?',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          autofocus: true,
        ),
      ),
    );
  }
}
