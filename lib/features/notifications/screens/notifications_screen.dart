import 'package:flutter/material.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length}개 선택' : '알림'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _selectionMode = true),
              tooltip: '선택 삭제',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _items.isEmpty ? null : _deleteAll,
              tooltip: '전체 삭제',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
              tooltip: '취소',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              tooltip: '선택 삭제',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outline),
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
                          : Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
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
                      trailing: _selectionMode ? null : Text(
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
