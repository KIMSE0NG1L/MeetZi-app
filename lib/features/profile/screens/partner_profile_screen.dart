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
                profile['bio']?.toString() ?? '',
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
    final values = <String?>[
      profile['preferredGender']?.toString(),
      profile['affiliation']?.toString(),
      profile['heightCm'] != null ? '${profile['heightCm']}cm' : null,
      profile['smoking']?.toString(),
      profile['mbti']?.toString(),
      profile['instagram']?.toString(),
    ];

    return values
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => _chip(value!.trim()))
        .toList();
  }
}
