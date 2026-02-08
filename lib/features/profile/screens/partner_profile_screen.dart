import 'package:flutter/material.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key});

  static const Map<String, dynamic> fallbackProfile = {
    'nickname': '두쫀쿠공주',
    'birthYear': 2005,
    'gender': '여성',
    'preferredGender': '남성 선호',
    'affiliation': '세종대학교',
    'heightCm': 160,
    'smoking': '비흡연',
    'mbti': 'INFP',
    'instagram': '@dck',
    'bio': '세종대 컴공과에요!',
  };

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final profile = args is Map<String, dynamic> ? args : fallbackProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상대 프로필'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      profile['nickname']?.toString().substring(0, 1) ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['nickname']?.toString() ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile['birthYear']}년생 · ${profile['gender']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildChips(profile),
              ),
              const SizedBox(height: 16),
              Text(
                profile['bio'] != null && profile['bio'].toString().trim().isNotEmpty
                    ? '자기소개: ${profile['bio']}'
                    : '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
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

  List<Widget> _buildChips(Map<String, dynamic> profile) {
    String? _smokingToKr(String? value) {
      switch (value) {
        case 'none':
          return '비흡연';
        case 'sometimes':
          return '가끔 흡연';
        case 'often':
          return '자주 흡연';
        case '비흡연':
        case '가끔':
        case '자주':
          return value; // 이미 한글로 저장된 경우
        default:
          return value;
      }
    }
    String? _drinkingToKr(String? value) {
      switch (value) {
        case 'none':
          return '음주 안 함';
        case 'sometimes':
          return '가끔 음주';
        case 'often':
          return '자주 음주';
        case '안 함':
        case '가끔':
        case '자주':
          return value; // 이미 한글로 저장된 경우
        default:
          return value;
      }
    }
    final values = <String?>[
      profile['preferredGender']?.toString(),
      profile['affiliation']?.toString(),
      profile['heightCm'] != null ? '${profile['heightCm']}cm' : null,
      _smokingToKr(profile['smoking']?.toString()),
      _drinkingToKr(profile['drinking']?.toString()),
      profile['mbti']?.toString(),
      profile['instagram']?.toString(),
    ];

    return values
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => _chip(value!.trim()))
        .toList();
  }
}
