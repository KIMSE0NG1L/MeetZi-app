import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';

class MatchingBoardScreen extends StatelessWidget {
  const MatchingBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MatchingBoardScreenBody();
  }
}

class _MatchingBoardScreenBody extends StatefulWidget {
  @override
  State<_MatchingBoardScreenBody> createState() => _MatchingBoardScreenBodyState();
}

class _MatchingBoardScreenBodyState extends State<_MatchingBoardScreenBody> {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = false;
  int _profileViewCount = 0;
  DateTime? _lastViewTime;
  int? _myCredit;
  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    _fetchMyCredit();
  }

  Future<void> _fetchMyCredit() async {
    try {
      final credit = await _repository.fetchMyCredit();
      setState(() => _myCredit = credit);
    } catch (_) {
      setState(() => _myCredit = null);
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() => _loading = true);
    try {
      final profiles = await _repository.fetchProfiles();
      setState(() => _profiles = profiles);
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registerProfile() async {
    // 내 프로필 정보 가져오기
    final authRepo = AuthRepository();
    final profile = await authRepo.getProfile();
    final nickname = profile['nickname'];
    final gender = profile['gender'];
    String school = profile['school'] ?? '세종대';
    final userEnvs = profile['userEnvironments'];
    if (school == null || school.isEmpty) {
      if (userEnvs != null && userEnvs is List && userEnvs.isNotEmpty) {
        final env = userEnvs[0]['environment'];
        if (env != null && env['name'] != null) {
          school = env['name'];
        }
      }
    }
    if (nickname == null || gender == null || school == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 정보가 없습니다.')));
      return;
    }
    await _repository.registerProfile({
      'nickname': nickname,
      'gender': gender,
      'school': school,
    });
    await _fetchProfiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 완료')));
  }

  Future<void> _takeNote(String profileId) async {
    await _repository.takeNote(profileId);
    await _fetchProfiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('쪽지 가져가기 완료, 크레딧 1 차감')));
  }

  void _viewProfile(Map<String, dynamic> profile) {
    final now = DateTime.now();
    if (_lastViewTime == null || now.difference(_lastViewTime!).inHours >= 1) {
      _profileViewCount = 0;
      _lastViewTime = now;
    }
    if (_profileViewCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('1시간에 최대 4번만 상세보기 가능')));
      return;
    }
    _profileViewCount++;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(profile['nickname'] ?? '프로필'),
        content: Text('상세 정보: ${profile.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 게시판'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(_myCredit != null ? '${_myCredit}코인' : '-'),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _registerProfile,
              child: const Text('프로필 등록'),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(profile['nickname'] ?? '사용자 프로필'),
                          subtitle: Text('성별: ${profile['gender'] ?? '-'}'),
                          // 쪽지 가져가기 버튼 완전 제거
                          onTap: () => _viewProfile(profile),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
