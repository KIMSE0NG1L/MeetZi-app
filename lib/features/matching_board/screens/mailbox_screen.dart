import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/profile_detail_sheet.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart'
    as board;
import 'package:nearo_app/features/matching_board/screens/take_note_sent_detail_screen.dart';
import 'package:nearo_app/features/matching_board/utils/take_note_request_profile.dart';
import 'package:nearo_app/features/matching_board/widgets/match_card_avatar.dart';
import 'package:nearo_app/features/matching_board/widgets/reject_reason_modal.dart';
import 'package:nearo_app/features/matching_board/widgets/request_card_widget.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// 매칭대기함: 내가 받은 가져가기 요청 목록 (매칭 알림이 여기로 옴)
class MailboxScreen extends StatefulWidget {
  const MailboxScreen({super.key, this.isModal = false});

  /// true면 모달(팝업)로 띄울 때 사용. 상단바가 모달 상단에 맞게 표시됨.
  final bool isModal;

  @override
  State<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends State<MailboxScreen>
    with SingleTickerProviderStateMixin {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;
  final ScrollController _receivedScroll = ScrollController();
  final ScrollController _sentScroll = ScrollController();

  /// 모달로 띄울 때 true (상단 SafeArea 비활성화). initState에서만 읽음.
  late bool _isModal;

  @override
  void initState() {
    super.initState();
    _isModal = widget.isModal;
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

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
      final received = List<Map<String, dynamic>>.from(results[0]);
      received.sort((a, b) {
        int statusRank(Map<String, dynamic> req) {
          final status = req['status']?.toString() ?? 'pending';
          switch (status) {
            case 'pending':
              return 0;
            case 'accepted':
              return 1;
            case 'rejected':
              return 2;
            default:
              return 3;
          }
        }

        DateTime? createdAt(Map<String, dynamic> req) {
          final raw = req['createdAt'] ?? req['created_at'];
          if (raw is DateTime) return raw;
          if (raw is String) return DateTime.tryParse(raw);
          return null;
        }

        final rankCompare = statusRank(a).compareTo(statusRank(b));
        if (rankCompare != 0) return rankCompare;
        final atA = createdAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final atB = createdAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return atB.compareTo(atA);
      });
      setState(() {
        _receivedRequests = received;
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

  Widget _buildRecipientAvatar(
      BuildContext context, Map<String, dynamic>? recipient) {
    if (recipient == null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        child: Icon(LucideIcons.user, color: Colors.grey.shade600),
      );
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: buildMatchCardAvatar(recipient, size: 48),
    );
  }

  bool _isRead(Map<String, dynamic> req) {
    final at = req['recipientReadAt'];
    return at != null && at.toString().trim().isNotEmpty;
  }

  /// 요청 시각을 "5분 전", "1시간 전" 등으로 표시
  String _formatTimeAgo(Map<String, dynamic> req) {
    final raw = req['createdAt'] ?? req['created_at'];
    if (raw == null) return '';
    DateTime? at;
    if (raw is DateTime) {
      at = raw;
    } else if (raw is String) {
      at = DateTime.tryParse(raw);
    }
    if (at == null) return '';
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  Widget _buildRequesterAvatar(
      BuildContext context, Map<String, dynamic>? requester) {
    return _buildRecipientAvatar(context, requester);
  }

  Map<String, dynamic>? _resolveReceivedRequestProfile(Map<String, dynamic> req,
      {Map<String, dynamic>? primary}) {
    return resolveReceivedRequestTargetProfile(req, primary: primary);
  }

  Map<String, dynamic>? _resolveSentRequestProfile(Map<String, dynamic> req,
      {Map<String, dynamic>? primary}) {
    return resolveSentRequestTargetProfile(req, primary: primary);
  }

  Future<Map<String, dynamic>?> _resolveReceivedRequestDetailProfile(
    String requestId, {
    Map<String, dynamic>? primary,
  }) async {
    Map<String, dynamic>? fetched;
    try {
      final detail = await _repository.fetchTakeNoteRequest(requestId);
      fetched = resolveReceivedRequestTargetProfile(detail);
    } catch (_) {
      fetched = null;
    }
    return mergeProfileMaps([primary, fetched]);
  }

  Future<Map<String, dynamic>?> _resolveSentRequestDetailProfile(
    String requestId, {
    Map<String, dynamic>? primary,
  }) async {
    Map<String, dynamic>? fetched;
    try {
      final detail = await _repository.fetchTakeNoteRequest(requestId);
      fetched = resolveSentRequestTargetProfile(detail);
    } catch (_) {
      fetched = null;
    }
    return mergeProfileMaps([primary, fetched]);
  }

  Future<void> _openRequestProfileDetail(
    BuildContext context, {
    required String requestId,
    required Map<String, dynamic>? fallbackProfile,
    required bool isSentRequest,
  }) async {
    final profile = isSentRequest
        ? await _resolveSentRequestDetailProfile(
            requestId,
            primary: fallbackProfile,
          )
        : await _resolveReceivedRequestDetailProfile(
            requestId,
            primary: fallbackProfile,
          );
    if (!mounted || profile == null) return;
    await showProfileDetailSheet(
      context,
      profile: profile,
      buildAvatar: (ctx, p) => _buildRecipientAvatar(ctx, p),
      hideMatchButton: true,
    );
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

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
        ),
        child: SafeArea(
          top: !_isModal,
          child: Column(
            children: [
              _buildHeader(context, dark),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState(context)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildReceivedList(context, surface, onSurface,
                                  onSurfaceVariant),
                              _buildSentList(context, surface, onSurface,
                                  onSurfaceVariant),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark) {
    final receivedCount = _receivedRequests.length;
    final sentCount = _sentRequests.length;

    return Container(
      decoration: BoxDecoration(gradient: ThemeController.getHeaderGradient()),
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.heart, size: 24, color: Colors.white),
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
                icon: const Icon(LucideIcons.x, size: 24),
                onPressed: () => Navigator.of(context).maybePop(),
                color: Colors.white,
                tooltip: '닫기',
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              labelColor: const Color(0xFF111827),
              unselectedLabelColor: Colors.white.withOpacity(0.90),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
              BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.circleAlert,
                  color: Color(0xFFEF4444), size: 22),
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

  Widget _buildReceivedList(BuildContext context, Color surface,
      Color onSurface, Color onSurfaceVariant) {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 56, color: onSurfaceVariant),
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
          final dark = Theme.of(context).brightness == Brightness.dark;
          final onSurface = dark ? Colors.white : const Color(0xFF111827);
          final requestId = req['id']?.toString() ?? '';
          final status = req['status']?.toString() ?? 'pending';
          final isPending = status == 'pending';
          final requester = req['requester'] as Map<String, dynamic>?;
          final detailProfile =
              _resolveReceivedRequestProfile(req, primary: requester);
          final nickname = detailProfile?['nickname']?.toString() ??
              requester?['nickname']?.toString() ??
              '알 수 없음';
          final senderMessage = (req['senderMessage'] as String?)?.trim();
          final subtitle = _buildProfileSubtitle(detailProfile ?? requester);
          final readAt = req['recipientReadAt']?.toString().trim();
          final isNew = isPending && (readAt == null || readAt.isEmpty);
          final timeAgo = _formatTimeAgo(req);

          return RequestCardWidget(
            avatar: GestureDetector(
              onTap: () => _openRequestProfileDetail(
                context,
                requestId: requestId,
                fallbackProfile: detailProfile ?? requester,
                isSentRequest: false,
              ),
              behavior: HitTestBehavior.opaque,
              child: _buildRequesterAvatar(context, detailProfile ?? requester),
            ),
            title: nickname,
            subtitle: subtitle,
            timestamp: timeAgo,
            message: senderMessage,
            badge: isNew
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.25)),
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
            footer: isPending
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectReasonModal(
                              context,
                              requestId,
                              detailProfile ?? requester,
                              nickname,
                              subtitle),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onSurface,
                            side: BorderSide(
                                color: dark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _confirmAcceptRequest(
                                context, requestId),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: ThemeController.getHeaderGradient(),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '수락',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _sentStatusRow(
                    dark: dark,
                    status: status,
                    statusLabel: status == 'accepted' ? '수락됨' : '거절됨',
                    read: true,
                    isRejected: status == 'rejected',
                  ),
            onTap: null,
          );
        },
      ),
    );
  }

  Future<void> _confirmAcceptRequest(
      BuildContext context, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('수락하시겠습니까?'),
          content: const Text('수락하면 매칭이 성사되고 바로 대화를 시작할 수 있어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.acceptTakeNoteRequest(requestId);
      if (!mounted) return;
      await board.showMatchCompleteCelebration(context);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showRejectReasonModal(
    BuildContext context,
    String requestId,
    Map<String, dynamic>? requester,
    String nickname,
    String subtitle,
  ) async {
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: RejectReasonModal(
          nickname: nickname,
          subtitle: subtitle,
          avatarWidget: _buildRequesterAvatar(ctx, requester),
          onSubmit: (String message) async {
            try {
              await _repository.rejectTakeNoteRequest(requestId, message);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(true);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            }
          },
        ),
      ),
    );
    if (submitted == true && mounted) _load();
  }

  Widget _buildSentList(BuildContext context, Color surface, Color onSurface,
      Color onSurfaceVariant) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.send, size: 56, color: onSurfaceVariant),
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
          final detailProfile =
              _resolveSentRequestProfile(req, primary: recipient ?? profile);
          final nickname = detailProfile?['nickname']?.toString() ??
              recipient?['nickname']?.toString() ??
              profile?['nickname']?.toString() ??
              '알 수 없음';
          final read = _isRead(req);
          final rejectionMessage = req['rejectionMessage'] as String?;
          final isRejected = status == 'rejected';
          final statusLabel = status == 'accepted'
              ? '수락됨'
              : status == 'rejected'
                  ? '거절됨'
                  : '대기 중';
          final senderMessage = (req['senderMessage'] as String?)?.trim();
          final subtitle =
              _buildProfileSubtitle(detailProfile ?? recipient ?? profile);
          final timeAgo = _formatTimeAgo(req);

          return RequestCardWidget(
            avatar: GestureDetector(
              onTap: () => _openRequestProfileDetail(
                context,
                requestId: requestId,
                fallbackProfile: detailProfile ?? recipient ?? profile,
                isSentRequest: true,
              ),
              behavior: HitTestBehavior.opaque,
              child: _buildRecipientAvatar(
                  context, detailProfile ?? recipient ?? profile),
            ),
            title: nickname,
            subtitle: subtitle,
            timestamp: timeAgo,
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
                    recipient: detailProfile ?? recipient,
                    profile: detailProfile ?? profile,
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
    final user = userOrProfile['user'] as Map<String, dynamic>?;
    final school = (userOrProfile['affiliationText'] ??
            userOrProfile['affiliation'] ??
            userOrProfile['school'] ??
            userOrProfile['schoolName'] ??
            user?['affiliationText'] ??
            user?['affiliation'] ??
            user?['school'] ??
            user?['schoolName'])
        ?.toString()
        .trim();
    final major = (userOrProfile['department'] ??
            userOrProfile['major'] ??
            userOrProfile['majorName'] ??
            user?['department'] ??
            user?['major'] ??
            user?['majorName'])
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
          Icon(Icons.favorite, size: 16, color: Color(0xFF10B981)),
          SizedBox(width: 6),
          Text('수락됨',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981))),
        ],
      );
    }
    if (status == 'rejected') {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.heartCrack, size: 16, color: Color(0xFF9CA3AF)),
          SizedBox(width: 6),
          Text('거절됨',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9CA3AF))),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.clock,
            size: 16,
            color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
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


}




