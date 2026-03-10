import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nearo_app/presentation/widgets/meetzy_profile_detail_modal.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';

/// 프로필 맵에서 크게 보기용 사진/아바타 URL 추출 (모달에서 아바타 탭 시 사용)
void _enlargeUrlsFromProfile(Map<String, dynamic> profile, void Function(String? photoUrl, String? avatarUrl) setUrls) {
  final user = profile['user'] as Map<String, dynamic>?;
  final displayType = (profile['boardDisplayType'] ?? user?['boardDisplayType'])?.toString().trim().toLowerCase();
  String? photoUrl;
  if (displayType == 'photo') {
    dynamic photos = user?['photos'] ?? profile['photos'];
    if (photos is List && photos.isNotEmpty && photos[0] is Map) {
      final key = (photos[0] as Map)['storageKey']?.toString();
      if (key != null && key.isNotEmpty) photoUrl = photoUrlFromStorageKey(key);
    }
  }
  final seed = user?['avatarSeed']?.toString() ?? profile['avatarSeed']?.toString() ?? profile['userId']?.toString();
  final style = (user?['avatarStyle'] ?? profile['avatarStyle'])?.toString() ?? 'lorelei';
  Map<String, String> opts = {};
  final raw = user?['avatarOptions'] ?? profile['avatarOptions'];
  if (raw is Map) {
    opts = raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  } else if (raw != null && raw.toString().trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map) opts = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } catch (_) {}
  }
  final avatarUrl = seed != null && seed.isNotEmpty
      ? diceBearAvatarUrl(seed, style: style, options: opts.isNotEmpty ? opts : null)
      : null;
  setUrls(photoUrl, avatarUrl);
}

/// 프로필 맵에서 크게 보기용 사진/아바타 URL 반환 (탭 시 확대 다이얼로그용)
(String?, String?) getEnlargeUrlsFromProfile(Map<String, dynamic> profile) {
  String? photoUrl;
  String? avatarUrl;
  _enlargeUrlsFromProfile(profile, (p, a) {
    photoUrl = p;
    avatarUrl = a;
  });
  return (photoUrl, avatarUrl);
}

MeetzyProfileDetailData profileMapToDetailData(Map<String, dynamic> profile) {
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

/// 채팅방·메시지함 등에서 프로필 상세만 볼 때 사용 — 게시판 카드와 동일한 슬라이드 업 효과 + MeetzyProfileDetailModal, hideMatchButton 시 매칭하기 비표시
/// [overridePhotoUrlForEnlarge]: 프로필에 photos가 없어도(동의 전 등) 목록에서 쓰는 사진 URL이 있으면 탭 시 확대용으로 전달
Future<void> showProfileDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> profile,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  bool hideMatchButton = false,
  String? overridePhotoUrlForEnlarge,
}) async {
  final detailData = profileMapToDetailData(profile);
  String? photoUrlForEnlarge;
  String? avatarUrlForEnlarge;
  _enlargeUrlsFromProfile(profile, (photo, avatar) {
    photoUrlForEnlarge = photo;
    avatarUrlForEnlarge = avatar;
  });
  if ((photoUrlForEnlarge == null || photoUrlForEnlarge!.isEmpty) && overridePhotoUrlForEnlarge != null && overridePhotoUrlForEnlarge.isNotEmpty) {
    photoUrlForEnlarge = overridePhotoUrlForEnlarge;
  }
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (!context.mounted) return;
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
      final slideY = 700.0 * (1.0 - t);
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
                          avatarWidget: buildAvatar(ctx, profile),
                          hideMatchButton: hideMatchButton,
                          onClose: () => Navigator.of(ctx).pop(),
                          onMatch: hideMatchButton ? null : () {},
                          photoUrlForEnlarge: photoUrlForEnlarge,
                          avatarUrlForEnlarge: avatarUrlForEnlarge,
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
}
