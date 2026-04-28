import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/features/messages/data/partner_profile_repository.dart';
import 'package:nearo_app/shared/notification_utils.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/profanity_mask.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/core/auth/auth_repository.dart';
import 'package:nearo_app/features/matching_board/profile_detail_sheet.dart';
import 'package:nearo_app/features/messages/data/ice_breaking_phrases.dart';
import 'package:nearo_app/features/messages/data/report_repository.dart';
import 'package:nearo_app/features/users/data/block_repository.dart';
import 'package:nearo_app/features/shared_chat/data/shared_chat_repository.dart';
import 'package:nearo_app/features/shared_chat/screens/shared_chat_compose_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class _ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final bool isSystem;
  final bool isPending;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String senderId;

  _ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.senderId,
    this.isSystem = false,
    this.isPending = false,
    this.readAt,
    this.createdAt,
  });
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  static const _reportReasons = [
    {'value': 'spam', 'label': '스팸/도배'},
    {'value': 'harassment', 'label': '괴롭힘/혐오'},
    {'value': 'impersonation', 'label': '사칭'},
    {'value': 'sexual', 'label': '성적 불쾌감'},
    {'value': 'scam', 'label': '사기'},
    {'value': 'other', 'label': '기타'},
  ];

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  bool _isMuted = false;
  final _authRepository = AuthRepository();
  final _tokenStorage = TokenStorage();
  Future<void> _toggleMute() async {
    if (_roomId == null) return;
    final newMute = !_isMuted;
    try {
      await _repository.setChatRoomMute(roomId: _roomId!, muted: newMute);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 설정에 실패했어요. 다시 시도해 주세요.')),
        );
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_mute_${_roomId!}';
    await prefs.setBool(key, newMute);
    if (!mounted) return;
    setState(() {
      _isMuted = newMute;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isMuted ? '채팅방 알림을 껐습니다' : '채팅방 알림을 켰습니다')),
    );
  }

  Future<void> _loadMuteStatus() async {
    if (_roomId == null) return;
    try {
      final room = await _repository.getRoom(roomId: _roomId!);
      final muted = room['muted'] == true;
      if (mounted) setState(() => _isMuted = muted);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chat_mute_${_roomId!}', muted);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final muted = prefs.getBool('chat_mute_${_roomId!}') ?? false;
      if (mounted) setState(() => _isMuted = muted);
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    final dt = dateTime ?? DateTime.now();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  DateTime? _parseServerDateTime(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  IO.Socket? _socket;
  String? _myUserId;
  final _partnerProfileRepository = PartnerProfileRepository();
  final _repository = ChatRepository();
  final _matchingRepository = MatchingRepository();
  final _reportRepository = ReportRepository();
  final _blockRepository = BlockRepository();
  final _sharedChatRepository = SharedChatRepository();
  final _controller = TextEditingController();
  bool _isReconnecting = false;
  final Map<String, Map<String, dynamic>> _sharedChatRequestDetails = {};
  final Set<String> _sharedChatRequestLoadingIds = {};
  String? _partnerId;
  final List<_ChatMessage> _messages = [];
  bool _loading = true;
  String _title = '대화';
  String? _roomId;
  bool _isActive = true;
  bool _isProfileRevealed = false;
  String? _partnerConsentStatus; // 'yes' | 'pending' | 'no' - 상대방?숈쓽 ?щ?
  bool _partnerInRoom = false; // ?곷?媛 ??梨꾪똿諛??붾㈃???덈뒗吏(?쒕쾭 presence)
  String? _partnerPhotoStorageKey;
  String? _partnerNickname;
  String? _partnerAvatarSeed;
  String? _partnerAvatarOptions;
  Map<String, dynamic>? _partnerProfile;
  String? _matchId;

  final ScrollController _scrollController = ScrollController();

  void _scheduleMessageSync() {
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted || _roomId == null) return;
      _repository.clearRoomCache(_roomId!);
      await _loadMessages();
      if (!mounted) return;
      _sendReadReceipts();
      _scrollToBottom();
    });
  }

  void _appendOrMergeIncomingMessage(_ChatMessage incoming) {
    final existingIndex =
        _messages.indexWhere((message) => message.id == incoming.id);
    if (existingIndex >= 0) {
      _messages[existingIndex] = incoming;
      return;
    }

    if (incoming.isMine) {
      final pendingIndex = _messages.indexWhere(
        (message) =>
            message.isMine &&
            message.isPending &&
            message.text == incoming.text,
      );
      if (pendingIndex >= 0) {
        _messages[pendingIndex] = incoming;
        return;
      }
    }

    _messages.add(incoming);
  }

  /// 梨꾪똿諛⑹뿉???닿? 吏곸젒 ??踰덉씠?쇰룄 硫붿떆吏瑜?蹂대깉?쇰㈃ ?꾩씠?ㅻ툕?덉씠而?臾멸뎄 ?④?
  bool get _shouldHideIceBreakers => _messages.any((m) => m.isMine);

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
      // 紐⑸줉?먯꽌 ?꾨떖???꾨줈???곗씠?곕줈 利됱떆 ?쒖떆 (getRoom ?묐떟 ?꾩뿉??紐⑸줉怨??숈씪?섍쾶)
      final passedPhotoKey = args['partnerPhotoStorageKey']?.toString();
      if (passedPhotoKey != null && passedPhotoKey.trim().isNotEmpty) {
        _partnerPhotoStorageKey = passedPhotoKey.trim();
      }
      final passedSeed = args['partnerAvatarSeed']?.toString();
      if (passedSeed != null && passedSeed.trim().isNotEmpty) {
        _partnerAvatarSeed = passedSeed.trim();
      }
      final passedOpts = args['partnerAvatarOptions']?.toString();
      if (passedOpts != null && passedOpts.trim().isNotEmpty) {
        _partnerAvatarOptions = passedOpts.trim();
      }
    }
    if (_roomId != null) {
      _fetchMyUserIdAndInitSocketAndLoadMessages();
      _loadMuteStatus();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMyUserIdAndInitSocketAndLoadMessages() async {
    try {
      final profile = await _authRepository.getProfile();
      final userId = profile['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        _myUserId = userId;
        await _initSocket();
        await _loadMessages();
        _sendReadReceipts();
        _scrollToBottom();
      } else {
        _myUserId = null;
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch user profile/init socket: $e');
      _myUserId = null;
      setState(() => _loading = false);
    }
  }

  /// getRoom ?묐떟??messageReadAts濡?'1' 媛깆떊 (listMessages ???媛踰쇱슫 getRoom ?ъ슜)
  void _disposeSocketConnection({bool emitOutRoom = false}) {
    final socket = _socket;
    if (socket == null) return;
    if (emitOutRoom && socket.connected && _roomId != null) {
      socket.emit('outRoom', {'roomId': _roomId});
    }
    socket.dispose();
    socket.destroy();
    _socket = null;
  }

  Future<void> _restoreRoomConnection() async {
    if (!mounted || _roomId == null || _myUserId == null || _isReconnecting) {
      return;
    }
    _isReconnecting = true;
    try {
      final socket = _socket;
      if (socket == null || !socket.connected) {
        _disposeSocketConnection();
        await _initSocket();
      } else {
        socket.emit('joinRoom', {'roomId': _roomId});
      }
      await _loadMessages();
      await _syncReadAt();
      if (!mounted) return;
      _sendReadReceipts();
      _scrollToBottom();
    } catch (e) {
      debugPrint('[restoreRoomConnection] failed: $e');
    } finally {
      _isReconnecting = false;
    }
  }

  void _applyMessageReadAts(List<dynamic>? messageReadAts) {
    if (messageReadAts == null || messageReadAts.isEmpty || !mounted) return;
    final serverReadAt = <String, DateTime>{};
    for (final m in messageReadAts) {
      final id = m['id']?.toString();
      final readAt = m['readAt'] != null
          ? _parseServerDateTime(m['readAt'])
          : null;
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
            createdAt: msg.createdAt,
          );
        }
      }
    });
  }

  /// 梨꾪똿諛⑹뿉 ?덈뒗 ?숈븞 getRoom?쇰줈 readAt 媛깆떊 + 매칭 취소 ??isActive 諛섏쁺
  Future<void> _syncReadAt() async {
    if (_roomId == null || !mounted) return;
    try {
      final room = await _repository.getRoom(roomId: _roomId!);
      if (!mounted) return;
      // ?쒕쾭???뚮┝ ???곹깭 ?숆린??
      if (room['muted'] != null && (room['muted'] == true) != _isMuted) {
        setState(() => _isMuted = room['muted'] == true);
      }
      // 매칭 취소 ???쒕쾭?먯꽌 isActive=false濡??ㅻ?濡?二쇨린?곸쑝濡?諛섏쁺???낅젰 留됯린
      final isActiveFromServer = room['isActive'] == true;
      final partnerInRoom =
          room['partnerOnline'] == true || room['partnerInRoom'] == true;
      if (!isActiveFromServer && _isActive) {
        setState(() => _isActive = false);
      }
      if (partnerInRoom != _partnerInRoom) {
        setState(() => _partnerInRoom = partnerInRoom);
      }
      final list = room['messageReadAts'];
      if (list is List) _applyMessageReadAts(list);
    } catch (e) {
      debugPrint('[syncReadAt] failed: $e');
    }
  }

  // ?쎌? ?딆? 硫붿떆吏??????뚯폆?쇰줈 ?쎌쓬 ?대깽???꾩넚
  void _sendReadReceipts() {
    if (_socket == null ||
        !_socket!.connected ||
        _roomId == null ||
        _myUserId == null) return;
    for (final msg in _messages) {
      if (!msg.isMine && msg.readAt == null) {
        final payload = {
          'roomId': _roomId,
          'messageId': msg.id,
          'userId': _myUserId,
          'readAt': DateTime.now().toIso8601String(),
        };
        print('[?뚯폆 ?쎌쓬 emit] $payload');
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
            print(
                '[isMine ?먮퀎] senderId=$senderId, _myUserId=$_myUserId, isMine=$isMine, text=${m['content']}');
            return _ChatMessage(
              id: m['id']?.toString() ?? '',
              text: m['content']?.toString() ?? '',
              isMine: isMine,
              senderId: senderId ?? '',
              isSystem: m['isSystem'] == true || _isSystemContent(m['content']?.toString() ?? ''),
              readAt: m['readAt'] != null
                  ? _parseServerDateTime(m['readAt'])
                  : null,
              createdAt: m['createdAt'] != null
                  ? _parseServerDateTime(m['createdAt'])
                  : null,
            );
          }));
        _loading = false;
      });
      // ?쎌? ?딆? ?곷? 硫붿떆吏 ?쎌쓬 泥섎━
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (!msg.isMine && msg.readAt == null) {
          await _repository.readMessage(roomId: _roomId!, messageId: msg.id);
          final now = DateTime.now();
          // ?쎌쓬 泥섎━ ??readAt??利됱떆 媛깆떊?섏뿬 UI?먯꽌 諭껋? ?щ씪吏寃?
          setState(() {
            _messages[i] = _ChatMessage(
              id: msg.id,
              text: msg.text,
              isMine: msg.isMine,
              senderId: msg.senderId,
              isSystem: msg.isSystem,
              readAt: now,
              createdAt: msg.createdAt,
            );
          });
          // ?뚯폆?쇰줈 ?쎌쓬 ?대깽?몃룄 媛숈씠 ?꾩넚
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
      // ?뚮┝/諭껋? ?대━??
      await clearAllNotifications();
      unawaited(_prefetchSharedChatRequestDetails());
      await _loadRoomState();
    } catch (e) {
      debugPrint('[loadMessages] failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _initSocket() async {
    if (_roomId == null || _myUserId == null || _myUserId!.isEmpty) return;
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    _disposeSocketConnection();
    final completer = Completer<void>();
    print('[?뚯폆 ?곌껐 ?쒕룄] roomId=$_roomId, myUserId=$_myUserId');
    _socket = IO.io(
      '${AppConfig.baseUrl}/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'accessToken': accessToken})
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {
      print('[?뚯폆 ?곌껐 ?깃났]');
      _socket!.emit('joinRoom', {'roomId': _roomId});
      if (!completer.isCompleted) completer.complete();
      print('[?뚯폆 joinRoom emit] roomId=$_roomId');
    });
    _socket!.onDisconnect((reason) {
      debugPrint('[chat socket disconnected] $reason');
    });
    _socket!.onConnectError((error) {
      debugPrint('[chat socket connect error] $error');
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'connect error');
      }
    });
    _socket!.onError((error) {
      debugPrint('[chat socket error] $error');
    });
    _socket!.on('newMessage', (data) {
      print('[?뚯폆 newMessage ?몃뱾???깅줉?? data=$data');
      if (!mounted) return;
      final messageId = data['id']?.toString() ?? '';
      final isMine = data['senderId']?.toString() == _myUserId;
      setState(() {
        _appendOrMergeIncomingMessage(_ChatMessage(
          id: messageId,
          text: data['content'] ?? '',
          isMine: isMine,
          senderId: data['senderId']?.toString() ?? '',
          isSystem: data['isSystem'] == true || _isSystemContent(data['content']?.toString() ?? ''),
          readAt: data['readAt'] != null
              ? _parseServerDateTime(data['readAt'])
              : null,
          createdAt: data['createdAt'] != null
              ? _parseServerDateTime(data['createdAt'])
              : null,
        ));
      });
      _scrollToBottom();
      // ?곷?媛 蹂대궦 硫붿떆吏硫??쎌쓬 泥섎━ + ?뚯폆 ?쎌쓬 ?꾩넚 ??蹂대궦 ?щ엺 ?붾㈃?먯꽌 "1" ?щ씪吏?
      if (!isMine &&
          messageId.isNotEmpty &&
          _roomId != null &&
          _myUserId != null) {
        final now = DateTime.now();
        _repository.readMessage(roomId: _roomId!, messageId: messageId);
        if (_socket != null && _socket!.connected) {
          _socket!.emit('read', {
            'roomId': _roomId,
            'messageId': messageId,
            'userId': _myUserId,
            'readAt': now.toIso8601String(),
          });
        }
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx >= 0) {
            final msg = _messages[idx];
            _messages[idx] = _ChatMessage(
              id: msg.id,
              text: msg.text,
              isMine: msg.isMine,
              senderId: msg.senderId,
              isSystem: msg.isSystem,
              readAt: now,
              createdAt: msg.createdAt,
            );
          }
        });
      }
    });
    print('[?뚯폆 read ?몃뱾???깅줉??');
    // ?쎌쓬 ?대깽??泥섎━: ?대떦 硫붿떆吏??readAt 媛깆떊
    _socket!.on('read', (data) {
      debugPrint(
          '[read ?대깽???섏떊] messageId=${data['messageId']}, userId=${data['userId']}, ??硫붿떆吏 ??${_messages.where((m) => m.isMine && m.readAt == null).length}');
      if (!mounted) return;
      final String? messageId = data['messageId']?.toString();
      final String? userId = data['userId']?.toString();
      final DateTime? readAt = data['readAt'] != null
          ? _parseServerDateTime(data['readAt'])
          : null;
      if (messageId == null || userId == null || readAt == null) return;
      // ?닿? 蹂대궦 硫붿떆吏媛 ?곷??먭쾶 ?쏀삍???뚮쭔 媛깆떊 (userId = ?쎌? ?щ엺 = ?곷?)
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
              createdAt: msg.createdAt,
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
    print('[?뚯폆 connect ?몄텧??');
    await completer.future.timeout(const Duration(seconds: 10));
  }

  Future<void> _loadRoomState() async {
    if (_roomId == null) return;
    try {
      final room = await _repository.getRoom(roomId: _roomId!);
      if (!mounted) return;
      _isActive = room['isActive'] == true;
      _isProfileRevealed = room['isProfileRevealed'] == true;
      _partnerInRoom =
          room['partnerOnline'] == true || room['partnerInRoom'] == true;
      _partnerConsentStatus = room['partnerConsentStatus']?.toString();
      final roomPhotoKey = room['partnerPhotoStorageKey']?.toString();
      if (roomPhotoKey != null && roomPhotoKey.trim().isNotEmpty) {
        _partnerPhotoStorageKey = roomPhotoKey.trim();
      }
      _partnerNickname = room['partnerNickname']?.toString();
      // API에서 닉네임을 받아오면 화면 타이틀도 업데이트 (알림 딥링크 진입 시 빈값 보정)
      if (_partnerNickname != null && _partnerNickname!.isNotEmpty) {
        _title = _partnerNickname!;
      }
      final roomSeed = room['partnerAvatarSeed']?.toString();
      if (roomSeed != null && roomSeed.trim().isNotEmpty) {
        _partnerAvatarSeed = roomSeed.trim();
      }
      final roomOpts = room['partnerAvatarOptions']?.toString();
      if (roomOpts != null && roomOpts.trim().isNotEmpty) {
        _partnerAvatarOptions = roomOpts.trim();
      }
      _partnerId = room['partnerId']?.toString();
      _matchId = room['matchId']?.toString();
      // room??partnerPhotoStorageKey ?놁쑝硫?room.partner ?먮뒗 room.partnerUser?먯꽌 異붿텧 (諛깆뿏??援ъ“ ?ㅼ뼇?????
      if ((_partnerPhotoStorageKey == null ||
          _partnerPhotoStorageKey!.trim().isEmpty)) {
        final partner = room['partner'] as Map<String, dynamic>?;
        final partnerUser = room['partnerUser'] as Map<String, dynamic>?;
        final p = partner ?? partnerUser;
        if (p != null) {
          final displayType = (p['boardDisplayType'] ??
                  (p['user'] as Map?)?['boardDisplayType'])
              ?.toString()
              .trim()
              .toLowerCase();
          if (displayType == 'photo') {
            dynamic photos = (p['user'] as Map?)?['photos'] ?? p['photos'];
            if (photos is List && photos.isNotEmpty && photos[0] is Map) {
              final key = (photos[0] as Map)['storageKey']?.toString();
              if (key != null && key.isNotEmpty) _partnerPhotoStorageKey = key;
            } else {
              final singleKey = p['photoStorageKey'] ??
                  p['partnerPhotoStorageKey'] ??
                  (p['user'] as Map?)?['photoStorageKey'];
              if (singleKey != null && singleKey.toString().trim().isNotEmpty)
                _partnerPhotoStorageKey = singleKey.toString().trim();
            }
          }
        }
      }
      final list = room['messageReadAts'];
      if (list is List) _applyMessageReadAts(list);
      // ?숈쓽 ?щ?? 愿怨꾩뾾???곷? ?꾨줈??濡쒕뱶 (?꾨컮? ????諛붾줈 ?뺣낫 蹂닿린)
      if (_matchId != null) {
        try {
          final profile = await _partnerProfileRepository.getPartnerProfile(
              matchId: _matchId!);
          if (!mounted) return;
          setState(() {
            _partnerProfile = profile;
            // room???곷? ?ъ쭊 ?ㅺ? ?놁쑝硫??꾨줈?꾩뿉??梨꾩? (?ъ쭊 ?좏깮 ??梨꾪똿?먯꽌???ъ쭊 ?몄텧)
            if ((_partnerPhotoStorageKey == null ||
                _partnerPhotoStorageKey!.trim().isEmpty)) {
              _partnerPhotoStorageKey = _photoStorageKeyFromProfile(profile);
            }
          });
        } catch (_) {
          if (mounted) {
            // API ?ㅽ뙣 ??room.partner媛 ?덉쑝硫?洹멸구濡?理쒖냼 ?꾨줈??援ъ꽦 (?ъ쭊 ?쒖떆??
            final partner = room['partner'] as Map<String, dynamic>?;
            final partnerUser = room['partnerUser'] as Map<String, dynamic>?;
            final p = partner ?? partnerUser;
            if (p != null) {
              final normalized = _normalizePartnerMap(p);
              setState(() {
                _partnerProfile = normalized;
                if ((_partnerPhotoStorageKey == null ||
                    _partnerPhotoStorageKey!.trim().isEmpty)) {
                  _partnerPhotoStorageKey =
                      _photoStorageKeyFromProfile(normalized);
                }
              });
            } else {
              setState(() => _partnerProfile = null);
            }
          }
        }
      } else {
        // matchId ?놁뼱??room.partner媛 ?덉쑝硫??꾨줈???ъ쭊 ?쒖떆?⑹쑝濡??ъ슜
        final partner = room['partner'] as Map<String, dynamic>?;
        final partnerUser = room['partnerUser'] as Map<String, dynamic>?;
        final p = partner ?? partnerUser;
        setState(() {
          _partnerProfile = p != null ? _normalizePartnerMap(p) : null;
          if (p != null &&
              (_partnerPhotoStorageKey == null ||
                  _partnerPhotoStorageKey!.trim().isEmpty)) {
            _partnerPhotoStorageKey =
                _photoStorageKeyFromProfile(_partnerProfile);
          }
        });
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
    final tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _messages.add(_ChatMessage(
        id: tempId,
        text: text,
        isMine: true,
        isPending: true,
        senderId: _myUserId ?? '',
        createdAt: DateTime.now(),
      ));
    });
    _scrollToBottom();
    try {
      final response =
          await _repository.sendMessage(roomId: _roomId!, content: text);
      final message = response['message'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (message != null) {
        setState(() {
          _appendOrMergeIncomingMessage(_ChatMessage(
            id: message['id']?.toString() ?? tempId,
            text: message['content']?.toString() ?? text,
            isMine: true,
            senderId: message['senderId']?.toString() ?? (_myUserId ?? ''),
            createdAt: message['createdAt'] != null
                ? _parseServerDateTime(message['createdAt'])
                : DateTime.now(),
          ));
        });
      } else {
        _scheduleMessageSync();
      }
    } catch (e) {
      debugPrint('[sendMessage] failed: $e');
      if (!mounted) return;
      setState(() {
        _appendOrMergeIncomingMessage(_ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '메시지 전송 실패',
          isMine: false,
          senderId: _myUserId ?? '',
          createdAt: DateTime.now(),
        ));
      });
      _scheduleMessageSync();
    }
  }

  Future<void> _cancelMatch() async {
    final matchId = _matchId;
    if (matchId == null || matchId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 채팅방의 매칭 정보를 찾을 수 없습니다.')),
      );
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 취소'),
        content: const Text(
          '정말로 취소하시겠어요? 취소하면 상대방과의 대화가 비활성화됩니다.',
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
      await _matchingRepository.cancelMatch(matchId: matchId);
      if (!mounted) return;
      setState(() => _isActive = false);
      _controller.clear();
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[cancelMatch] failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭 취소에 실패했습니다.')),
      );
    }
  }

  Future<void> _openBlockConfirm() async {
    if (_partnerId == null) return;
    final partnerId = _partnerId!;
    final partnerName = _title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Text(
          '$partnerName님을 차단하시겠어요? 차단하면 대화가 비활성화되고 목록에서 사라질 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('차단', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _blockRepository.blockUser(partnerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단했습니다')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      String msg = '차단에 실패했어요';
      if (e is DioException && e.response?.data is Map) {
        final d = e.response!.data as Map<String, dynamic>;
        if (d['message'] != null) msg = d['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreRoomConnection());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final socket = _socket;
      if (socket != null && socket.connected && _roomId != null) {
        socket.emit('outRoom', {'roomId': _roomId});
      }
    }
  }

  @override
  void dispose() {
    _disposeSocketConnection(emitOutRoom: true);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // AppDesign: 硫붿떆吏 ?꾩넚/?섏떊 ?쒓컖 (createdAt ?곗꽑)
  String _messageTime(_ChatMessage message) {
    final dt = message.createdAt ?? DateTime.now();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? '오후' : '오전';
    return '$ampm ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _insertIceBreaker(String phrase) {
    _controller.text = phrase;
    _controller.selection = TextSelection.collapsed(offset: phrase.length);
    setState(() {});
  }

  Widget _buildEmptyStateWithIceBreakers(
      BuildContext context, bool dark, Color timeColor) {
    if (IceBreakingPhrases.phrases.isEmpty) {
      return Center(
        child: Text(
          '첫 메시지를 보내 보세요',
          style: TextStyle(color: timeColor, fontSize: 15),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            '첫 메시지를 보내 보세요',
            style: TextStyle(color: timeColor, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Text(
            '어색한 분위기가 걱정된다면',
            style: TextStyle(
              color: timeColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: IceBreakingPhrases.phrases.map((phrase) {
              return ActionChip(
                label: Text(phrase, style: const TextStyle(fontSize: 12)),
                onPressed: () => _insertIceBreaker(phrase),
                backgroundColor: dark ? Colors.grey.shade800 : Colors.white,
                side: BorderSide(
                    color: dark ? Colors.grey.shade600 : Colors.grey.shade300),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIceBreakerChipsRow(bool dark, Color hintColor) {
    if (IceBreakingPhrases.phrases.isEmpty) return const SizedBox.shrink();
    const maxChips = 6;
    final list = IceBreakingPhrases.phrases.take(maxChips).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final phrase = list[index];
          return ActionChip(
            label: Text(phrase, style: const TextStyle(fontSize: 11)),
            onPressed: () => _insertIceBreaker(phrase),
            backgroundColor: dark ? Colors.grey.shade800 : Colors.white,
            side: BorderSide(
                color: dark ? Colors.grey.shade600 : Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final messageBg = dark ? const Color(0xFF1F2937) : Colors.grey.shade50;
    final bubbleOther = dark ? const Color(0xFF374151) : Colors.white;
    final bubbleMine = theme.colorScheme.primary;
    final inputBg = dark ? const Color(0xFF374151) : Colors.grey.shade100;
    final borderColor = dark ? Colors.grey.shade700 : Colors.grey.shade200;
    final hintColor = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final timeColor = dark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // AppDesign: 濡쒖쫰 洹몃씪?곗씠???ㅻ뜑, ?ㅻ줈媛湲? ?꾨컮?+?대쫫+?⑤씪?? ?붾낫湲?
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: ThemeController.getHeaderGradient(),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(LucideIcons.arrowLeft,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _openPartnerProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: _buildPartnerAvatar(context),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _partnerInRoom ? '온라인' : '오프라인',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.flag,
                        color: Colors.white, size: 22),
                    tooltip: '신고',
                    onPressed: _openReportSheet,
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.ban, color: Colors.white, size: 22),
                    tooltip: '차단',
                    onPressed: _partnerId != null ? _openBlockConfirm : null,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white, size: 24),
                    color: theme.colorScheme.surface,
                    onSelected: (value) {
                      if (value == 'cancel') _cancelMatch();
                      if (value == 'mute') _toggleMute();
                      if (value == 'share') _openSharedChatComposer();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'cancel', child: Text('매칭 취소')),
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('대화 구간 공유'),
                      ),
                      PopupMenuItem(
                        value: 'mute',
                        child: Text(_isMuted ? '채팅방 알림 켜기' : '채팅방 알림 끄기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isActive)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                child: Text(
                  '매칭이 취소되어 비활성화되었어요',
                  style: TextStyle(
                      color:
                          dark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildEmptyStateWithIceBreakers(
                          context, dark, timeColor)
                      : ListView.separated(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.only(
                              left: 20, right: 12, top: 16, bottom: 16),
                          itemCount: _messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final message =
                                _messages[_messages.length - 1 - index];
                            final messageDate = message.createdAt ??
                                message.readAt ??
                                DateTime.now();
                            DateTime? prevDate;
                            if (index < _messages.length - 1) {
                              final prev =
                                  _messages[_messages.length - 1 - (index + 1)];
                              prevDate = prev.createdAt ??
                                  prev.readAt ??
                                  DateTime.now();
                            }
                            final isNewDate = prevDate == null ||
                                messageDate.year != prevDate.year ||
                                messageDate.month != prevDate.month ||
                                messageDate.day != prevDate.day;
                            final dateStr =
                                '${messageDate.year}년 ${messageDate.month}월 ${messageDate.day}일';
                            final List<Widget> children = [];
                            if (isNewDate) {
                              children.add(
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: TextStyle(
                                            fontSize: 12, color: timeColor),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (message.isSystem) {
                              final sharedChatRequest =
                                  _parseSharedChatRequestMessage(message.text);
                              children.add(
                                sharedChatRequest != null
                                    ? _buildSharedChatRequestCard(
                                        context,
                                        sharedChatRequest,
                                        dark,
                                      )
                                    : Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: dark
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _displaySystemText(message.text),
                                            style: TextStyle(
                                                color: dark
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade700),
                                          ),
                                        ),
                                      ),
                              );
                            } else {
                              children.add(
                                Row(
                                  key: ValueKey(
                                      '${message.id}_${message.readAt?.millisecondsSinceEpoch ?? 0}'),
                                  mainAxisAlignment: message.isMine
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (message.isMine)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 6, bottom: 2),
                                        child: message.readAt == null
                                            ? Text(
                                                '안읽음',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: dark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade600,
                                                ),
                                              )
                                            : Icon(
                                                LucideIcons.check,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                      ),
                                    if (!message.isMine) ...[
                                      _buildPartnerAvatar(context),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: message.isMine
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: message.isMine
                                            ? [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 2),
                                                  child: Text(
                                                    _messageTime(message),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: timeColor),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: bubbleMine,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        topLeft:
                                                            Radius.circular(16),
                                                        topRight:
                                                            Radius.circular(16),
                                                        bottomLeft:
                                                            Radius.circular(16),
                                                        bottomRight:
                                                            Radius.circular(4),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.06),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      maskProfanity(message.text),
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: bubbleOther,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft: const Radius
                                                            .circular(16),
                                                        topRight: const Radius
                                                            .circular(16),
                                                        bottomLeft: const Radius
                                                            .circular(4),
                                                        bottomRight:
                                                            Radius.circular(16),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.06),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      maskProfanity(message.text),
                                                      style: TextStyle(
                                                        color: dark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF111827),
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 2),
                                                  child: Text(
                                                    _messageTime(message),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: timeColor),
                                                  ),
                                                ),
                                              ],
                                      ),
                                    ),
                                    if (!message.isMine &&
                                        message.readAt == null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text('1',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children,
                            );
                          },
                        ),
            ),
            if (_isActive &&
                _messages.isNotEmpty &&
                _messages.length <= 3 &&
                !_shouldHideIceBreakers)
              _buildIceBreakerChipsRow(dark, hintColor),
            if (_isActive)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF374151) : Colors.white,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 96),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: '메시지를 입력해 주세요...',
                            hintStyle:
                                TextStyle(color: hintColor, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        final hasText = value.text.trim().isNotEmpty;
                        return Material(
                          color: hasText
                              ? bubbleMine
                              : (dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(999),
                          elevation: 2,
                          shadowColor: Colors.black26,
                          child: InkWell(
                            onTap: hasText ? _sendMessage : null,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                LucideIcons.send,
                                size: 22,
                                color: hasText
                                    ? Colors.white
                                    : (dark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600),
                              ),
                            ),
                          ),
                        );
                      },
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

  bool _isSystemContent(String text) {
    return text.startsWith('[system]') || text.startsWith('[shared_chat_request]');
  }

  String _displaySystemText(String text) {
    if (text.startsWith('[system]')) {
      return text.replaceFirst('[system]', '').trim();
    }
    return text;
  }

  Map<String, dynamic>? _parseSharedChatRequestMessage(String text) {
    const prefix = '[shared_chat_request]';
    if (!text.startsWith(prefix)) return null;
    final payload = text.substring(prefix.length).trim();
    if (payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _prefetchSharedChatRequestDetails() async {
    final ids = _messages
        .map((message) => _parseSharedChatRequestMessage(message.text))
        .whereType<Map<String, dynamic>>()
        .map((payload) => payload['sharedChatPostId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final id in ids) {
      await _ensureSharedChatRequestDetailLoaded(id);
    }
  }

  Future<void> _ensureSharedChatRequestDetailLoaded(String sharedChatPostId) async {
    if (_sharedChatRequestDetails.containsKey(sharedChatPostId) ||
        _sharedChatRequestLoadingIds.contains(sharedChatPostId)) {
      return;
    }
    _sharedChatRequestLoadingIds.add(sharedChatPostId);
    try {
      final detail = await _sharedChatRepository.getDetail(sharedChatPostId);
      if (!mounted) return;
      setState(() {
        _sharedChatRequestDetails[sharedChatPostId] = detail;
      });
    } catch (_) {
      // The card can still render with payload-only fallback text.
    } finally {
      _sharedChatRequestLoadingIds.remove(sharedChatPostId);
    }
  }

  String _sharedChatRequestStatusLabel(
    Map<String, dynamic> payload,
    Map<String, dynamic>? detail,
  ) {
    final status = detail?['status']?.toString();
    final isRequester = payload['requesterUserId']?.toString() == _myUserId;
    final myConsent = detail?['myConsent']?.toString();
    final partnerConsent = detail?['partnerConsent']?.toString();

    if (status == 'rejected') {
      if (isRequester) {
        return '상대방이 거절했어요.';
      }
      return myConsent == 'no' ? '공유 요청을 거절했어요.' : '상대방이 거절했어요.';
    }
    if (status == 'published') {
      return '동의가 완료되어 커뮤니티에 게시됐어요.';
    }
    if (partnerConsent == 'yes' && isRequester) {
      return '상대방이 동의했어요.';
    }
    if (myConsent == 'yes' && !isRequester) {
      return '동의 완료. 게시를 준비 중이에요.';
    }
    return isRequester ? '상대방의 응답을 기다리는 중이에요.' : '채팅 구간을 커뮤니티 후기 글로 올리기 전에 동의를 받는 요청입니다.';
  }

  String _sharedChatRequestButtonLabel(
    Map<String, dynamic> payload,
    Map<String, dynamic>? detail,
  ) {
    final status = detail?['status']?.toString();
    final isRequester = payload['requesterUserId']?.toString() == _myUserId;
    final myConsent = detail?['myConsent']?.toString();

    if (status == 'rejected') {
      return isRequester ? '거절됨' : (myConsent == 'no' ? '거절 완료' : '결과 보기');
    }
    if (status == 'published') {
      return '게시 완료';
    }
    if (myConsent == 'pending') {
      return '내용 보고 결정하기';
    }
    return isRequester ? '응답 기다리는 중' : '상세 보기';
  }

  Future<void> _openSharedChatRequestSheet(String sharedChatPostId) async {
    Map<String, dynamic> detail;
    try {
      detail = await _sharedChatRepository.getDetail(sharedChatPostId);
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
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        final messages = (detail['messages'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final myConsent = detail['myConsent']?.toString();
        final canDecide = myConsent == 'pending' && detail['status'] == 'pending_consent';

        Widget bubble(bool isMine, String content) {
          return Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMine) ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white10 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.userRound,
                    size: 14,
                    color: dark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? theme.colorScheme.primary : (dark ? const Color(0xFF374151) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isMine ? Colors.white : (dark ? Colors.white : const Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message['senderRole']?.toString() == 'A';
                        return bubble(isMine, message['content']?.toString() ?? '');
                      },
                    ),
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
                        detail['status'] == 'published'
                            ? '이미 커뮤니티에 올라갔어요'
                            : myConsent == 'yes'
                                ? '내 동의는 이미 완료됐어요'
                                : '확인',
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
        final updatedDetail = await _sharedChatRepository.decideConsent(sharedChatPostId, action!);
        if (!mounted) return;
        setState(() {
          _sharedChatRequestDetails[sharedChatPostId] = updatedDetail;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'yes' ? '공유 요청에 동의했어요.' : '공유 요청을 거절했어요.')),
        );
        await _loadMessages();
      } on DioException catch (e) {
        if (!mounted) return;
        final message = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : '동의 상태를 저장하지 못했어요.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Widget _buildSharedChatRequestCard(
    BuildContext context,
    Map<String, dynamic> payload,
    bool dark,
  ) {
    final sharedChatPostId = payload['sharedChatPostId']?.toString();
    if (sharedChatPostId != null && sharedChatPostId.isNotEmpty) {
      unawaited(_ensureSharedChatRequestDetailLoaded(sharedChatPostId));
    }
    final detail = sharedChatPostId == null ? null : _sharedChatRequestDetails[sharedChatPostId];
    final title = payload['title']?.toString() ?? '대화 공유 요청';
    final status = detail?['status']?.toString();
    final buttonLabel = _sharedChatRequestButtonLabel(payload, detail);
    final statusLabel = _sharedChatRequestStatusLabel(payload, detail);
    final statusTone = status == 'rejected'
        ? Colors.red
        : status == 'published'
            ? Colors.green
            : Colors.orange;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: ThemeController.getHeaderGradient(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.messagesSquare, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '대화 공유 요청',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (detail != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusTone.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status == 'rejected'
                                      ? '거절됨'
                                      : status == 'published'
                                          ? '게시됨'
                                          : '대기중',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusTone.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: dark ? Colors.grey.shade300 : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sharedChatPostId == null ? null : () => _openSharedChatRequestSheet(sharedChatPostId),
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _partnerAvatarRadius = 18;
  static final Set<String> _reportedMatchIds = {};

  Future<void> _openSharedChatComposer() async {
    if (_roomId == null) return;
    final shareableMessages = _messages
        .where((message) => !message.isSystem)
        .map((message) => {
              'id': message.id,
              'text': message.text,
              'isMine': message.isMine,
              'isSystem': message.isSystem,
              'createdAt': message.createdAt?.toIso8601String(),
            })
        .toList();
    if (shareableMessages.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 대화가 아직 부족해요.')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SharedChatComposeScreen(
          roomId: _roomId!,
          partnerName: _title,
          messages: shareableMessages,
        ),
      ),
    );
    if (result == true && mounted) {
      await _loadMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅방에 공유 요청을 보냈어요.')),
      );
    }
  }
  void _openReportSheet() async {
    if (_matchId == null) {
      await _loadRoomState();
      if (!mounted) return;
      if (_matchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('잠시 후 다시 시도해 주세요')),
        );
        return;
      }
    }
    final matchId = _matchId!;
    final partnerName = _title;
    final alreadyReported = _reportedMatchIds.contains(matchId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportSheetContent(
        matchId: matchId,
        partnerName: partnerName,
        reportRepository: _reportRepository,
        alreadyReported: alreadyReported,
        onSubmitted: () {
          _reportedMatchIds.add(matchId);
          Navigator.of(ctx).pop();
        },
        onError: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      ),
    );
  }

  Future<void> _openPartnerProfile() async {
    Future<Widget> avatarBuilder(Map<String, dynamic> profile) async {
      // ?꾨줈?꾩뿉???ъ쭊??怨⑤옄?쇰㈃ ?ъ쭊 ?곗꽑, ?놁쑝硫?梨꾪똿諛⑹뿉 ?곕뒗 _partnerPhotoStorageKey ?ъ슜
      String? photoUrl = _photoUrlFromProfile(profile);
      if ((photoUrl == null || photoUrl.isEmpty) &&
          _partnerPhotoStorageKey != null &&
          _partnerPhotoStorageKey!.trim().isNotEmpty) {
        photoUrl = photoUrlFromStorageKey(_partnerPhotoStorageKey);
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        return CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade300,
          child: ClipOval(
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) =>
                  Icon(LucideIcons.user, size: 40, color: Colors.grey.shade600),
            ),
          ),
        );
      }
      final seed = profile['avatarSeed']?.toString() ??
          (profile['user'] as Map?)?['avatarSeed']?.toString() ??
          profile['userId']?.toString() ??
          _partnerAvatarSeed;
      final raw = (profile['user'] as Map?)?['avatarOptions']?.toString() ??
          profile['avatarOptions']?.toString() ??
          _partnerAvatarOptions;
      Map<String, String> opts = {};
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>)
            opts = decoded
                .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        } catch (_) {}
      }
      if (seed != null && seed.isNotEmpty) {
        final url =
            diceBearAvatarUrl(seed, options: opts.isNotEmpty ? opts : null);
        return CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade300,
          child: ClipOval(
            child: SvgPicture.network(
              url,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              placeholderBuilder: (_) =>
                  Icon(LucideIcons.user, size: 40, color: Colors.grey.shade600),
            ),
          ),
        );
      }
      return CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade300,
          child: Icon(LucideIcons.user, size: 40, color: Colors.grey.shade600));
    }

    // room ?뺣낫留뚯쑝濡?理쒖냼 ?꾨줈??留?援ъ꽦 (API ?ㅽ뙣/ matchId ?놁쓣 ???ъ슜)
    Map<String, dynamic> _minimalProfileFromRoom() {
      final user = <String, dynamic>{
        'avatarSeed': _partnerAvatarSeed,
        'avatarOptions': _partnerAvatarOptions,
      };
      if (_partnerPhotoStorageKey != null &&
          _partnerPhotoStorageKey!.trim().isNotEmpty) {
        user['boardDisplayType'] = 'photo';
        user['photos'] = [
          {'storageKey': _partnerPhotoStorageKey}
        ];
      }
      return {
        'nickname': _partnerNickname ?? '상대방',
        'user': user,
        'partnerPhotoStorageKey': _partnerPhotoStorageKey,
        'avatarSeed': _partnerAvatarSeed,
        'avatarOptions': _partnerAvatarOptions,
      };
    }

    if (_partnerProfile != null) {
      final photoForEnlarge = photoUrlFromStorageKey(_partnerPhotoStorageKey);
      await showProfileDetailSheet(
        context,
        profile: _partnerProfile!,
        buildAvatar: (ctx, profile) => FutureBuilder<Widget>(
          future: avatarBuilder(profile),
          builder: (ctx, snap) =>
              snap.hasData ? snap.data! : const SizedBox.shrink(),
        ),
        hideMatchButton: true,
        overridePhotoUrlForEnlarge: photoForEnlarge,
      );
      return;
    }
    if (_matchId != null) {
      try {
        final profile = await _partnerProfileRepository.getPartnerProfile(
            matchId: _matchId!);
        if (!mounted) return;
        setState(() => _partnerProfile = profile);
        final photoForEnlarge =
            photoUrlFromStorageKey(_partnerPhotoStorageKey) ??
                _photoUrlFromProfile(profile);
        await showProfileDetailSheet(
          context,
          profile: profile,
          buildAvatar: (ctx, profile) => FutureBuilder<Widget>(
            future: avatarBuilder(profile),
            builder: (ctx, snap) =>
                snap.hasData ? snap.data! : const SizedBox.shrink(),
          ),
          hideMatchButton: true,
          overridePhotoUrlForEnlarge: photoForEnlarge,
        );
      } catch (_) {
        if (!mounted) return;
        // API ?ㅽ뙣 ??room ?뺣낫濡?理쒖냼 ?꾨줈???쒖떆
        final photoForEnlarge = photoUrlFromStorageKey(_partnerPhotoStorageKey);
        await showProfileDetailSheet(
          context,
          profile: _minimalProfileFromRoom(),
          buildAvatar: (ctx, profile) => FutureBuilder<Widget>(
            future: avatarBuilder(profile),
            builder: (ctx, snap) =>
                snap.hasData ? snap.data! : const SizedBox.shrink(),
          ),
          hideMatchButton: true,
          overridePhotoUrlForEnlarge: photoForEnlarge,
        );
      }
      return;
    }
    // matchId ?놁쓬 ??room ?뺣낫留뚯쑝濡??꾨줈???쒖떆
    final photoForEnlarge = photoUrlFromStorageKey(_partnerPhotoStorageKey);
    await showProfileDetailSheet(
      context,
      profile: _minimalProfileFromRoom(),
      buildAvatar: (ctx, profile) => FutureBuilder<Widget>(
        future: avatarBuilder(profile),
        builder: (ctx, snap) =>
            snap.hasData ? snap.data! : const SizedBox.shrink(),
      ),
      hideMatchButton: true,
      overridePhotoUrlForEnlarge: photoForEnlarge,
    );
  }

  /// room.partner / room.partnerUser瑜??꾨줈???뺤떇?쇰줈 蹂??(_photoUrlFromProfile ?깆뿉???ъ슜)
  Map<String, dynamic> _normalizePartnerMap(Map<String, dynamic> p) {
    final user = p['user'] as Map<String, dynamic>?;
    final flat = <String, dynamic>{
      'nickname': p['nickname'] ?? user?['nickname'] ?? '상대방',
      'avatarSeed':
          p['avatarSeed'] ?? user?['avatarSeed'] ?? _partnerAvatarSeed,
      'avatarOptions':
          p['avatarOptions'] ?? user?['avatarOptions'] ?? _partnerAvatarOptions,
      'boardDisplayType': p['boardDisplayType'] ?? user?['boardDisplayType'],
      'photos': p['photos'] ?? user?['photos'],
      'photoStorageKey': p['photoStorageKey'] ??
          p['partnerPhotoStorageKey'] ??
          user?['photoStorageKey'],
    };
    return {
      'nickname': flat['nickname'],
      'user': user ?? flat,
      'partner': null,
      'boardDisplayType': flat['boardDisplayType'],
      'photos': flat['photos'],
      'partnerPhotoStorageKey': flat['photoStorageKey'],
    };
  }

  /// ?꾨줈?꾩뿉???ъ쭊(boardDisplayType:'photo')????泥?踰덉㎏ ?ъ쭊??storageKey 異붿텧 (room???ㅺ? ?놁쓣 ??梨꾩???
  String? _photoStorageKeyFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final user = profile['user'] as Map<String, dynamic>?;
    final partner = profile['partner'] as Map<String, dynamic>?;
    final displayType = (profile['boardDisplayType'] ??
            user?['boardDisplayType'] ??
            partner?['boardDisplayType'])
        ?.toString()
        .trim()
        .toLowerCase();
    // displayType??'photo'?닿굅?? ?녿뒗??photos媛 ?덉쑝硫? getPartnerProfile flat ?묐떟) ?ъ쭊 ?ъ슜
    if (displayType == 'avatar') return null;
    final singleKey = profile['partnerPhotoStorageKey'] ??
        profile['photoStorageKey'] ??
        user?['photoStorageKey'];
    if (singleKey != null) {
      final s = singleKey.toString().trim();
      if (s.isNotEmpty) return s;
    }
    dynamic photos = user?['photos'] ?? profile['photos'] ?? partner?['photos'];
    if (photos is! List || photos.isEmpty) return null;
    final first = photos[0];
    if (first is Map) {
      final m = first as Map;
      final raw = m['storageKey'] ?? m['storage_key'] ?? m['key'];
      if (raw != null) {
        final key = raw.toString().trim();
        if (key.isNotEmpty) return key;
      }
    } else if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
    return null;
  }

  /// ?꾨줈?꾩뿉???ъ쭊(boardDisplayType:'photo')??怨⑤옄?????ъ쭊 URL 異붿텧
  /// API ?묐떟 ?뺥깭: { user: { boardDisplayType, photos: [{storageKey}] } } ?먮뒗 { boardDisplayType, photos } ??
  String? _photoUrlFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final user = profile['user'] as Map<String, dynamic>?;
    final partner = profile['partner'] as Map<String, dynamic>?;
    final displayType = (profile['boardDisplayType'] ??
            user?['boardDisplayType'] ??
            partner?['boardDisplayType'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (displayType == 'avatar') return null;

    // ?⑥씪 storageKey ?꾨뱶 (?쇰? API??泥??ъ쭊 ?ㅻ쭔 ?대젮以?
    final singleKey = profile['partnerPhotoStorageKey'] ??
        profile['photoStorageKey'] ??
        profile['primaryPhotoStorageKey'] ??
        user?['partnerPhotoStorageKey'] ??
        user?['photoStorageKey'] ??
        user?['primaryPhotoStorageKey'];
    if (singleKey != null) {
      final s = singleKey.toString().trim();
      if (s.isNotEmpty) return photoUrlFromStorageKey(s);
    }

    dynamic photos = user?['photos'] ?? profile['photos'] ?? partner?['photos'];
    if (photos is! List || photos.isEmpty) return null;

    final first = photos[0];
    if (first is Map) {
      final m = first as Map;
      final raw = m['storageKey'] ?? m['storage_key'] ?? m['key'];
      if (raw != null) {
        final key = raw.toString().trim();
        if (key.isNotEmpty) return photoUrlFromStorageKey(key);
      }
    } else if (first is String && first.trim().isNotEmpty) {
      return photoUrlFromStorageKey(first.trim());
    }
    return null;
  }

  Widget _buildPartnerAvatar(BuildContext context) {
    Widget avatar;
    // room API??partnerPhotoStorageKey ?곗꽑, ?놁쑝硫?partnerProfile?먯꽌 boardDisplayType:photo????異붿텧
    String? partnerPhotoUrl = photoUrlFromStorageKey(_partnerPhotoStorageKey);
    if ((partnerPhotoUrl == null || partnerPhotoUrl.isEmpty) &&
        _partnerProfile != null) {
      partnerPhotoUrl = _photoUrlFromProfile(_partnerProfile);
    }
    if (partnerPhotoUrl != null && partnerPhotoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: _partnerAvatarRadius,
        backgroundImage: NetworkImage(partnerPhotoUrl),
      );
    } else {
      final userMap = _partnerProfile != null
          ? (_partnerProfile!['user'] as Map<String, dynamic>?)
          : null;
      final seed = userMap?['avatarSeed']?.toString() ??
          _partnerProfile?['avatarSeed']?.toString() ??
          _partnerProfile?['userId']?.toString() ??
          _partnerAvatarSeed;
      if (seed != null && seed.isNotEmpty) {
        Map<String, String> opts = {};
        final raw = userMap?['avatarOptions']?.toString() ??
            _partnerProfile?['avatarOptions']?.toString() ??
            _partnerAvatarOptions;
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              opts = decoded
                  .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
            }
          } catch (_) {}
        }
        final url =
            diceBearAvatarUrl(seed, options: opts.isNotEmpty ? opts : null);
        avatar = CircleAvatar(
          radius: _partnerAvatarRadius,
          backgroundColor: Colors.grey.shade300,
          child: ClipOval(
            child: SvgPicture.network(
              url,
              fit: BoxFit.cover,
              width: _partnerAvatarRadius * 2,
              height: _partnerAvatarRadius * 2,
              placeholderBuilder: (_) => Icon(LucideIcons.user,
                  size: _partnerAvatarRadius, color: Colors.grey.shade600),
            ),
          ),
        );
      } else {
        avatar = CircleAvatar(
          radius: _partnerAvatarRadius,
          backgroundColor: Colors.grey.shade300,
          child: Icon(LucideIcons.user,
              size: _partnerAvatarRadius, color: Colors.grey.shade600),
        );
      }
    }
    return InkWell(
      onTap: _openPartnerProfile,
      borderRadius: BorderRadius.circular(_partnerAvatarRadius),
      child: avatar,
    );
  }
}

class _ReportReasonGrid extends StatelessWidget {
  const _ReportReasonGrid({
    required this.reasons,
    required this.selectedValue,
    required this.dark,
    required this.onSurface,
    required this.onSelected,
  });

  final List<Map<String, String>> reasons;
  final String selectedValue;
  final bool dark;
  final Color onSurface;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    const chipHeight = 40.0;
    const gap = 8.0;
    final chipList = reasons.map((r) {
      final value = r['value']!;
      final label = r['label']!;
      final selected = selectedValue == value;
      return SizedBox(
        height: chipHeight,
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected
                  ? (dark ? Colors.white : Colors.red.shade900)
                  : onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          selected: selected,
          onSelected: (_) => onSelected(value),
          selectedColor: dark ? Colors.red.shade800 : Colors.red.shade100,
          backgroundColor: dark ? Colors.grey.shade800 : Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: chipList[0]),
            const SizedBox(width: gap),
            Expanded(child: chipList[1]),
            const SizedBox(width: gap),
            Expanded(child: chipList[2]),
          ],
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(child: chipList[3]),
            const SizedBox(width: gap),
            Expanded(child: chipList[4]),
            const SizedBox(width: gap),
            Expanded(child: chipList[5]),
          ],
        ),
      ],
    );
  }
}

class _ReportSheetContent extends StatefulWidget {
  const _ReportSheetContent({
    required this.matchId,
    required this.partnerName,
    required this.reportRepository,
    required this.alreadyReported,
    required this.onSubmitted,
    required this.onError,
  });

  final String matchId;
  final String partnerName;
  final ReportRepository reportRepository;
  final bool alreadyReported;
  final VoidCallback onSubmitted;
  final void Function(String) onError;

  @override
  State<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends State<_ReportSheetContent> {
  String _reason = 'spam';
  final _detailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.reportRepository.report(
        matchId: widget.matchId,
        reason: _reason,
        detail: _detailController.text.trim().isEmpty
            ? null
            : _detailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다')));
      widget.onSubmitted();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map && e.response!.data['message'] != null
          ? e.response!.data['message'].toString()
          : '신고 접수에 실패했어요';
      widget.onError(msg);
    } catch (_) {
      if (!mounted) return;
      widget.onError('신고 접수에 실패했어요');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final padding = MediaQuery.of(context).viewPadding;
    final viewInsets = MediaQuery.of(context).viewInsets;

    if (widget.alreadyReported) {
      return Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: padding.bottom + viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Icon(LucideIcons.circleCheck,
                size: 56, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text(
              '신고 완료',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              '이미 신고가 접수된 대상입니다.',
              style: TextStyle(fontSize: 14, color: onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: padding.bottom + viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.flag, size: 24, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text(
                  '상대방 신고',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.partnerName}님을 신고합니다. 사유와 내용을 입력해 주세요.',
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text('신고 사유',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface)),
            const SizedBox(height: 8),
            _ReportReasonGrid(
              reasons: ChatRoomScreen._reportReasons,
              selectedValue: _reason,
              dark: dark,
              onSurface: onSurface,
              onSelected: (value) => setState(() => _reason = value),
            ),
            const SizedBox(height: 16),
            Text('상세 내용 (선택)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _detailController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '구체적인 상황을 적어 주시면 검토에 도움이 됩니다.',
                filled: true,
                fillColor: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: onSurface, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('신고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





