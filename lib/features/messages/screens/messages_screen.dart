import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:flutter/material.dart';

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

  String? _resolvePhotoUrl(String? photoKey) {
    if (photoKey == null || photoKey.isEmpty) return null;
    return '${AppConfig.baseUrl}/files/$photoKey';
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
      body: _loading
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
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
                          child: photoUrl == null ? Text(partner.substring(0, 1)) : null,
                        ),
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
                ),
    );
  }
}
