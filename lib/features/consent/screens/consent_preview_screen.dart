import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

class ConsentPreviewScreen extends StatefulWidget {
  const ConsentPreviewScreen({super.key});

  @override
  State<ConsentPreviewScreen> createState() => _ConsentPreviewScreenState();
}

class _ConsentPreviewScreenState extends State<ConsentPreviewScreen> {
  final _chatStore = ChatHistoryStore.instance;
  final _scrollController = ScrollController();
  bool _didLoadHistory = false;

  static const Map<String, dynamic> _fallbackProfile = {
    'nickname': '익명 사용자',
    'gender': '여성',
    'preferredGender': '남성 선호',
    'affiliation': '캠퍼스 커뮤니티',
    'heightCm': 160,
    'smoking': '비흡연',
    'mbti': 'INFP',
    'bio': '채팅 후기를 미리 보여주는 예시 프로필입니다.',
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
    _scrollController.dispose();
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final partnerProfile = args is Map<String, dynamic> ? args : _fallbackProfile;
    final partnerName = partnerProfile['nickname']?.toString() ?? '상대';

    await _chatStore.ensureLoaded();
    final thread = _chatStore.getThread(partnerName);
    if (thread == null || !mounted) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(
          thread.messages.map(
            (m) => _ChatMessage(
              text: m.text,
              isMine: m.isMine,
              createdAt: m.createdAt,
            ),
          ),
        );
    });
  }

  void _requestPhotoShare() {
    setState(() {
      _consentMessage = '상대가 동의하면 사진 공유 요청 상태를 여기에서 보여줄 수 있어요.';
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final partnerProfile = args is Map<String, dynamic> ? args : _fallbackProfile;
    final partnerName = partnerProfile['nickname']?.toString() ?? '상대';
    final now = DateTime.now();

    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true, createdAt: now));
      _chatController.clear();
    });
    _chatStore.addMessage(partner: partnerName, text: text, isMine: true);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isMine: false,
          createdAt: DateTime.now(),
        ),
      );
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
      _showMessage(error.response?.data.toString() ?? '동의 상태 조회에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _messageTime(_ChatMessage message) {
    final dt = message.createdAt;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? '오전' : '오후';
    return '$period $hour:$minute';
  }

  String _dateLabel(DateTime dt) {
    return '${dt.year}년 ${dt.month}월 ${dt.day}일';
  }

  Widget _buildMaskedAvatar({
    required BuildContext context,
    required bool dark,
    required bool isMine,
  }) {
    final bg = isMine
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
        : (dark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200);
    final fg = isMine
        ? Theme.of(context).colorScheme.primary
        : (dark ? Colors.white70 : const Color(0xFF6B7280));

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          width: 1.5,
        ),
      ),
      child: Icon(LucideIcons.userRound, size: 18, color: fg),
    );
  }

  Widget _buildEmptyState(bool dark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: dark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.messagesSquare,
              size: 34,
              color: dark ? Colors.white70 : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 가져온 대화가 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '후기 화면도 단순 텍스트 나열이 아니라\n실제 채팅방처럼 보이도록 구성했습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: dark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _checkConsentStatus,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.badgeCheck),
            label: const Text('동의 상태 확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, bool dark) {
    final theme = Theme.of(context);
    final timeColor = dark ? Colors.grey.shade500 : Colors.grey.shade600;
    final bubbleOther = dark ? const Color(0xFF374151) : Colors.white;
    final bubbleMine = theme.colorScheme.primary;

    if (_messages.isEmpty) {
      return _buildEmptyState(dark);
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 20, right: 12, top: 16, bottom: 16),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final message = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        final isNewDate = prev == null ||
            prev.createdAt.year != message.createdAt.year ||
            prev.createdAt.month != message.createdAt.month ||
            prev.createdAt.day != message.createdAt.day;

        final children = <Widget>[];
        if (isNewDate) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: dark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    _dateLabel(message.createdAt),
                    style: TextStyle(fontSize: 12, color: timeColor),
                  ),
                ),
              ),
            ),
          );
        }

        children.add(
          Row(
            mainAxisAlignment:
                message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMine) ...[
                _buildMaskedAvatar(context: context, dark: dark, isMine: false),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: message.isMine
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              _messageTime(message),
                              style: TextStyle(fontSize: 11, color: timeColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleMine,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                message.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleOther,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              _messageTime(message),
                              style: TextStyle(fontSize: 11, color: timeColor),
                            ),
                          ),
                        ],
                ),
              ),
              if (message.isMine) ...[
                const SizedBox(width: 8),
                _buildMaskedAvatar(context: context, dark: dark, isMine: true),
              ],
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 16),
              decoration: BoxDecoration(
                gradient: ThemeController.getHeaderGradient(),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildMaskedAvatar(context: context, dark: true, isMine: false),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '익명 매칭 후기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '이름과 아바타를 가린 실제 채팅방 미리보기',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _requestPhotoShare,
                    icon: const Icon(LucideIcons.camera, color: Colors.white, size: 22),
                    tooltip: '사진 공유 요청',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildMessageList(context, dark),
            ),
            if (_consentMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: dark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _consentMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1F2937) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF374151) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendMessage(),
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          color: dark ? Colors.white : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: '대화를 이어서 미리보기',
                          hintStyle: TextStyle(
                            color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(LucideIcons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMine;
  final DateTime createdAt;

  const _ChatMessage({
    required this.text,
    required this.isMine,
    required this.createdAt,
  });
}
