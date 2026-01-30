import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/features/health/data/health_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _repository = HealthRepository();
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
        title: const Text('헬스 체크 API'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              PrimaryButton(
                label: '헬스 체크 실행',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.check),
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
