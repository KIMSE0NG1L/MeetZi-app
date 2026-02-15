import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _profile == null
                    ? const Center(child: Text('프로필 정보가 없습니다.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
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
                                  Text('MBTI: ${_profile?['mbti'] ?? '-'}'),
                                  Text('인스타: ${_profile?['instagramHandle'] ?? '-'}'),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                            child: PrimaryButton(
                                  label: '내 프로필 수정',
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.profileSetup,
                                      arguments: true,
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
