import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/community/screens/community_post_detail_screen.dart';
import 'package:nearo_app/features/community/screens/community_post_write_screen.dart';
import 'package:nearo_app/features/shared_chat/screens/shared_chat_requests_screen.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';
import 'package:nearo_app/features/matching_board/utils/board_note_sheet_launcher.dart';
import 'package:nearo_app/features/matching_board/widgets/match_card_avatar.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/post_time_format.dart';
import 'package:nearo_app/shared/utils/mention_text_span.dart';

/// ?숆탳蹂?而ㅻ??덊떚 ?쇰뱶 ?붾㈃
class CommunityScreen extends StatefulWidget {
  final String environmentId;
  final String schoolName;

  const CommunityScreen({
    super.key,
    required this.environmentId,
    required this.schoolName,
    this.isRootTab = false,
  });

  /// true硫?猷⑦듃 ??쑝濡??ъ슜(?ㅻ줈媛湲?????곷떒 ?쇱そ ?щ갚).
  final bool isRootTab;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const List<MapEntry<String, String>> _tabs = [
    MapEntry('all', '\uC804\uCCB4'),
    MapEntry('free', '\uC790\uC720'),
    MapEntry('love', '\uC5F0\uC560\u00B7\uC378'),
    MapEntry('matching_review', '\uC18C\uAC1C\uD305\u00B7\uB9E4\uCE6D\uD6C4\uAE30'),
    MapEntry('counsel', '\uACE0\uBBFC\uC0C1\uB2F4'),
    MapEntry('meme', '\uC720\uBA38\u00B7\uBC08'),
  ];

  final CommunityRepository _repo = CommunityRepository();
  final MatchingBoardRepository _matchingRepo = MatchingBoardRepository();
  List<Map<String, dynamic>> _posts = [];
  String? _nextCursor;
  String? _myUserId;
  bool _loading = true;
  bool _loadingMore = false;
  String _selectedTag = 'all';
  String _selectedScope = ''; // 기본: 체크 없음, 전체(태그) 피드

  bool get _isGlobalCommunity =>
      widget.environmentId == CommunityRepository.globalEnvironmentId;

  String get _communityTitle =>
      _isGlobalCommunity ? '커뮤니티' : '${widget.schoolName} 커뮤니티';

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
    _load();
  }

  Future<void> _loadMyUserId() async {
    try {
      final res = await AuthRepository().getProfile();
      // GET /users/me ??user 媛앹껜瑜?洹몃?濡?諛섑솚?쒕떎.
      final id = (res['user'] as Map<String, dynamic>?)?['id']?.toString() ?? res['id']?.toString();
      if (mounted) setState(() => _myUserId = id);
    } catch (_) {
      if (mounted) setState(() => _myUserId = null);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getPosts(
        widget.environmentId,
        tag: _selectedTag,
        scope: _selectedScope,
        limit: 20,
      );
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
      final data = await _repo.getPosts(
        widget.environmentId,
        cursor: _nextCursor,
        tag: _selectedTag,
        scope: _selectedScope,
        limit: 20,
      );
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
          initialTag: _selectedTag == 'all' ? 'free' : _selectedTag,
        ),
      ),
    );
    _load();
  }

  void _openPost(Map<String, dynamic> post) {
    final postId = post['id']?.toString();
    if (postId == null || postId.isEmpty) return;
    Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (_) => CommunityPostDetailScreen(
          environmentId: widget.environmentId,
          schoolName: widget.schoolName,
          postId: postId,
          initialPost: post,
          myUserId: _myUserId,
        ),
      ),
    ).then((deleted) {
      _load();
      if (deleted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글을 삭제했어요')),
        );
      }
    });
  }

  Future<void> _onAuthorTap(Map<String, dynamic> author) async {
    final userId = author['id']?.toString();
    if (userId == null || userId.isEmpty || !mounted) return;
    if (_myUserId != null && _myUserId == userId) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('알림'),
          content: const Text('내 프로필입니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
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

  Future<void> _showDeleteConfirm(BuildContext context, Map<String, dynamic> post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('글 삭제'),
        content: const Text('이 글을 삭제할까요? 삭제한 글은 복구할 수 없어요.'),
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
      await _repo.deletePost(widget.environmentId, post['id'] as String);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글을 삭제했어요')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('403') || e.toString().contains('Forbidden')
                  ? '본인 글만 삭제할 수 있어요'
                  : '삭제에 실패했어요. 잠시 후 다시 시도해 주세요.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post, int index) async {
    final postId = post['id'] as String?;
    if (postId == null) return;
    final prevLiked = post['liked'] == true;
    final prevCount = (post['likeCount'] is int) ? post['likeCount'] as int : 0;
    setState(() {
      _posts[index] = Map<String, dynamic>.from(post)
        ..['liked'] = !prevLiked
        ..['likeCount'] = prevCount + (prevLiked ? -1 : 1);
    });
    try {
      final res = await _repo.toggleLike(widget.environmentId, postId);
      final liked = res['liked'] as bool? ?? !prevLiked;
      if (mounted) {
        setState(() {
          _posts[index] = Map<String, dynamic>.from(_posts[index])
            ..['liked'] = liked
            ..['likeCount'] = (liked ? prevCount + 1 : prevCount - 1);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts[index] = Map<String, dynamic>.from(_posts[index])
            ..['liked'] = prevLiked
            ..['likeCount'] = prevCount;
        });
      }
    }
  }

  String _tagLabel(String? tag) {
    switch (tag) {
      case 'free':
        return '\uC790\uC720';
      case 'love':
        return '\uC5F0\uC560\u00B7\uC378';
      case 'matching_review':
        return '\uC18C\uAC1C\uD305\u00B7\uB9E4\uCE6D\uD6C4\uAE30';
      case 'counsel':
        return '\uACE0\uBBFC\uC0C1\uB2F4';
      case 'meme':
        return '\uC720\uBA38\u00B7\uBC08';
      default:
        return '\uC790\uC720';
    }
  }

  IconData _tabIcon(String tag) {
    switch (tag) {
      case 'all':
        return LucideIcons.layoutGrid;
      case 'free':
        return LucideIcons.messageSquare;
      case 'love':
        return LucideIcons.heart;
      case 'matching_review':
        return LucideIcons.sparkles;
      case 'counsel':
        return LucideIcons.handHeart;
      case 'meme':
        return LucideIcons.laugh;
      default:
        return LucideIcons.messageSquare;
    }
  }

  Widget _buildBottomTagBar(bool dark) {
    final bgColor = dark ? const Color(0xFF111827) : Colors.white;
    final borderColor = dark ? Colors.grey.shade800 : Colors.grey.shade200;
    final activeColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabs.map((tab) {
              final selected = _selectedTag == tab.key;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (_selectedTag == tab.key) return;
                    setState(() => _selectedTag = tab.key);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? activeColor.withOpacity(0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? activeColor : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tabIcon(tab.key),
                          size: 14,
                          color: selected ? activeColor : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? activeColor : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildScopeBar(bool dark) {
    const scopes = <MapEntry<String, String>>[
      MapEntry('my_posts', '\uB0B4 \uAE00'),
      MapEntry('my_comments', '\uB0B4 \uB313\uAE00'),
    ];
    final activeColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8,
        children: scopes.map((scope) {
          final selected = _selectedScope == scope.key;
          return ChoiceChip(
            label: Text(scope.value),
            selected: selected,
            onSelected: (_) {
              if (_selectedScope == scope.key) {
                // 媛숈? 移??ㅼ떆 ?????닿?/?대뙎湲 ?꾪꽣 ?댁젣 ???섎떒 ???쒓렇) 湲곗? ?쇰뱶濡?
                setState(() => _selectedScope = '');
                _load();
                return;
              }
              setState(() => _selectedScope = scope.key);
              _load();
            },
            selectedColor: activeColor.withOpacity(0.2),
            backgroundColor: dark ? Colors.grey.shade800 : Colors.grey.shade100,
            side: BorderSide(
              color: selected ? activeColor : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? activeColor : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = ThemeController.getHeaderGradient();
    final accentGradient = ThemeController.getActiveAccentGradient();
    final primary = Theme.of(context).colorScheme.primary;
    // ?꾩껜(?쒓렇) ?쇰뱶???뚮쭔 踰좎뒪??HOT ?곷떒 ?몄텧 (내 글쨌내 댓글 ?꾪꽣 以묒뿉??誘몃끂異?
    final showBest = _selectedScope.isEmpty;
    final sortedByLikes = List<Map<String, dynamic>>.from(_posts)
      ..sort((a, b) => ((b['likeCount'] as int?) ?? 0).compareTo((a['likeCount'] as int?) ?? 0));
    final bestPosts = showBest ? sortedByLikes.take(3).toList() : <Map<String, dynamic>>[];
    final bestIds = bestPosts.map((e) => e['id']).toSet();
    final regularPosts = _posts.where((p) => !bestIds.contains(p['id'])).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: Column(
          children: [
          // 헤더
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: headerGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    if (widget.isRootTab)
                      const SizedBox(width: 48)
                    else
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Expanded(
                      child: Text(
                        _communityTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.messagesSquare, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SharedChatRequestsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageSquare, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '아직 글이 없어요\n첫 글을 올려보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                          children: [
                            _buildScopeBar(dark),
                            if (bestPosts.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '베스트 글',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: dark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...bestPosts.asMap().entries.map((entry) {
                                final rank = entry.key + 1;
                                final post = entry.value;
                                final indexInPosts = _posts.indexWhere((p) => p['id'] == post['id']);
                                return _buildPostCardInner(
                                  context,
                                  post,
                                  dark,
                                  indexInPosts >= 0 ? indexInPosts : 0,
                                  isBest: true,
                                  bestRank: rank,
                                );
                              }),
                              const SizedBox(height: 24),
                              Divider(height: 1, color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              _selectedScope == 'my_posts'
                                  ? '내 글'
                                  : _selectedScope == 'my_comments'
                                      ? '내 댓글'
                                      : _tabs.firstWhere((t) => t.key == _selectedTag, orElse: () => _tabs.first).value,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...regularPosts.map((post) {
                              final indexInPosts = _posts.indexWhere((p) => p['id'] == post['id']);
                              return _buildPostCardInner(
                                context,
                                post,
                                dark,
                                indexInPosts >= 0 ? indexInPosts : 0,
                                isBest: false,
                              );
                            }),
                            if (_nextCursor != null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _loadingMore
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : TextButton(
                                          onPressed: _loadMore,
                                          child: const Text('더보기'),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    ),  // body Container
      floatingActionButton: Container(
        width: 56,
        height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: accentGradient,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openWrite,
            customBorder: const CircleBorder(),
            child: const Center(
              child: Icon(LucideIcons.squarePen, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomTagBar(dark),
    );
  }

  Widget _buildPostCardInner(
    BuildContext context,
    Map<String, dynamic> post,
    bool dark,
    int index, {
    required bool isBest,
    int? bestRank,
  }) {
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final nickname = author['nickname']?.toString() ?? '이름 없음';
    final authorId = author['id']?.toString();
    final isMe = _myUserId != null && authorId == _myUserId;
    final isDailyBest = post['isDailyBest'] == true;
    final tagLabel = _tagLabel(post['tag']?.toString());
    final content = post['content']?.toString() ?? '';
    final likeCount = (post['likeCount'] is int) ? post['likeCount'] as int : 0;
    final commentCount = (post['commentCount'] is int) ? post['commentCount'] as int : 0;
    final viewCount = (post['viewCount'] is int) ? post['viewCount'] as int : 0;
    final liked = post['liked'] == true;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        top: (isBest && bestRank != null) ? 4 : 0,
        left: (isBest && bestRank != null) ? 12 : 0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: dark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: isBest ? 2 : 1,
            shadowColor: isBest ? primary.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            child: Container(
              decoration: isBest
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withOpacity(0.5), width: 2),
                    )
                  : null,
              child: InkWell(
                onTap: () => _openPost(post),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _onAuthorTap(author),
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: buildMatchCardAvatar(author, size: 34),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                    if (isBest) const SizedBox(width: 4),
                                    if (isBest) const Text('BEST', style: TextStyle(fontSize: 12)),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '작성자',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isDailyBest) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'HOT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  formatPostTime(post['createdAt']),
                                  style: TextStyle(fontSize: 11, color: dark ? Colors.grey.shade500 : Colors.grey.shade400),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tagLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: dark ? Colors.grey.shade200 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                            height: 1.25,
                          ),
                          children: buildMentionSpans(
                            content,
                            baseStyle: TextStyle(
                              fontSize: 13,
                              color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                              height: 1.25,
                            ),
                            mentionColor: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      if (post['poll'] != null) ...[
                        const SizedBox(height: 6),
                        _buildPollChip(context, post['poll'] as Map<String, dynamic>, dark),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Material(
                            color: liked
                                ? null
                                : (dark ? Colors.grey.shade700 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _toggleLike(post, index),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                                      size: 14,
                                      color: liked ? Colors.white : (dark ? Colors.grey.shade300 : Colors.grey.shade600),
                                      fill: liked ? 1.0 : 0,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$likeCount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: liked ? Colors.white : (dark ? Colors.grey.shade300 : Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.messageCircle, size: 14, color: dark ? Colors.grey.shade300 : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '$commentCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dark ? Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.eye, size: 14, color: dark ? Colors.grey.shade300 : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '$viewCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dark ? Colors.grey.shade300 : Colors.grey.shade600,
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
              ),
            ),
          ),
          if (isBest && bestRank != null)
            Positioned(
              top: -8,
              left: -8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: bestRank == 1
                        ? [const Color(0xFFFACC15), const Color(0xFFEAB308)]
                        : bestRank == 2
                            ? [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)]
                            : [const Color(0xFFFB923C), const Color(0xFFEA580C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$bestRank',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPollChip(BuildContext context, Map<String, dynamic> poll, bool dark) {
    final question = poll['question']?.toString() ?? '투표';
    final voteCounts = (poll['voteCounts'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [];
    final total = voteCounts.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (dark ? Colors.grey.shade700 : Colors.grey.shade200).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.vote, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              question,
              style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$total명 참여',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}







