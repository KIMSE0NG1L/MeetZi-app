import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/features/subscription/data/subscription_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repository = SubscriptionRepository();
  String _result = '';
  bool _isLoading = false;

  Future<void> _run(Future<dynamic> Function() task) async {
    setState(() => _isLoading = true);
    try {
      final response = await task();
      setState(() => _result = response.toString());
    } on DioException catch (error) {
      setState(
        () => _result = error.response?.data.toString() ?? '요청 실패',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 API'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              PrimaryButton(
                label: '구독 조회',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.getSubscription),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '구독 취소',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.cancelSubscription),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '구독 일시중지',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.pauseSubscription),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '구독 재개',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.resumeSubscription),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '구독 활성 여부',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.isSubscriptionActive),
              ),
              const SizedBox(height: 16),
              Text(
                _result,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
