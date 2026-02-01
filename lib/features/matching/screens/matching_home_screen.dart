import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';

class MatchingHomeScreen extends StatelessWidget {
  const MatchingHomeScreen({super.key});

  static const _profiles = [
    _MatchProfile(
      nickname: '두쫀쿠공주1',
      birthYear: 2005,
      gender: '여성',
      preferredGender: '남성 선호',
      affiliation: '세종대학교',
      heightCm: 160,
      smoking: '비흡연',
      mbti: 'INFP',
      instagram: '@dck',
      bio: '세종대 컴공과에요!',
    ),
    _MatchProfile(
      nickname: '두쫀쿠공주2',
      birthYear: 2005,
      gender: '여성',
      preferredGender: '남성 선호',
      affiliation: '세종대학교',
      heightCm: 160,
      smoking: '비흡연',
      mbti: 'INFP',
      instagram: '@dck',
      bio: '세종대 컴공과에요!',
    ),
    _MatchProfile(
      nickname: '두쫀쿠공주3',
      birthYear: 2005,
      gender: '여성',
      preferredGender: '남성 선호',
      affiliation: '세종대학교',
      heightCm: 160,
      smoking: '비흡연',
      mbti: 'INFP',
      instagram: '@dck',
      bio: '세종대 컴공과에요!',
    ),
    _MatchProfile(
      nickname: '두쫀쿠공주4',
      birthYear: 2005,
      gender: '여성',
      preferredGender: '남성 선호',
      affiliation: '세종대학교',
      heightCm: 160,
      smoking: '비흡연',
      mbti: 'INFP',
      instagram: '@dck',
      bio: '세종대 컴공과에요!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 홈'),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.88),
          itemCount: _profiles.length,
          itemBuilder: (context, index) {
            final profile = _profiles[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
              child: _ProfileCard(
                profile: profile,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.chatPreview,
                    arguments: profile.toMap(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MatchProfile {
  final String nickname;
  final int birthYear;
  final String gender;
  final String preferredGender;
  final String affiliation;
  final int heightCm;
  final String smoking;
  final String mbti;
  final String instagram;
  final String bio;

  const _MatchProfile({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.preferredGender,
    required this.affiliation,
    required this.heightCm,
    required this.smoking,
    required this.mbti,
    required this.instagram,
    required this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'birthYear': birthYear,
      'gender': gender,
      'preferredGender': preferredGender,
      'affiliation': affiliation,
      'heightCm': heightCm,
      'smoking': smoking,
      'mbti': mbti,
      'instagram': instagram,
      'bio': bio,
    };
  }
}

class _ProfileCard extends StatelessWidget {
  final _MatchProfile profile;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.nickname,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('${profile.birthYear}년생'),
                _chip(profile.gender),
                _chip(profile.preferredGender),
                _chip(profile.affiliation),
                _chip('${profile.heightCm}cm'),
                _chip(profile.smoking),
                _chip(profile.mbti),
                _chip(profile.instagram),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              profile.bio,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '선택하기',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
