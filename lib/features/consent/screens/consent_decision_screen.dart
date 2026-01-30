import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/consent/data/consent_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentDecisionScreen extends StatefulWidget {
  const ConsentDecisionScreen({super.key});

  @override
  State<ConsentDecisionScreen> createState() => _ConsentDecisionScreenState();
}

class _ConsentDecisionScreenState extends State<ConsentDecisionScreen> {
  final _matchIdController = TextEditingController();
  final _repository = ConsentRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _matchIdController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(bool decision) async {
    if (_matchIdController.text.trim().isEmpty) {
      _showMessage('매칭 ID를 입력해 주세요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _repository.giveConsent(
        matchId: _matchIdController.text.trim(),
        decision: decision,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.consentSuccess);
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '동의 처리에 실패했습니다.');
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
        title: const Text('얼굴 공개 동의'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상호 동의 시\n프로필 사진이 공개됩니다.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '부담 없이 결정해 주세요.\n상대방도 동일하게 동의해야 공개돼요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _matchIdController,
                decoration: const InputDecoration(
                  labelText: '매칭 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: '동의하기',
                isLoading: _isLoading,
                onPressed: () => _submitDecision(true),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : () => _submitDecision(false),
                child: const Text('아직은 보류할래요'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
