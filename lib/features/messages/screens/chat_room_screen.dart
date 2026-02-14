import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/features/messages/data/partner_profile_repository.dart';
import 'package:nearo_app/shared/notification_utils.dart';


import 'package:nearo_app/core/auth/auth_repository.dart';

class _ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final bool isSystem;
  final DateTime? readAt;
  final String senderId;

  _ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.senderId,
    this.isSystem = false,
    this.readAt,
  });
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  IO.Socket? _socket;
  String? _myUserId;
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
  // Removed unused fields _user1Consent and _user2Consent
  String? _matchId;

  final ScrollController _scrollController = ScrollController();
  Timer? _readAtPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

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
      _fetchMyUserIdAndInitSocketAndLoadMessages();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMyUserIdAndInitSocketAndLoadMessages() async {
    try {
      final profile = await AuthRepository().getProfile();
      final userId = profile['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        _myUserId = userId;
        await _initSocket();
        await _loadMessages();
        _sendReadReceipts();
        _scrollToBottom();
        _readAtPollTimer?.cancel();
        _readAtPollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _syncReadAt());
      } else {
        _myUserId = null;
        setState(() => _loading = false);
      }
    } catch (_) {
      _myUserId = null;
      setState(() => _loading = false);
    }
  }

  /// getRoom 응답의 messageReadAts로 '1' 갱신 (listMessages 대신 가벼운 getRoom 사용)
  void _applyMessageReadAts(List<dynamic>? messageReadAts) {
    if (messageReadAts == null || messageReadAts.isEmpty || !mounted) return;
    final serverReadAt = <String, DateTime>{};
    for (final m in messageReadAts) {
      final id = m['id']?.toString();
      final readAt = m['readAt'] != null ? DateTime.tryParse(m['readAt'].toString()) : null;
      if (id != null && readAt != null) {
        serverReadAt[id] = readAt;
      }
    }
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (!msg.isMine || msg.readAt != null) continue;
        final readAt = serverReadAt[msg.id];
        if (readAt != null) {
          _messages[i] = _ChatMessage(
            id: msg.id,
            text: msg.text,
            isMine: msg.isMine,
            senderId: msg.senderId,
            isSystem: msg.isSystem,
            readAt: readAt,
          );
        }
      }
    });
  }

  /// 채팅방에 있는 동안 getRoom으로 readAt 갱신 + 매칭 취소 시 isActive 반영
  Future<void> _syncReadAt() async {
    if (_roomId == null || !mounted) return;
    try {
      final room = await _repository.getRoom(roomId: _roomId!);
      if (!mounted) return;
      // 매칭 취소 시 서버에서 isActive=false로 오므로 주기적으로 반영해 입력 막기
      final isActiveFromServer = room['isActive'] == true;
      if (!isActiveFromServer && _isActive) {
        setState(() => _isActive = false);
      }
      final list = room['messageReadAts'];
      if (list is List) _applyMessageReadAts(list);
    } catch (_) {}
  }

  // 읽지 않은 메시지에 대해 소켓으로 읽음 이벤트 전송
  void _sendReadReceipts() {
    if (_socket == null || !_socket!.connected || _roomId == null || _myUserId == null) return;
    for (final msg in _messages) {
      if (!msg.isMine && msg.readAt == null) {
        final payload = {
          'roomId': _roomId,
          'messageId': msg.id,
          'userId': _myUserId,
          'readAt': DateTime.now().toIso8601String(),
        };
        print('[소켓 읽음 emit] $payload');
        _socket!.emit('read', payload);
      }
    }
  }

  // Removed unused method _fetchMyUserIdAndInitSocket

  Future<void> _loadMessages() async {
    if (_roomId == null) return;
    try {
      final result = await _repository.listMessages(roomId: _roomId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(result.map((m) {
            final senderId = m['senderId']?.toString();
            final isMine = senderId == _myUserId;
            print('[isMine 판별] senderId=$senderId, _myUserId=$_myUserId, isMine=$isMine, text=${m['content']}');
            return _ChatMessage(
              id: m['id']?.toString() ?? '',
              text: m['content']?.toString() ?? '',
              isMine: isMine,
              senderId: senderId ?? '',
              isSystem: m['isSystem'] == true,
              readAt: m['readAt'] != null ? DateTime.tryParse(m['readAt'].toString()) : null,
            );
          }));
        _loading = false;
      });
      // 읽지 않은 상대 메시지 읽음 처리
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (!msg.isMine && msg.readAt == null) {
          await _repository.readMessage(roomId: _roomId!, messageId: msg.id);
          final now = DateTime.now();
          // 읽음 처리 후 readAt을 즉시 갱신하여 UI에서 뱃지 사라지게
          setState(() {
            _messages[i] = _ChatMessage(
              id: msg.id,
              text: msg.text,
              isMine: msg.isMine,
              senderId: msg.senderId,
              isSystem: msg.isSystem,
              readAt: now,
            );
          });
          // 소켓으로 읽음 이벤트도 같이 전송
          if (_socket != null && _socket!.connected) {
            _socket!.emit('read', {
              'roomId': _roomId,
              'messageId': msg.id,
              'userId': _myUserId,
              'readAt': now.toIso8601String(),
            });
          }
        }
      }
      // 알림/뱃지 클리어
      await clearAllNotifications();
      await _loadRoomState();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _initSocket() async {
    if (_roomId == null || _myUserId == null || _myUserId!.isEmpty) return;
    final completer = Completer<void>();
    print('[소켓 연결 시도] roomId=$_roomId, myUserId=$_myUserId');
    _socket = IO.io(
      'https://hurtlingly-blatant-tari.ngrok-free.dev/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': _myUserId})
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {
      print('[소켓 연결 성공]');
      _socket!.emit('joinRoom', {'roomId': _roomId});
      if (!completer.isCompleted) completer.complete();
      print('[소켓 joinRoom emit] roomId=$_roomId');
    });
    _socket!.on('newMessage', (data) {
      print('[소켓 newMessage 핸들러 등록됨] data=$data');
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          id: data['id']?.toString() ?? '',
          text: data['content'] ?? '',
          isMine: data['senderId']?.toString() == _myUserId,
          senderId: data['senderId']?.toString() ?? '',
          isSystem: false,
          readAt: data['readAt'] != null ? DateTime.tryParse(data['readAt'].toString()) : null,
        ));
      });
      _scrollToBottom();
    });
    print('[소켓 read 핸들러 등록됨]');
    // 읽음 이벤트 처리: 해당 메시지의 readAt 갱신
    _socket!.on('read', (data) {
      debugPrint('[read 이벤트 수신] messageId=${data['messageId']}, userId=${data['userId']}, 내 메시지 수=${_messages.where((m) => m.isMine && m.readAt == null).length}');
      if (!mounted) return;
      final String? messageId = data['messageId']?.toString();
      final String? userId = data['userId']?.toString();
      final DateTime? readAt = data['readAt'] != null ? DateTime.tryParse(data['readAt'].toString()) : null;
      if (messageId == null || userId == null || readAt == null) return;
      // 내가 보낸 메시지가 상대에게 읽혔을 때만 갱신 (userId = 읽은 사람 = 상대)
      setState(() {
        final newList = <_ChatMessage>[];
        for (final msg in _messages) {
          if (msg.id == messageId && msg.isMine && msg.readAt == null) {
            newList.add(_ChatMessage(
              id: msg.id,
              text: msg.text,
              isMine: msg.isMine,
              senderId: msg.senderId,
              isSystem: msg.isSystem,
              readAt: readAt,
            ));
          } else {
            newList.add(msg);
          }
        }
        _messages
          ..clear()
          ..addAll(newList);
      });
    });
    _socket!.connect();
    print('[소켓 connect 호출됨]');
    await completer.future;
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
      _matchId = room['matchId']?.toString();
      final list = room['messageReadAts'];
      if (list is List) _applyMessageReadAts(list);
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
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendMessage', {'roomId': _roomId, 'content': text});
    } else {
      setState(() {
        _messages.add(_ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMine: true,
          senderId: _myUserId ?? '',
        ));
      });
      try {
        await _repository.sendMessage(roomId: _roomId!, content: text);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '메시지 전송 실패',
            isMine: false,
            senderId: _myUserId ?? '',
          ));
        });
      }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_socket == null || !_socket!.connected || _roomId == null) return;
    if (state == AppLifecycleState.resumed) {
      _socket!.emit('joinRoom', {'roomId': _roomId});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socket!.emit('outRoom', {'roomId': _roomId});
    }
  }

  @override
  void dispose() {
    if (_socket != null && _socket!.connected && _roomId != null) {
      _socket!.emit('outRoom', {'roomId': _roomId});
    }
    _readAtPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final message = _messages[_messages.length - 1 - index];
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
                                  return Row(
                                    key: ValueKey('${message.id}_${message.readAt?.millisecondsSinceEpoch ?? 0}'),
                                    mainAxisAlignment: message.isMine
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (message.isMine && message.readAt == null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text('1', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(message.text, style: TextStyle(color: textColor)),
                                      ),
                                      if (!_isActive && !message.isMine && message.readAt == null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text('1', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // removed duplicate _ChatMessage class
}
