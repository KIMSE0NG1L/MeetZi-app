import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';

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
  String _selectedGender = '여성';
  String _selectedSchool = '세종대학교';
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = false;
  int _profileViewCount = 0;
  DateTime? _lastViewTime;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() => _loading = true);
    try {
      final profiles = await _repository.fetchProfiles(gender: _selectedGender, school: _selectedSchool);
      setState(() => _profiles = profiles);
    } catch (_) {
      setState(() => _profiles = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registerProfile() async {
    // 예시 프로필 등록
    await _repository.registerProfile({
      'nickname': '테스트',
      'gender': _selectedGender,
      'school': _selectedSchool,
    });
    await _fetchProfiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 등록 완료, 크레딧 1 지급')));
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
      appBar: AppBar(title: const Text('매칭 게시판')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    items: const [
                      DropdownMenuItem(value: '여성', child: Text('여성')),
                      DropdownMenuItem(value: '남성', child: Text('남성')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedGender = v ?? '여성');
                      _fetchProfiles();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSchool,
                    items: const [
                      DropdownMenuItem(value: '세종대학교', child: Text('세종대학교')),
                      DropdownMenuItem(value: '건국대학교', child: Text('건국대학교')),
                      DropdownMenuItem(value: '한양대학교', child: Text('한양대학교')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedSchool = v ?? '세종대학교');
                      _fetchProfiles();
                    },
                  ),
                ),
              ],
            ),
          ),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('상세 정보 보기 제한: 1시간 4회'),
                              Text('내 학교와 다른 성별만 표시'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _takeNote(profile['id']?.toString() ?? ''),
                            child: const Text('쪽지 가져가기'),
                          ),
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
