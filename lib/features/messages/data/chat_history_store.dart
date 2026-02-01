class ChatHistoryStore {
  static final ChatHistoryStore instance = ChatHistoryStore._();
  ChatHistoryStore._();

  final List<ChatThread> threads = [];

  void addMessage({
    required String partner,
    required String text,
    required bool isMine,
  }) {
    final existing = threads.where((t) => t.partner == partner).toList();
    final thread = existing.isEmpty
        ? ChatThread(partner: partner, messages: [])
        : existing.first;

    if (!threads.contains(thread)) {
      threads.insert(0, thread);
    }

    thread.messages.add(ChatMessage(text: text, isMine: isMine));
    thread.updatedAt = DateTime.now();

    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}

class ChatThread {
  final String partner;
  final List<ChatMessage> messages;
  DateTime updatedAt;

  ChatThread({
    required this.partner,
    required this.messages,
  }) : updatedAt = DateTime.now();
}

class ChatMessage {
  final String text;
  final bool isMine;
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.isMine,
  }) : createdAt = DateTime.now();
}
