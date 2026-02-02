import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/messages/data/chat_history_store.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _store = ChatHistoryStore.instance;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _store.ensureLoaded();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final threads = _store.threads;
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지함'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: threads.isEmpty
          ? const Center(child: Text('아직 대화가 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final last = thread.messages.isNotEmpty
                    ? thread.messages.last.text
                    : '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(thread.partner.substring(0, 1)),
                  ),
                  title: Text(thread.partner),
                  subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.chatPreview,
                      arguments: {
                        'nickname': thread.partner,
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
