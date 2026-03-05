import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/mailbox_screen.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/presentation/pages/meetzy_board_page.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_detail_modal.dart';

/// 프로필 맵 → MeetzyProfileDetailData (last 상세 모달용)
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
    smoking: toLabel('smoking', pluck(['smoking', 'smoke'])),
    drinking: toLabel('drinking', pluck(['drinking', 'alcohol'])),
    intro: str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction'])),
    interest: str(pluck(['intoLately', 'hobby', 'recentInterest'])),
    idealType: str(pluck(['idealType', 'ideal'])),
    fashionStyle: toLabel('fashionStyle', pluck(['fashionStyle', 'style'])),
    datePreference: toLabel('preferredDateType', pluck(['preferredDateType', 'preferredDate'])),
    activeTime: toLabel('activityTime', pluck(['activityTime', 'activeTime'])),
    tags: listTags,
  );
}

/// 채팅 등 외부에서 프로필 시트만 볼 때 사용 (hideActionButtons: true → 넘기기/가져가기 비표시)
Future<void> showBoardNoteSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> profiles,
  int startIndex = 0,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  VoidCallback? onPop,
  int myMatchingTicket = 0,
  Future<void> Function()? onRefreshTickets,
  Future<bool> Function(String profileId)? onTakeNote,
  /// true면 넘기기/가져가기 버튼 숨김 (채팅방에서 프로필 보기용)
  bool hideActionButtons = false,
}) async {
  final sheetContent = _BoardNoteSheetContent(
    profiles: profiles,
    startIndex: startIndex,
    buildAvatar: buildAvatar,
    onTakeNote: onTakeNote ?? (_) async => false,
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
  bool _isOpeningSheet = false; // 카드 연타 방지: 시트 열리는 동안 추가 탭 무시
  int? _myCredit;
  MyTickets? _myTickets;
  late Future<Map<String, dynamic>> _myProfileFuture;
  String? _preferredGender;

  @override
  void initState() {
    super.initState();
    _myProfileFuture = _authRepository.getProfile();
    _primePreferredGender();
    _fetchProfiles();
    _fetchMySummary();
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

  Future<void> _fetchMyCredit() async {
    await _fetchMySummary();
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
        _myCredit = summary.credit;
        _myTickets = summary.tickets;
      });
    } catch (_) {
      setState(() {
        _myCredit = null;
        _myTickets = null;
      });
    }
  }

  /// 내 성별의 반대만 게시판에 노출 (남자 계정 → 여자만, 여자 계정 → 남자만)
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
      setState(() => _profiles = profiles);
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registerProfile() async {
    if (_isRegistering) return;
    final registerTicket = _myTickets?.registerTicket ?? 0;
    if (registerTicket <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록권이 부족해요. 등록권으로 게시판에 등록하면 매칭권 1장이 지급돼요.')),
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
      String school = user['school']?.toString() ?? user['affiliationText']?.toString() ?? profile['affiliationText']?.toString() ?? '세종대';
      final department = user['department']?.toString();
      final userEnvs = profile['userEnvironments'] ?? user['userEnvironments'];
      if ((school.isEmpty || school == 'null') && userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
        final first = userEnvs[0];
        if (first is Map && first['environment'] is Map) {
          final name = (first['environment'] as Map)['name']?.toString();
          if (name != null && name.isNotEmpty) school = name;
        }
      }
      if (school.isEmpty || school == 'null') school = '세종대';
      if (nickname == null || nickname.isEmpty || gender == null || gender.isEmpty) {
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
      await _fetchMySummary();
      _myProfileFuture = _authRepository.getProfile(forceRefresh: true);
      await _primePreferredGender();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 완료! 매칭권 1장이 지급됐어요.')));
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
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null))),
            errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
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
            placeholderBuilder: (context) => Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white,
      child: Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary),
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
        final meProfile = profileData != null
            ? {'user': profileData, 'userId': myUserId, 'nickname': myNickname}
            : null;
        // 내가 등록한 카드는 게시판에 보이지 않도록 제외
        final displayProfiles = myUserId != null
            ? _profiles.where((p) {
                final uid = p['userId']?.toString() ?? (p['user'] as Map<String, dynamic>?)?['id']?.toString();
                return uid != myUserId;
              }).toList()
            : List<Map<String, dynamic>>.from(_profiles);

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
            viewTicket: _myTickets?.viewTicket ?? 0,
            registerTicket: _myTickets?.registerTicket ?? 0,
            matchingTicket: _myTickets?.matchingTicket ?? 0,
            profiles: displayProfiles.asMap().entries.map((e) {
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
            onProfileTap: (index, _) => _openNoteSheet(context, index, displayProfiles, myUserId),
            onRegister: _registerProfile,
            onRefresh: () async {
              await _fetchProfiles();
              await _fetchMySummary();
            },
            onMatchingInboxTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MailboxScreen()),
              );
            },
            isLoading: _loading,
            isRegistering: _isRegistering,
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
      // 열람권: 상세 보기 시 1장 소비
      final viewTicket = _myTickets?.viewTicket ?? 0;
      if (viewTicket <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('열람권이 부족해요. 열람권을 구매한 뒤 프로필을 확인해 주세요.')),
        );
        return;
      }
      final profileId = tappedProfile['id']?.toString();
      if (profileId == null || profileId.isEmpty) return;
      try {
        await _repository.consumeViewTicket(profileId);
        await _fetchMySummary();
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '');
        final isTaken = msg.contains('열람할 수 없') || msg.contains('400');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTaken ? '이미 다른 사람이 가져간 프로필이에요.' : msg),
          ),
        );
        if (isTaken) _fetchProfiles();
        return;
      }
      if (!mounted) return;
      final detailData = _profileMapToDetailData(tappedProfile);
      final dark = Theme.of(context).brightness == Brightness.dark;
      // last ProfileDetailModal: 열기/닫기 rotateY 플립, scale, opacity, perspective 1000px
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '닫기',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(animation.value);
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
                    child: Container(color: Colors.black.withValues(alpha: barrierOpacity)),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390, maxHeight: 700),
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
                            child: Material(
                              type: MaterialType.transparency,
                              child: MeetzyProfileDetailModal(
                                profile: detailData,
                                darkMode: dark,
                                avatarWidget: _buildBoardAvatar(ctx, tappedProfile),
                                onClose: () => Navigator.of(ctx).pop(),
                                onMatch: () async {
                                  final ok = await _takeNote(profileId);
                                  if (!ctx.mounted) return;
                                  if (ok) {
                                    await showDialog<void>(
                                      context: ctx,
                                      barrierDismissible: false,
                                      barrierColor: Colors.black54,
                                      builder: (dialogCtx) => _MatchCelebrationOverlay(
                                        profile: tappedProfile,
                                        buildAvatar: _buildBoardAvatar,
                                      ),
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.of(ctx).pop();
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

  Future<bool> _takeNote(String profileId) async {
    final matchingTicket = _myTickets?.matchingTicket ?? 0;
    if (matchingTicket <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭권이 부족해요. 매칭권을 구매한 뒤 가져가기를 시도해 주세요.')),
      );
      return false;
    }
    final message = await showDialog<String?>(
      context: context,
      builder: (ctx) => _TakeNoteMessageDialog(),
    );
    if (!mounted) return false;
    if (message == null) return false; // 취소 시 요청 안 보냄
    final trimmed = message.trim();
    if (trimmed.length < 5) return false;
    try {
      await _repository.takeNote(profileId, message: trimmed);
      await _fetchProfiles();
      await _fetchMySummary();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요청을 보냈어요. 상대가 수락하면 매칭돼요.')));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      return false;
    }
  }
}

/// 가져가기 요청 시 상대에게 보낼 멘트 입력 다이얼로그. 5자 이상. 확인 시 입력 텍스트 반환, 취소 시 null.
class _TakeNoteMessageDialog extends StatefulWidget {
  @override
  State<_TakeNoteMessageDialog> createState() => _TakeNoteMessageDialogState();
}

class _TakeNoteMessageDialogState extends State<_TakeNoteMessageDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool get _isValid => _controller.text.trim().length >= 5;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('가져가기 멘트'),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '상대에게 보낼 말 (5자 이상)',
            border: const OutlineInputBorder(),
            helperText: _controller.text.trim().isNotEmpty && !_isValid
                ? '5자 이상 입력해 주세요'
                : '5자 이상 입력해 주세요',
            helperStyle: TextStyle(
              color: _controller.text.trim().isNotEmpty && !_isValid ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_isValid) Navigator.of(context).pop(_controller.text.trim());
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: const Text('보내기'),
        ),
      ],
    );
  }
}

/// Design MeetZyBoard 스타일: 열람권/등록권/매칭권 (라벨 + 이모지 + 개수)
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

/// 등록/열람/매칭권 뱃지 (아이콘 + 개수만)
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
  final Future<bool> Function(String profileId) onTakeNote;
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
          content: const Text('매칭권이 부족해요. 매칭권을 구매한 뒤 가져가기를 시도해 주세요.'),
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
      final sent = await widget.onTakeNote(_profile['id'] as String);
      if (widget.onRefreshTickets != null) await widget.onRefreshTickets!();
      if (!mounted) return;
      setState(() => _taking = false);
      if (!sent) return; // 취소했거나 실패 시 축하 안 함
      // AppDesign ProfileDetailModal: 카드 비행 1.5초 + 스파클 12 → 성공 문구 2초
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

    // AppDesign ProfileDetailModal: 테마 primary 그라데이션 헤더, 아바타+닉네임, 스크롤 정보+태그, 하단 닫기/가져가기
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
            // 헤더: 그라데이션 + 드래그 핸들 + X + 아바타 + 닉네임 (높이 200으로 오버플로우 방지)
            Container(
              height: 200,
              decoration: BoxDecoration(gradient: primaryGradient),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
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
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.buildAvatar(context, profile),
                            ),
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
            // 스크롤: 정보 행 + 태그
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
                      _rowAppDesign(theme, dark, '학번', _toLabel('gradeYear', pluck(['grade', 'year', 'schoolYear', 'class']) )),
                      _rowAppDesign(theme, dark, 'MBTI', _str(pluck(['mbti', 'mbtiType']))),
                      _rowAppDesign(theme, dark, '흡연', _toLabel('smoking', pluck(['smoking', 'smoke'])?.toString())),
                      _rowAppDesign(theme, dark, '음주', _toLabel('drinking', pluck(['drinking', 'alcohol'])?.toString())),
                      _rowAppDesign(theme, dark, '한 줄 소개', _str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction']))),
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
                                '나를 소개하는...',
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
            // 하단: 채팅방에서는 닫기만, 게시판에서는 넘기기 + 가져가기
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
                          '닫기',
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
                              '넘기기',
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
                                            '가져가기',
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

/// 매칭 완료 시 (가져가기 수락 등) 전용 오버레이. 앱 전역에서 호출 가능. 다이얼로그가 닫힐 때까지 완료.
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
                '이제 대화를 시작해보세요 💕',
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

/// 가져가기 요청 전송 후: 카드 비행 + 성공 문구 (요청만 보낸 상태 → 상대 수락 시 매칭)
class _MatchCelebrationOverlay extends StatefulWidget {
  const _MatchCelebrationOverlay({
    required this.profile,
    required this.buildAvatar,
    this.requestOnly = true,
  });

  final Map<String, dynamic> profile;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  /// true: 요청만 보냄 문구 / false: 카드 획득 문구
  final bool requestOnly;

  @override
  State<_MatchCelebrationOverlay> createState() => _MatchCelebrationOverlayState();
}

class _MatchCelebrationOverlayState extends State<_MatchCelebrationOverlay> with TickerProviderStateMixin {
  static const _flyingDuration = Duration(milliseconds: 1500);
  static const _successDuration = Duration(milliseconds: 2000);

  late AnimationController _flyController;
  late AnimationController _heartController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this, duration: _flyingDuration);
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _flyController.forward().then((_) {
      if (!mounted) return;
      setState(() => _showSuccess = true);
      Future.delayed(_successDuration, () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    });
  }

  @override
  void dispose() {
    _flyController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  static double _lerp(List<double> keyframes, double t) {
    final n = keyframes.length - 1;
    final seg = (t * n).clamp(0.0, n.toDouble());
    final i = seg.floor().clamp(0, n - 1);
    final f = seg - i;
    return keyframes[i] + f * (keyframes[i + 1] - keyframes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.profile['nickname']?.toString() ?? '';
    final dark = Theme.of(context).brightness == Brightness.dark;
    const cardW = 256.0;
    const cardH = 320.0;
    final cardBg = Colors.grey.shade300;

    if (_showSuccess) {
      return _buildSuccessPhase(dark, nickname);
    }
    return AnimatedBuilder(
      animation: _flyController,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_flyController.value);
        final x = _lerp([0.0, -100.0, 100.0, 0.0], t);
        final y = _lerp([0.0, -200.0, -400.0, -600.0], t);
        final scale = _lerp([0.3, 0.5, 0.7, 0.2], t);
        final rotateDeg = _lerp([-15.0, 5.0, -10.0, 360.0], t);
        final rotateRad = rotateDeg * (math.pi / 180.0);
        final opacity = _lerp([0.8, 1.0, 1.0, 0.0], t).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: rotateRad,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: cardW,
                          height: cardH,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white.withOpacity(0.25), Colors.transparent],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 4),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: 128,
                                            height: 128,
                                            child: widget.buildAvatar(context, widget.profile),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        nickname,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(12, (i) {
              final angleRad = i * 30 * (math.pi / 180);
              final progress = _flyController.value;
              final rad = 150.0 * (progress < 0.5 ? progress * 2 : 1.0);
              final ox = rad * math.cos(angleRad);
              final oy = rad * math.sin(angleRad);
              final sparkOpacity = progress < 0.6 ? (progress / 0.6) : ((1 - progress) / 0.4).clamp(0.0, 1.0);
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + ox - 12,
                top: MediaQuery.of(context).size.height / 2 + oy - 12,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: sparkOpacity,
                    child: Icon(LucideIcons.sparkles, color: Colors.amber.shade400, size: 24),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
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
                AnimatedBuilder(
                  animation: _heartController,
                  builder: (context, _) {
                    final v = _heartController.value;
                    final scale = 1.0 + 0.2 * math.sin(math.pi * v);
                    final rotateDeg = 10 * math.sin(2 * math.pi * v);
                    return Transform.rotate(
                      angle: rotateDeg * (math.pi / 180),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(LucideIcons.heart, size: 80, color: Theme.of(context).colorScheme.primary),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  widget.requestOnly ? '요청을 보냈어요!' : '카드 획득!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.requestOnly
                      ? '$nickname님이 수락하면\n매칭이 성사돼요 💕'
                      : '$nickname님의 프로필을\n가져왔어요! 💕',
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

