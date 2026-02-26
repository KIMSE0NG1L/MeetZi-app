import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/messages/data/report_repository.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:share_plus/share_plus.dart';

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
  Map<String, dynamic>? _post;
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = Map<String, dynamic>.from(widget.initialPost!);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getPost(widget.environmentId, widget.postId);
      if (mounted) setState(() {
        _post = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    try {
      final res = await _repo.toggleLike(widget.environmentId, widget.postId);
      final liked = res['liked'] as bool? ?? false;
      final prevCount = (_post!['likeCount'] is int) ? _post!['likeCount'] as int : 0;
      if (mounted) {
        setState(() {
          _post = Map<String, dynamic>.from(_post!)..['liked'] = liked..['likeCount'] = prevCount + (liked ? 1 : -1);
        });
      }
    } catch (_) {}
  }

  Future<void> _share() async {
    try {
      await Share.share(
        (_post?['content']?.toString() ?? '').replaceAll('\n', ' '),
        subject: '${widget.schoolName} 커뮤니티 글',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유하기를 지원하지 않는 환경이에요.')),
        );
      }
    }
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

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await _repo.createComment(widget.environmentId, widget.postId, content);
      _commentController.clear();
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
    final isPostAuthorMe = widget.myUserId != null && authorId == widget.myUserId;
    final content = post['content']?.toString() ?? '';
    final likeCount = (post['likeCount'] is int) ? post['likeCount'] as int : 0;
    final liked = post['liked'] == true;
    final isDailyBest = post['isDailyBest'] == true;
    final comments = (post['comments'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('글'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: _share,
            tooltip: '공유',
          ),
          if (isPostAuthorMe)
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              onPressed: _deletePost,
              tooltip: '삭제',
            ),
          if (!isPostAuthorMe)
            IconButton(
              icon: const Icon(LucideIcons.flag),
              onPressed: () => _showReportSheet(context),
              tooltip: '신고',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DiceBearAvatar(
                        style: author['avatarStyle']?.toString() ?? 'notionists',
                        seed: author['avatarSeed']?.toString() ?? nickname,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                nickname,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPostAuthorMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '작성자',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                            if (isDailyBest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '일간 베스트',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: TextStyle(fontSize: 16, height: 1.5, color: dark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                liked ? LucideIcons.heart : LucideIcons.heart,
                                size: 22,
                                color: liked ? Colors.red : Colors.grey.shade600,
                                fill: liked ? 1.0 : 0,
                              ),
                              const SizedBox(width: 6),
                              Text('$likeCount', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.messageCircle, size: 22, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text('${comments.length}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('댓글 ${comments.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...comments.map((c) {
                    final ca = c['author'] as Map<String, dynamic>? ?? {};
                    final cn = ca['nickname']?.toString() ?? '알 수 없음';
                    final cAuthorId = ca['id']?.toString();
                    final isCommentAuthorMe = widget.myUserId != null && cAuthorId == widget.myUserId;
                    final ct = c['content']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DiceBearAvatar(
                            style: ca['avatarStyle']?.toString() ?? 'notionists',
                            seed: ca['avatarSeed']?.toString() ?? cn,
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(cn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    ),
                                    if (isCommentAuthorMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '작성자',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(ct, style: TextStyle(fontSize: 14, color: dark ? Colors.white70 : Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendingComment ? null : _sendComment,
                    icon: _sendingComment
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
