import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';

class MatchingHomeScreen extends StatefulWidget {
  const MatchingHomeScreen({super.key});

  @override
  State<MatchingHomeScreen> createState() => _MatchingHomeScreenState();
}

class _MatchingHomeScreenState extends State<MatchingHomeScreen> {
  final MatchingRepository _matchingRepository = MatchingRepository();
  bool _isLoading = false;
  String? _message;

  void _requestMatch() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _matchingRepository.requestMatch();
      
      if (!mounted) return;
      
      setState(() {
        _message = '✅ ${result['message'] ?? '매칭 요청이 완료되었습니다.'}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message!), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      
      // 에러 메시지 파싱
      String errorMessage = e.toString();
      if (errorMessage.contains('소속된 환경') || errorMessage.contains('학교')) {
        errorMessage = '프로필을 먼저 완성해주세요.\n(학교 선택 및 이메일 인증 필요)';
        // 프로필 화면으로 이동
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamed(context, AppRoutes.profileSetup);
          }
        });
      } else if (errorMessage.contains('이미 매칭')) {
        errorMessage = '이미 매칭된 상태입니다.';
      } else if (errorMessage.contains('대기')) {
        errorMessage = '이미 매칭 대기 중입니다.';
      } else {
        errorMessage = '매칭 요청 실패: $errorMessage';
      }
      
      setState(() {
        _message = '❌ $errorMessage';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
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
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestMatch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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

