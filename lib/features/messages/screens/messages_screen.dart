import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repository = ChatRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];
  Map<String, int> _unreadCounts = {}; // roomId -> unread count

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadUnreadCounts() async {
    // 각 방의 안읽은 메시지 개수 계산
    Map<String, int> unreadCounts = {};
    for (final room in _rooms) {
      final roomId = room['roomId']?.toString() ?? '';
      if (roomId.isEmpty) continue;
      try {
        final messages = await _repository.listMessages(roomId: roomId);
        int count = 0;
        for (final m in messages) {
          // 내 메시지가 아니고, readAt이 null이면 안읽음
          final isMine = m['senderId']?.toString() == room['userId']?.toString();
          if (!isMine && m['readAt'] == null) count++;
        }
        unreadCounts[roomId] = count;
      } catch (_) {
        unreadCounts[roomId] = 0;
      }
    }
    setState(() {
      _unreadCounts = unreadCounts;
    });
  }

  String? _resolvePhotoUrl(String? photoKey) {
    if (photoKey == null || photoKey.isEmpty) return null;
    return '${AppConfig.baseUrl}/files/$photoKey';
  }

  Widget _buildAvatar(String? photoUrl, String? avatarSeed, Map<String, String> avatarOptions, String partner) {
    const double avatarRadius = 28; // 더 큰 크기로 변경 (기본 ListTile leading 크기에 맞춤)
    
    // 1. 프로필 사진이 있으면 프로필 사진 표시
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {
          // 이미지 로드 실패 시 아바타로 폴백 (하지만 위젯을 다시 빌드할 수 없으므로 일단 그대로 둠)
        },
      );
    }
    
    // 2. 아바타 시드가 있으면 아바타 표시 (chat_room_screen과 동일한 방식)
    if (avatarSeed != null && avatarSeed.isNotEmpty) {
      final avatarUrl = diceBearAvatarUrl(avatarSeed, options: avatarOptions.isNotEmpty ? avatarOptions : null);
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: SvgPicture.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            placeholderBuilder: (_) => Icon(Icons.person, size: avatarRadius, color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    // 3. 둘 다 없으면 닉네임 첫 글자 표시 (fallback)
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        partner.isNotEmpty ? partner.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: avatarRadius * 0.6,
        ),
      ),
    );
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final rooms = await _repository.listRooms();
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
    await _loadUnreadCounts();
  }

  Future<void> _deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId: roomId);
    _loadRooms();
  }

  Widget _buildTopBar() {
    final universityColor = Theme.of(context).colorScheme.primary;
    // 홈과 동일한 스타일의 배너
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                universityColor,
                universityColor.withOpacity(0.85),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/noise.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '메시지함',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                          ),
                        ),
                        const Spacer(),
                        // 필요시 알림/설정 아이콘 추가 가능
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                    ? const Center(child: Text('아직 대화가 없습니다.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          final partner = room['partnerNickname']?.toString() ?? '대화';
                          final last = room['lastMessage']?.toString() ?? '';
                          final photoKey = room['partnerPhotoStorageKey']?.toString();
                          final photoUrl = _resolvePhotoUrl(photoKey);
                          final roomId = room['roomId']?.toString() ?? '';
                          final isActive = room['isActive'] == true;
                          
                          // 아바타 정보 가져오기 (chat_room_screen과 동일한 방식)
                          // room 데이터에서 partnerAvatarSeed와 partnerAvatarOptions를 우선 사용
                          // 없으면 partnerUserId를 시드로 사용
                          final avatarSeed = room['partnerAvatarSeed']?.toString() ?? 
                                           room['partnerUserId']?.toString();
                          final avatarOptionsRaw = room['partnerAvatarOptions']?.toString();
                          Map<String, String> avatarOptions = {};
                          if (avatarOptionsRaw != null && avatarOptionsRaw.isNotEmpty) {
                            try {
                              final decoded = jsonDecode(avatarOptionsRaw);
                              if (decoded is Map<String, dynamic>) {
                                avatarOptions = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
                              }
                            } catch (_) {}
                          }
                          
                          int unread = _unreadCounts[roomId] ?? 0;
                          
                          return Dismissible(
                            key: ValueKey(roomId),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('대화방 삭제'),
                                  content: const Text('이 대화방을 삭제할까요?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('삭제'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deleteRoom(roomId),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              leading: _buildAvatar(photoUrl, avatarSeed, avatarOptions, partner),
                              title: Text(partner),
                              subtitle: Text(
                                isActive
                                    ? last
                                    : '매칭이 취소된 대화입니다.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(
                                      AppRoutes.chatRoom,
                                      arguments: {
                                        'roomId': roomId,
                                        'partnerNickname': partner,
                                        'isActive': isActive,
                                      },
                                    )
                                    .then((value) {
                                  if (value == true) {
                                    _loadRooms();
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
