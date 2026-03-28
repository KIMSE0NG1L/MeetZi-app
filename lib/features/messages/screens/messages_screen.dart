import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/matching_board/profile_detail_sheet.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/features/messages/data/partner_profile_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/shared/utils/profanity_mask.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with RouteAware, WidgetsBindingObserver {
  final _repository = ChatRepository();
  final _partnerProfileRepository = PartnerProfileRepository();

  bool _loading = true;
  bool _routeObserverSubscribed = false;
  List<Map<String, dynamic>> _rooms = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRooms();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _loadRooms(showLoader: false),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        _routeObserverSubscribed = true;
      }
    }
  }

  @override
  void didPopNext() {
    _loadRooms(showLoader: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRooms(showLoader: false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_routeObserverSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  Future<void> _loadRooms({bool showLoader = true}) async {
    if (!mounted) return;
    if (showLoader) {
      setState(() => _loading = true);
    }

    try {
      _repository.clearAllCache();
      final rooms = await _repository.listRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load rooms: $e');
      if (!mounted) return;
      setState(() {
        _rooms = [];
        _loading = false;
      });
    }
  }

  String? _resolvePhotoUrl(String? photoKey) {
    return photoUrlFromStorageKey(photoKey);
  }

  Widget _buildAvatar(
    String? photoUrl,
    String? avatarSeed,
    Map<String, String> avatarOptions,
    String partner,
  ) {
    const double avatarRadius = 28;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    if (avatarSeed != null && avatarSeed.isNotEmpty) {
      final avatarUrl = diceBearAvatarUrl(
        avatarSeed,
        options: avatarOptions.isNotEmpty ? avatarOptions : null,
      );
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: SvgPicture.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            placeholderBuilder: (_) => Icon(
              LucideIcons.user,
              size: avatarRadius,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

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

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseServerDateTime(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  Future<void> _deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId: roomId);
    await _loadRooms(showLoader: false);
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
      } catch (e) {
        debugPrint('Failed to get matchId for room: $e');
      }
    }
    if (matchId == null || matchId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필을 불러올 수 없어요.')),
        );
      }
      return;
    }
    try {
      final profile =
          await _partnerProfileRepository.getPartnerProfile(matchId: matchId);
      if (!context.mounted) return;

      String? profilePhotoUrl;
      final displayType = profile['boardDisplayType']?.toString() ??
          (profile['user'] as Map?)?['boardDisplayType']?.toString();
      if (displayType == 'photo') {
        final photos =
            (profile['user'] as Map?)?['photos'] ?? profile['photos'];
        if (photos is List && photos.isNotEmpty && photos[0] is Map) {
          final key = (photos[0] as Map)['storageKey']?.toString();
          if (key != null) {
            profilePhotoUrl = _resolvePhotoUrl(key);
          }
        }
      }

      final effectivePhotoUrl = photoUrl ?? profilePhotoUrl;
      final user = profile['user'] as Map<String, dynamic>?;
      final seed = user?['avatarSeed']?.toString() ??
          profile['avatarSeed']?.toString() ??
          avatarSeed;
      Map<String, String> optsMap = avatarOptions;
      final rawOpts = user?['avatarOptions'] ?? profile['avatarOptions'];
      if (rawOpts != null) {
        if (rawOpts is Map) {
          optsMap = rawOpts
              .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        } else if (rawOpts is String) {
          try {
            final decoded = jsonDecode(rawOpts);
            if (decoded is Map<String, dynamic>) {
              optsMap = decoded
                  .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
            }
          } catch (_) {}
        }
      }
      await showProfileDetailSheet(
        context,
        profile: profile,
        buildAvatar: (ctx, p) =>
            _buildProfileModalAvatar(ctx, effectivePhotoUrl, seed, optsMap),
        hideMatchButton: true,
        overridePhotoUrlForEnlarge: effectivePhotoUrl,
      );
    } catch (e) {
      debugPrint('Failed to load partner profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필을 불러올 수 없어요.')),
        );
      }
    }
  }

  Widget _buildProfileModalAvatar(
    BuildContext context,
    String? photoUrl,
    String? avatarSeed,
    Map<String, String> avatarOptions,
  ) {
    const double size = 96;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            LucideIcons.user,
            size: 48,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    if (avatarSeed != null && avatarSeed.isNotEmpty) {
      final url = diceBearAvatarUrl(
        avatarSeed,
        options: avatarOptions.isNotEmpty ? avatarOptions : null,
      );
      return ClipOval(
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholderBuilder: (_) => Icon(
            LucideIcons.user,
            size: 48,
            color: Colors.grey.shade600,
          ),
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
                          Icon(LucideIcons.messageCircle,
                              size: 64, color: onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            '아직 메시지가 없어요',
                            style: TextStyle(
                                fontSize: 16, color: onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '게시판에서 마음에 드는 프로필을 찾아보세요',
                            style: TextStyle(
                                fontSize: 14, color: onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadRooms(showLoader: false),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            dark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final partner =
                            room['partnerNickname']?.toString() ?? '상대';
                        final last = maskProfanity(room['lastMessage']?.toString() ?? '');
                        final photoKey =
                            room['partnerPhotoStorageKey']?.toString();
                        final photoUrl = _resolvePhotoUrl(photoKey);
                        final roomId = room['roomId']?.toString() ?? '';
                        final isActive = room['isActive'] == true;
                        final avatarSeed =
                            room['partnerAvatarSeed']?.toString() ??
                                room['partnerUserId']?.toString();
                        final avatarOptionsRaw =
                            room['partnerAvatarOptions']?.toString();
                        Map<String, String> avatarOptions = {};
                        if (avatarOptionsRaw != null &&
                            avatarOptionsRaw.isNotEmpty) {
                          try {
                            final decoded = jsonDecode(avatarOptionsRaw);
                            if (decoded is Map<String, dynamic>) {
                              avatarOptions = decoded.map((k, v) =>
                                  MapEntry(k.toString(), v?.toString() ?? ''));
                            }
                          } catch (_) {}
                        }

                        final unread =
                            (room['unreadCount'] as num?)?.toInt() ?? 0;
                        final lastTimeRaw = room['lastMessageAt']?.toString();
                        final lastTime = _parseServerDateTime(lastTimeRaw);
                        final timeAgo = _formatTimeAgo(lastTime);

                        return Dismissible(
                          key: ValueKey(roomId),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('대화방 삭제'),
                                    content: const Text('이 대화방을 목록에서 제거할까요?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('삭제'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) => _deleteRoom(roomId),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red.shade400,
                            child: const Icon(LucideIcons.trash2,
                                color: Colors.white),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chatRoom,
                                  arguments: {
                                    'roomId': roomId,
                                    'partnerNickname': partner,
                                    'isActive': isActive,
                                    'partnerPhotoStorageKey': photoKey,
                                    'partnerAvatarSeed': avatarSeed,
                                    'partnerAvatarOptions': avatarOptionsRaw,
                                  },
                                ).then((_) {
                                  _loadRooms(showLoader: false);
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _onAvatarTap(
                                        context,
                                        room,
                                        roomId,
                                        photoUrl,
                                        avatarSeed,
                                        avatarOptions,
                                        partner,
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: _buildAvatar(photoUrl,
                                            avatarSeed, avatarOptions, partner),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  partner,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: onSurface,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (timeAgo.isNotEmpty)
                                                Text(
                                                  timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isActive
                                                      ? last
                                                      : '매칭이 종료된 대화입니다.',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: onSurfaceVariant,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (unread > 0)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    unread.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(LucideIcons.chevronRight,
                                        color: onSurfaceVariant, size: 24),
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
