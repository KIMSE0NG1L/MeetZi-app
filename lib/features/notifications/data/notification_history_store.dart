import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryStore {
  static final NotificationHistoryStore instance = NotificationHistoryStore._();
  NotificationHistoryStore._();

  static const _storageKey = 'notification_history';

  final List<NotificationHistoryItem> items = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          items
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((item) => NotificationHistoryItem.fromMap(Map<String, dynamic>.from(item))),
            );
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> add({
    required String id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    await ensureLoaded();
    if (items.any((e) => e.id == id)) return;
    items.insert(0, NotificationHistoryItem(
      id: id,
      title: title ?? '알림',
      body: body ?? '',
      data: data ?? {},
      createdAt: DateTime.now(),
      read: false,
    ));
    await _persist();
  }

  Future<void> markAsRead(String id) async {
    await ensureLoaded();
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    items[index] = NotificationHistoryItem(
      id: items[index].id,
      title: items[index].title,
      body: items[index].body,
      data: items[index].data,
      createdAt: items[index].createdAt,
      read: true,
    );
    await _persist();
  }

  Future<void> remove(String id) async {
    await ensureLoaded();
    items.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> removeIds(List<String> ids) async {
    await ensureLoaded();
    final set = ids.toSet();
    items.removeWhere((e) => set.contains(e.id));
    await _persist();
  }

  Future<void> removeAll() async {
    items.clear();
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(items.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool read;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.read = false,
  });

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) {
    final data = map['data'];
    final read = map['read'];
    return NotificationHistoryItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '알림',
      body: map['body']?.toString() ?? '',
      data: data is Map ? Map<String, dynamic>.from(data as Map) : {},
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      read: read == true || read == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }
}
