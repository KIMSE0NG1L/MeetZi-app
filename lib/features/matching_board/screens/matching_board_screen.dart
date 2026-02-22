import 'dart:convert';

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
      final authRepo = AuthRepository();
      final profile = await authRepo.getProfile();
      final nickname = profile['nickname'];
      final gender = profile['gender'];
      String school = profile['school'] ?? profile['affiliationText'] ?? '세종대';
      final department = profile['department']?.toString();
      final userEnvs = profile['userEnvironments'];
      if (school.isEmpty && userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
        final env = userEnvs[0]['environment'];
        if (env != null && env['name'] != null) school = env['name'];
      }
      if (school.isEmpty) school = '세종대';
      if (nickname == null || gender == null || school == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 정보가 없습니다.')));
        return;
      }
      final payload = <String, dynamic>{
        'nickname': nickname,
        'gender': gender,
        'school': school,
      };
      if (department != null && department.isNotEmpty) payload['department'] = department;
      await _repository.registerProfile(payload);
      await _fetchProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 완료')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 실패')));
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

  static const _rose = Color(0xFFF43F5E);
  static const _blueGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return FutureBuilder<Map<String, dynamic>>(
      future: AuthRepository().getProfile(),
      builder: (context, snapshot) {
        final raw = snapshot.data;
        final Map<String, dynamic>? profileData = raw != null && raw is Map<String, dynamic>
            ? (raw['user'] as Map<String, dynamic>?) ?? raw
            : null;
        final myUserId = profileData?['id']?.toString() ?? raw?['id']?.toString();
        final myNickname = profileData?['nickname']?.toString() ?? raw?['nickname']?.toString() ?? '나';
        final meProfile = profileData != null
            ? {'user': profileData, 'userId': myUserId, 'nickname': myNickname}
            : null;

        return Scaffold(
          backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Column(
                      children: [
                        // AppDesign 스탯 바: 내 아바타 + 닉네임 + 남자 게시판 버튼
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Material(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.06),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (meProfile != null)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFECDD3), width: 2),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                                      ),
                                      child: ClipOval(
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: 64,
                                            height: 64,
                                            child: _buildBoardAvatar(context, meProfile),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade300, child: Icon(Icons.person, color: Colors.grey.shade600)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      myNickname,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('남자 게시판은 준비 중이에요')),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: _blueGradient,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        child: const Text('남자 게시판 →', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _profiles.length,
                              itemBuilder: (context, index) {
                                final profile = _profiles[index];
                                final isMe = myUserId != null && profile['userId'] == myUserId;
                                final tag = isMe ? '' : ((profile['idealType'] ?? (profile['user'] as Map<String, dynamic>?)?['idealType'])?.toString() ?? '-');
                                // AppDesign 스타일: 단순 카드, 탭 시 프로필 상세(노트 시트)만 열기
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isMe ? null : () => _openNoteSheet(context, index, myUserId),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: surface,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: dark ? Colors.grey.shade700 : const Color(0xFFF3F4F6), width: 2),
                                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                                              ),
                                              child: _buildBoardAvatar(context, profile),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              isMe ? '나' : (profile['nickname'] ?? ''),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (tag.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                tag,
                                                style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                    // AppDesign FAB 등록
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Center(
                        child: Material(
                          color: const Color(0xFFFB7185),
                          borderRadius: BorderRadius.circular(999),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.25),
                          child: InkWell(
                            onTap: _registerProfile,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  const Text('등록', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _openNoteSheet(BuildContext context, int startIndex, String? myUserId) {
    final others = myUserId != null
        ? _profiles.where((p) => p['userId'] != myUserId).toList()
        : List<Map<String, dynamic>>.from(_profiles);
    final tappedProfile = startIndex < _profiles.length ? _profiles[startIndex] : null;
    final startInOthers = tappedProfile != null ? others.indexWhere((p) => p['id'] == tappedProfile['id']) : 0;
    final initialIndex = startInOthers >= 0 ? startInOthers : 0;
    if (others.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BoardNoteSheetContent(
        profiles: others,
        startIndex: initialIndex,
        buildAvatar: _buildBoardAvatar,
        onTakeNote: _takeNote,
        onPop: _fetchProfiles,
        myCredit: _myCredit,
        onRefreshCredit: _fetchMyCredit,
      ),
    );
  }

  Future<void> _takeNote(String profileId) async {
    // 코인 체크
    if (_myCredit == null || _myCredit! <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코인이 부족합니다. 코인을 충전해주세요.')),
      );
      return;
    }
    
    try {
      await _repository.takeNote(profileId);
      await _fetchProfiles();
      await _fetchMyCredit(); // 코인 갱신
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가져가기 완료! 매칭이 성사되었어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }
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
    this.myCredit,
    this.onRefreshCredit,
    this.showTakeButton = true,
    this.showHabits = true,
  });

  final List<Map<String, dynamic>> profiles;
  final int startIndex;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  final Future<void> Function(String profileId) onTakeNote;
  final VoidCallback onPop;
  final int? myCredit;
  final Future<void> Function()? onRefreshCredit;
  final bool showTakeButton;
  final bool showHabits;

  @override
  State<_BoardNoteSheetContent> createState() => _BoardNoteSheetContentState();
}

class _BoardNoteSheetContentState extends State<_BoardNoteSheetContent> {
  late int _currentIndex;
  bool _taking = false;
  bool _animating = false;
  double _cardScale = 1.0;
  Offset _cardOffset = Offset.zero;
  final GlobalKey _cardKey = GlobalKey();

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
    if (_taking || _animating) return;
    
    // 코인 체크
    if (widget.myCredit == null || widget.myCredit! <= 0) {
      if (!mounted) return;
      // ModalBottomSheet 위에 표시되도록 root navigator의 context 사용
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('코인이 부족합니다. 코인을 충전해주세요.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() => _taking = true);
    // 1. 카드 shrink/move 애니메이션 시작
    setState(() => _animating = true);
    // 메시지함 위치(예시: 화면 우측 하단) 계산
    final RenderBox? cardBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Overlay.of(context)?.context.findRenderObject() as RenderBox?;
    Offset target = Offset.zero;
    if (cardBox != null && overlay != null) {
      final cardPos = cardBox.localToGlobal(Offset.zero, ancestor: overlay);
      final cardSize = cardBox.size;
      // 메시지함 위치: 우측 하단 32, 32 기준
      final screenSize = overlay.size;
      target = Offset(screenSize.width - cardPos.dx - cardSize.width / 2 - 32, screenSize.height - cardPos.dy - cardSize.height / 2 - 32);
    }
    // 애니메이션 실행
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 10)),
      Future(() async {
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 10));
          setState(() {
            _cardScale = 1.0 - 0.03 * i;
            _cardOffset = Offset(target.dx * (i + 1) / 20, target.dy * (i + 1) / 20);
          });
        }
      })
    ]);
    // 2. 실제 데이터 처리
    await widget.onTakeNote(_profile['id'] as String);
    // 코인 갱신
    if (widget.onRefreshCredit != null) {
      await widget.onRefreshCredit!();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onPop();
    setState(() {
      _animating = false;
      _cardScale = 1.0;
      _cardOffset = Offset.zero;
    });
    setState(() => _taking = false);
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

    dynamic pluck(List<String> keys) {
      for (final k in keys) {
        final v1 = profile[k];
        if (v1 != null && v1.toString().trim().isNotEmpty) return v1;
        final v2 = user?[k];
        if (v2 != null && v2.toString().trim().isNotEmpty) return v2;
      }
      return null;
    }

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
                    AnimatedContainer(
                      key: _cardKey,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      transform: Matrix4.identity()
                        ..translate(_cardOffset.dx, _cardOffset.dy)
                        ..scale(_cardScale),
                      child: widget.buildAvatar(context, profile),
                    ),
                    const SizedBox(height: 16),
                    Text(_str(profile['nickname']), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _row(theme, '학과', _str(pluck(['department', 'major', 'departmentName']))),
                    _row(theme, '성별', _toLabel('gender', pluck(['gender', 'sex'])?.toString())),
                    _row(theme, '소속', _str(pluck(['affiliation', 'school', 'affiliationText', 'organization']))),
                    _row(theme, '키', pluck(['heightCm', 'height']) != null ? '${pluck(['heightCm', 'height'])} cm' : '-'),
                    _row(theme, '학년', _toLabel('gradeYear', pluck(['grade', 'year', 'schoolYear', 'class']) )),
                    _row(theme, 'MBTI', _str(pluck(['mbti', 'mbtiType']))),
                    if (widget.showHabits) _row(theme, '흡연', _toLabel('smoking', pluck(['smoking', 'smoke'])?.toString())),
                    if (widget.showHabits) _row(theme, '음주', _toLabel('drinking', pluck(['drinking', 'alcohol'])?.toString())),
                    _row(theme, '한 줄 소개', _str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction']))),
                    _row(theme, '요즘 빠진 것', _str(pluck(['intoLately', 'hobby', 'recentInterest']))),
                    _row(theme, '이상형', _str(pluck(['idealType', 'ideal']))),
                    _row(theme, '패션 스타일', _toLabel('fashionStyle', pluck(['fashionStyle', 'style']))),
                    _row(theme, '선호 데이트', _toLabel('preferredDateType', pluck(['preferredDateType', 'preferredDate']))),
                    _row(theme, '활동 시간대', _toLabel('activityTime', pluck(['activityTime', 'activeTime']))),
                    if ((pluck(['idealTypeKeywords']) is List) || (user?['idealTypeKeywords'] is List))
                      _row(theme, '나를 소개하는 키워드', ((pluck(['idealTypeKeywords']) ?? user?['idealTypeKeywords']) as List).join(', ')),
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
                      onPressed: _taking || _animating ? null : _skip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_currentIndex + 1 < widget.profiles.length ? '넘기기' : '닫기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.showTakeButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _taking || _animating ? null : _take,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _taking || _animating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('가져가기'),
                      ),
                    ),
                  ],
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

/// Show the board-style profile bottom sheet.
/// This is a small public helper so other screens can reuse the same UI.
Future<void> showBoardNoteSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> profiles,
  int startIndex = 0,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  Future<void> Function(String profileId)? onTakeNote,
  required VoidCallback onPop,
  int? myCredit,
  Future<void> Function()? onRefreshCredit,
  bool showTakeButton = true,
  bool showHabits = true,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _BoardNoteSheetContent(
        profiles: profiles,
        startIndex: startIndex,
        buildAvatar: buildAvatar,
        onTakeNote: onTakeNote ?? ((_) async {}),
        onPop: onPop,
        myCredit: myCredit,
        onRefreshCredit: onRefreshCredit,
        showTakeButton: showTakeButton,
        showHabits: showHabits,
      );
    },
  );
}

