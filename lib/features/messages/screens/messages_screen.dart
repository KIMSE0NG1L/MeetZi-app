import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/features/messages/data/partner_profile_repository.dart';
import 'package:nearo_app/features/matching_board/profile_detail_sheet.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.refreshTrigger});

  final ValueListenable<int>? refreshTrigger;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repository = ChatRepository();
  final _authRepository = AuthRepository();
  final _partnerProfileRepository = PartnerProfileRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];
  Map<String, int> _unreadCounts = {}; // roomId -> unread count
  Map<String, DateTime?> _lastMessageTimes = {}; // roomId -> last message time
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_onRefreshTriggerChanged);
    _initAndLoad();
  }

  @override
  void didUpdateWidget(covariant MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggerChanged);
      widget.refreshTrigger?.addListener(_onRefreshTriggerChanged);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggerChanged);
    super.dispose();
  }

  void _onRefreshTriggerChanged() {
    _loadRooms();
  }

  Future<void> _initAndLoad() async {
    try {
      final res = await _authRepository.getProfile();
      final user = res['user'] as Map<String, dynamic>?;
      final id = user?['id']?.toString() ?? res['id']?.toString();
      if (mounted) setState(() => _myUserId = id);
    } catch (_) {
      if (mounted) setState(() => _myUserId = null);
    }
    await _loadRooms();
  }

  Future<void> _loadUnreadCountsAndTimes() async {
    // 揶?獄쎻뫗????됱뵭?? 筌롫뗄?놅쭪? 揶쏆뮇??? 筌띾뜆?筌?筌롫뗄?놅쭪? ??볦퍢 ?④쑴沅?(??筌롫뗄?놅쭪?/?怨? 筌롫뗄?놅쭪? 餓???筌ㅼ뮄????볦퍢)
    Map<String, int> unreadCounts = {};
    Map<String, DateTime?> lastTimes = {};
    for (final room in _rooms) {
      final roomId = room['roomId']?.toString() ?? '';
      if (roomId.isEmpty) continue;
      try {
        final messages = await _repository.listMessages(roomId: roomId);
        int count = 0;
        DateTime? lastTime;
        for (final m in messages) {
          // ??userId揶쎛 ??곸몵筌?燁삳똻??紐낅릭筌왖 ??놁벉
          if (_myUserId == null) continue;
          // '?怨?揶쎛 癰귣?沅?筌롫뗄?놅쭪?'??욱? ??? ?袁⑹춦 ??? ??? 野껋럩??쭕?燁삳똻???
          final isFromPartner = m['senderId']?.toString() != _myUserId;
          final isUnreadFromPartner = isFromPartner && m['readAt'] == null;
          if (isUnreadFromPartner) count++;
          // 筌띾뜆?筌?筌롫뗄?놅쭪? ??볦퍢 ?곕뗄??(??筌롫뗄?놅쭪?/?怨? 筌롫뗄?놅쭪? 筌뤴뫀紐???釉?
          final createdAtRaw = m['createdAt']?.toString();
          final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
          if (createdAt != null && (lastTime == null || createdAt.isAfter(lastTime))) {
            lastTime = createdAt;
          }
        }
        unreadCounts[roomId] = count;
        lastTimes[roomId] = lastTime;
      } catch (_) {
        unreadCounts[roomId] = 0;
        lastTimes[roomId] = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _unreadCounts = unreadCounts;
      _lastMessageTimes = lastTimes;
    });
  }

  String? _resolvePhotoUrl(String? photoKey) {
    return photoUrlFromStorageKey(photoKey);
  }

  Widget _buildAvatar(String? photoUrl, String? avatarSeed, Map<String, String> avatarOptions, String partner) {
    const double avatarRadius = 28; // ??????由경에?癰궰野?(疫꿸퀡??ListTile leading ??由??筌띿쉸??
    
    // 1. ?袁⑥쨮????彛????됱몵筌??袁⑥쨮????彛???뽯뻻
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {
          // ???筌왖 嚥≪뮆諭???쎈솭 ???袁⑥뺍??嚥???媛?(???筌??袁⑹졐????쇰뻻 ??슢諭??????곸몵沃샕嚥???곕뼊 域밸챶?嚥???
        },
      );
    }
    
    // 2. ?袁⑥뺍?? ??뺣굡揶쎛 ??됱몵筌??袁⑥뺍?? ??뽯뻻 (chat_room_screen????덉뵬??獄쎻뫗??
    if (avatarSeed != null && avatarSeed.isNotEmpty) {
      final avatarUrl = diceBearAvatarUrl(avatarSeed, options: avatarOptions.isNotEmpty ? avatarOptions : null);
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: SvgPicture.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            placeholderBuilder: (_) => Icon(LucideIcons.user, size: avatarRadius, color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    // 3. ??????곸몵筌???곌퐬??筌?疫꼲????뽯뻻 (fallback)
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        partner.isNotEmpty ? partner.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: avatarRadius * 0.6,
        ),
      ),
    );
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final rooms = await _repository.listRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
      await _loadUnreadCountsAndTimes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rooms = [];
        _loading = false;
      });
    }
  }
  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '\uBC29\uAE08 \uC804';
    if (diff.inMinutes < 60) return '${diff.inMinutes}\uBD84 \uC804';
    if (diff.inHours < 24) return '${diff.inHours}\uC2DC\uAC04 \uC804';
    if (diff.inDays < 7) return '${diff.inDays}\uC77C \uC804';
    return '${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId: roomId);
    _loadRooms();
  }

  Future<void> _onAvatarTap(
    BuildContext context,
    Map<String, dynamic> room,
    String roomId,
    String? photoUrl,
    String? avatarSeed,
    Map<String, String> avatarOptions,
    String partner,
  ) async {
    String? matchId = room['matchId']?.toString();
    if (matchId == null || matchId.isEmpty) {
      try {
        final roomData = await _repository.getRoom(roomId: roomId);
        matchId = roomData['matchId']?.toString();
      } catch (_) {}
    }
    if (matchId == null || matchId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('\uD504\uB85C\uD544\uC744 \uBD88\uB7EC\uC62C \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.')),
        );
      }
      return;
    }
    try {
      final profile = await _partnerProfileRepository.getPartnerProfile(matchId: matchId);
      if (!context.mounted) return;
      String? profilePhotoUrl;
      final displayType = profile['boardDisplayType']?.toString() ?? (profile['user'] as Map?)?['boardDisplayType']?.toString();
      if (displayType == 'photo') {
        final photos = (profile['user'] as Map?)?['photos'] ?? profile['photos'];
        if (photos is List && photos.isNotEmpty && photos[0] is Map) {
          final key = (photos[0] as Map)['storageKey']?.toString();
          if (key != null) profilePhotoUrl = _resolvePhotoUrl(key);
        }
      }
      // 목록에서 이미 사진이 보이면(photoUrl) 그걸 우선 사용 (getPartnerProfile은 동의 전 photos:[] 반환)
      final effectivePhotoUrl = photoUrl ?? profilePhotoUrl;
      final user = profile['user'] as Map<String, dynamic>?;
      final seed = user?['avatarSeed']?.toString() ?? profile['avatarSeed']?.toString() ?? avatarSeed;
      Map<String, String> optsMap = avatarOptions;
      final rawOpts = user?['avatarOptions'] ?? profile['avatarOptions'];
      if (rawOpts != null) {
        if (rawOpts is Map) {
          optsMap = rawOpts.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        } else if (rawOpts is String) {
          try {
            final decoded = jsonDecode(rawOpts);
            if (decoded is Map<String, dynamic>) {
              optsMap = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
            }
          } catch (_) {}
        }
      }
      await showProfileDetailSheet(
        context,
        profile: profile,
        buildAvatar: (ctx, p) => _buildProfileModalAvatar(ctx, effectivePhotoUrl, seed, optsMap),
        hideMatchButton: true,
        overridePhotoUrlForEnlarge: effectivePhotoUrl,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('\uD504\uB85C\uD544\uC744 \uBD88\uB7EC\uC62C \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.')),
        );
      }
    }
  }

  Widget _buildProfileModalAvatar(BuildContext context, String? photoUrl, String? avatarSeed, Map<String, String> avatarOptions) {
    const double size = 96;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 48, color: Colors.grey.shade600),
        ),
      );
    }
    if (avatarSeed != null && avatarSeed.isNotEmpty) {
      final url = diceBearAvatarUrl(avatarSeed, options: avatarOptions.isNotEmpty ? avatarOptions : null);
      return ClipOval(
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholderBuilder: (_) => Icon(LucideIcons.user, size: 48, color: Colors.grey.shade600),
        ),
      );
    }
    return Icon(LucideIcons.user, size: 48, color: Colors.grey.shade600);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageCircle, size: 64, color: onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          '\uC544\uC9C1 \uBA54\uC2DC\uC9C0\uAC00 \uC5C6\uC5B4\uC694',
                          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\uAC8C\uC2DC\uD310\uC5D0\uC11C \uB9C8\uC74C\uC5D0 \uB4DC\uB294 \uD504\uB85C\uD544\uC744 \uCC3E\uC544\uBCF4\uC138\uC694.',
                          style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _initAndLoad();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: dark ? Colors.grey.shade800 : Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final partner = room['partnerNickname']?.toString() ?? '\uC54C \uC218 \uC5C6\uC74C';
                      final last = room['lastMessage']?.toString() ?? '';
                      final photoKey = room['partnerPhotoStorageKey']?.toString();
                      final photoUrl = _resolvePhotoUrl(photoKey);
                      final roomId = room['roomId']?.toString() ?? '';
                      final isActive = room['isActive'] == true;
                      final avatarSeed = room['partnerAvatarSeed']?.toString() ?? room['partnerUserId']?.toString();
                      final avatarOptionsRaw = room['partnerAvatarOptions']?.toString();
                      Map<String, String> avatarOptions = {};
                      if (avatarOptionsRaw != null && avatarOptionsRaw.isNotEmpty) {
                        try {
                        final decoded = jsonDecode(avatarOptionsRaw);
                        if (decoded is Map<String, dynamic>) {
                          avatarOptions = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
                        }
                      } catch (_) {}
                    }
                    int unread = _unreadCounts[roomId] ?? 0;
                    DateTime? lastTime = _lastMessageTimes[roomId];
                    String timeAgo = _formatTimeAgo(lastTime);

                    return Dismissible(
                      key: ValueKey(roomId),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('\uB300\uD654\uBC29 \uC0AD\uC81C'),
                            content: const Text('\uC774 \uB300\uD654\uBC29\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('\uCDE8\uC18C')),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('\uC0AD\uC81C')),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _deleteRoom(roomId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red.shade400,
                        child: const Icon(LucideIcons.trash2, color: Colors.white),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.chatRoom, arguments: {
                                  'roomId': roomId,
                                  'partnerNickname': partner,
                                  'isActive': isActive,
                                  'partnerPhotoStorageKey': photoKey,
                                  'partnerAvatarSeed': avatarSeed,
                                  'partnerAvatarOptions': avatarOptionsRaw,
                                })
                                .then((value) {
                              if (value == true) _loadRooms();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _onAvatarTap(context, room, roomId, photoUrl, avatarSeed, avatarOptions, partner),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                                    ),
                                    child: _buildAvatar(photoUrl, avatarSeed, avatarOptions, partner),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              partner,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (timeAgo.isNotEmpty)
                                            Text(
                                              timeAgo,
                                              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isActive ? last : '\uB9E4\uCE6D\uC774 \uCDE8\uC18C\uB41C \uB300\uD654\uC785\uB2C8\uB2E4.',
                                              style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (unread > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                unread.toString(),
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.chevronRight, color: onSurfaceVariant, size: 24),
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
    );
  }
}
