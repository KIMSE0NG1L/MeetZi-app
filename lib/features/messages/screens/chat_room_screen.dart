import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/features/messages/data/partner_profile_repository.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _consentRepository = ConsentRepository();
  final _partnerProfileRepository = PartnerProfileRepository();
  final _repository = ChatRepository();
  final _matchingRepository = MatchingRepository();
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _loading = true;
  String _title = '대화';
  String? _roomId;
  bool _isActive = true;
  bool _isProfileRevealed = false;
  String? _partnerPhotoStorageKey;
  String? _partnerNickname;
  Map<String, dynamic>? _partnerProfile;
  String? _user1Consent;
  String? _user2Consent;
  String? _matchId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _roomId = args['roomId']?.toString();
      _title = args['partnerNickname']?.toString() ?? _title;
      if (args.containsKey('isActive')) {
        _isActive = args['isActive'] == true;
      }
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
              isSystem: m['isSystem'] == true,
            ),
          ));
        _loading = false;
      });
      await _loadRoomState();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRoomState() async {
    if (_roomId == null) return;
    try {
      final room = await _repository.getRoom(roomId: _roomId!);
      if (!mounted) return;
      _isActive = room['isActive'] == true;
      _isProfileRevealed = room['isProfileRevealed'] == true;
      _partnerPhotoStorageKey = room['partnerPhotoStorageKey']?.toString();
      _partnerNickname = room['partnerNickname']?.toString();
      _user1Consent = room['user1Consent']?.toString();
      _user2Consent = room['user2Consent']?.toString();
      _matchId = room['matchId']?.toString();
      if (_isProfileRevealed && _matchId != null) {
        try {
          final profile = await _partnerProfileRepository.getPartnerProfile(matchId: _matchId!);
          if (mounted) setState(() => _partnerProfile = profile);
        } catch (_) {
          if (mounted) setState(() => _partnerProfile = null);
        }
      } else {
        setState(() => _partnerProfile = null);
      }
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActive = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!_isActive) return;
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

  Future<void> _cancelMatch() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 취소'),
        content: const Text(
          '정말로 취소하시겠습니까? 취소하면 상대방과의 대화창은 비활성화 됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      await _matchingRepository.cancelMatch();
      if (!mounted) return;
      setState(() => _isActive = false);
      _controller.clear();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭 취소에 실패했습니다.')),
      );
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
        actions: [
          TextButton(
            onPressed: _cancelMatch,
            child: const Text('매칭 취소'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 프로필 공개/동의 UI
            if (_isActive)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    if (_isProfileRevealed)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _partnerPhotoStorageKey != null
                                  ? CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage('https://nearo-image.s3.ap-northeast-2.amazonaws.com/${_partnerPhotoStorageKey!}'),
                                    )
                                  : const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                              const SizedBox(width: 16),
                              Text(_partnerNickname ?? '상대', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _partnerProfile == null ? null : () {
                              Navigator.of(context).pushNamed(
                                '/chat/partner-profile',
                                arguments: _partnerProfile,
                              );
                            },
                            child: const Text('정보보기'),
                          ),
                          if (_partnerProfile != null && _partnerProfile!['bio'] != null && _partnerProfile!['bio'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '자기소개: ${_partnerProfile!['bio']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      )
                    else ...[
                      const Text(
                        '상호 동의 시에만 프로필 사진이 공개됩니다.',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_matchId == null) return;
                          // 동의 API 호출
                          try {
                            await _consentRepository.giveConsent(matchId: _matchId!, decision: true);
                            await _loadRoomState();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('동의가 완료되었습니다.')));
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('동의 처리에 실패했습니다.')));
                          }
                        },
                        child: const Text('프로필 공개 동의하기'),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (!_isActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.grey.shade200,
                      child: Text(
                        '매칭이 취소되어 메시지를 보낼 수 없습니다.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
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
                                  if (message.isSystem) {
                                    return Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message.text,
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ),
                                    );
                                  }

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
                ],
              ),
            ),
            if (_isActive)
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
  final bool isSystem;

  const _ChatMessage({
    required this.text,
    required this.isMine,
    this.isSystem = false,
  });
}
