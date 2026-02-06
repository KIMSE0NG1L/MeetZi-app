import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';

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

  Future<void> _loadRooms() async {
    try {
      final rooms = await _repository.listRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지함'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(partner.substring(0, 1)),
                  ),
                  title: Text(partner),
                  subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.chatRoom,
                      arguments: {
                        'roomId': room['roomId']?.toString(),
                        'partnerNickname': partner,
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
