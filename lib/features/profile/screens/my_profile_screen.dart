import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.background,
                ],
                stops: const [0.0, 0.08, 0.25],
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _profile == null
                      ? const Center(child: Text('프로필 정보가 없습니다.'))
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ...existing code...
                            ],
                          ),
                        ),
        ],
      ),
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _profile == null
                  ? const Center(child: Text('프로필 정보가 없습니다.'))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile?['nickname']?.toString() ?? '',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('소속: ${_profile?['affiliationText'] ?? '-'}'),
                          Text('성별: ${_profile?['gender'] ?? '-'}'),
                          Text('출생년도: ${_profile?['birthYear'] ?? '-'}'),
                          Text('MBTI: ${_profile?['mbti'] ?? '-'}'),
                          Text('인스타: ${_profile?['instagramHandle'] ?? '-'}'),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: '내 프로필 수정',
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.profileSetup,
                                arguments: true,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _load,
                            child: const Text('새로고침'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/profile/avatar-setup',
                              );
                            },
                            child: const Text('아바타 편집'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
