import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/profile_detail_sheet.dart';
import 'package:nearo_app/features/matching_board/screens/mailbox_screen.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/presentation/pages/meetzy_board_page.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_detail_modal.dart';

/// 설명 주석
MeetzyProfileDetailData _profileMapToDetailData(Map<String, dynamic> profile) {
  final user = profile['user'] as Map<String, dynamic>?;
  dynamic pluck(List<String> keys) {
    for (final k in keys) {
      final v1 = profile[k];
      if (v1 != null && v1.toString().trim().isNotEmpty) return v1;
      final v2 = user?[k];
      if (v2 != null && v2.toString().trim().isNotEmpty) return v2;
    }
    return null;
  }
  String str(dynamic v) => v?.toString().trim() ?? '';
  String toLabel(String? field, dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return '';
    switch (field) {
      case 'gender':
        switch (s.toLowerCase()) {
          case 'male':
            return '남성';
          case 'female':
            return '여성';
          default:
            return s;
        }
      case 'gradeYear':
        switch (s.toLowerCase()) {
          case 'one':
            return '1학년';
          case 'two':
            return '2학년';
          case 'three':
            return '3학년';
          case 'four':
            return '4학년';
          case 'five':
            return '5학년';
          case 'graduation_deferred':
            return '졸업유예';
          default:
            return s;
        }
      case 'smoking':
        if (v is bool) return v ? '흡연' : '비흡연';
        switch (s.toLowerCase()) {
          case 'none':
            return '비흡연';
          case 'sometimes':
            return '가끔';
          case 'often':
            return '자주';
          default:
            return s;
        }
      case 'drinking':
        if (v is bool) return v ? '음주' : '비음주';
        switch (s.toLowerCase()) {
          case 'none':
            return '비음주';
          case 'sometimes':
            return '가끔';
          case 'often':
            return '자주';
          default:
            return s;
        }
      case 'fashionStyle':
        switch (s.toLowerCase()) {
          case 'hood_casual':
            return '후드/캐주얼';
          case 'shirt_neat':
            return '셔츠/단정';
          case 'street':
            return '스트릿';
          case 'knit':
            return '니트/감성';
          case 'sporty':
            return '스포티';
          case 'minimal':
            return '미니멀';
          case 'hip':
            return '힙한';
          default:
            return s;
        }
      case 'preferredDateType':
        switch (s.toLowerCase()) {
          case 'cafe':
            return '카페';
          case 'walk':
            return '산책';
          case 'movie':
            return '영화';
          case 'drink':
            return '술자리';
          case 'exercise':
            return '운동';
          case 'food_tour':
            return '맛집 탐방';
          case 'drive':
            return '드라이브';
          default:
            return s;
        }
      case 'activityTime':
        switch (s.toLowerCase()) {
          case 'morning':
            return '아침형';
          case 'daytime':
            return '주간형';
          case 'evening':
            return '저녁형';
          case 'night_owl':
            return '야행성';
          default:
            return s;
        }
      default:
        return s;
    }
  }
  final heightVal = pluck(['heightCm', 'height']);
  final heightStr = heightVal != null ? '${heightVal} cm' : '';
  final listTags = <String>[];
  final kw = pluck(['idealTypeKeywords']) ?? user?['idealTypeKeywords'];
  if (kw is List) {
    for (final e in kw) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty) listTags.add(s);
    }
  }
  return MeetzyProfileDetailData(
    nickname: str(pluck(['nickname']) ?? user?['nickname']).isEmpty ? '-' : str(pluck(['nickname']) ?? user?['nickname']),
    major: str(pluck(['department', 'major', 'departmentName'])),
    gender: toLabel('gender', pluck(['gender', 'sex'])),
    school: str(pluck(['affiliation', 'school', 'affiliationText', 'organization'])),
    height: heightStr,
    grade: toLabel('gradeYear', pluck(['grade', 'year', 'schoolYear', 'class'])),
    mbti: str(pluck(['mbti', 'mbtiType'])),
    smoking: toLabel('smoking', pluck(['isSmoking', 'smoking', 'smoke'])),
    drinking: toLabel('drinking', pluck(['isDrinking', 'drinking', 'alcohol'])),
    intro: str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction'])),
    interest: str(pluck(['intoLately', 'hobby', 'recentInterest'])),
    idealType: str(pluck(['idealType', 'ideal'])),
    fashionStyle: toLabel('fashionStyle', pluck(['fashionStyle', 'style'])),
    datePreference: toLabel('preferredDateType', pluck(['preferredDateType', 'preferredDate'])),
    activeTime: toLabel('activityTime', pluck(['activityTime', 'activeTime'])),
    tags: listTags,
  );
}

/// 설명 주석
Future<void> showBoardNoteSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> profiles,
  int startIndex = 0,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  VoidCallback? onPop,
  int myMatchingTicket = 0,
  Future<void> Function()? onRefreshTickets,
  Future<bool> Function(String profileId, Map<String, dynamic> profile)? onTakeNote,
  /// 설명 주석
  bool hideActionButtons = false,
}) async {
  final sheetContent = _BoardNoteSheetContent(
    profiles: profiles,
    startIndex: startIndex,
    buildAvatar: buildAvatar,
    onTakeNote: onTakeNote ?? (_, __) async => false,
    onPop: onPop ?? () {},
    myMatchingTicket: myMatchingTicket,
    onRefreshTickets: onRefreshTickets,
    hideActionButtons: hideActionButtons,
  );
  if (!context.mounted) return;
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(animation.value);
          final barrierOpacity = 0.6 * t;
          final opacity = t;
          final scale = 0.5 + 0.5 * t;
          final isReverse = animation.status == AnimationStatus.reverse;
          final rotateYDeg = isReverse ? 180.0 - 180.0 * t : -180.0 + 180.0 * t;
          final rotateYRad = rotateYDeg * (3.14159265359 / 180.0);
          return Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.black.withOpacity(barrierOpacity)),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotateYRad),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: sheetContent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class MatchingBoardScreen extends StatelessWidget {
  const MatchingBoardScreen({super.key, this.refreshTrigger});

  final ValueNotifier<int>? refreshTrigger;

  @override
  Widget build(BuildContext context) {
    return _MatchingBoardScreenBody(refreshTrigger: refreshTrigger);
  }
}

class _MatchingBoardScreenBody extends StatefulWidget {
  const _MatchingBoardScreenBody({this.refreshTrigger});

  final ValueNotifier<int>? refreshTrigger;

  @override
  State<_MatchingBoardScreenBody> createState() => _MatchingBoardScreenBodyState();
}

class _MatchingBoardScreenBodyState extends State<_MatchingBoardScreenBody> {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  final AuthRepository _authRepository = AuthRepository();
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = false;
  bool _isRegistering = false;
  bool _isOpeningSheet = false; // 설명 주석
  MyTickets? _myTickets;
  int _receivedRequestCount = 0;
  late Future<Map<String, dynamic>> _myProfileFuture;
  String? _preferredGender;
  bool _hasAppliedFilter = false;
  bool _filterNonSmokingOnly = false;
  bool _filterNonDrinkingOnly = false;
  int _filterMinHeight = 150;
  int _filterMaxHeight = 190;
  bool _isShowingAllUniversities = false;

  static const int _heightMinLimit = 120;
  static const int _heightMaxLimit = 230;

  @override
  void initState() {
    super.initState();
    _myProfileFuture = _authRepository.getProfile();
    _primePreferredGender();
    _fetchProfiles();
    _fetchMySummary();
    _fetchReceivedRequestCount();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    _fetchProfiles();
    _fetchMySummary();
    _fetchReceivedRequestCount();
  }

  Future<void> _fetchReceivedRequestCount() async {
    try {
      final list = await _repository.fetchMyTakeNoteRequests();
      if (!mounted) return;
      setState(() => _receivedRequestCount = list.length);
    } catch (_) {
      if (mounted) setState(() => _receivedRequestCount = 0);
    }
  }

  String? _normalizePreferredGender(dynamic rawGender) {
    final g = rawGender?.toString().trim().toLowerCase();
    if (g == 'male' || g == '남성') return 'female';
    if (g == 'female' || g == '여성') return 'male';
    return null;
  }

  Future<void> _primePreferredGender() async {
    try {
      final profile = await _myProfileFuture;
      final raw = profile['user'] is Map ? profile['user'] as Map : profile;
      _preferredGender = _normalizePreferredGender(raw['gender']);
    } catch (_) {
      _preferredGender = null;
    }
  }

  Future<void> _fetchMyTickets() async {
    await _fetchMySummary();
  }

  Future<void> _fetchMySummary() async {
    try {
      final summary = await _repository.fetchMySummary();
      _myProfileFuture = Future.value(summary.user);
      _preferredGender = _normalizePreferredGender(summary.user['gender']);
      setState(() {
        _myTickets = summary.tickets;
      });
    } catch (_) {
      setState(() {
        _myTickets = null;
      });
    }
  }

  /// 설명 주석
  Future<void> _fetchProfilesAllUniversities() async {
    setState(() => _loading = true);
    try {
      String? preferredGender = _preferredGender;
      try {
        final profile = await _myProfileFuture;
        final raw = profile['user'] is Map ? profile['user'] as Map : profile;
        final g = raw['gender']?.toString().trim().toLowerCase();
        if (g == 'male' || g == '남성') {
          preferredGender = 'female';
        } else if (g == 'female' || g == '여성') {
          preferredGender = 'male';
        }
      } catch (_) {}
      final profiles = await _repository.fetchProfiles(preferredGender: preferredGender, allSchools: true);
      setState(() {
        _profiles = profiles;
        _isShowingAllUniversities = true;
      });
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 설명 주석
  Future<void> _fetchProfiles() async {
    setState(() => _loading = true);
    try {
      String? preferredGender = _preferredGender;
      try {
        final profile = await _myProfileFuture;
        final raw = profile['user'] is Map ? profile['user'] as Map : profile;
        final g = raw['gender']?.toString().trim().toLowerCase();
        if (g == 'male' || g == '남성') {
          preferredGender = 'female';
        } else if (g == 'female' || g == '여성') {
          preferredGender = 'male';
        }
      } catch (_) {}
      final profiles = await _repository.fetchProfiles(preferredGender: preferredGender);
      setState(() {
        _profiles = profiles;
        _isShowingAllUniversities = false;
      });
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onDeveloperMatchTap() async {
    if (!mounted) return;
    try {
      final myProfile = await _myProfileFuture;
      final user = myProfile['user'] is Map ? myProfile['user'] as Map<String, dynamic> : myProfile;
      final myGender = (user['gender'] ?? myProfile['gender'])?.toString().trim().toLowerCase();
      if (myGender == 'male') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('개발자는 남자라서 신청할 수 없어요.')),
        );
        return;
      }
      final developerProfile = await _repository.fetchDeveloperProfile();
      if (!mounted) return;
      // 일반 카드와 동일한 상세 모달 + 매칭 로직 사용
      await _openNoteSheet(context, 0, [developerProfile], null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('개발자 프로필을 불러오지 못했습니다: $e')),
      );
    }
  }

  int? _extractHeightCm(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final raw = profile['heightCm'] ?? profile['height'] ?? user?['heightCm'] ?? user?['height'];
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits);
    }
    return null;
  }

  bool _isNonSmoking(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final v = profile['isSmoking'] ?? user?['isSmoking'] ?? profile['smoking'] ?? profile['smoke'] ?? user?['smoking'] ?? user?['smoke'];
    if (v is bool) return v == false;
    final raw = v?.toString().trim().toLowerCase();
    return raw == 'none' || raw == '비흡연' || raw == '금연';
  }

  bool _isNonDrinking(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final v = profile['isDrinking'] ?? user?['isDrinking'] ?? profile['drinking'] ?? profile['alcohol'] ?? user?['drinking'] ?? user?['alcohol'];
    if (v is bool) return v == false;
    final raw = v?.toString().trim().toLowerCase();
    return raw == 'none' || raw == '비음주' || raw == '금주';
  }

  List<Map<String, dynamic>> _filterProfiles(
    List<Map<String, dynamic>> source, {
    required bool nonSmokingOnly,
    required bool nonDrinkingOnly,
    required int minHeight,
    required int maxHeight,
  }) {
    return source.where((profile) {
      if (nonSmokingOnly && !_isNonSmoking(profile)) return false;
      if (nonDrinkingOnly && !_isNonDrinking(profile)) return false;
      final height = _extractHeightCm(profile);
      if (height == null) return false;
      return height >= minHeight && height <= maxHeight;
    }).toList();
  }

  Future<void> _openFilterDialog(List<Map<String, dynamic>> baseProfiles) async {
    if (!mounted) return;
    bool nonSmokingOnly = _filterNonSmokingOnly;
    bool nonDrinkingOnly = _filterNonDrinkingOnly;
    final minController = TextEditingController(text: '$_filterMinHeight');
    final maxController = TextEditingController(text: '$_filterMaxHeight');
    String? errorText;

    int? parseHeight(String value) => int.tryParse(value.trim());
    int filteredCount() {
      final minHeight = parseHeight(minController.text) ?? _filterMinHeight;
      final maxHeight = parseHeight(maxController.text) ?? _filterMaxHeight;
      if (minHeight > maxHeight) return 0;
      return _filterProfiles(
        baseProfiles,
        nonSmokingOnly: nonSmokingOnly,
        nonDrinkingOnly: nonDrinkingOnly,
        minHeight: minHeight.clamp(_heightMinLimit, _heightMaxLimit),
        maxHeight: maxHeight.clamp(_heightMinLimit, _heightMaxLimit),
      ).length;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final count = filteredCount();
              final dark = Theme.of(context).brightness == Brightness.dark;
              final maxHeight = MediaQuery.of(context).size.height * 0.85;
              return Container(
                constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                      decoration: const BoxDecoration(
                        gradient: UniversityTheme.designPinkGradient,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.funnel, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '필터링',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 33 / 2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '원하는 조건으로 프로필을 필터링하세요',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          _FilterOptionTile(
                            icon: Icons.smoke_free,
                            title: '비흡연자만',
                            subtitle: '담배를 피우지 않는 사람',
                            selected: nonSmokingOnly,
                            onTap: () => setModalState(() => nonSmokingOnly = !nonSmokingOnly),
                          ),
                          const SizedBox(height: 12),
                          _FilterOptionTile(
                            icon: Icons.no_drinks,
                            title: '비음주자만',
                            subtitle: '술을 마시지 않는 사람',
                            selected: nonDrinkingOnly,
                            onTap: () => setModalState(() => nonDrinkingOnly = !nonDrinkingOnly),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '키 범위 (cm)',
                            style: TextStyle(
                              color: dark ? Colors.white : const Color(0xFF374151),
                              fontSize: 28 / 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _HeightInputField(
                                  controller: minController,
                                  onChanged: (_) => setModalState(() => errorText = null),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '~',
                                  style: TextStyle(
                                    color: dark ? Colors.white : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _HeightInputField(
                                  controller: maxController,
                                  onChanged: (_) => setModalState(() => errorText = null),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: dark ? Colors.white10 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '필터 결과: $count명',
                                style: TextStyle(
                                  color: dark ? Colors.white : const Color(0xFF374151),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorText!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: UniversityTheme.designPinkGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  final minHeight = parseHeight(minController.text);
                                  final maxHeight = parseHeight(maxController.text);
                                  if (minHeight == null || maxHeight == null) {
                                    setModalState(() => errorText = '키는 숫자로 입력해 주세요.');
                                    return;
                                  }
                                  if (minHeight < _heightMinLimit || maxHeight > _heightMaxLimit) {
                                    setModalState(() => errorText = '키 범위는 $_heightMinLimit ~ $_heightMaxLimit cm 입니다.');
                                    return;
                                  }
                                  if (minHeight > maxHeight) {
                                    setModalState(() => errorText = '최소 키가 최대 키보다 클 수 없습니다.');
                                    return;
                                  }
                                  setState(() {
                                    _hasAppliedFilter = true;
                                    _filterNonSmokingOnly = nonSmokingOnly;
                                    _filterNonDrinkingOnly = nonDrinkingOnly;
                                    _filterMinHeight = minHeight;
                                    _filterMaxHeight = maxHeight;
                                  });
                                  Navigator.of(dialogContext).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  '필터 적용하기',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                          if (_hasAppliedFilter) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _hasAppliedFilter = false;
                                  _filterNonSmokingOnly = false;
                                  _filterNonDrinkingOnly = false;
                                  _filterMinHeight = _heightMinLimit;
                                  _filterMaxHeight = _heightMaxLimit;
                                });
                                Navigator.of(dialogContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: dark ? Colors.white70 : const Color(0xFF6B7280),
                                side: BorderSide(color: dark ? Colors.white38 : const Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('필터 해제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  Future<void> _registerProfile() async {
    if (_isRegistering) return;
    final registerTicket = _myTickets?.registerTicket ?? 0;
    if (registerTicket <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록권이 부족합니다. 등록권을 구매하면 게시판 등록 시 매칭권 1개가 지급됩니다.')),
      );
      return;
    }
    setState(() => _isRegistering = true);
    try {
      final profileRaw = await _myProfileFuture;
      final profile = profileRaw is Map<String, dynamic> ? profileRaw : <String, dynamic>{};
      final user = profile['user'] is Map ? profile['user'] as Map<String, dynamic> : profile;
      final nickname = user['nickname']?.toString();
      final gender = user['gender']?.toString();
      String school = user['school']?.toString() ?? user['affiliationText']?.toString() ?? profile['affiliationText']?.toString() ?? '미정';
      final department = user['department']?.toString();
      final userEnvs = profile['userEnvironments'] ?? user['userEnvironments'];
      if ((school.isEmpty || school == 'null') && userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
        final first = userEnvs[0];
        if (first is Map && first['environment'] is Map) {
          final name = (first['environment'] as Map)['name']?.toString();
          if (name != null && name.isNotEmpty) school = name;
        }
      }
      if (school.isEmpty || school == 'null') school = '미정';
      if (nickname == null || nickname.isEmpty || gender == null || gender.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내 프로필 정보가 없습니다.')));
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
      await _fetchMySummary();
      _myProfileFuture = _authRepository.getProfile(forceRefresh: true);
      await _primePreferredGender();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내 게시글 등록 완료! 매칭권 1개가 지급되었어요.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
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
    final displayType = user?['boardDisplayType']?.toString();
    final photos = user?['photos'];
    String? primaryPhotoKey;
    if (photos is List && photos.isNotEmpty && photos[0] is Map) {
      primaryPhotoKey = (photos[0] as Map<String, dynamic>)['storageKey']?.toString();
    }
    final photoUrl = primaryPhotoKey != null ? photoUrlFromStorageKey(primaryPhotoKey) : null;
    if (displayType == 'photo' && photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: MeetzyDesignTokens.cardAvatarSize,
          height: MeetzyDesignTokens.cardAvatarSize,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null))),
          errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
    final seed = user?['avatarSeed']?.toString() ?? profile['userId']?.toString();
    final options = _parseAvatarOptions(user?['avatarOptions']);
    if (seed != null && seed.isNotEmpty) {
      return ClipOval(
        child: SvgPicture.network(
          diceBearAvatarUrl(seed, options: options.isNotEmpty ? options : null),
          fit: BoxFit.cover,
          width: MeetzyDesignTokens.cardAvatarSize,
          height: MeetzyDesignTokens.cardAvatarSize,
          placeholderBuilder: (context) => Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
    return ClipOval(
      child: Container(
        width: MeetzyDesignTokens.cardAvatarSize,
        height: MeetzyDesignTokens.cardAvatarSize,
        color: Colors.white,
        alignment: Alignment.center,
        child: Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return FutureBuilder<Map<String, dynamic>>(
      future: _myProfileFuture,
      builder: (context, snapshot) {
        final raw = snapshot.data;
        final Map<String, dynamic>? profileData = raw != null && raw is Map<String, dynamic>
            ? (raw['user'] as Map<String, dynamic>?) ?? raw
            : null;
        final myUserId = profileData?['id']?.toString() ?? raw?['id']?.toString();
        final myNickname = profileData?['nickname']?.toString() ?? raw?['nickname']?.toString() ?? '나';
        final mySchoolName = (profileData?['affiliationText'] ?? profileData?['school'])?.toString().trim();
        final mySchoolNameOrNull = (mySchoolName != null && mySchoolName.isNotEmpty) ? mySchoolName : null;
        final meProfile = profileData != null
            ? {'user': profileData, 'userId': myUserId, 'nickname': myNickname}
            : null;
        // 설명 주석
        final displayProfiles = myUserId != null
            ? _profiles.where((p) {
                final uid = p['userId']?.toString() ?? (p['user'] as Map<String, dynamic>?)?['id']?.toString();
                return uid != myUserId;
              }).toList()
            : List<Map<String, dynamic>>.from(_profiles);
        final filteredProfiles = _hasAppliedFilter
            ? _filterProfiles(
                displayProfiles,
                nonSmokingOnly: _filterNonSmokingOnly,
                nonDrinkingOnly: _filterNonDrinkingOnly,
                minHeight: _filterMinHeight,
                maxHeight: _filterMaxHeight,
              )
            : displayProfiles;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: MeetzyBoardContent(
            myNickname: myNickname,
            myAvatarWidget: meProfile != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _buildBoardAvatar(context, meProfile),
                    ),
                  )
                : null,
            matchingTicket: _myTickets?.matchingTicket ?? 0,
            receivedRequestCount: _receivedRequestCount,
            profiles: filteredProfiles.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final nickname = p['nickname']?.toString().trim();
              final displayName = (nickname != null && nickname.isNotEmpty)
                  ? nickname
                  : (p['user'] as Map<String, dynamic>?)?['nickname']?.toString().trim() ?? '-';
              final tag = (p['idealType'] ?? (p['user'] as Map<String, dynamic>?)?['idealType'])?.toString() ?? '-';
              return MeetzyBoardProfileItem(
                nickname: displayName.isEmpty ? '-' : displayName,
                tag: tag,
                avatarWidget: _buildBoardAvatar(context, p),
                isNew: i < 6,
              );
            }).toList(),
            onProfileTap: (index, _) => _openNoteSheet(context, index, filteredProfiles, myUserId),
            onRefresh: () async {
              await _fetchProfiles();
              await _fetchMySummary();
              await _fetchReceivedRequestCount();
            },
            onMatchingInboxTap: () {
              final size = MediaQuery.of(context).size;
              final padding = EdgeInsets.symmetric(
                horizontal: size.width > 400 ? 24 : 16,
                vertical: 48,
              );
              showGeneralDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black54,
                barrierLabel: '?リ린',
                pageBuilder: (_, __, ___) => Padding(
                  padding: padding,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 420,
                          maxHeight: size.height * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1F2937)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: const MailboxScreen(isModal: true),
                      ),
                    ),
                  ),
                ),
              ).then((_) => _fetchReceivedRequestCount());
            },
            onDeveloperMatchTap: _onDeveloperMatchTap,
            onLoadAllUniversities: _fetchProfilesAllUniversities,
            onLoadMySchool: _fetchProfiles,
            isShowingAllUniversities: _isShowingAllUniversities,
            mySchoolName: mySchoolNameOrNull,
            onFilterTap: () => _openFilterDialog(displayProfiles),
            isLoading: _loading,
          ),
        );
      },
    );
  }

  Future<void> _openNoteSheet(BuildContext context, int startIndex, List<Map<String, dynamic>> displayProfiles, String? myUserId) async {
    if (_isOpeningSheet) return;
    _isOpeningSheet = true;
    if (mounted) setState(() {});

    try {
      final tappedProfile = startIndex < displayProfiles.length ? displayProfiles[startIndex] : null;
      if (tappedProfile == null) return;
      final profileId = tappedProfile['id']?.toString();
      if (profileId == null || profileId.isEmpty) return;
      if (!mounted) return;
      final detailData = _profileMapToDetailData(tappedProfile);
      final (photoUrlForEnlarge, avatarUrlForEnlarge) = getEnlargeUrlsFromProfile(tappedProfile);
      final dark = Theme.of(context).brightness == Brightness.dark;
      // 설명 주석
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '닫기',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutCubic;
          final t = curve.transform(animation.value);
          final barrierOpacity = 0.6 * t;
          final slideY = 700.0 * (1.0 - t); // 설명 주석
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      color: Colors.black.withValues(alpha: barrierOpacity),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(0, slideY),
                      child: Center(
                        child: SizedBox(
                          width: 390,
                          height: 700,
                          child: Material(
                            type: MaterialType.transparency,
                            child: MeetzyProfileDetailModal(
                          profile: detailData,
                          darkMode: dark,
                          avatarWidget: _buildBoardAvatar(ctx, tappedProfile),
                          photoUrlForEnlarge: photoUrlForEnlarge,
                          avatarUrlForEnlarge: avatarUrlForEnlarge,
                          onClose: () => Navigator.of(ctx).pop(),
                          onMatch: () async {
                            if (!ctx.mounted) return;
                            final message = await showModalBottomSheet<String?>(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (sheetCtx) => _TakeNoteMessageSheet(profile: tappedProfile),
                            );
                            if (!ctx.mounted) return;
                            if (message == null) return;
                            Navigator.of(ctx).pop();
                            if (!mounted) return;
                            final ok = await _takeNote(profileId, tappedProfile, message: message);
                            if (!mounted) return;
                            if (ok) {
                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                barrierColor: Colors.black54,
                                builder: (dialogCtx) => _MatchCelebrationOverlay(
                                  profile: tappedProfile,
                                  buildAvatar: _buildBoardAvatar,
                                ),
                              );
                              if (!mounted) return;
                              _fetchProfiles();
                              _fetchMySummary();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      _fetchProfiles();
      _fetchMySummary();
    } finally {
      if (mounted) setState(() => _isOpeningSheet = false);
    }
  }

  Future<bool> _takeNote(String profileId, Map<String, dynamic> profile, {String? message}) async {
    final matchingTicket = _myTickets?.matchingTicket ?? 0;
    if (matchingTicket <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭권이 부족합니다. 매칭권을 구매한 뒤 요청을 보내 주세요.')),
      );
      return false;
    }
    final nickname = (profile['nickname']?.toString().trim().isNotEmpty ?? false)
        ? profile['nickname'].toString().trim()
        : ((profile['user'] as Map<String, dynamic>?)?['nickname']?.toString().trim() ?? '상대');
    final trimmed = message != null && message.trim().isNotEmpty
        ? message.trim()
        : '$nickname 님 반가워요!';
    try {
      await _repository.takeNote(profileId, message: trimmed);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요청을 보냈어요. 상대가 수락하면 매칭돼요.')));
      // Avoid keeping the match action blocked while refresh APIs are in flight.
      _fetchProfiles();
      _fetchMySummary();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      return false;
    }
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? Colors.white10 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dark ? Colors.white12 : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF43F5E), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: dark ? Colors.grey.shade300 : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFFF43F5E)
                    : (dark ? Colors.white24 : const Color(0xFFD1D5DB)),
              ),
              child: selected
                  ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeightInputField extends StatelessWidget {
  const _HeightInputField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: dark ? Colors.white : const Color(0xFF111827),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        filled: true,
        fillColor: dark ? Colors.white10 : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFD1D5DB)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFFF43F5E), width: 1.4),
        ),
      ),
    );
  }
}

/// 설명 주석
class _TakeNoteMessageSheet extends StatefulWidget {
  const _TakeNoteMessageSheet({required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<_TakeNoteMessageSheet> createState() => _TakeNoteMessageSheetState();
}

class _TakeNoteMessageSheetState extends State<_TakeNoteMessageSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  static const int _minLength = 5;
  static const int _maxLength = 200;

  bool get _isValid => _controller.text.trim().length >= _minLength;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final nickname = _str(widget.profile['nickname']);
    final school = _str(widget.profile['affiliationText']) != ''
        ? _str(widget.profile['affiliationText'])
        : _str(widget.profile['school']);
    final major = _str(widget.profile['department']) != ''
        ? _str(widget.profile['department'])
        : _str(widget.profile['major']);

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 설명 주석
              Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                gradient: UniversityTheme.designPinkGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '첫 인사를 해보세요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop<String?>(null),
                        icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${nickname.isNotEmpty ? nickname : '상대'}님에게 보낼 메시지를 작성해 주세요',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 설명 주석
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildProfileAvatar(context, widget.profile, 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname.isNotEmpty ? nickname : '프로필',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [school, major].where((s) => s.isNotEmpty).join(' · '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Message input (ad: textarea, placeholder, max 200, count)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        maxLines: 4,
                        maxLength: _maxLength,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '안녕하세요! 프로필을 보고 관심이 생겨 메시지를 보냅니다 :)',
                          hintStyle: TextStyle(
                            color: dark ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: dark ? const Color(0xFF374151) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEC4899),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        ),
                        style: TextStyle(
                          color: dark ? Colors.white : const Color(0xFF111827),
                          fontSize: 16,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 8,
                        child: Text(
                          '${_controller.text.length}/$_maxLength',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isValid
                                ? (dark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Warning/Success box (ad)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isValid
                          ? (dark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFD1FAE5))
                          : (dark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isValid
                            ? (dark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
                            : (dark ? const Color(0xFFB45309) : const Color(0xFFFDE68A)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isValid ? LucideIcons.heart : LucideIcons.circleAlert,
                          size: 20,
                          color: _isValid
                              ? (dark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isValid
                                ? '좋아요! 이제 전송할 수 있어요 💌'
                                : '최소 $_minLength자 이상 입력해 주세요 (현재 ${_controller.text.length}자)',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isValid
                                  ? (dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                  : (dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 설명 주석
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isValid
                          ? () => Navigator.of(context).pop<String?>(_controller.text.trim())
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: _isValid
                              ? UniversityTheme.designPinkGradient
                              : null,
                          color: _isValid ? null : (dark ? const Color(0xFF374151) : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isValid
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.send,
                              size: 20,
                              color: _isValid ? Colors.white : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isValid ? '메시지 보내고 카드 가져가기' : '메시지를 입력해 주세요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isValid ? Colors.white : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, Map<String, dynamic> profile, double size) {
    final displayType = profile['boardDisplayType']?.toString() ?? profile['user']?['boardDisplayType']?.toString() ?? 'avatar';
    final photos = profile['photos'];
    String? photoUrl;
    if (displayType == 'photo' && photos is List && photos.isNotEmpty && photos[0] is Map) {
      final storageKey = (photos[0] as Map)['storageKey']?.toString();
      if (storageKey != null && storageKey.isNotEmpty) {
        photoUrl = photoUrlFromStorageKey(storageKey);
      }
    }
    String? seed = profile['avatarSeed']?.toString() ?? (profile['user'] as Map?)?['avatarSeed']?.toString();
    if (seed != null && seed.isNotEmpty) {
      // avatarOptions는 Map 또는 JSON String일 수 있으므로 안전하게 파싱
      final rawOptions = profile['avatarOptions'] ?? (profile['user'] as Map?)?['avatarOptions'];
      Map<String, String> opts = {};
      if (rawOptions is Map) {
        opts = rawOptions.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      } else if (rawOptions != null && rawOptions.toString().trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawOptions.toString());
          if (decoded is Map) {
            opts = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
          }
        } catch (_) {}
      }
      final options = opts.isNotEmpty ? opts : null;
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarPlaceholder(size))
              : SvgPicture.network(
                  diceBearAvatarUrl(seed, options: options),
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => _avatarPlaceholder(size),
                ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: _avatarPlaceholder(size),
    );
  }

  Widget _avatarPlaceholder(double size) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Icon(LucideIcons.user, size: size * 0.5, color: Colors.grey),
    );
  }
}

/// 설명 주석
class _DesignTicketChip extends StatelessWidget {
  const _DesignTicketChip({
    required this.label,
    required this.emoji,
    required this.count,
    required this.color,
    required this.dark,
  });

  final String label;
  final String emoji;
  final int count;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [color.withOpacity(0.2), color.withOpacity(0.15)]
              : [color.withOpacity(0.25), color.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: dark ? color.withOpacity(0.9) : color,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: dark ? color.withOpacity(0.9) : color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 설명 주석
class _TicketChip extends StatelessWidget {
  const _TicketChip({
    required this.icon,
    required this.count,
    required this.color,
    required this.dark,
  });

  final IconData icon;
  final int count;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? color.withOpacity(0.25) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dark ? Colors.white : color),
          ),
        ],
      ),
    );
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
    required this.myMatchingTicket,
    this.onRefreshTickets,
    this.hideActionButtons = false,
  });

  final List<Map<String, dynamic>> profiles;
  final int startIndex;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  final Future<bool> Function(String profileId, Map<String, dynamic> profile) onTakeNote;
  final VoidCallback onPop;
  final int myMatchingTicket;
  final Future<void> Function()? onRefreshTickets;
  final bool hideActionButtons;

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

    if (widget.myMatchingTicket <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('매칭권이 부족합니다. 매칭권을 구매한 뒤 요청을 보내 주세요.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _taking = true);
    try {
      final profileId = _profile['id']?.toString();
      if (profileId == null || profileId.isEmpty) {
        throw Exception('프로필 ID를 찾을 수 없습니다.');
      }
      final sent = await widget.onTakeNote(profileId, _profile);
      if (widget.onRefreshTickets != null) await widget.onRefreshTickets!();
      if (!mounted) return;
      setState(() => _taking = false);
      if (!sent) return; // 설명 주석
      // 설명 주석
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (ctx) => _MatchCelebrationOverlay(
          profile: _profile,
          buildAvatar: widget.buildAvatar,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _taking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  static String _str(dynamic v) => v?.toString() ?? '-';

  /// 설명 주석
  static String _toLabel(String? field, dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return '-';
    switch (field) {
      case 'gender':
        switch (s.toLowerCase()) {
          case 'male':
            return '남성';
          case 'female':
            return '여성';
          default:
            return s;
        }
      case 'gradeYear':
        switch (s.toLowerCase()) {
          case 'one':
            return '1학년';
          case 'two':
            return '2학년';
          case 'three':
            return '3학년';
          case 'four':
            return '4학년';
          case 'five':
            return '5학년';
          case 'graduation_deferred':
            return '졸업유예';
          default:
            return s;
        }
      case 'smoking':
        switch (s.toLowerCase()) {
          case 'none':
            return '비흡연';
          case 'sometimes':
            return '가끔';
          case 'often':
            return '자주';
          default:
            return s;
        }
      case 'drinking':
        switch (s.toLowerCase()) {
          case 'none':
            return '비음주';
          case 'sometimes':
            return '가끔';
          case 'often':
            return '자주';
          default:
            return s;
        }
      case 'fashionStyle':
        switch (s.toLowerCase()) {
          case 'hood_casual':
            return '후드/캐주얼';
          case 'shirt_neat':
            return '셔츠/단정';
          case 'street':
            return '스트릿';
          case 'knit':
            return '니트/감성';
          case 'sporty':
            return '스포티';
          case 'minimal':
            return '미니멀';
          case 'hip':
            return '힙한';
          default:
            return s;
        }
      case 'preferredDateType':
        switch (s.toLowerCase()) {
          case 'cafe':
            return '카페';
          case 'walk':
            return '산책';
          case 'movie':
            return '영화';
          case 'drink':
            return '술자리';
          case 'exercise':
            return '운동';
          case 'food_tour':
            return '맛집 탐방';
          case 'drive':
            return '드라이브';
          default:
            return s;
        }
      case 'activityTime':
        switch (s.toLowerCase()) {
          case 'morning':
            return '아침형';
          case 'daytime':
            return '주간형';
          case 'evening':
            return '저녁형';
          case 'night_owl':
            return '야행성';
          default:
            return s;
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

    // 설명 주석
    final primaryGradient = ThemeController.getSheetGradient();
    final dark = theme.brightness == Brightness.dark;
    final listTags = <String>[];
    final kw = pluck(['idealTypeKeywords']) ?? user?['idealTypeKeywords'];
    if (kw is List) {
      for (final e in kw) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) listTags.add(s);
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // 설명 주석
            Container(
              height: 200,
              decoration: BoxDecoration(gradient: primaryGradient),
              child: Stack(
                children: [
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final content = Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Builder(
                                builder: (context) {
                                  final (photoUrl, avatarUrl) = getEnlargeUrlsFromProfile(profile);
                                  final hasEnlarge = (photoUrl != null && photoUrl.isNotEmpty) ||
                                      (avatarUrl != null && avatarUrl.isNotEmpty);
                                  Widget avatarChild = widget.buildAvatar(context, profile);
                                  if (hasEnlarge) {
                                    avatarChild = GestureDetector(
                                      onTap: () => MeetzyProfileDetailModal.showPhotoEnlarge(
                                        context,
                                        photoUrl: photoUrl,
                                        avatarUrl: avatarUrl,
                                      ),
                                      child: avatarChild,
                                    );
                                  }
                                  return Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: ClipOval(child: avatarChild),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 280),
                                child: Text(
                                  _str(profile['nickname']),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                        return FittedBox(
                          alignment: Alignment.topCenter,
                          fit: BoxFit.scaleDown,
                          child: content,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _taking ? null : () {
                          Navigator.of(context).pop();
                          widget.onPop();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(LucideIcons.x, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 설명 주석
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                physics: const AlwaysScrollableScrollPhysics(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _rowAppDesign(theme, dark, '학과', _str(pluck(['department', 'major', 'departmentName']))),
                      _rowAppDesign(theme, dark, '성별', _toLabel('gender', pluck(['gender', 'sex'])?.toString())),
                      _rowAppDesign(theme, dark, '소속', _str(pluck(['affiliation', 'school', 'affiliationText', 'organization']))),
                      _rowAppDesign(theme, dark, '키', pluck(['heightCm', 'height']) != null ? '${pluck(['heightCm', 'height'])} cm' : '-'),
                      _rowAppDesign(theme, dark, '학년', _toLabel('gradeYear', pluck(['grade', 'year', 'schoolYear', 'class']))),
                      _rowAppDesign(theme, dark, 'MBTI', _str(pluck(['mbti', 'mbtiType']))),
                      _rowAppDesign(theme, dark, '흡연', _toLabel('smoking', pluck(['smoking', 'smoke'])?.toString())),
                      _rowAppDesign(theme, dark, '음주', _toLabel('drinking', pluck(['drinking', 'alcohol'])?.toString())),
                      _rowAppDesign(theme, dark, '자기소개', _str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction']))),
                      _rowAppDesign(theme, dark, '요즘 빠진 것', _str(pluck(['intoLately', 'hobby', 'recentInterest']))),
                      _rowAppDesign(theme, dark, '이상형', _str(pluck(['idealType', 'ideal']))),
                      _rowAppDesign(theme, dark, '패션 스타일', _toLabel('fashionStyle', pluck(['fashionStyle', 'style']))),
                      _rowAppDesign(theme, dark, '선호 데이트', _toLabel('preferredDateType', pluck(['preferredDateType', 'preferredDate']))),
                      _rowAppDesign(theme, dark, '활동 시간대', _toLabel('activityTime', pluck(['activityTime', 'activeTime']))),
                      if (listTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 112,
                              child: Text(
                                '나를 소개하는 태그',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: listTags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.grey.shade700 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: dark ? Colors.grey.shade300 : Colors.grey.shade800,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // 설명 주석
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1F2937) : Colors.white,
                border: Border(top: BorderSide(color: dark ? Colors.grey.shade700 : Colors.grey.shade200)),
              ),
              child: widget.hideActionButtons
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: dark ? Colors.grey.shade600 : Colors.grey.shade300),
                        ),
                        child: Text(
                          '?リ린',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.grey.shade200 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _taking ? null : _skip,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: dark ? Colors.grey.shade600 : Colors.grey.shade300),
                            ),
                            child: Text(
                              '숨기기',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.grey.shade200 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: primaryGradient,
                              boxShadow: [
                                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _taking ? null : _take,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _taking
                                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text(
                                            '諛쏄린',
                                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ),
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
  }

  Widget _row(ThemeData theme, String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  /// AppDesign InfoRow: label 112, value, border-bottom
  Widget _rowAppDesign(ThemeData theme, bool dark, String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dark ? Colors.grey.shade700 : Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: dark ? Colors.grey.shade300 : const Color(0xFF111827),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 설명 주석
Future<void> showMatchCompleteCelebration(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (ctx) => const _MatchCompleteOnlyOverlay(),
  );
}

class _MatchCompleteOnlyOverlay extends StatefulWidget {
  const _MatchCompleteOnlyOverlay();

  @override
  State<_MatchCompleteOnlyOverlay> createState() => _MatchCompleteOnlyOverlayState();
}

class _MatchCompleteOnlyOverlayState extends State<_MatchCompleteOnlyOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.heart, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '매칭 완료!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '두 분의 대화를 시작해 보세요 💬',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: dark ? Colors.grey : const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 설명 주석
class _MatchCelebrationOverlay extends StatefulWidget {
  const _MatchCelebrationOverlay({
    required this.profile,
    required this.buildAvatar,
    this.requestOnly = true,
  });

  final Map<String, dynamic> profile;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  /// 설명 주석
  final bool requestOnly;

  @override
  State<_MatchCelebrationOverlay> createState() => _MatchCelebrationOverlayState();
}

class _MatchCelebrationOverlayState extends State<_MatchCelebrationOverlay> {
  static const _successDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    Future.delayed(_successDuration, () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.profile['nickname']?.toString() ?? '';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _buildSuccessPhase(dark, nickname);
  }

  Widget _buildSuccessPhase(bool dark, String nickname) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.heart, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  widget.requestOnly ? '요청을 보냈어요!' : '매칭 성사!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.requestOnly
                      ? '$nickname 님이 수락하면\n대화를 시작할 수 있어요 💬'
                      : '$nickname 님과의 인연으로\n매칭되었어요! 💖',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: dark ? Colors.grey.shade300 : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



