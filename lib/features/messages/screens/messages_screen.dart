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

  @override
  void initState() {
    super.initState();
    _loadRooms();
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
  }

  Future<void> _deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId: roomId);
    _loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지함'),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return Center(child: CircularProgressIndicator());
          } else if (_rooms.isEmpty) {
            return Center(child: Text('아직 대화가 없습니다.'));
          } else {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final partner = room['partnerNickname']?.toString() ?? '대화';
                final last = room['lastMessage']?.toString() ?? '';
                final photoKey = room['partnerPhotoStorageKey']?.toString();
                String? photoUrl = (photoKey != null && photoKey.isNotEmpty)
                    ? AppConfig.baseUrl + '/files/' + photoKey
                    : null;
                final roomId = room['roomId']?.toString() ?? '';
                final isActive = room['isActive'] == true;
                // 아바타 정보 채팅방과 동일하게 추출
                final avatarSeed = room['avatarSeed']?.toString()
                  ?? room['userId']?.toString()
                  ?? room['partnerAvatarSeed']?.toString();
                String? avatarOptionsRaw = room['avatarOptions']?.toString() ?? room['partnerAvatarOptions']?.toString();
                Map<String, String> avatarOptions = {};
                if (avatarOptionsRaw != null && avatarOptionsRaw.isNotEmpty) {
                  try {
                    final decoded = jsonDecode(avatarOptionsRaw);
                    if (decoded is Map<String, dynamic>) {
                      avatarOptions = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
                    }
                  } catch (_) {}
                }
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
                    trailing: const Icon(Icons.chevron_right),
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
            );
          }
        },
      ),
    );
  }
    // ...existing code...
  }
