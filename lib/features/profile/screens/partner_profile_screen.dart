import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/app/app_routes.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key});

  static const Map<String, dynamic> fallbackProfile = {
    'nickname': '두쫀쿠공주',
    'gender': '여성',
    'preferredGender': '남성 선호',
    'affiliation': '세종대학교',
    'heightCm': 160,
    'smoking': '비흡연',
    'mbti': 'INFP',
    'instagram': '@dck',
    'bio': '세종대 컴공과에요!',
  };

  // --- Avatar helpers ---
  Widget buildAvatar(Map<String, dynamic> profile, BuildContext context) {
    if (profile['photoUrl'] != null && profile['photoUrl'].toString().isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: NetworkImage(profile['photoUrl']),
      );
    }

    // support both shapes: incoming profile may contain `user` object or direct fields
    final user = profile['user'] as Map<String, dynamic>?;
    final seed = user?['avatarSeed']?.toString() ?? profile['avatarSeed']?.toString() ?? profile['userId']?.toString();
    final options = _parseAvatarOptions(user?['avatarOptions'] ?? profile['avatarOptions']);

    if (seed != null && seed.isNotEmpty) {
      final avatarUrl = diceBearAvatarUrl(seed, options: options.isNotEmpty ? options : null);
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: SvgPicture.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            placeholderBuilder: (_) => Icon(Icons.person, size: 40, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        (profile['nickname']?.toString().isNotEmpty == true)
            ? (profile['nickname']?.toString().substring(0, 1) ?? '?')
            : '?',
        style: const TextStyle(color: Colors.white, fontSize: 32),
      ),
    );
  }

  // --- Localization helpers ---
  String _smokingToKr(String? value) {
    switch (value) {
      case 'none':
        return '비흡연';
      case 'sometimes':
        return '가끔';
      case 'often':
        return '자주';
      case '비흡연':
      case '가끔':
      case '자주':
        return value ?? '-';
      default:
        return value ?? '-';
    }
  }

  String _drinkingToKr(String? value) {
    switch (value) {
      case 'none':
        return '안 함';
      case 'sometimes':
        return '가끔';
      case 'often':
        return '자주';
      case '안 함':
      case '가끔':
      case '자주':
        return value ?? '-';
      default:
        return value ?? '-';
    }
  }

  String _genderToKr(String? value) {
    switch (value) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      case '남성':
      case '여성':
        return value ?? '-';
      default:
        return value ?? '-';
    }
  }

  // --- UI helpers ---
  TableRow _infoRow(String label, String? value) {
    final display = value == null || value.toString().trim().isEmpty ? '-' : value.toString();
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(display),
      ),
    ]);
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

  /// Try multiple keys in order and return the first non-empty value.
  dynamic _pluck(Map<String, dynamic>? profile, List<String> keys) {
    if (profile == null) return null;
    // If profile contains nested 'user', prefer values there as well.
    final user = profile['user'] as Map<String, dynamic>?;
    for (final k in keys) {
      final v1 = profile[k];
      if (v1 != null && v1.toString().trim().isNotEmpty) return v1;
      final v2 = user?[k];
      if (v2 != null && v2.toString().trim().isNotEmpty) return v2;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final profile = args is Map<String, dynamic> ? args : fallbackProfile;
    // Debug: log incoming profile shape so we can verify field names
    // (remove or guard this in production)
    // ignore: avoid_print
    print('[PartnerProfileScreen] profile payload: $profile');
    // Debug: print received profile shape to help diagnose missing fields
    // ignore: avoid_print
    print('[PartnerProfileScreen] profile keys: ${profile.keys.toList()}');

    final infoRows = [
      _infoRow('학과', _pluck(profile, ['department', 'major', 'departmentName']) ?? '-'),
      _infoRow('성별', _genderToKr(_pluck(profile, ['gender', 'sex'])?.toString())),
      _infoRow('소속', _pluck(profile, ['affiliation', 'school', 'affiliationText', 'organization']) ?? '-'),
      _infoRow('키', _pluck(profile, ['heightCm', 'height']) != null ? '${_pluck(profile, ['heightCm', 'height'])} cm' : '-'),
      _infoRow('학년', _pluck(profile, ['grade', 'year', 'schoolYear', 'class']) ?? '-'),
      _infoRow('MBTI', _pluck(profile, ['mbti', 'mbtiType']) ?? '-'),
      _infoRow('흡연', _smokingToKr(_pluck(profile, ['smoking', 'smoke'])?.toString())),
      _infoRow('음주', _drinkingToKr(_pluck(profile, ['drinking', 'alcohol'])?.toString())),
      _infoRow('한 줄 소개', _pluck(profile, ['oneLineIntroduce', 'bio', 'introduction']) ?? '-'),
      _infoRow('이상형', _pluck(profile, ['idealType', 'ideal']) ?? '-'),
      _infoRow('패션 스타일', _pluck(profile, ['fashionStyle', 'style']) ?? '-'),
      _infoRow('선호 데이트', _pluck(profile, ['preferredDate', 'preferredDating']) ?? '-'),
      _infoRow('활동 시간대', _pluck(profile, ['activeTime', 'activeHours']) ?? '-'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('상대 프로필')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              buildAvatar(profile, context),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile['nickname']?.toString() ?? '미정',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileSetup),
                    child: const Text('프로필 수정'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Table(columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()}, children: infoRows),
            ],
          ),
        ),
      ),
    );
  }
}
