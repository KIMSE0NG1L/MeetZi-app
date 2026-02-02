import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentPreviewScreen extends StatefulWidget {
  const ConsentPreviewScreen({super.key});

  @override
  State<ConsentPreviewScreen> createState() => _ConsentPreviewScreenState();
}

class _ConsentPreviewScreenState extends State<ConsentPreviewScreen> {
  final _chatStore = ChatHistoryStore.instance;
  bool _didLoadHistory = false;
  static const Map<String, dynamic> _fallbackProfile = {
    'nickname': '두쫀쿠공주',
    'birthYear': 2005,
    'gender': '여성',
    'preferredGender': '남성 선호',
    'affiliation': '세종대학교',
    'heightCm': 160,
    'smoking': '비흡연',
    'mbti': 'INFP',
    'instagram': '@dck',
    'bio': '세종대 컴공과에요!',
  };
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadHistory) return;
    _didLoadHistory = true;
    _loadHistoryForPartner();
  }

  Future<void> _loadHistoryForPartner() async {
    await _chatStore.ensureLoaded();
    final args = ModalRoute.of(context)?.settings.arguments;
    final partnerProfile =
        args is Map<String, dynamic> ? args : _fallbackProfile;
    final partnerName = partnerProfile['nickname']?.toString() ?? '상대';
    final thread = _chatStore.getThread(partnerName);
    if (thread == null || !mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(
          thread.messages.map(
            (m) => _ChatMessage(text: m.text, isMine: m.isMine),
          ),
        );
    });
  }

  void _requestPhotoShare() {
    setState(() {
      _consentMessage = '상대가 동의하여 사진이 공유되었습니다.';
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final partnerProfile =
        args is Map<String, dynamic> ? args : _fallbackProfile;
    final partnerName = partnerProfile['nickname']?.toString() ?? '상대';

    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true));
      _chatController.clear();
    });
    _chatStore.addMessage(partner: partnerName, text: text, isMine: true);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: false));
    });
    _chatStore.addMessage(partner: partnerName, text: text, isMine: false);
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final partnerProfile =
        args is Map<String, dynamic> ? args : _fallbackProfile;
    final partnerName = partnerProfile['nickname']?.toString() ?? '대화';
    return Scaffold(
      appBar: AppBar(
      title: Text(partnerName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkResponse(
              onTap: _requestPhotoShare,
              radius: 22,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            final color = message.isMine
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200;
                            final textColor = message.isMine
                                ? Colors.white
                                : Colors.black87;
                            if (message.isMine) {
                              return Align(
                                alignment: Alignment.centerRight,
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
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.partnerProfile,
                                      arguments: partnerProfile,
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      partnerProfile['nickname']
                                              ?.toString()
                                              .substring(0, 1) ??
                                          '',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
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
                              ],
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
