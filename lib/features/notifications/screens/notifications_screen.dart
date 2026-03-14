import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/features/matching_board/screens/take_note_request_response_screen.dart';
import 'package:nearo_app/features/community/screens/community_post_detail_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (topInset > 0 ? topInset : 56.0) + 20 + 36;
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // AppDesign 헤더: 메시지함 등과 동일 높이 (pt + 20 + 36)
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: ThemeController.getHeaderGradient(),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
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
                        icon: const Icon(LucideIcons.listChecks, color: Colors.white, size: 24),
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.bell, size: 64, color: theme.colorScheme.outline),
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
                          final isFromPerson = item.data['type']?.toString() == 'chat';
                          final senderAvatarUrl = item.data['senderAvatarUrl']?.toString();
                          return ListTile(
                            leading: _selectionMode
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleSelection(item.id),
                                    activeColor: theme.colorScheme.primary,
                                  )
                                : _buildNotificationLeading(
                                    theme: theme,
                                    isFromPerson: isFromPerson,
                                    senderAvatarUrl: senderAvatarUrl,
                                  ),
                            title: Row(
                              children: [
                                if (!item.read)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                                      color: item.read ? theme.colorScheme.onSurface.withOpacity(0.85) : theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: item.body.isNotEmpty
                                ? Text(
                                    item.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(item.read ? 0.6 : 0.8),
                                    ),
                                  )
                                : null,
                            trailing: _selectionMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!item.read)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            '읽지 않음',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                            onTap: () async {
                              if (_selectionMode) {
                                _toggleSelection(item.id);
                                return;
                              }
                              if (!item.read) {
                                await _store.markAsRead(item.id);
                                if (mounted) _load();
                              }
                              final type = item.data['type']?.toString();
                              if (type == 'take_note_request') {
                                final requestId = item.data['requestId']?.toString();
                                if (requestId != null && requestId.isNotEmpty) {
                                  final requesterProfile = item.data['requesterProfile'] is Map
                                      ? Map<String, dynamic>.from(item.data['requesterProfile'] as Map)
                                      : null;
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (ctx) => TakeNoteRequestResponseScreen(
                                        requestId: requestId,
                                        requesterProfile: requesterProfile,
                                      ),
                                    ),
                                  );
                                }
                              } else if (type == 'chat') {
                                final roomId = item.data['roomId']?.toString();
                                if (roomId != null && roomId.isNotEmpty) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.chatRoom,
                                    arguments: {'roomId': roomId, 'partnerNickname': '대화'},
                                  );
                                }
                              } else if (type == 'support_reply' || type == 'support_submitted') {
                                if (!context.mounted) return;
                                Navigator.of(context).pushNamed(AppRoutes.customerSupport);
                              } else if (type == 'community_comment_reply' || type == 'community_mention') {
                                final environmentId = item.data['environmentId']?.toString();
                                final postId = item.data['postId']?.toString();
                                final schoolName = item.data['schoolName']?.toString() ?? '커뮤니티';
                                if (environmentId != null &&
                                    environmentId.isNotEmpty &&
                                    postId != null &&
                                    postId.isNotEmpty) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CommunityPostDetailScreen(
                                        environmentId: environmentId,
                                        schoolName: schoolName,
                                        postId: postId,
                                      ),
                                    ),
                                  );
                                }
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

  /// 사람이 보낸 메시지 알림 → 발신자 아바타, 시스템 알림(매칭·가져가기 등) → 앱 로고
  Widget _buildNotificationLeading({
    required ThemeData theme,
    required bool isFromPerson,
    String? senderAvatarUrl,
  }) {
    const size = 40.0;
    if (isFromPerson && senderAvatarUrl != null && senderAvatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(senderAvatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        'assets/icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(LucideIcons.bell, color: theme.colorScheme.primary, size: 22),
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
