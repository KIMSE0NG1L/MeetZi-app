import 'dart:convert';

import 'package:flutter/material.dart';
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
      // 내 프로필 정보 가져오기
      final authRepo = AuthRepository();
      final profile = await authRepo.getProfile();
      final nickname = profile['nickname'];
      final gender = profile['gender'];
      String school = profile['school'] ?? profile['affiliationText'] ?? '세종대';
      final department = profile['department']?.toString();
      final userEnvs = profile['userEnvironments'];
      if (school.isEmpty) {
        if (userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
          final env = userEnvs[0]['environment'];
          if (env != null && env['name'] != null) {
            school = env['name'];
          }
        }
      }
      if (school.isEmpty) school = '세종대';
      if (nickname == null || gender == null || school == null) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 완료')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 실패')));
    }
  }

  Future<void> _takeNote(String profileId) async {
    try {
      await _repository.takeNote(profileId);
      await _fetchProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가져가기 완료! 매칭이 성사되었어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
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
      ),
    );
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
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('매칭 게시판', style: TextStyle(color: Colors.white)),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(_myCredit != null ? '${_myCredit}코인' : '-', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          body: Container(
            color: Theme.of(context).colorScheme.background,
            child: _loading
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
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                color: Theme.of(context).colorScheme.primary,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: isMe ? null : () => _openNoteSheet(context, index, myUserId),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        _buildBoardAvatar(context, profile),
                                        const SizedBox(height: 12),
                                        Text(
                                          isMe ? '나' : (profile['nickname'] ?? ''),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isMe ? '' : ((profile['idealType'] ?? (profile['user'] as Map<String, dynamic>?)?['idealType'])?.toString() ?? '-'),
                                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
          ),
        );
      },
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
                    _row(theme, '성별', _str(profile['gender'] ?? user?['gender'])),
                    _row(theme, '소속', _str(user?['affiliationText'])),
                    _row(theme, '키', user?['heightCm'] != null ? '${user!['heightCm']} cm' : '-'),
                    _row(theme, '학년', _str(user?['gradeYear'])),
                    _row(theme, 'MBTI', _str(user?['mbti'])),
                    _row(theme, '흡연', _str(user?['smoking'])),
                    _row(theme, '음주', _str(user?['drinking'])),
                    _row(theme, '한 줄 소개', _str(user?['introOneLine'])),
                    _row(theme, '요즘 빠진 것', _str(user?['intoLately'])),
                    _row(theme, '이상형', _str(user?['idealType'])),
                    _row(theme, '패션 스타일', _str(user?['fashionStyle'])),
                    _row(theme, '선호 데이트', _str(user?['preferredDateType'])),
                    _row(theme, '활동 시간대', _str(user?['activityTime'])),
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
