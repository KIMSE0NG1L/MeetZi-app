import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/features/community/screens/community_screen.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Map<String, String> _parseAvatarOptions(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    final s = raw.toString();
    if (s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (_) {}
    return {};
  }

    String _toLabel(String field, dynamic value) {
      final s = value?.toString().trim();
      if (s == null || s.isEmpty) return '-';
      switch (field) {
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
        case 'activityTime':
          switch (s.toLowerCase()) {
            case 'morning': return '아침형';
            case 'daytime': return '낮 활동형';
            case 'evening': return '저녁형';
            case 'night_owl': return '야행성';
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
        case 'smoking':
          if (value is bool) return value ? '흡연' : '비흡연';
          switch (s.toLowerCase()) {
            case 'none': return '비흡연';
            case 'sometimes': return '가끔';
            case 'often': return '자주';
            default: return s;
          }
        case 'drinking':
          if (value is bool) return value ? '음주' : '비음주';
          switch (s.toLowerCase()) {
            case 'none': return '안 함';
            case 'sometimes': return '가끔';
            case 'often': return '자주';
            default: return s;
          }
        default:
          return s;
      }
    }
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await AuthRepository().getProfile();
      final profile = (res['user'] as Map<String, dynamic>?) ?? res as Map<String, dynamic>;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 프로필 방식(사진/아바타)에 따라 내 프로필 이미지 위젯
  Widget _buildMyProfileAvatar() {
    final displayType = _profile?['boardDisplayType']?.toString();
    final photos = _profile?['photos'];
    if (displayType == 'photo' && photos is List && photos.isNotEmpty && photos[0] is Map) {
      final first = photos[0] as Map<String, dynamic>;
      final storageKey = first['storageKey']?.toString();
      final photoUrl = storageKey != null && storageKey.isNotEmpty
          ? photoUrlFromStorageKey(storageKey)
          : null;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        return CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.network(
              photoUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        );
      }
    }
    final seed = _profile?['avatarSeed']?.toString() ?? _profile?['id']?.toString();
    final options = _parseAvatarOptions(_profile?['avatarOptions']);
    final style = _profile?['avatarStyle'] ?? (_profile?['user'] as Map?)?['avatarStyle'];
    if (seed != null && seed.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: SizedBox(
            width: 96,
            height: 96,
            child: SvgPicture.network(
              diceBearAvatarUrl(
                seed,
                style: style?.toString() ?? 'lorelei',
                options: options.isNotEmpty ? options : null,
              ),
              fit: BoxFit.cover,
              placeholderBuilder: (context) => Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.white,
      child: Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.primary),
    );
  }

  /// 사진/아바타 탭 시 크게 보기
  void _showAvatarLarge() {
    final displayType = _profile?['boardDisplayType']?.toString();
    dynamic photos = _profile?['photos'];
    if (photos is! List && _profile?['user'] is Map) {
      photos = (_profile!['user'] as Map)['photos'];
    }
    String? photoUrl;
    if (displayType == 'photo' && photos is List && photos.isNotEmpty && photos[0] is Map) {
      final first = photos[0] as Map<String, dynamic>;
      final storageKey = first['storageKey']?.toString();
      if (storageKey != null && storageKey.isNotEmpty) {
        photoUrl = photoUrlFromStorageKey(storageKey);
      }
    }
    final seed = _profile?['avatarSeed']?.toString() ?? _profile?['id']?.toString();
    final options = _parseAvatarOptions(_profile?['avatarOptions']);
    final style = _profile?['avatarStyle'] ?? (_profile?['user'] as Map?)?['avatarStyle'];
    final avatarUrl = seed != null && seed.isNotEmpty
        ? diceBearAvatarUrl(seed, style: style?.toString() ?? 'lorelei', options: options.isNotEmpty ? options : null)
        : null;

    if (photoUrl == null && avatarUrl == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: GestureDetector(
            onTap: () {}, // 내부 탭 시 닫히지 않게
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 120, color: Colors.grey.shade400),
                            )
                          : avatarUrl != null
                              ? SvgPicture.network(
                                  avatarUrl,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (_) => Icon(LucideIcons.user, size: 120, color: Colors.grey.shade400),
                                )
                              : Icon(LucideIcons.user, size: 120, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '탭하면 닫기',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;
    final contentBg = dark ? const Color(0xFF374151).withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final onContent = dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);

    String _tag(String? v) => (v == null || v.toString().trim().isEmpty || v == '-') ? '' : v.toString().trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: onSurfaceVariant)))
                : _profile == null
                    ? Center(child: Text('프로필 정보가 없습니다.', style: TextStyle(color: onSurfaceVariant)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                          children: [
                            // ad: 한 장의 카드 — 아바타·닉네임 + 태그·키워드·프로필 수정 (글래스모피즘)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: _glass(
                                borderRadius: BorderRadius.circular(24),
                                dark: dark,
                                color: dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
                                child: Column(
                                children: [
                                  // 아바타·닉네임·학교
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: primary.withValues(alpha: 0.4), width: 4),
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16)],
                                          ),
                                          child: GestureDetector(
                                            onTap: _showAvatarLarge,
                                            behavior: HitTestBehavior.opaque,
                                            child: _buildMyProfileAvatar(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _profile?['nickname']?.toString() ?? '',
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(LucideIcons.mapPin, size: 16, color: onSurfaceVariant),
                                            const SizedBox(width: 6),
                                            Text(
                                              _profile?['affiliationText']?.toString() ?? _profile?['school']?.toString() ?? '-',
                                              style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                                  // 태그·한줄소개·키워드·프로필 수정 — 좌우 여백 통일
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.start,
                                          runAlignment: WrapAlignment.start,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _infoTag(_tag(_profile?['department']?.toString()), dark),
                                            _infoTag(_profile?['gender']?.toString() == 'male' ? '남성' : (_profile?['gender']?.toString() == 'female' ? '여성' : ''), dark),
                                            _infoTag(_tag(_profile?['affiliationText']?.toString() ?? _profile?['school']?.toString()), dark),
                                            _infoTag(_profile?['heightCm'] != null ? '${_profile!['heightCm']}cm' : '', dark),
                                            _infoTag(_toLabel('gradeYear', _profile?['gradeYear']), dark),
                                            _infoTag(_profile?['mbti']?.toString() ?? '', dark),
                                            _infoTag(_toLabel('smoking', _profile?['isSmoking'] ?? _profile?['smoking']), dark),
                                            _infoTag(_toLabel('drinking', _profile?['isDrinking'] ?? _profile?['drinking']), dark),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (_tag(_profile?['introOneLine']?.toString()).isNotEmpty) ...[
                                          _contentBox('💬', _profile!['introOneLine']!.toString(), contentBg, onContent),
                                          const SizedBox(height: 12),
                                        ],
                                        if (_tag(_profile?['intoLately']?.toString()).isNotEmpty) ...[
                                          _contentBox('✨ 요즘 빠진 것', _profile!['intoLately']!.toString(), contentBg, onContent),
                                          const SizedBox(height: 12),
                                        ],
                                        if (_tag(_profile?['idealType']?.toString()).isNotEmpty) ...[
                                          _contentBox('💕 이상형', _profile!['idealType']!.toString(), contentBg, onContent),
                                          const SizedBox(height: 12),
                                        ],
                                        Wrap(
                                          alignment: WrapAlignment.start,
                                          runAlignment: WrapAlignment.start,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (_toLabel('fashionStyle', _profile?['fashionStyle']).isNotEmpty && _toLabel('fashionStyle', _profile?['fashionStyle']) != '-')
                                              _infoTag('👔 ${_toLabel('fashionStyle', _profile?['fashionStyle'])}', dark),
                                            if (_toLabel('preferredDateType', _profile?['preferredDateType']).isNotEmpty && _toLabel('preferredDateType', _profile?['preferredDateType']) != '-')
                                              _infoTag('☕ ${_toLabel('preferredDateType', _profile?['preferredDateType'])}', dark),
                                            if (_toLabel('activityTime', _profile?['activityTime']).isNotEmpty && _toLabel('activityTime', _profile?['activityTime']) != '-')
                                              _infoTag('🕐 ${_toLabel('activityTime', _profile?['activityTime'])}', dark),
                                          ],
                                        ),
                                        if (_profile?['idealTypeKeywords'] is List && (_profile!['idealTypeKeywords'] as List).isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            '# 나를 소개하는 키워드',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            alignment: WrapAlignment.start,
                                            runAlignment: WrapAlignment.start,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: ((_profile!['idealTypeKeywords'] as List).map((e) => e?.toString() ?? '')).where((s) => s.isNotEmpty).map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: ThemeController.getSheetGradient(),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text('#$tag', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                            )).toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        // ad: 커뮤니티 활동 관리 (내 글 / 내 댓글)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildCommunityLink(
                                                context: context,
                                                title: '내 글',
                                                icon: LucideIcons.fileText,
                                                scope: 'my_posts',
                                                dark: dark,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildCommunityLink(
                                                context: context,
                                                title: '내 댓글',
                                                icon: LucideIcons.messageSquare,
                                                scope: 'my_comments',
                                                dark: dark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileSetup, arguments: true),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                                              ),
                                              child: _glass(
                                                borderRadius: BorderRadius.circular(12),
                                                dark: dark,
                                                color: primary.withOpacity(0.55),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(LucideIcons.pencil, color: Colors.white, size: 20),
                                                      SizedBox(width: 8),
                                                      Text('프로필 수정하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                    ],
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
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  /// 카드/버튼 공통 글래스모피즘 래퍼. 그림자는 바깥에서 그리고, 여기선 블러+반투명만 담당한다.
  Widget _glass({
    required Widget child,
    required BorderRadius borderRadius,
    Color? color,
    bool dark = false,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white.withOpacity(dark ? 0.08 : 0.55)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _infoTag(String value, bool dark) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: dark ? null : ThemeController.getSheetGradient(),
        color: dark ? const Color(0xFF374151) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: dark ? const Color(0xFFE5E7EB) : Colors.white,
        ),
      ),
    );
  }

  Widget _contentBox(String prefix, String text, Color bg, Color textColor) {
    final display = prefix.isEmpty ? text : (prefix.length <= 2 ? '$prefix $text' : '$prefix: $text');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        display,
        style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
      ),
    );
  }

  Widget _buildCommunityLink({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String scope,
    required bool dark,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final envId = _profile?['environmentId']?.toString() ?? _profile?['school']?['id']?.toString() ?? 'global';
          final schoolName = _profile?['schoolName']?.toString() ?? _profile?['school']?['name']?.toString() ?? '우리 학교';
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CommunityScreen(
                environmentId: envId,
                schoolName: schoolName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: _glass(
          borderRadius: BorderRadius.circular(12),
          dark: dark,
          color: dark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : Colors.grey.shade800,
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
