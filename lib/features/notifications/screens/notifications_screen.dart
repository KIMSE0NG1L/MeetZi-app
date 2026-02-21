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

  static const _roseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // AppDesign 헤더: 로즈 그라데이션 + 뒤로가기 + 알림 + 액션
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: _roseGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
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
                        icon: const Icon(Icons.checklist, color: Colors.white, size: 24),
                        onPressed: () => setState(() => _selectionMode = true),
                        tooltip: '선택 삭제',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_sweep, color: _items.isEmpty ? Colors.white54 : Colors.white, size: 24),
                        onPressed: _items.isEmpty ? null : _deleteAll,
                        tooltip: '전체 삭제',
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => setState(() {
                          _selectionMode = false;
                          _selectedIds.clear();
                        }),
                        tooltip: '취소',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: _selectedIds.isEmpty ? Colors.white54 : Colors.white, size: 24),
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
