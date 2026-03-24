import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/matching_board/utils/board_note_sheet_launcher.dart';
import 'package:nearo_app/features/matching_board/widgets/match_card_avatar.dart';
import 'package:nearo_app/features/messages/data/report_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/post_time_format.dart';
import 'package:nearo_app/shared/utils/mention_text_span.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final String environmentId;
  final String schoolName;
  final String postId;
  final Map<String, dynamic>? initialPost;
  final String? myUserId;

  const CommunityPostDetailScreen({
    super.key,
    required this.environmentId,
    required this.schoolName,
    required this.postId,
    this.initialPost,
    this.myUserId,
  });

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final CommunityRepository _repo = CommunityRepository();
  final MatchingBoardRepository _matchingRepo = MatchingBoardRepository();
  Map<String, dynamic>? _post;
  String? _myUserIdResolved; // 목록에서 안 넘어오면 프로필에서 로드
  Map<String, dynamic>? _myProfile; // 댓글 입력란 아바타용
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _sendingComment = false;
  String _commentSort = 'latest';
  String? _replyingToCommentId;
  String? _replyingToCommentNickname;

  void _onCommentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _myUserIdResolved = widget.myUserId;
    // 아바타 연동을 위해 항상 프로필 로드(avatarStyle/Seed/Options)
    _loadMyUserId();
    if (widget.initialPost != null) {
      _post = Map<String, dynamic>.from(widget.initialPost!);
      _loading = false;
    }
    _commentController.addListener(_onCommentChanged);
    _load();
  }

  Future<void> _loadMyUserId() async {
    try {
      final res = await AuthRepository().getProfile();
      // GET /users/me 는 user 객체를 그대로 반환. GET /auth/profile 은 { user } 반환 가능.
      final user = (res['user'] as Map<String, dynamic>?) ?? res as Map<String, dynamic>;
      final id = user['id']?.toString();
      if (mounted) setState(() {
        _myUserIdResolved = id;
        _myProfile = user;
      });
    } catch (_) {
      if (mounted) setState(() {
        _myUserIdResolved = null;
        _myProfile = null;
      });
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onReplyToComment(Map<String, dynamic> comment) {
    final ca = comment['author'] as Map<String, dynamic>?;
    final nickname = ca?['nickname']?.toString().trim() ?? '';
    setState(() {
      _replyingToCommentId = comment['id']?.toString();
      _replyingToCommentNickname = nickname.isNotEmpty ? nickname : null;
    });
    if (nickname.isNotEmpty) {
      final prefix = _commentController.text.trim().isEmpty ? '' : '${_commentController.text} ';
      _commentController.text = '$prefix@$nickname ';
      _commentController.selection = TextSelection.collapsed(offset: _commentController.text.length);
    }
    _commentFocusNode.requestFocus();
  }

  void _clearReplying() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToCommentNickname = null;
    });
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteComment(widget.environmentId, widget.postId, commentId);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 삭제 실패. ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getPost(widget.environmentId, widget.postId);
      if (mounted) setState(() {
        if (data != null) {
          // 목록에서 이미 좋아요한 상태면 상세에서도 반드시 핑크로 표시 (상세 API가 liked를 안 넘겨도 유지)
          final likedFromList = _post?['liked'] == true || widget.initialPost?['liked'] == true;
          _post = Map<String, dynamic>.from(data);
          if (likedFromList) _post!['liked'] = true;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        // 에러 시에도 initialPost가 있으면 유지 (내 글 등)
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    try {
      final res = await _repo.toggleLike(widget.environmentId, widget.postId);
      final liked = res['liked'] == true;
      final prevCount = (_post!['likeCount'] is int) ? _post!['likeCount'] as int : 0;
      if (mounted) {
        setState(() {
          _post = Map<String, dynamic>.from(_post!)..['liked'] = liked..['likeCount'] = prevCount + (liked ? 1 : -1);
        });
      }
    } catch (_) {}
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('글 삭제'),
        content: const Text('이 글을 삭제할까요? 삭제된 글은 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deletePost(widget.environmentId, widget.postId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('403') || e.toString().contains('Forbidden')
                  ? '본인 글만 삭제할 수 있어요.'
                  : '삭제에 실패했어요. 잠시 후 다시 시도해 주세요.',
            ),
          ),
        );
      }
    }
  }

  static const _reportReasons = <String, String>{
    'spam': '스팸/허위',
    'harassment': '욕설·혐오',
    'impersonation': '사칭',
    'sexual': '성희롱·음란',
    'scam': '사기',
    'other': '기타',
  };

  void _showReportSheet(BuildContext context) {
    String? selectedReason;
    final detailController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewPadding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '글 신고',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._reportReasons.entries.map((e) => RadioListTile<String>(
                    title: Text(e.value),
                    value: e.key,
                    groupValue: selectedReason,
                    onChanged: (v) => setModalState(() => selectedReason = v),
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      hintText: '상세 내용 (선택)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: selectedReason == null
                        ? null
                        : () async {
                            try {
                              await ReportRepository().reportCommunityPost(
                                postId: widget.postId,
                                reason: selectedReason!,
                                detail: detailController.text.trim().isEmpty
                                    ? null
                                    : detailController.text.trim(),
                              );
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('신고가 접수되었습니다.')),
                              );
                            } catch (err) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err.toString().contains('401')
                                        ? '로그인이 필요해요.'
                                        : '신고 접수에 실패했어요. 잠시 후 다시 시도해 주세요.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('신고하기'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(detailController.dispose);
  }

  /// 본인 글 포함 모든 글에 댓글/답글 작성 가능.
  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await _repo.createComment(
        widget.environmentId,
        widget.postId,
        content,
        parentCommentId: _replyingToCommentId,
      );
      _commentController.clear();
      _clearReplying();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 등록 실패. ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _onAuthorTap(Map<String, dynamic> author) async {
    final userId = author['id']?.toString();
    if (userId == null || userId.isEmpty || !mounted) return;
    final myId = _myUserIdResolved ?? widget.myUserId;
    if (myId != null && myId == userId) return; // 본인 글: 아무 동작 없음 (스낵바 없이)
    try {
      final profile = await _matchingRepo.fetchProfileByUserId(userId);
      if (!mounted) return;
      await launchBoardNoteSheet(
        context: context,
        repo: _matchingRepo,
        profile: profile,
        buildAvatar: (ctx, p) => buildMatchCardAvatar(p),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _voteOption(int optionIndex) async {
    final poll = _post?['poll'] as Map<String, dynamic>?;
    if (poll == null) return;
    if (poll['myVoteOptionIndex'] != null) return; // already voted
    try {
      final res = await _repo.votePost(widget.environmentId, widget.postId, optionIndex);
      if (!mounted) return;
      setState(() {
        _post = Map<String, dynamic>.from(_post!)
          ..['poll'] = Map<String, dynamic>.from(poll)
            ..['myVoteOptionIndex'] = res['myVoteOptionIndex']
            ..['voteCounts'] = res['voteCounts'];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표에 실패했어요. 로그인 후 다시 시도해 주세요.')),
        );
      }
    }
  }

  String? _extractMentionQuery(String text) {
    final match = RegExp(r'(?:^|\s)@([^\s@]{0,20})$').firstMatch(text);
    if (match == null) return null;
    return match.group(1) ?? '';
  }

  List<String> _collectMentionCandidates(
    Map<String, dynamic> post,
    List<Map<String, dynamic>> comments,
  ) {
    final set = <String>{};
    final postAuthor = post['author'] as Map<String, dynamic>?;
    final postNickname = postAuthor?['nickname']?.toString().trim();
    if (postNickname != null && postNickname.isNotEmpty) set.add(postNickname);
    for (final c in comments) {
      final ca = c['author'] as Map<String, dynamic>?;
      final nickname = ca?['nickname']?.toString().trim();
      if (nickname != null && nickname.isNotEmpty) set.add(nickname);
    }
    return set.toList()..sort();
  }

  void _insertMention(String nickname) {
    final text = _commentController.text;
    final replaced = text.replaceFirst(RegExp(r'@([^\s@]{0,20})$'), '@$nickname ');
    _commentController.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: replaced.length),
    );
    setState(() {});
  }

  /// 댓글 카드 (루트용)
  Widget _buildCommentCard(BuildContext context, Map<String, dynamic> c, bool dark) {
    final ca = c['author'] as Map<String, dynamic>? ?? {};
    final cn = ca['nickname']?.toString() ?? '알 수 없음';
    final cAuthorId = ca['id']?.toString();
    final isCommentAuthorMe = _myUserIdResolved != null && cAuthorId == _myUserIdResolved;
    final ct = c['content']?.toString() ?? '';
    final cLiked = c['liked'] == true;
    final cLikeCount = (c['likeCount'] is int) ? c['likeCount'] as int : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _onAuthorTap(ca),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dark ? Colors.grey.shade600 : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: buildMatchCardAvatar(ca, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cn,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCommentAuthorMe) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '작성자',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatPostTime(c['createdAt']?.toString()),
                          style: TextStyle(
                            fontSize: 11,
                            color: dark ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                            children: buildMentionSpans(
                              ct,
                              baseStyle: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                              mentionColor: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.heart,
                              size: 14,
                              color: dark ? Colors.white : Colors.black,
                              fill: cLiked ? 1.0 : 0,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$cLikeCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: cLiked ? FontWeight.bold : FontWeight.w500,
                                color: dark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _onReplyToComment(c),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                child: Text(
                                  '답글 달기',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: dark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            if (isCommentAuthorMe) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _deleteComment(c['id']?.toString() ?? ''),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                  child: Icon(
                                    LucideIcons.trash2,
                                    size: 14,
                                    color: dark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  /// 답글 연결선: 세로선 + 하단 곡선으로 한 줄처럼 이어지게
  static const double _replyLineWidth = 2.0;
  static const double _replyConnectorW = 24.0;
  static const double _replyCurveRadius = 10.0;

  Widget _buildReplyRow(BuildContext context, Map<String, dynamic> c, bool dark) {
    final lineColor = dark ? Colors.grey.shade600 : Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.only(left: _replyConnectorW, top: 0, bottom: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _replyConnectorW,
              child: CustomPaint(
                painter: _ReplyLinePainter(
                  color: lineColor,
                  lineWidth: _replyLineWidth,
                  curveRadius: _replyCurveRadius,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildCommentCard(context, c, dark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _parseMatchingReviewContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return null;

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final title = lines.first;
    final messages = <Map<String, String>>[];
    String? summary;

    for (final line in lines.skip(1)) {
      final match = RegExp(r'^([A-Za-z]):\s*(.+)$').firstMatch(line);
      if (match != null) {
        messages.add({
          'senderRole': match.group(1) ?? 'A',
          'content': match.group(2) ?? '',
        });
        continue;
      }
      if (summary == null) {
        summary = line;
      }
    }

    if (messages.isEmpty) return null;
    return {
      'title': title,
      'summary': summary,
      'messages': messages,
    };
  }

  Widget _buildMatchingReviewBody(
    BuildContext context,
    Map<String, dynamic> parsed,
    bool dark,
  ) {
    final theme = Theme.of(context);
    final title = parsed['title']?.toString() ?? '공유된 대화';
    final summary = parsed['summary']?.toString();
    final messages = (parsed['messages'] as List<dynamic>)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    final bubbleOther = dark ? const Color(0xFF374151) : Colors.white;
    final bubbleMine = theme.colorScheme.primary;
    final surface = dark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final border = dark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    Widget maskedAvatar(bool isMine) {
      final bg = isMine
          ? theme.colorScheme.primary.withValues(alpha: 0.18)
          : (dark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade200);
      final fg = isMine
          ? theme.colorScheme.primary
          : (dark ? Colors.white70 : const Color(0xFF6B7280));
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: dark ? Colors.white12 : Colors.white, width: 1.5),
        ),
        child: Icon(LucideIcons.userRound, size: 15, color: fg),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: ThemeController.getHeaderGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.messagesSquare, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '익명 처리된 채팅 기록',
                      style: TextStyle(
                        fontSize: 11,
                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: dark ? Colors.grey.shade300 : const Color(0xFF4B5563),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final message in messages) ...[
                  Builder(
                    builder: (context) {
                      final role = (message['senderRole'] ?? 'A').toUpperCase();
                      final isMine = role == 'A';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMine) ...[
                              maskedAvatar(false),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isMine ? bubbleMine : bubbleOther,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                                    bottomRight: Radius.circular(isMine ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isMine
                                        ? Colors.white
                                        : (dark ? Colors.white : const Color(0xFF111827)),
                                  ),
                                ),
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 8),
                              maskedAvatar(true),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_loading && _post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final post = _post;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('글')),
        body: const Center(child: Text('글을 찾을 수 없어요.')),
      );
    }
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final nickname = author['nickname']?.toString() ?? '알 수 없음';
    final authorId = author['id']?.toString();
    final isPostAuthorMe = _myUserIdResolved != null && authorId != null && authorId == _myUserIdResolved;
    final content = post['content']?.toString() ?? '';
    final likeCount = (post['likeCount'] is int) ? post['likeCount'] as int : 0;
    final viewCount = (post['viewCount'] is int) ? post['viewCount'] as int : 0;
    final liked = post['liked'] == true;
    final isDailyBest = post['isDailyBest'] == true;
    final comments = (post['comments'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final mentionCandidates = _collectMentionCandidates(post, comments);
    final mentionQuery = _extractMentionQuery(_commentController.text);
    final filteredMentions = (mentionQuery == null)
        ? const <String>[]
        : mentionCandidates
            .where((n) => mentionQuery.isEmpty || n.toLowerCase().startsWith(mentionQuery.toLowerCase()))
            .take(6)
            .toList();
    // 루트 댓글 / 답글 구분 (유튜브처럼 답글은 부모 아래 들여쓰기 + 연결선)
    final rootComments = comments.where((c) {
      final pid = c['parentCommentId']?.toString().trim();
      return pid == null || pid.isEmpty;
    }).toList();
    final replyMap = <String, List<Map<String, dynamic>>>{};
    for (final c in comments) {
      final pid = c['parentCommentId']?.toString().trim();
      if (pid != null && pid.isNotEmpty) {
        replyMap.putIfAbsent(pid, () => []).add(Map<String, dynamic>.from(c));
      }
    }
    for (final list in replyMap.values) {
      list.sort((a, b) {
        final aT = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bT = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aT.compareTo(bT);
      });
    }
    final sortedRoots = List<Map<String, dynamic>>.from(rootComments);
    sortedRoots.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final aLike = (a['likeCount'] as int?) ?? 0;
      final bLike = (b['likeCount'] as int?) ?? 0;
      final aReply = (replyMap[a['id']?.toString()]?.length ?? 0);
      final bReply = (replyMap[b['id']?.toString()]?.length ?? 0);
      if (_commentSort == 'likes') {
        if (aLike != bLike) return bLike - aLike;
        return bTime.compareTo(aTime);
      }
      if (_commentSort == 'replies') {
        if (aReply != bReply) return bReply - aReply;
        return bTime.compareTo(aTime);
      }
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '게시글',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deletePost();
              } else if (value == 'report') {
                _showReportSheet(context);
              }
            },
            itemBuilder: (ctx) => [
              if (isPostAuthorMe)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('삭제'),
                ),
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('신고'),
              ),
            ],
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post block (ad: p-5 border-b)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _onAuthorTap(author),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: dark ? Colors.grey.shade600 : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: buildMatchCardAvatar(
                                          isPostAuthorMe && _myProfile != null
                                              ? _myProfile!
                                              : author,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              nickname,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: dark ? Colors.white : const Color(0xFF111827),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatPostTime(post['createdAt']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: dark ? Colors.grey.shade400 : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final parsedReview = post['tag'] == 'matching_review'
                                  ? _parseMatchingReviewContent(content)
                                  : null;
                              if (parsedReview != null) {
                                return _buildMatchingReviewBody(context, parsedReview, dark);
                              }
                              return RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: dark ? Colors.white : const Color(0xFF111827),
                                  ),
                                  children: buildMentionSpans(
                                    content,
                                    baseStyle: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: dark ? Colors.white : const Color(0xFF111827),
                                    ),
                                    mentionColor: dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (post['poll'] != null) ...[
                            const SizedBox(height: 20),
                            _buildPoll(context, post['poll'] as Map<String, dynamic>, dark),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Material(
                                color: liked
                                    ? Colors.transparent
                                    : (dark ? Colors.grey.shade800 : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: _toggleLike,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: liked
                                        ? BoxDecoration(
                                            gradient: ThemeController.getActiveAccentGradient(),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.12),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.heart,
                                          size: 16,
                                          color: liked ? Colors.white : (dark ? Colors.grey.shade400 : Colors.grey.shade600),
                                          fill: liked ? 1.0 : 0,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: liked ? Colors.white : (dark ? Colors.grey.shade400 : Colors.grey.shade600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: dark ? Colors.grey.shade800 : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.messageCircle,
                                      size: 16,
                                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${comments.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: dark ? Colors.grey.shade800 : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.eye,
                                      size: 16,
                                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$viewCount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Comments section (ad: rounded-2xl cards)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '댓글 ${comments.length}개',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              DropdownButton<String>(
                                value: _commentSort,
                                isDense: true,
                                underline: const SizedBox(),
                                iconSize: 18,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'latest',
                                    child: Text('\uCD5C\uC2E0\uC21C', style: TextStyle(fontSize: 11)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'likes',
                                    child: Text('\uC88B\uC544\uC694\uC21C', style: TextStyle(fontSize: 11)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'replies',
                                    child: Text('\uB2F5\uAE00\uB9CE\uC740\uC21C', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _commentSort = v);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...sortedRoots.expand((root) {
                            final replies = replyMap[root['id']?.toString()] ?? [];
                            return [
                              _buildCommentCard(context, root, dark),
                              ...replies.map((reply) => _buildReplyRow(context, reply, dark)),
                            ];
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filteredMentions.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredMentions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final mentionNickname = filteredMentions[index];
                    return ActionChip(
                      label: Text('@$mentionNickname'),
                      onPressed: () => _insertMention(mentionNickname),
                    );
                  },
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1F2937) : Colors.white,
                  border: Border(
                    top: BorderSide(color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dark ? Colors.grey.shade600 : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: buildMatchCardAvatar(
                          _myProfile ??
                              <String, dynamic>{'userId': _myUserIdResolved ?? 'me'},
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          decoration: InputDecoration(
                            hintText: '댓글을 입력하세요...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: _commentController.text.trim().isEmpty
                          ? (dark ? Colors.grey.shade700 : Colors.grey.shade200)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _sendingComment ? null : _sendComment,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: _commentController.text.trim().isNotEmpty
                              ? BoxDecoration(
                                  gradient: ThemeController.getActiveAccentGradient(),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: _sendingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  LucideIcons.send,
                                  size: 20,
                                  color: _commentController.text.trim().isEmpty
                                      ? (dark ? Colors.grey.shade500 : Colors.grey.shade400)
                                      : Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoll(BuildContext context, Map<String, dynamic> poll, bool dark) {
    final question = poll['question']?.toString() ?? '';
    final options = (poll['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final voteCounts = (poll['voteCounts'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? List.filled(options.length, 0);
    final myVote = poll['myVoteOptionIndex'];
    final totalVotes = voteCounts.fold<int>(0, (a, b) => a + b);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.vote, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$totalVotes명 참여',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final count = i < voteCounts.length ? voteCounts[i] : 0;
            final pct = totalVotes > 0 ? (count / totalVotes).clamp(0.0, 1.0) : 0.0;
            final isMyVote = myVote != null && myVote == i;

            if (myVote == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => _voteOption(i),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: Text(options[i]),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            fontSize: 14,
                            color: dark ? Colors.white : Colors.black87,
                            fontWeight: isMyVote ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      Text(
                        '$count표',
                        style: TextStyle(
                          fontSize: 13,
                          color: isMyVote ? primary : Colors.grey.shade600,
                          fontWeight: isMyVote ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(isMyVote ? primary : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 답글 연결선: 세로선 + 답글 세로 중앙에서 곡선으로 꽂음
class _ReplyLinePainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double curveRadius;

  _ReplyLinePainter({
    required this.color,
    this.lineWidth = 2.0,
    this.curveRadius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < curveRadius) return;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(centerX, 0);
    path.lineTo(centerX, centerY);
    path.lineTo(size.width, centerY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

