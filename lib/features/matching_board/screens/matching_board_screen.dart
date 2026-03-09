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

/// ?袁⑥쨮??筌???MeetzyProfileDetailData (last ?怨멸쉭 筌뤴뫀???
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
          case 'male': return '?⑥꽦';
          case 'female': return '?ъ꽦';
          default: return s;
        }
      case 'gradeYear':
        switch (s.toLowerCase()) {
          case 'one': return '1';
          case 'two': return '2';
          case 'three': return '3';
          case 'four': return '4';
          case 'five': return '5';
          case 'graduation_deferred': return '議몄뾽?좎삁';
          default: return s;
        }
      case 'smoking':
        switch (s.toLowerCase()) {
          case 'none': return '鍮꾪씉??;
          case 'sometimes': return '媛??;
          case 'often': return '?먯＜';
          default: return s;
        }
      case 'drinking':
        switch (s.toLowerCase()) {
          case 'none': return '鍮꾩쓬二?;
          case 'sometimes': return '媛??;
          case 'often': return '?먯＜';
          default: return s;
        }
      case 'fashionStyle':
        switch (s.toLowerCase()) {
          case 'hood_casual': return '?꾨뱶/罹먯＜??;
          case 'shirt_neat': return '?붿툩/?⑥젙';
          case 'street': return '?ㅽ듃由?;
          case 'knit': return '?덊듃/媛먯꽦';
          case 'sporty': return '?ㅽ룷??;
          case 'minimal': return '誘몃땲硫';
          case 'hip': return '?숉븳';
          default: return s;
        }
      case 'preferredDateType':
        switch (s.toLowerCase()) {
          case 'cafe': return '移댄럹';
          case 'walk': return '?곗콉';
          case 'movie': return '?곹솕';
          case 'drink': return '?좎옄由?;
          case 'exercise': return '?대룞';
          case 'food_tour': return '留쏆쭛 ?먮갑';
          case 'drive': return '?쒕씪?대툕';
          default: return s;
        }
      case 'activityTime':
        switch (s.toLowerCase()) {
          case 'morning': return '?꾩묠??;
          case 'daytime': return '二쇨컙??;
          case 'evening': return '??곹삎';
          case 'night_owl': return '?쇳뻾??;
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

/// 筌?쑵?????紐??癒?퐣 ?袁⑥쨮????쀫뱜筌?癰???????(hideActionButtons: true ????띾┛疫?揶쎛?硫?疫???쑵紐??
Future<void> showBoardNoteSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> profiles,
  int startIndex = 0,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  VoidCallback? onPop,
  int myMatchingTicket = 0,
  Future<void> Function()? onRefreshTickets,
  Future<bool> Function(String profileId, Map<String, dynamic> profile)? onTakeNote,
  /// true筌???띾┛疫?揶쎛?硫?疫?甕곌쑵????? (筌?쑵?욤쳸?밸퓠???袁⑥쨮??癰귣떯由??
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
    barrierLabel: '??る┛',
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
  bool _isOpeningSheet = false; // 燁삳?諭??怨? 獄쎻뫗?: ??쀫뱜 ???????덈툧 ?곕떽? ???얜똻??
  int? _myCredit;
  MyTickets? _myTickets;
  int _receivedRequestCount = 0;
  late Future<Map<String, dynamic>> _myProfileFuture;
  String? _preferredGender;

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
    if (g == 'male' || g == '??κ쉐') return 'female';
    if (g == 'female' || g == '??苑?) return 'male';
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

  /// ???源낇??獄쏆꼶?筌?野껊슣??癒?퓠 ?紐꾪뀱 (??μ쁽 ?④쑴???????꾬쭕? ?????④쑴??????μ쁽筌?
  Future<void> _fetchProfiles() async {
    setState(() => _loading = true);
    try {
      String? preferredGender = _preferredGender;
      try {
        final profile = await _myProfileFuture;
        final raw = profile['user'] is Map ? profile['user'] as Map : profile;
        final g = raw['gender']?.toString().trim().toLowerCase();
        if (g == 'male' || g == '??κ쉐') {
          preferredGender = 'female';
        } else if (g == 'female' || g == '??苑?) {
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
        const SnackBar(content: Text('?깅줉沅뚯씠 遺議깊빐?? ?깅줉沅뚯쑝濡?寃뚯떆?먯뿉 ?깅줉?섎㈃ 留ㅼ묶沅?1?μ씠 吏湲됰맗?덈떎.')),
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
      String school = user['school']?.toString() ?? user['affiliationText']?.toString() ?? profile['affiliationText']?.toString() ?? '?紐꾩쪒??';
      final department = user['department']?.toString();
      final userEnvs = profile['userEnvironments'] ?? user['userEnvironments'];
      if ((school.isEmpty || school == 'null') && userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
        final first = userEnvs[0];
        if (first is Map && first['environment'] is Map) {
          final name = (first['environment'] as Map)['name']?.toString();
          if (name != null && name.isNotEmpty) school = name;
        }
      }
      if (school.isEmpty || school == 'null') school = '?紐꾩쪒??';
      if (nickname == null || nickname.isEmpty || gender == null || gender.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('?袁⑥쨮???類ｋ궖揶쎛 ??곷뮸??덈뼄.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('?꾨줈???깅줉 ?꾨즺! 留ㅼ묶沅?1?μ씠 吏湲됰릱?댁슂.')));
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
        final myNickname = profileData?['nickname']?.toString() ?? raw?['nickname']?.toString() ?? '??;
        final meProfile = profileData != null
            ? {'user': profileData, 'userId': myUserId, 'nickname': myNickname}
            : null;
        // ??? ?源낆쨯??燁삳?諭??野껊슣??癒?퓠 癰귣똻?좑쭪? ??낅즲嚥???뽰뇚
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
            matchingTicket: _myTickets?.matchingTicket ?? 0,
            receivedRequestCount: _receivedRequestCount,
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
      // ad ProfileDetailModal: ??용┛ = ?袁⑥삋?癒?퐣 ?????諭???+ 獄쏄퀗瑗???륁뵠?? ??る┛ = ?袁⑥삋嚥??????諭???쇱뒲 + 獄쏄퀗瑗???륁뵠??
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '??る┛',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutCubic;
          final t = curve.transform(animation.value);
          final barrierOpacity = 0.6 * t;
          final slideY = 700.0 * (1.0 - t); // ??용┛: 700??, ??る┛: 0??00
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
                            final ok = await _takeNote(profileId, tappedProfile);
                            if (!ctx.mounted) return;
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

  Future<bool> _takeNote(String profileId, Map<String, dynamic> profile) async {
    final matchingTicket = _myTickets?.matchingTicket ?? 0;
    if (matchingTicket <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭권이 부족해요. 매칭권을 구매한 뒤 매칭 요청을 보내주세요.')),
      );
      return false;
    }
    final message = await showModalBottomSheet<String?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TakeNoteMessageSheet(profile: profile),
    );
    if (!mounted || message == null) return false;
    final trimmed = message.trim();
    if (trimmed.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지는 5자 이상 입력해주세요')),
      );
      return false;
    }
    try {
      await _repository.takeNote(profileId, message: trimmed);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청을 보냈어요. 상대가 수락하면 매칭돼요.')),
      );
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

/// ad ProfileDetailModal "筌??紐꾧텢???袁る퉸癰귣똻苑?? 筌롫뗄?놅쭪? ??낆젾 ??쀫뱜: ??롫뼊 ??쀫뱜, 域밸챶??怨쀬뵠????삳쐭, ?袁⑥쨮??沃섎챶?곮퉪?용┛, 5????곴맒/200?? ?袁⑸꽊 甕곌쑵??
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
              // Header (ad: gradient, "筌??紐꾧텢???袁る퉸癰귣똻苑??, X, subtitle)
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
                        '泥??몄궗瑜??대낫?몄슂',
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
                    '${nickname.isNotEmpty ? nickname : '?곷?'}?섏뿉寃?蹂대궪 硫붿떆吏瑜??묒꽦?댁＜?몄슂',
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
                  // Profile preview (ad: avatar + nickname + school 夷?major)
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
                                nickname.isNotEmpty ? nickname : '?꾨줈??,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [school, major].where((s) => s.isNotEmpty).join(' 쨌 '),
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
                          hintText: '?덈뀞?섏꽭?? ?꾨줈?꾩쓣 蹂닿퀬 愿?ъ씠 ?앷꺼 硫붿떆吏 蹂대깄?덈떎 :)',
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
                                ? '좋아요! 이제 전송할 수 있어요 💕'
                                : '최소 $_minLength자 이상 입력해주세요 (현재 ${_controller.text.length}자)',
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
                  // Send button (ad: "筌롫뗄?놅쭪? 癰귣?沅→?燁삳?諭?揶쎛?硫?疫?)
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
                              _isValid ? '硫붿떆吏 蹂대궡怨?移대뱶 媛?멸?湲? : '硫붿떆吏瑜??낅젰?댁＜?몄슂',
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
      final opts = profile['avatarOptions'] as Map<String, String>? ?? (profile['user'] as Map?)?['avatarOptions'] as Map<String, String>?;
      final options = opts != null && opts.isNotEmpty ? opts : null;
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

/// Design MeetZyBoard ????? ???뷸쾮??源낆쨯亦?筌띲끉臾뜻쾮?(??곌볼 + ???덌쭪? + 揶쏆뮇??
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

/// ?源낆쨯/????筌띲끉臾뜻쾮?獄?퍔? (?袁⑹뵠??+ 揶쏆뮇?뷂쭕?
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
          content: const Text('留ㅼ묶沅뚯씠 遺議깊빐?? ?곸젏?먯꽌 留ㅼ묶沅뚯쓣 援щℓ??二쇱꽭??'),
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
        throw Exception('?꾨줈??ID瑜?李얠쓣 ???놁뒿?덈떎.');
      }
      final sent = await widget.onTakeNote(profileId, _profile);
      if (widget.onRefreshTickets != null) await widget.onRefreshTickets!();
      if (!mounted) return;
      setState(() => _taking = false);
      if (!sent) return; // ?띯뫁???뉕탢????쎈솭 ???곕벤釉?????
      // AppDesign ProfileDetailModal: 燁삳?諭???쑵六?1.5??+ ??쎈솁??12 ???源껊궗 ?얜㈇??2??
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

  /// ?袁⑥쨮????륁젟 ??낆젾??????덉뵬????볥럢????곌볼嚥???뽯뻻
  static String _toLabel(String? field, dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return '-';
    switch (field) {
      case 'gender':
        switch (s.toLowerCase()) {
          case 'male': return '?⑥꽦';
          case 'female': return '?ъ꽦';
          default: return s;
        }
      case 'gradeYear':
        switch (s.toLowerCase()) {
          case 'one': return '1';
          case 'two': return '2';
          case 'three': return '3';
          case 'four': return '4';
          case 'five': return '5';
          case 'graduation_deferred': return '議몄뾽?좎삁';
          default: return s;
        }
      case 'smoking':
        switch (s.toLowerCase()) {
          case 'none': return '鍮꾪씉??;
          case 'sometimes': return '媛??;
          case 'often': return '?먯＜';
          default: return s;
        }
      case 'drinking':
        switch (s.toLowerCase()) {
          case 'none': return '鍮꾩쓬二?;
          case 'sometimes': return '媛??;
          case 'often': return '?먯＜';
          default: return s;
        }
      case 'fashionStyle':
        switch (s.toLowerCase()) {
          case 'hood_casual': return '?꾨뱶/罹먯＜??;
          case 'shirt_neat': return '?붿툩/?⑥젙';
          case 'street': return '?ㅽ듃由?;
          case 'knit': return '?덊듃/媛먯꽦';
          case 'sporty': return '?ㅽ룷??;
          case 'minimal': return '誘몃땲硫';
          case 'hip': return '?숉븳';
          default: return s;
        }
      case 'preferredDateType':
        switch (s.toLowerCase()) {
          case 'cafe': return '移댄럹';
          case 'walk': return '?곗콉';
          case 'movie': return '?곹솕';
          case 'drink': return '?좎옄由?;
          case 'exercise': return '?대룞';
          case 'food_tour': return '留쏆쭛 ?먮갑';
          case 'drive': return '?쒕씪?대툕';
          default: return s;
        }
      case 'activityTime':
        switch (s.toLowerCase()) {
          case 'morning': return '?꾩묠??;
          case 'daytime': return '二쇨컙??;
          case 'evening': return '??곹삎';
          case 'night_owl': return '?쇳뻾??;
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

    // AppDesign ProfileDetailModal: ???춳 primary 域밸챶??怨쀬뵠????삳쐭, ?袁⑥뺍??+??곌퐬?? ??쎄쾿嚥??類ｋ궖+??볥젃, ??롫뼊 ??る┛/揶쎛?硫?疫?
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
            // ??삳쐭: 域밸챶??怨쀬뵠??+ ??뺤삋域??紐껊굶 + X + ?袁⑥뺍?? + ??곌퐬??(?誘れ뵠 200??곗쨮 ??살쒔???쨮??獄쎻뫗?)
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
            // ??쎄쾿嚥? ?類ｋ궖 ??+ ??볥젃
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
                      _rowAppDesign(theme, dark, '?숆낵', _str(pluck(['department', 'major', 'departmentName']))),
                      _rowAppDesign(theme, dark, '?깅퀎', _toLabel('gender', pluck(['gender', 'sex'])?.toString())),
                      _rowAppDesign(theme, dark, '?뚯냽', _str(pluck(['affiliation', 'school', 'affiliationText', 'organization']))),
                      _rowAppDesign(theme, dark, '??, pluck(['heightCm', 'height']) != null ? '${pluck(['heightCm', 'height'])} cm' : '-'),
                      _rowAppDesign(theme, dark, '?숇뀈', _toLabel('gradeYear', pluck(['grade', 'year', 'schoolYear', 'class']))),
                      _rowAppDesign(theme, dark, 'MBTI', _str(pluck(['mbti', 'mbtiType']))),
                      _rowAppDesign(theme, dark, '?≪뿰', _toLabel('smoking', pluck(['smoking', 'smoke'])?.toString())),
                      _rowAppDesign(theme, dark, '?뚯＜', _toLabel('drinking', pluck(['drinking', 'alcohol'])?.toString())),
                      _rowAppDesign(theme, dark, '?먭린?뚭컻', _str(pluck(['oneLineIntroduce', 'introOneLine', 'bio', 'introduction']))),
                      _rowAppDesign(theme, dark, '?붿쬁 鍮좎쭊 寃?, _str(pluck(['intoLately', 'hobby', 'recentInterest']))),
                      _rowAppDesign(theme, dark, '?댁긽??, _str(pluck(['idealType', 'ideal']))),
                      _rowAppDesign(theme, dark, '?⑥뀡 ?ㅽ???, _toLabel('fashionStyle', pluck(['fashionStyle', 'style']))),
                      _rowAppDesign(theme, dark, '?좏샇 ?곗씠??, _toLabel('preferredDateType', pluck(['preferredDateType', 'preferredDate']))),
                      _rowAppDesign(theme, dark, '?쒕룞 ?쒓컙', _toLabel('activityTime', pluck(['activityTime', 'activeTime']))),
                      if (listTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 112,
                              child: Text(
                                '?섎? ?뚭컻?섎뒗 ?쒓렇',
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
            // ??롫뼊: 筌?쑵?욤쳸?밸퓠??뺣뮉 ??る┛筌? 野껊슣??癒?퓠??뺣뮉 ??띾┛疫?+ 揶쎛?硫?疫?
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
                              '?섍린湲?,
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
                                            '留ㅼ묶?섍린',
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

/// 筌띲끉臾??袁⑥┷ ??(揶쎛?硫?疫???롮뵭 ?? ?袁⑹뒠 ??살쒔??됱뵠. ???袁⑸열?癒?퐣 ?紐꾪뀱 揶쎛?? ??쇱뵠??곗쨮域밸㈇? ???쁽 ???돱筌왖 ?袁⑥┷.
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
                '留ㅼ묶 ?꾨즺!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '??곸젫 ???遺? ??뽰삂????紐꾩뒄 ?裕?,
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

/// 揶쎛?硫?疫??遺욧퍕 ?袁⑸꽊 ?? 燁삳?諭???쑵六?+ ?源껊궗 ?얜㈇??(?遺욧퍕筌?癰귣?沅??怨밴묶 ???怨? ??롮뵭 ??筌띲끉臾?
class _MatchCelebrationOverlay extends StatefulWidget {
  const _MatchCelebrationOverlay({
    required this.profile,
    required this.buildAvatar,
    this.requestOnly = true,
  });

  final Map<String, dynamic> profile;
  final Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar;
  /// true: ?遺욧퍕筌?癰귣?源??얜㈇??/ false: 燁삳?諭???얜굣 ?얜㈇??
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
                  widget.requestOnly ? '?붿껌??蹂대깉?댁슂!' : '移대뱶 ?띾뱷!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.requestOnly
                      ? '$nickname?섏씠 ?섎씫?섎㈃\n留ㅼ묶???깆궗?쇱슂.'
                      : '$nickname?섏쓽 ?꾨줈?꾩쓣\n媛?몄솕?댁슂!',
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

