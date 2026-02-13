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
    try {
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
    } catch (e) {
      final msg = e is String ? e : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
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
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthRepository().getProfile(),
      builder: (context, snapshot) {
        final myUserId = snapshot.data?['id'];
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
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.57,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            final isMe = myUserId != null && profile['userId'] == myUserId;
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isMe
                                    ? null
                                    : () async {
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('매칭 확인'),
                                            content: const Text('이 프로필과 매칭하시겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('취소'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('확인'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (result == true) {
                                          await _takeNote(profile['id']);
                                        }
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        child: const Icon(Icons.person, size: 40),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isMe ? '나' : (profile['nickname'] ?? ''),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(profile['gender'] ?? '-', style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text(profile['school'] ?? '-', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _registerProfile,
            label: const Text('등록'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
