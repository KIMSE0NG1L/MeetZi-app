import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final _environmentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _repository = EnvironmentRepository();
  final _authRepository = AuthRepository();
  late final Future<List<dynamic>> _environmentsFuture;
  String? _selectedEnvironmentId;
  String? _selectedEnvironmentName;
  String? _selectedEnvironmentEmailDomain;

  bool _isRequesting = false;
  bool _isConfirming = false;

  @override
  void dispose() {
    _environmentIdController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _environmentsFuture = _repository.getEnvironments();
    _loadProfileEnvironment();
  }

  Future<void> _loadProfileEnvironment() async {
    try {
      final profile = await _authRepository.getProfile();
      final user = (profile['user'] as Map?) ?? profile;
      final affiliation = user['affiliationText']?.toString();
      if (affiliation != null && affiliation.isNotEmpty) {
        _selectedEnvironmentName = affiliation;
      }
    } catch (_) {
      // ignore profile errors; environment list fallback will handle.
    }

    final items = await _environmentsFuture;
    if (!mounted) return;
    final universities = items
        .where((item) => item is Map && item['type']?.toString() == 'university')
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    Map<String, dynamic>? matched;
    if (_selectedEnvironmentName != null) {
      matched = universities.firstWhere(
        (item) => item['name']?.toString() == _selectedEnvironmentName,
        orElse: () => <String, dynamic>{},
      );
      if (matched.isEmpty) {
        matched = null;
      }
    }

    matched ??= universities.isNotEmpty ? universities.first : null;

    if (matched != null) {
      setState(() {
        _selectedEnvironmentId = matched!['id'] as String?;
        _environmentIdController.text = _selectedEnvironmentId ?? '';
        _selectedEnvironmentName = matched!['name']?.toString();
        _selectedEnvironmentEmailDomain = matched!['emailDomain']?.toString();
      });
      _applyThemeForAffiliationName();
    }
  }

  bool get _isUniversitySelected =>
      _selectedEnvironmentEmailDomain != null &&
      _selectedEnvironmentEmailDomain!.isNotEmpty;

  String? _resolvedEnvironmentId() {
    final id = _selectedEnvironmentId ?? _environmentIdController.text.trim();
    return id.isEmpty ? null : id;
  }

  String? _resolvedEmail() {
    if (_isUniversitySelected) {
      final studentId = _studentIdController.text.trim();
      final domain = _selectedEnvironmentEmailDomain?.trim();
      if (studentId.isEmpty || domain == null || domain.isEmpty) return null;
      return '$studentId@$domain';
    }
    final email = _emailController.text.trim();
    return email.isEmpty ? null : email;
  }

  void _applyThemeForAffiliationName() {
    switch (_selectedEnvironmentName) {
      case '세종대학교':
        ThemeController.setSeedColor(const Color(0xFFB93234));
        break;
      case '건국대학교':
        ThemeController.setSeedColor(const Color(0xFF036B3F));
        break;
      case '한양대학교':
        ThemeController.setSeedColor(const Color(0xFF1D2475));
        break;
    }
  }

  Future<void> _requestCode() async {
    final environmentId = _resolvedEnvironmentId();
    final email = _resolvedEmail();
    if (environmentId == null || email == null) {
      _showMessage('환경을 선택하고 이메일을 입력해 주세요.');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      await _repository.requestEmailVerification(
        environmentId: environmentId,
        email: email,
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
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
        title: const Text('학교 메일 인증'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (_isUniversitySelected)
                TextField(
                  controller: _studentIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '학번',
                    suffixText: _selectedEnvironmentEmailDomain == null
                        ? null
                        : '@${_selectedEnvironmentEmailDomain!}',
                    border: const OutlineInputBorder(),
                  ),
                )
              else
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '학교 이메일',
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
