import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentPreviewScreen extends StatefulWidget {
  const ConsentPreviewScreen({super.key});

  @override
  State<ConsentPreviewScreen> createState() => _ConsentPreviewScreenState();
}

class _ConsentPreviewScreenState extends State<ConsentPreviewScreen> {
  final _matchIdController = TextEditingController();
  final _chatController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final _repository = ConsentRepository();
  bool _isLoading = false;
  String? _consentMessage;

  @override
  void dispose() {
    _matchIdController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _requestPhotoShare() {
    setState(() {
      _consentMessage = '상대가 동의하여 사진이 공유되었습니다.';
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true));
      _chatController.clear();
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: false));
    });
  }

  Future<void> _checkConsentStatus() async {
    if (_matchIdController.text.trim().isEmpty) {
      _showMessage('매칭 ID를 입력해 주세요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _repository.getConsentStatus(
        matchId: _matchIdController.text.trim(),
      );
      _showMessage(result.toString());
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '조회에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('익명 대화 프리뷰'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상대와 대화가 잘 이어지고 있나요?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '양쪽이 모두 동의하면\n서로의 얼굴이 공개되고 카카오톡으로 넘어갑니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text('첫 메시지를 보내 보세요.'),
                        )
                      : ListView.separated(
                          itemCount: _messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final alignment = message.isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft;
                            final color = message.isMine
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200;
                            final textColor = message.isMine
                                ? Colors.white
                                : Colors.black87;
                            return Align(
                              alignment: alignment,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              PrimaryButton(
                label: '사진 공유 요청',
                isLoading: _isLoading,
                onPressed: _requestPhotoShare,
              ),
              if (_consentMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _consentMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMine;

  const _ChatMessage({required this.text, required this.isMine});
}
