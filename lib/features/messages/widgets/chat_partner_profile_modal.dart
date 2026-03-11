import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';

/// AppDesign ProfileDetailModal ????? 3D ???逾꿨ㅇ???덈뒆嶺뚮씧猿ョ뙴諛몃츩????????節뗪땁 + ?잙갭梨???⑥щ턄?????녹맠鸚룸삁nfoRow鸚??蹂μ쟽鸚???뗢뵛嶺?(嶺?????
class ChatPartnerProfileModal {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> profile,
    String? partnerPhotoStorageKey,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '???뗢뵛',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _ProfileModalContent(
          profile: profile,
          partnerPhotoStorageKey: partnerPhotoStorageKey,
          animation: animation,
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _ProfileModalContent extends StatefulWidget {
  const _ProfileModalContent({
    required this.profile,
    this.partnerPhotoStorageKey,
    required this.animation,
    required this.onClose,
  });

  final Map<String, dynamic> profile;
  final String? partnerPhotoStorageKey;
  final Animation<double> animation;
  final VoidCallback onClose;

  @override
  State<_ProfileModalContent> createState() => _ProfileModalContentState();
}

class _ProfileModalContentState extends State<_ProfileModalContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    widget.animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) _contentController.forward();
    });
    widget.animation.addListener(() {
      if (widget.animation.value >= 0.35 && !_contentController.isAnimating && _contentController.value == 0) {
        _contentController.forward();
      }
    });
    if (widget.animation.status == AnimationStatus.completed || widget.animation.value >= 0.35) {
      _contentController.forward();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _contentController.value == 0 && !_contentController.isAnimating) {
          _contentController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // AppDesign: backdrop
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final t = widget.animation.value;
        final opacity = Curves.easeOut.transform(t);
        final scale = 0.5 + 0.5 * Curves.elasticOut.transform(
          Curves.easeOut.transform((t - 0.15) / 0.85).clamp(0.0, 1.0),
        );
        const double perspective = 0.001;
        final angle = -math.pi * (1 - t);
        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withOpacity(0.6 * opacity),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, perspective)
                ..rotateY(angle),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Material(
                    color: Colors.transparent,
                    child: _ModalCard(
                      profile: widget.profile,
                      partnerPhotoStorageKey: widget.partnerPhotoStorageKey,
                      dark: dark,
                      onClose: widget.onClose,
                      contentFade: _contentFade,
                      contentSlide: _contentSlide,
                      contentController: _contentController,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModalCard extends StatelessWidget {
  const _ModalCard({
    required this.profile,
    this.partnerPhotoStorageKey,
    required this.dark,
    required this.onClose,
    required this.contentFade,
    required this.contentSlide,
    required this.contentController,
  });

  final Map<String, dynamic> profile;
  final String? partnerPhotoStorageKey;
  final bool dark;
  final VoidCallback onClose;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final AnimationController contentController;

  static String _str(dynamic v) => v?.toString() ?? '-';

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

  Map<String, dynamic>? get _user =>
      profile['user'] is Map<String, dynamic> ? profile['user'] as Map<String, dynamic>? : null;

  dynamic _pick(List<String> keys) {
    final user = _user;
    final partner = profile['partner'] is Map<String, dynamic> ? profile['partner'] as Map<String, dynamic> : null;
    final requester = profile['requester'] is Map<String, dynamic> ? profile['requester'] as Map<String, dynamic> : null;
    final recipient = profile['recipient'] is Map<String, dynamic> ? profile['recipient'] as Map<String, dynamic> : null;
    final sources = <Map<String, dynamic>>[
      profile,
      if (user != null) user,
      if (partner != null) partner,
      if (requester != null) requester,
      if (recipient != null) recipient,
      if (partner?['user'] is Map<String, dynamic>) partner!['user'] as Map<String, dynamic>,
      if (requester?['user'] is Map<String, dynamic>) requester!['user'] as Map<String, dynamic>,
      if (recipient?['user'] is Map<String, dynamic>) recipient!['user'] as Map<String, dynamic>,
    ];
    for (final key in keys) {
      for (final source in sources) {
        final value = source[key];
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        return value;
      }
    }
    return null;
  }

  Widget _buildAvatar(BuildContext context) {
    const double size = 96;
    final u = _user;
    final photoUrl = photoUrlFromStorageKey(partnerPhotoStorageKey);
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: size * 0.6, color: Colors.grey),
          ),
        ),
      );
    }
    final seed = profile['avatarSeed']?.toString() ??
        profile['userId']?.toString() ??
        u?['avatarSeed']?.toString() ??
        u?['userId']?.toString();
    if (seed != null && seed.isNotEmpty) {
      Map<String, String> opts = {};
      final raw = profile['avatarOptions']?.toString() ?? u?['avatarOptions']?.toString();
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            opts = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
          }
        } catch (_) {}
      }
      final url = diceBearAvatarUrl(seed, options: opts.isNotEmpty ? opts : null);
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: SvgPicture.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Icon(LucideIcons.user, size: size * 0.5, color: Colors.grey),
            theme: const SvgTheme(currentColor: Colors.black),
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Icon(LucideIcons.user, size: size * 0.6, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    final borderColor = dark ? Colors.grey.shade700 : const Color(0xFFF3F4F6);
    final p = profile;

    final maxH = MediaQuery.of(context).size.height * 0.9;
    final cardHeight = (700.0).clamp(400.0, maxH);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 390, maxHeight: cardHeight),
      height: cardHeight,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient (AppDesign)
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: ThemeController.getSheetGradient(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Drag handle
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(LucideIcons.x, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                  // Avatar + nickname (scale-in effect via contentController)
                  Center(
                    child: AnimatedBuilder(
                      animation: contentController,
                      builder: (context, _) {
                        final v = contentController.value;
                        final scale = (v < 0.01 ? 0.0 : v).clamp(0.3, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: _buildAvatar(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _str(p['nickname']),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: AnimatedBuilder(
                  animation: contentController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: contentFade,
                      child: SlideTransition(
                        position: contentSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _infoRow('Major', _str(_pick(['department', 'major', 'departmentName'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Gender', _toLabel('gender', _pick(['gender', 'sex'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('School', _str(_pick(['affiliationText', 'affiliation', 'school', 'schoolName', 'organization'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Height', _pick(['heightCm', 'height']) != null ? '${_pick(['heightCm', 'height'])} cm' : '-', onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Grade', _toLabel('gradeYear', _pick(['gradeYear', 'grade', 'year', 'schoolYear', 'class'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('MBTI', _str(_pick(['mbti', 'mbtiType'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Smoking', _toLabel('smoking', _pick(['isSmoking', 'smoking', 'smoke'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Drinking', _toLabel('drinking', _pick(['isDrinking', 'drinking', 'alcohol'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Intro', _str(_pick(['introOneLine', 'oneLineIntroduce', 'bio', 'introduction', 'selfIntroduction'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Interests', _str(_pick(['intoLately', 'hobby', 'recentInterest', 'interests'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Ideal Type', _str(_pick(['idealType', 'ideal'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Fashion', _toLabel('fashionStyle', _pick(['fashionStyle', 'style'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Date Preference', _toLabel('preferredDateType', _pick(['preferredDateType', 'preferredDate'])), onSurfaceVariant, onSurface, borderColor),
                            _infoRow('Active Time', _toLabel('activityTime', _pick(['activityTime', 'activeTime'])), onSurfaceVariant, onSurface, borderColor),
                            _tagsRow(borderColor, onSurfaceVariant, onSurface),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Bottom: ???뗢뵛嶺?(嶺?????
            AnimatedBuilder(
              animation: contentController,
              builder: (context, _) {
                return FadeTransition(
                  opacity: contentFade,
                  child: SlideTransition(
                    position: contentSlide,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onClose,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: dark ? Colors.grey.shade600 : const Color(0xFFE5E7EB), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: onSurface,
                          ),
                          child: const Text('???뗢뵛', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color labelColor, Color valueColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: TextStyle(fontSize: 14, color: labelColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: valueColor), maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _tagsRow(Color borderColor, Color labelColor, Color tagColor) {
    final list = _pick(['idealTypeKeywords', 'keywords', 'tags']);
    final tags = list is List
        ? (list as List).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : <String>[];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text('??? ???六??濡ル츎...', style: TextStyle(fontSize: 14, color: labelColor))),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dark ? Colors.grey.shade700 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(tag, style: TextStyle(fontSize: 13, color: tagColor)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
