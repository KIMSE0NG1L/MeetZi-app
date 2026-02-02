import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryStore {
  static final ChatHistoryStore instance = ChatHistoryStore._();
  ChatHistoryStore._();

  static const _storageKey = 'chat_history_threads';

  final List<ChatThread> threads = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        threads
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => ChatThread.fromMap(Map<String, dynamic>.from(item))),
          );
      }
    }
    _loaded = true;
  }

  ChatThread? getThread(String partner) {
    return threads.where((t) => t.partner == partner).isEmpty
        ? null
        : threads.firstWhere((t) => t.partner == partner);
  }

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
    _persist();
  }

  Future<void> clear() async {
    threads.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(threads.map((t) => t.toMap()).toList());
      await prefs.setString(_storageKey, payload);
    } catch (_) {
      // ignore persistence errors
    }
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

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      partner: map['partner']?.toString() ?? '',
      messages: (map['messages'] as List? ?? [])
          .whereType<Map>()
          .map((item) => ChatMessage.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    )
      ..updatedAt = DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'partner': partner,
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }
}

class ChatMessage {
  final String text;
  final bool isMine;
  DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.isMine,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text']?.toString() ?? '',
      isMine: map['isMine'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isMine': isMine,
      'createdAt': createdAt.toIso8601String(),
    };
  }

}
