import 'package:flutter/material.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _repository = ChatRepository();
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _loading = true;
  String _title = '대화';
  String? _roomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _roomId = args['roomId']?.toString();
      _title = args['partnerNickname']?.toString() ?? _title;
    }
    if (_roomId != null) {
      _loadMessages();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;
    try {
      final result = await _repository.listMessages(roomId: _roomId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(result.map(
            (m) => _ChatMessage(
              text: m['content']?.toString() ?? '',
              isMine: m['isMine'] == true,
            ),
          ));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _roomId == null) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true));
    });

    try {
      await _repository.sendMessage(roomId: _roomId!, content: text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(text: '메시지 전송 실패', isMine: false));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? const Center(child: Text('첫 메시지를 보내 보세요.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
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
                            return Align(
                              alignment: message.isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(message.text, style: TextStyle(color: textColor)),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
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

  const _ChatMessage({required this.text, required this.isMine});
}
