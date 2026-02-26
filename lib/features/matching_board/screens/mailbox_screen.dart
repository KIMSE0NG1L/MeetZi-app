import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/take_note_request_response_screen.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';

/// 매칭대기함: 내가 받은 가져가기 요청 목록 (매칭 알림이 여기로 옴)
class MailboxScreen extends StatefulWidget {
  const MailboxScreen({super.key});

  @override
  State<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends State<MailboxScreen> with SingleTickerProviderStateMixin {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.fetchMyTakeNoteRequests(),
        _repository.fetchMySentTakeNoteRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _receivedRequests = results[0];
        _sentRequests = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Map<String, String> _parseAvatarOptions(dynamic raw) {
    if (raw == null) return {};
    final s = raw.toString();
    if (s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (_) {}
    return {};
  }

  Widget _buildRecipientAvatar(BuildContext context, Map<String, dynamic>? recipient) {
    if (recipient == null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        child: Icon(LucideIcons.user, color: Colors.grey.shade600),
      );
    }
    final displayType = recipient['boardDisplayType']?.toString();
    final photos = recipient['photos'];
    String? primaryPhotoKey;
    if (photos is List && photos.isNotEmpty && photos[0] is Map) {
      primaryPhotoKey = (photos[0] as Map<String, dynamic>)['storageKey']?.toString();
    }
    final photoUrl = primaryPhotoKey != null ? photoUrlFromStorageKey(primaryPhotoKey) : null;
    if (displayType == 'photo' && photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 28, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    final seed = recipient['avatarSeed']?.toString() ?? recipient['id']?.toString();
    final options = _parseAvatarOptions(recipient['avatarOptions']);
    if (seed != null && seed.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: SvgPicture.network(
            diceBearAvatarUrl(seed, options: options.isNotEmpty ? options : null),
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            placeholderBuilder: (context) => Icon(LucideIcons.user, size: 28, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade300,
      child: Icon(LucideIcons.user, size: 28, color: Theme.of(context).colorScheme.primary),
    );
  }

  bool _isRead(Map<String, dynamic> req) {
    final at = req['recipientReadAt'];
    return at != null && at.toString().trim().isNotEmpty;
  }

  Widget _buildRequesterAvatar(BuildContext context, Map<String, dynamic>? requester) {
    return _buildRecipientAvatar(context, requester);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('매칭대기함'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeController.gradientFromPrimary(Theme.of(context).colorScheme.primary),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '받은 요청'),
            Tab(text: '보낸 요청'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loading ? null : _load,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedList(context, surface, onSurface, onSurfaceVariant),
                    _buildSentList(context, surface, onSurface, onSurfaceVariant),
                  ],
                ),
    );
  }

  Widget _buildReceivedList(BuildContext context, Color surface, Color onSurface, Color onSurfaceVariant) {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '도착한 가져가기 요청이 없어요',
              style: TextStyle(fontSize: 16, color: onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _receivedRequests.length,
        itemBuilder: (context, index) {
          final req = _receivedRequests[index];
          final requestId = req['id']?.toString() ?? '';
          final requester = req['requester'] as Map<String, dynamic>?;
          final nickname = requester?['nickname']?.toString() ?? '알 수 없음';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TakeNoteRequestResponseScreen(
                      requestId: requestId,
                      requesterProfile: requester,
                    ),
                  ),
                );
                if (result == true || result == false) _load();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildRequesterAvatar(context, requester),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '가져가기 요청',
                            style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$nickname님이 내 카드를 가져가려고 해요',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, color: onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentList(BuildContext context, Color surface, Color onSurface, Color onSurfaceVariant) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.send, size: 64, color: onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '보낸 가져가기 요청이 없어요',
              style: TextStyle(fontSize: 16, color: onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final req = _sentRequests[index];
          final recipient = req['recipient'] as Map<String, dynamic>?;
          final profile = req['profile'] as Map<String, dynamic>?;
          final nickname = recipient?['nickname']?.toString() ?? profile?['nickname']?.toString() ?? '알 수 없음';
          final read = _isRead(req);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildRecipientAvatar(context, recipient),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가져가기 요청 보냄',
                          style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nickname님에게',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: read
                                ? (dark ? Colors.green.shade900 : Colors.green.shade50)
                                : (dark ? Colors.grey.shade700 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            read ? '읽음' : '안 읽음',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: read
                                  ? (dark ? Colors.green.shade200 : Colors.green.shade700)
                                  : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
