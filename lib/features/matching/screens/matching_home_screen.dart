import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:lottie/lottie.dart';

class MatchingHomeScreen extends StatefulWidget {
  const MatchingHomeScreen({super.key});

  @override
  State<MatchingHomeScreen> createState() => _MatchingHomeScreenState();
}

class _MatchingHomeScreenState extends State<MatchingHomeScreen>
    with WidgetsBindingObserver {
  final MatchingRepository _matchingRepository = MatchingRepository();
  final AuthRepository _authRepository = AuthRepository();
  String? _matchStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkMatchStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMatchStatus();
    }
  }

  Future<void> _checkMatchStatus() async {
    if (!mounted) return;

    try {
      final profile = await _authRepository.getProfile();
      final user = profile['user'] as Map<String, dynamic>?;
      final matchStatus = (user?['matchStatus'] ?? profile['matchStatus']) as String?;

      if (!mounted) return;

      setState(() {
        _matchStatus = matchStatus;
      });
    } catch (e) {
      debugPrint('매칭 상태 확인 실패: $e');
    }
  }

  Future<void> _requestMatch() async {
    if (!mounted) return;

    try {
      await _matchingRepository.requestMatch();

      if (!mounted) return;

      // 매칭 요청 성공 - 홈(매칭 탭)으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.contains('소속된 환경') || errorMessage.contains('학교')) {
        errorMessage = '프로필을 먼저 완성해주세요.\n(학교 선택 및 이메일 인증 필요)';
      } else if (errorMessage.contains('이미 매칭')) {
        errorMessage = '이미 매칭된 상태입니다.';
      } else if (errorMessage.contains('대기')) {
        errorMessage = '이미 매칭 대기 중입니다.';
      } else {
        errorMessage = '매칭 요청 실패: $errorMessage';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelMatch() async {
    if (!mounted) return;

    try {
      await _matchingRepository.cancelMatch();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 매칭이 취소되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await _checkMatchStatus();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('취소 실패: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // WAITING 상태 - 매칭 대기 중
    if (_matchStatus == 'WAITING') {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Lottie.asset(
                    'assets/animations/Couple sharing and caring love.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '현재 같은 환경의\n누군가를 찾는 중이에요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '매칭이 성사되면 바로 알려드릴게요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: _cancelMatch,
                    child: const Text('매칭 요청 취소'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // MATCHED 상태
    if (_matchStatus == 'MATCHED') {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.heart,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '매칭이 성사됐어요!\n익명 대화로 먼저 연결돼요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '상호 동의 전까지는\n프로필 사진이 공개되지 않아요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      // 활성 매칭에서 roomId 조회 후 이동
                      final match = await _matchingRepository.getActiveMatch();
                      final roomId = match['roomId'] ?? (match['chatRoom']?['id']);
                      if (roomId != null) {
                        Navigator.pushNamed(context, '/chats/room', arguments: {'roomId': roomId});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('채팅방 정보를 찾을 수 없습니다.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      '대화방으로 이동하기',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // NOT_MATCHED 상태 (기본)
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 30),
                Text(
                  '매칭 준비 완료!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '프로필이 완성되었습니다.\n아래 버튼을 클릭해서 매칭을 시작하세요!',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _requestMatch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '💕 매칭 시작',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
