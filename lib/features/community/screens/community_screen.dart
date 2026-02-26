import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/community/screens/community_post_detail_screen.dart';
import 'package:nearo_app/features/community/screens/community_post_write_screen.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';

/// 학교별 커뮤니티 피드. 누구나 진입 가능.
class CommunityScreen extends StatefulWidget {
  final String environmentId;
  final String schoolName;

  const CommunityScreen({
    super.key,
    required this.environmentId,
    required this.schoolName,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityRepository _repo = CommunityRepository();
  List<Map<String, dynamic>> _posts = [];
  String? _nextCursor;
  String? _myUserId;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
    _load();
  }

  Future<void> _loadMyUserId() async {
    try {
      final res = await AuthRepository().getProfile();
      final user = res['user'] as Map<String, dynamic>?;
      final id = user?['id']?.toString();
      if (mounted) setState(() => _myUserId = id);
    } catch (_) {
      if (mounted) setState(() => _myUserId = null);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getPosts(widget.environmentId, limit: 20);
      if (mounted) {
        setState(() {
          _posts = (data['posts'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
          _nextCursor = data['nextCursor'] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _repo.getPosts(widget.environmentId, cursor: _nextCursor, limit: 20);
      if (mounted) {
        final more = (data['posts'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        setState(() {
          _posts = [..._posts, ...more];
          _nextCursor = data['nextCursor'] as String?;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openWrite() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityPostWriteScreen(
          environmentId: widget.environmentId,
          schoolName: widget.schoolName,
        ),
      ),
    );
    _load();
  }

  void _openPost(Map<String, dynamic> post) {
    Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (_) => CommunityPostDetailScreen(
          environmentId: widget.environmentId,
          schoolName: widget.schoolName,
          postId: post['id'] as String,
          initialPost: post,
          myUserId: _myUserId,
        ),
      ),
    ).then((deleted) {
      _load();
      if (deleted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글이 삭제되었어요.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.schoolName} 커뮤니티'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Icon(LucideIcons.messageSquare, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          '아직 글이 없어요.\n첫 글을 올려보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      itemCount: _posts.length + (_nextCursor != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _posts.length) {
                          _loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final post = _posts[index];
                        final author = post['author'] as Map<String, dynamic>? ?? {};
                        final nickname = author['nickname']?.toString() ?? '알 수 없음';
                        final authorId = author['id']?.toString();
                        final isMe = _myUserId != null && authorId == _myUserId;
                        final isDailyBest = post['isDailyBest'] == true;
                        final content = post['content']?.toString() ?? '';
                        final likeCount = (post['likeCount'] is int) ? post['likeCount'] as int : 0;
                        final commentCount = (post['commentCount'] is int) ? post['commentCount'] as int : 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _openPost(post),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      DiceBearAvatar(
                                        style: author['avatarStyle']?.toString() ?? 'notionists',
                                        seed: author['avatarSeed']?.toString() ?? nickname,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                nickname,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                            if (isDailyBest) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  '일간 베스트',
                                                  style: TextStyle(
                                                    fontSize: 11,
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
                                  const SizedBox(height: 12),
                                  Text(
                                    content,
                                    style: TextStyle(fontSize: 15, color: dark ? Colors.white : Colors.black87),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.heart, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('$likeCount', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      const SizedBox(width: 16),
                                      Icon(LucideIcons.messageCircle, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('$commentCount', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openWrite,
        child: const Icon(LucideIcons.pencil),
      ),
    );
  }
}
