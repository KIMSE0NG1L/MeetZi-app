import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentPreviewScreen extends StatefulWidget {
  const ConsentPreviewScreen({super.key});

  @override
  State<ConsentPreviewScreen> createState() => _ConsentPreviewScreenState();
}

class _ConsentPreviewScreenState extends State<ConsentPreviewScreen> {
  final _matchIdController = TextEditingController();
  final _repository = ConsentRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _matchIdController.dispose();
    super.dispose();
  }

  Future<void> _checkConsentStatus() async {
    if (_matchIdController.text.trim().isEmpty) {
      _showMessage('매칭 ID를 입력해 주세요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _repository.getConsentStatus(
        matchId: _matchIdController.text.trim(),
      );
      _showMessage(result.toString());
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '조회에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('익명 대화 프리뷰'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상대와 대화가 잘 이어지고 있나요?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '양쪽이 모두 동의하면\n서로의 얼굴이 공개되고 카카오톡으로 넘어갑니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('익명1: 오늘도 여기서 일하셨나요?'),
                    SizedBox(height: 8),
                    Text('익명2: 네! 자주 보던 분 같아요 :)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _matchIdController,
                decoration: const InputDecoration(
                  labelText: '매칭 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '동의 상태 조회',
                isLoading: _isLoading,
                onPressed: _checkConsentStatus,
              ),
              const Spacer(),
              PrimaryButton(
                label: '동의 화면으로 이동',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.consentDecision);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
