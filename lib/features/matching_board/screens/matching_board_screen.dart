import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';

class MatchingBoardScreen extends StatelessWidget {
  const MatchingBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MatchingBoardScreenBody();
  }
}

class _MatchingBoardScreenBody extends StatefulWidget {
  @override
  State<_MatchingBoardScreenBody> createState() => _MatchingBoardScreenBodyState();
}

class _MatchingBoardScreenBodyState extends State<_MatchingBoardScreenBody> {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = false;
  int _profileViewCount = 0;
  DateTime? _lastViewTime;
  int? _myCredit;
  int? _flippedIndex; // 추가: 현재 플립된 카드 인덱스
  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    _fetchMyCredit();
  }

  Future<void> _fetchMyCredit() async {
    try {
      final credit = await _repository.fetchMyCredit();
      setState(() => _myCredit = credit);
    } catch (_) {
      setState(() => _myCredit = null);
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() => _loading = true);
    try {
      final profiles = await _repository.fetchProfiles();
      setState(() => _profiles = profiles);
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registerProfile() async {
    try {
      // 내 프로필 정보 가져오기
      final authRepo = AuthRepository();
      final profile = await authRepo.getProfile();
      final nickname = profile['nickname'];
      final gender = profile['gender'];
      String school = profile['school'] ?? profile['affiliationText'] ?? '세종대';
      final department = profile['department']?.toString();
      final userEnvs = profile['userEnvironments'];
      // TODO: 프로필 등록 로직 구현
    } catch (e) {
      // TODO: 에러 처리
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

  Widget _buildBoardAvatar(BuildContext context, Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final seed = user?['avatarSeed']?.toString() ?? profile['userId']?.toString();
    final options = _parseAvatarOptions(user?['avatarOptions']);
    if (seed != null && seed.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: SvgPicture.network(
            diceBearAvatarUrl(seed, options: options.isNotEmpty ? options : null),
            fit: BoxFit.cover,
            width: 64,
            height: 64,
            placeholderBuilder: (context) => Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthRepository().getProfile(),
      builder: (context, snapshot) {
        final myUserId = snapshot.data?['id'];
        return Scaffold(
          backgroundColor: Colors.white,
          body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.57,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _profiles.length,
                            itemBuilder: (context, index) {
                              final profile = _profiles[index];
                              final isMe = myUserId != null && profile['userId'] == myUserId;
                              return _FlipCard(
                                flipped: _flippedIndex == index,
                                front: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isMe ? null : () async {
                                      setState(() => _flippedIndex = index);
                                      await Future.delayed(const Duration(milliseconds: 350));
                                      _openNoteSheet(context, index, myUserId);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.18),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.10),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color: Colors.brown.withOpacity(0.06),
                                            blurRadius: 2,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            _buildBoardAvatar(context, profile),
                                            const SizedBox(height: 14),
                                            Text(
                                              isMe ? '나' : (profile['nickname'] ?? ''),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              isMe ? '' : ((profile['idealType'] ?? (profile['user'] as Map<String, dynamic>?)?['idealType'])?.toString() ?? '-'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                back: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.18),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(Icons.info_outline, size: 40, color: Colors.grey[400]),
                                  ),
                                ),
                                onFlipBack: () => setState(() => _flippedIndex = null)
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: SizedBox(
                            width: 180,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _registerProfile,
                              icon: const Icon(Icons.add),
                              label: const Text('등록'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            _buildBoardAvatar(context, profile),
                                            const SizedBox(height: 14),
                                            Text(
                                              isMe ? '나' : (profile['nickname'] ?? ''),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              isMe ? '' : ((profile['idealType'] ?? (profile['user'] as Map<String, dynamic>?)?['idealType'])?.toString() ?? '-'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                back: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.18),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(Icons.info_outline, size: 40, color: Colors.grey[400]),
                                  ),
                                ),
                                onFlipBack: () => setState(() => _flippedIndex = null)
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: SizedBox(
                            width: 180,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _registerProfile,
                              icon: const Icon(Icons.add),
                              label: const Text('등록'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
  }

Future<BoxDecoration> _corkBoardDecoration() async {
  try {
    await rootBundle.load('assets/images/cork_board.png');
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/cork_board.png'),
        fit: BoxFit.cover,
      ),
    );
  } catch (_) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFD4B896),
          const Color(0xFFC4A574),
          const Color(0xFFB8956A),
        ],
      ),
    );
  }
}

class _BoardNoteSheetContent extends StatefulWidget {
  const _BoardNoteSheetContent({
    required this.profiles,
    required this.startIndex,
    required this.buildAvatar,
    required this.onTakeNote,
    required this.onPop,
  });

  final List<Map<String, dynamic>> profiles;
  final int startIndex;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  final Future<void> Function(String profileId) onTakeNote;
  final VoidCallback onPop;

  @override
  State<_BoardNoteSheetContent> createState() => _BoardNoteSheetContentState();
}

class _BoardNoteSheetContentState extends State<_BoardNoteSheetContent> {
  late int _currentIndex;
  bool _taking = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
  }

  Map<String, dynamic> get _profile => widget.profiles[_currentIndex];
  Map<String, dynamic>? get _user => _profile['user'] as Map<String, dynamic>?;

  void _skip() {
    if (_currentIndex + 1 < widget.profiles.length) {
      setState(() => _currentIndex++);
    } else {
      Navigator.of(context).pop();
      widget.onPop();
    }
  }

  Future<void> _take() async {
    if (_taking) return;
    setState(() => _taking = true);
    try {
      await widget.onTakeNote(_profile['id'] as String);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPop();
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  static String _str(dynamic v) => v?.toString() ?? '-';

  /// 프로필 수정 입력란과 동일한 한국어 라벨로 표시
  static String _toLabel(String? field, dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return '-';
    switch (field) {
      case 'gender':
        switch (s.toLowerCase()) {
          case 'male': return '남성';
          case 'female': return '여성';
          default: return s;
        }
      case 'gradeYear':
        switch (s.toLowerCase()) {
          case 'one': return '1';
          case 'two': return '2';
          case 'three': return '3';
          case 'four': return '4';
          case 'five': return '5';
          case 'graduation_deferred': return '졸업유예';
          default: return s;
        }
      case 'smoking':
        switch (s.toLowerCase()) {
          case 'none': return '비흡연';
          case 'sometimes': return '가끔';
          case 'often': return '자주';
          default: return s;
        }
      case 'drinking':
        switch (s.toLowerCase()) {
          case 'none': return '안 함';
          case 'sometimes': return '가끔';
          case 'often': return '자주';
          default: return s;
        }
      case 'fashionStyle':
        switch (s.toLowerCase()) {
          case 'hood_casual': return '후드/캐주얼';
          case 'shirt_neat': return '셔츠/단정';
          case 'street': return '스트릿';
          case 'knit': return '니트/감성';
          case 'sporty': return '체육복/스포티';
          case 'minimal': return '미니멀';
          case 'hip': return '힙한';
          default: return s;
        }
      case 'preferredDateType':
        switch (s.toLowerCase()) {
          case 'cafe': return '카페 탐방';
          case 'walk': return '산책';
          case 'movie': return '영화';
          case 'drink': return '술 한잔';
          case 'exercise': return '운동';
          case 'food_tour': return '맛집 투어';
          case 'drive': return '드라이브';
          default: return s;
        }
      case 'activityTime':
        switch (s.toLowerCase()) {
          case 'morning': return '아침형';
          case 'daytime': return '낮 활동형';
          case 'evening': return '저녁형';
          case 'night_owl': return '야행성';
          default: return s;
        }
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile;
    final user = _user;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Column(
                  key: ValueKey<int>(_currentIndex),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.buildAvatar(context, profile),
                    const SizedBox(height: 16),
                    Text(_str(profile['nickname']), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _row(theme, '학과', _str(profile['department'] ?? user?['department'])),
                    _row(theme, '성별', _toLabel('gender', profile['gender'] ?? user?['gender'])),
                    _row(theme, '소속', _str(user?['affiliationText'])),
                    _row(theme, '키', user?['heightCm'] != null ? '${user!['heightCm']} cm' : '-'),
                    _row(theme, '학년', _toLabel('gradeYear', user?['gradeYear'])),
                    _row(theme, 'MBTI', _str(user?['mbti'])),
                    _row(theme, '흡연', _toLabel('smoking', user?['smoking'])),
                    _row(theme, '음주', _toLabel('drinking', user?['drinking'])),
                    _row(theme, '한 줄 소개', _str(user?['introOneLine'])),
                    _row(theme, '요즘 빠진 것', _str(user?['intoLately'])),
                    _row(theme, '이상형', _str(user?['idealType'])),
                    _row(theme, '패션 스타일', _toLabel('fashionStyle', user?['fashionStyle'])),
                    _row(theme, '선호 데이트', _toLabel('preferredDateType', user?['preferredDateType'])),
                    _row(theme, '활동 시간대', _toLabel('activityTime', user?['activityTime'])),
                    if (user?['idealTypeKeywords'] is List)
                      _row(theme, '나를 소개하는 키워드', (user!['idealTypeKeywords'] as List).join(', ')),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _taking ? null : _skip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_currentIndex + 1 < widget.profiles.length ? '넘기기' : '닫기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _taking ? null : _take,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _taking ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('가져가기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// 카드 플립 애니메이션 위젯
class _FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool flipped;
  final VoidCallback? onFlipBack;
  const _FlipCard({required this.front, required this.back, required this.flipped, this.onFlipBack, Key? key}) : super(key: key);
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _wasFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipped && !_wasFlipped) {
      _controller.forward();
      _wasFlipped = true;
    } else if (!widget.flipped && _wasFlipped) {
      _controller.reverse();
      _wasFlipped = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isFront = _animation.value < 0.5;
        final angle = _animation.value * pi;
        return GestureDetector(
          onTap: () {
            if (!widget.flipped && widget.onFlipBack != null) widget.onFlipBack!();
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: widget.back,
                  ),
          ),
        );
      },
    );
  }
}
