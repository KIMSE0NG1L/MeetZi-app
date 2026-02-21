import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationHistoryStore.instance;
  List<NotificationHistoryItem> _items = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  Future<void> _load() async {
    await _store.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _items = List.from(_store.items);
      _loading = false;
      if (_selectionMode) _selectedIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    await _store.removeIds(_selectedIds.toList());
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    _load();
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 알림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _store.removeAll();
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    _load();
  }

  static const _roseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 홈 상단과 동일: pt-14(56) + pb-5(20) + 콘텐츠, px-5(20)
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    const pb = 20.0;
    const titleHeight = 36.0;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            height: pt + pb + titleHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: _roseGradient,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: pt, bottom: pb),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(8),
                  ),
                  Expanded(
                    child: Text(
                        _selectionMode ? '${_selectedIds.length}개 선택' : '알림',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!_selectionMode) ...[
                      IconButton(
                        icon: const Icon(LucideIcons.checkSquare, color: Colors.white, size: 24),
                        onPressed: () => setState(() => _selectionMode = true),
                        tooltip: '선택 삭제',
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.trash2, color: _items.isEmpty ? Colors.white54 : Colors.white, size: 24),
                        onPressed: _items.isEmpty ? null : _deleteAll,
                        tooltip: '전체 삭제',
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                        onPressed: () => setState(() {
                          _selectionMode = false;
                          _selectedIds.clear();
                        }),
                        tooltip: '취소',
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.trash2, color: _selectedIds.isEmpty ? Colors.white54 : Colors.white, size: 24),
                        onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                        tooltip: '선택 삭제',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.star, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              '도착한 알림이 없습니다',
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final selected = _selectedIds.contains(item.id);
                          return ListTile(
                            leading: _selectionMode
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleSelection(item.id),
                                    activeColor: theme.colorScheme.primary,
                                  )
                                : _buildNotificationLeading(context, item),
                            title: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.body.isNotEmpty
                                ? Text(
                                    item.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: _selectionMode
                                ? null
                                : Text(
                                    _formatDate(item.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                  ),
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(item.id);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 매칭 알림: 앱 로고, 사람이 보낸 알림: 아바타, 그 외: 종 아이콘
  Widget _buildNotificationLeading(BuildContext context, NotificationHistoryItem item) {
    final theme = Theme.of(context);
    final data = item.data;
    final type = data['type']?.toString().toLowerCase();
    final isMatch = type == 'match' ||
        (item.title.contains('매칭') || item.body.contains('매칭'));
    if (isMatch) {
      const double size = 44;
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(LucideIcons.bell, color: theme.colorScheme.primary, size: 24),
        ),
      );
    }
    final title = item.title;
    final body = item.body;
    final isMessageNotification = data['type']?.toString().toLowerCase() == 'message' ||
        data['roomId'] != null ||
        data['senderId'] != null ||
        (title.isNotEmpty && (title.contains('메시지') || title.toLowerCase().contains('message'))) ||
        (body.isNotEmpty && (body.contains('메시지') || body.toLowerCase().contains('message') || body.contains('보냈') || body.contains('님이')));
    if (!isMessageNotification) {
      return Icon(LucideIcons.bell, color: theme.colorScheme.primary);
    }

    // 새 메시지 알림 → 보낸 사람 아바타 (FCM data에 senderAvatarSeed 또는 partnerPhotoStorageKey 있으면 표시)
    final photoKey = data['partnerPhotoStorageKey']?.toString() ??
        data['senderPhotoStorageKey']?.toString() ??
        data['photoStorageKey']?.toString() ??
        data['senderPhotoUrl']?.toString();
    final seed = data['avatarSeed']?.toString() ??
        data['senderAvatarSeed']?.toString() ??
        data['senderId']?.toString();
    final hasAvatarData = (photoKey != null && photoKey.isNotEmpty) || (seed != null && seed.isNotEmpty);

    const double radius = 22;
    if (!hasAvatarData) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(LucideIcons.user, size: radius, color: theme.colorScheme.primary),
      );
    }
    if (photoKey != null && photoKey.isNotEmpty) {
      final imageUrl = photoKey.startsWith('http') ? photoKey : 'https://nearo-image.s3.ap-northeast-2.amazonaws.com/$photoKey';
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
      );
    }
    Map<String, String> opts = {};
    final raw = data['avatarOptions']?.toString() ?? data['senderAvatarOptions']?.toString();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          opts = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
      } catch (_) {}
    }
    final url = diceBearAvatarUrl(seed!, options: opts.isNotEmpty ? opts : null);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          placeholderBuilder: (_) => Icon(LucideIcons.user, size: radius, color: theme.colorScheme.outline),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(date).inDays == 1) {
      return '어제';
    }
    if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays}일 전';
    }
    return '${d.month}/${d.day}';
  }
}
