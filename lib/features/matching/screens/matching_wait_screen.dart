import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class MatchingWaitScreen extends StatefulWidget {
  const MatchingWaitScreen({super.key});

  @override
  State<MatchingWaitScreen> createState() => _MatchingWaitScreenState();
}

class _MatchingWaitScreenState extends State<MatchingWaitScreen> {
  final _repository = MatchingRepository();
  final _authRepository = AuthRepository();
  bool _isRequesting = false;
  bool _isCanceling = false;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _startStatusCheck();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    // 3초마다 매칭 상태 확인
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkMatchStatus();
    });
  }

  Future<void> _checkMatchStatus() async {
    if (!mounted) return;

    try {
      final profile = await _authRepository.getProfile();
      final user = profile['user'] as Map<String, dynamic>?;
      final matchStatus = (user?['matchStatus'] ?? profile['matchStatus']) as String?;

      if (!mounted) return;

      if (matchStatus == 'MATCHED') {
        // 매칭 완료! 매칭 결과 화면으로 이동
        _statusCheckTimer?.cancel();
        Navigator.pushReplacementNamed(context, AppRoutes.matchingResult);
      } else if (matchStatus == 'NOT_MATCHED') {
        // WAITING이 아니면 (NOT_MATCHED 등) 매칭 홈으로 돌아가기
        _statusCheckTimer?.cancel();
        Navigator.pushReplacementNamed(context, AppRoutes.matchingHome);
      }
    } catch (e) {
      debugPrint('매칭 상태 확인 실패: $e');
    }
  }

  Future<void> _requestMatch() async {
    setState(() => _isRequesting = true);
    try {
      await _repository.requestMatch();
      _showMessage('매칭 요청을 보냈습니다.');
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '매칭 요청에 실패했습니다.');
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _cancelMatch() async {
    if (_isCanceling) return; // 이미 취소 중이면 무시
    
    _statusCheckTimer?.cancel(); // 타이머 중지
    setState(() => _isCanceling = true);
    try {
      await _repository.cancelMatch();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 매칭이 취소되었습니다.')),
      );
      
      // 매칭 취소 성공 - 매칭 준비 화면으로 돌아가기
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.matchingHome);
        }
      });
    } on DioException catch (error) {
      if (!mounted) return;
      
      _showMessage(error.response?.data.toString() ?? '매칭 취소에 실패했습니다.');
      setState(() => _isCanceling = false);
      _startStatusCheck(); // 타이머 재시작
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 대기'),
      ),
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
              const Spacer(),
              OutlinedButton(
                onPressed: _isCanceling ? null : _cancelMatch,
                child: _isCanceling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('매칭 요청 취소'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.matchingResult);
                },
                child: const Text('매칭됐다고 가정하기'),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
