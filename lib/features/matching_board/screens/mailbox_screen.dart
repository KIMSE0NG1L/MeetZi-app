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
  final ScrollController _receivedScroll = ScrollController();
  final ScrollController _sentScroll = ScrollController();

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
    _receivedScroll.dispose();
    _sentScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF111827) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final seed = ThemeController.seedColor.value;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, dark, seed),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState(context)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildReceivedList(context, surface, onSurface, onSurfaceVariant),
                              _buildSentList(context, surface, onSurface, onSurfaceVariant),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark, Color seed) {
    final receivedCount = _receivedRequests.length;
    final sentCount = _sentRequests.length;

    return Container(
      decoration: BoxDecoration(gradient: ThemeController.getHeaderGradient()),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(LucideIcons.arrowLeft),
                color: Colors.white,
                tooltip: '뒤로',
              ),
              const SizedBox(width: 2),
              const Icon(LucideIcons.mail, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '매칭대기함',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: _loading ? null : _load,
                tooltip: '새로고침',
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(dark ? 0.10 : 0.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              labelColor: seed,
              unselectedLabelColor: Colors.white.withOpacity(0.80),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: '받은 요청 ($receivedCount)'),
                Tab(text: '보낸 요청 ($sentCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = dark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.circleAlert, color: Color(0xFFEF4444), size: 22),
              const SizedBox(height: 10),
              Text(
                _error ?? '오류가 발생했습니다.',
                style: TextStyle(color: onSurfaceVariant, height: 1.35),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedList(BuildContext context, Color surface, Color onSurface, Color onSurfaceVariant) {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
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
        controller: _receivedScroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _receivedRequests.length,
        itemBuilder: (context, index) {
          final req = _receivedRequests[index];
          final requestId = req['id']?.toString() ?? '';
          final requester = req['requester'] as Map<String, dynamic>?;
          final nickname = requester?['nickname']?.toString() ?? '알 수 없음';
          final senderMessage = (req['senderMessage'] as String?)?.trim();
          final subtitle = _buildProfileSubtitle(requester);
          final readAt = req['recipientReadAt']?.toString().trim();
          final isNew = readAt == null || readAt.isEmpty;

          return _adLikeRequestCard(
            context: context,
            dark: Theme.of(context).brightness == Brightness.dark,
            avatar: _buildRequesterAvatar(context, requester),
            title: nickname,
            subtitle: subtitle,
            message: senderMessage,
            badge: isNew
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        height: 1.0,
                      ),
                    ),
                  )
                : null,
            footer: Text(
              '$nickname님이 내 카드를 가져가려고 해요',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: onSurface),
            ),
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
            const Text('📬', style: TextStyle(fontSize: 64)),
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
        controller: _sentScroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final req = _sentRequests[index];
          final requestId = req['id']?.toString() ?? '';
          final status = req['status']?.toString() ?? 'pending';
          final recipient = req['recipient'] as Map<String, dynamic>?;
          final profile = req['profile'] as Map<String, dynamic>?;
          final nickname = recipient?['nickname']?.toString() ?? profile?['nickname']?.toString() ?? '알 수 없음';
          final read = _isRead(req);
          final rejectionMessage = req['rejectionMessage'] as String?;
          final isRejected = status == 'rejected';
          final statusLabel = status == 'accepted'
              ? '수락됨'
              : status == 'rejected'
                  ? '거절됨'
                  : '대기 중';
          final senderMessage = (req['senderMessage'] as String?)?.trim();
          final subtitle = _buildProfileSubtitle(recipient ?? profile);

          return _adLikeRequestCard(
            context: context,
            dark: dark,
            avatar: _buildRecipientAvatar(context, recipient),
            title: nickname,
            subtitle: subtitle,
            message: senderMessage,
            footer: _sentStatusRow(
              dark: dark,
              status: status,
              statusLabel: statusLabel,
              read: read,
              isRejected: isRejected,
            ),
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TakeNoteSentDetailScreen(
                    requestId: requestId,
                    recipientNickname: nickname,
                    recipient: recipient,
                    profile: profile,
                    status: status,
                    senderMessage: req['senderMessage'] as String?,
                    rejectionMessage: rejectionMessage,
                  ),
                ),
              );
              if (result == true) _load();
            },
          );
        },
      ),
    );
  }

  String _buildProfileSubtitle(Map<String, dynamic>? userOrProfile) {
    if (userOrProfile == null) return '';
    final school = (userOrProfile['affiliationText'] ??
            userOrProfile['affiliation'] ??
            userOrProfile['school'] ??
            userOrProfile['schoolName'])
        ?.toString()
        .trim();
    final major = (userOrProfile['department'] ??
            userOrProfile['major'] ??
            userOrProfile['majorName'])
        ?.toString()
        .trim();
    final parts = <String>[];
    if (school != null && school.isNotEmpty) parts.add(school);
    if (major != null && major.isNotEmpty) parts.add(major);
    return parts.join(' · ');
  }

  Widget _sentStatusRow({
    required bool dark,
    required String status,
    required String statusLabel,
    required bool read,
    required bool isRejected,
  }) {
    if (status == 'accepted') {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.heart, size: 16, color: Color(0xFF10B981)),
          SizedBox(width: 6),
          Text('수락됨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
        ],
      );
    }
    if (status == 'rejected') {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.heartCrack, size: 16, color: Color(0xFF9CA3AF)),
          SizedBox(width: 6),
          Text('거절됨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF))),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.clock, size: 16, color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
        const SizedBox(width: 6),
        Text(
          read ? '읽음' : '답변 대기중',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  Widget _adLikeRequestCard({
    required BuildContext context,
    required bool dark,
    required Widget avatar,
    required String title,
    required String subtitle,
    required String? message,
    required Widget footer,
    Widget? badge,
    required VoidCallback onTap,
  }) {
    final outerBg = dark ? const Color(0xFF374151).withOpacity(0.55) : const Color(0xFFF3F4F6);
    final innerBg = dark ? const Color(0xFF4B5563).withOpacity(0.50) : Colors.white;
    final onTitle = dark ? Colors.white : const Color(0xFF111827);
    final onSub = dark ? Colors.grey.shade300 : Colors.grey.shade600;
    final onMsg = dark ? Colors.grey.shade200 : const Color(0xFF374151);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: outerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
                        ],
                      ),
                      child: avatar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: onTitle),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                badge,
                              ],
                            ],
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSub),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: innerBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: dark
                          ? null
                          : const [
                              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
                            ],
                    ),
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.3, color: onMsg),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 내가 보낸 가져가기 요청 상세 (상태 + 거절 시 상대방 거절 사유 표시)
class TakeNoteSentDetailScreen extends StatelessWidget {
  const TakeNoteSentDetailScreen({
    super.key,
    required this.requestId,
    required this.recipientNickname,
    this.recipient,
    this.profile,
    required this.status,
    this.senderMessage,
    this.rejectionMessage,
  });

  final String requestId;
  final String recipientNickname;
  final Map<String, dynamic>? recipient;
  final Map<String, dynamic>? profile;
  final String status;
  final String? senderMessage;
  final String? rejectionMessage;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final statusLabel = status == 'accepted'
        ? '수락됨'
        : status == 'rejected'
            ? '거절됨'
            : '대기 중';
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(gradient: ThemeController.getHeaderGradient()),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(LucideIcons.arrowLeft),
                      color: Colors.white,
                      tooltip: '뒤로',
                    ),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.send, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '보낸 가져가기 요청',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$recipientNickname님에게 가져가기를 보냈어요.',
                        style: TextStyle(fontSize: 15, color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRejected ? LucideIcons.heartCrack : (status == 'accepted' ? LucideIcons.heart : LucideIcons.clock),
                              size: 18,
                              color: isRejected
                                  ? const Color(0xFF9CA3AF)
                                  : status == 'accepted'
                                      ? const Color(0xFF10B981)
                                      : (dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isRejected
                                    ? const Color(0xFF9CA3AF)
                                    : status == 'accepted'
                                        ? const Color(0xFF10B981)
                                        : onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (senderMessage != null && senderMessage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionLabel('내가 보낸 멘트', onSurfaceVariant),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF1F2937) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Text(
                            senderMessage!.trim(),
                            style: TextStyle(fontSize: 14, height: 1.35, color: onSurface),
                          ),
                        ),
                      ],
                      if (isRejected && rejectionMessage != null && rejectionMessage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionLabel('상대방 거절 사유', onSurfaceVariant),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: (dark ? Colors.red.shade900 : Colors.red.shade50).withOpacity(0.60),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: dark ? Colors.red.shade700 : Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            rejectionMessage!.trim(),
                            style: TextStyle(fontSize: 14, height: 1.35, color: onSurface),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }
}
