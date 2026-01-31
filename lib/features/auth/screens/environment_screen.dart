import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final _environmentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _repository = EnvironmentRepository();
  late final Future<List<dynamic>> _environmentsFuture;
  String? _selectedEnvironmentId;

  bool _isRequesting = false;
  bool _isConfirming = false;

  @override
  void dispose() {
    _environmentIdController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _environmentsFuture = _repository.getEnvironments();
  }

  String? _resolvedEnvironmentId() {
    final manual = _environmentIdController.text.trim();
    return (_selectedEnvironmentId ?? manual).isEmpty
        ? null
        : (_selectedEnvironmentId ?? manual);
  }

  Future<void> _requestCode() async {
    final environmentId = _resolvedEnvironmentId();
    if (environmentId == null || _emailController.text.trim().isEmpty) {
      _showMessage('환경을 선택하고 이메일을 입력해 주세요.');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      await _repository.requestEmailVerification(
        environmentId: environmentId,
        email: _emailController.text.trim(),
      );
      _showMessage('인증 코드가 전송되었습니다.');
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '요청에 실패했습니다.');
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _confirmCode() async {
    final environmentId = _resolvedEnvironmentId();
    if (environmentId == null || _codeController.text.trim().isEmpty) {
      _showMessage('환경을 선택하고 인증 코드를 입력해 주세요.');
      return;
    }

    setState(() => _isConfirming = true);
    try {
      await _repository.confirmEmailVerification(
        environmentId: environmentId,
        code: _codeController.text.trim(),
      );
      _showMessage('인증이 완료되었습니다.');
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.matchingWait);
    } on DioException catch (error) {
      _showMessage(error.response?.data.toString() ?? '인증에 실패했습니다.');
    } finally {
      setState(() => _isConfirming = false);
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
        title: const Text('환경 선택/인증'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어떤 환경에 속해 있나요?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _EnvironmentChip(label: '대학교'),
                  _EnvironmentChip(label: '회사'),
                  _EnvironmentChip(label: '아파트'),
                  _EnvironmentChip(label: '기타'),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<dynamic>>(
                future: _environmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Text('환경 목록을 불러오지 못했습니다.');
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedEnvironmentId,
                    decoration: const InputDecoration(
                      labelText: '환경 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['id'] as String?,
                            child: Text('${item['name']} (${item['type']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEnvironmentId = value;
                        _environmentIdController.text = value ?? '';
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _environmentIdController,
                enabled: _selectedEnvironmentId == null,
                decoration: const InputDecoration(
                  labelText: '환경 ID (직접 입력)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '학교/회사 이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '인증 코드 요청',
                isLoading: _isRequesting,
                onPressed: _requestCode,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '인증 코드',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '인증 완료하기',
                isLoading: _isConfirming,
                onPressed: _confirmCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  final String label;

  const _EnvironmentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
