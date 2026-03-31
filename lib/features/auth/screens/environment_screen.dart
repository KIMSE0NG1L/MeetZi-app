import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/privacy_consent_storage.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _repository = EnvironmentRepository();
  final _authRepository = AuthRepository();
  late final Future<List<dynamic>> _environmentsFuture;

  String? _selectedEnvironmentId;
  String? _selectedEnvironmentName;
  String? _selectedEnvironmentEmailDomain;
  bool _environmentsLoaded = false;

  bool _isCodeSent = false;
  bool _isRequesting = false;
  bool _isConfirming = false;
  int _timer = 0;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _environmentsFuture = _repository.getEnvironments();
    _loadProfileEnvironment();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileEnvironment() async {
    try {
      final profile = await _authRepository.getProfile();
      final user = (profile['user'] as Map?) ?? profile;
      final affiliation = user['affiliationText']?.toString();
      final items = await _environmentsFuture;
      if (!mounted) return;

      final universities = items
          .where((item) => item is Map && item['type']?.toString() == 'university')
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      Map<String, dynamic>? matched;
      if (affiliation != null && affiliation.isNotEmpty) {
        try {
          matched = universities.firstWhere(
            (item) => item['name']?.toString() == affiliation,
          );
        } catch (_) {
          matched = null;
        }
      }
      matched ??= universities.isNotEmpty ? universities.first : null;

      if (matched != null && mounted) {
        setState(() {
          _selectedEnvironmentId = matched!['id']?.toString();
          _selectedEnvironmentName = matched['name']?.toString();
          _selectedEnvironmentEmailDomain = matched['emailDomain']?.toString();
          _environmentsLoaded = true;
        });
        _applyThemeForAffiliationName();
      } else if (mounted) {
        setState(() => _environmentsLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _environmentsLoaded = true);
    }
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

  bool _isValidEmail(String email) {
    if (_selectedEnvironmentEmailDomain != null &&
        _selectedEnvironmentEmailDomain!.isNotEmpty) {
      return email.endsWith('@$_selectedEnvironmentEmailDomain');
    }
    return email.endsWith('@sju.ac.kr') || email.endsWith('@sejong.ac.kr');
  }

  String get _emailHint {
    if (_selectedEnvironmentEmailDomain != null &&
        _selectedEnvironmentEmailDomain!.isNotEmpty) {
      return 'example@$_selectedEnvironmentEmailDomain';
    }
    return 'example@sju.ac.kr';
  }

  String get _emailHelpText {
    if (_selectedEnvironmentEmailDomain != null &&
        _selectedEnvironmentEmailDomain!.isNotEmpty) {
      return '$_selectedEnvironmentEmailDomain 메일을 입력해주세요';
    }
    return '@sju.ac.kr 또는 @sejong.ac.kr 메일을 입력해주세요';
  }

  String _extractDioMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data != null) {
      return data.toString();
    }
    return fallback;
  }

  Future<void> _requestCode() async {
    setState(() {
      _error = '';
      _success = '';
    });
    final environmentId = _selectedEnvironmentId;
    final email = _emailController.text.trim();

    if (environmentId == null || environmentId.isEmpty) {
      setState(() => _error = '학교를 선택해주세요');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = '학생 메일을 입력해주세요');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = '${_selectedEnvironmentName ?? "해당 학교"} 메일 주소를 입력해주세요');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      await _repository.requestEmailVerification(
        environmentId: environmentId,
        email: email,
      );
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _isCodeSent = true;
        _success = '인증번호가 발송되었습니다.';
        _timer = 180;
      });
      _startTimer();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _error = _extractDioMessage(e, '요청에 실패했습니다.');
      });
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_timer <= 1) {
          _timer = 0;
        } else {
          _timer--;
        }
      });
      return _timer > 0;
    });
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmCode() async {
    setState(() {
      _error = '';
      _success = '';
    });
    final environmentId = _selectedEnvironmentId;
    final code = _codeController.text.trim();

    if (environmentId == null || environmentId.isEmpty) {
      setState(() => _error = '학교를 선택해주세요');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = '인증번호를 입력해주세요');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = '인증번호 6자리를 입력해주세요');
      return;
    }

    setState(() => _isConfirming = true);
    try {
      await _repository.confirmEmailVerification(
        environmentId: environmentId,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _success = '인증이 완료되었습니다.';
      });
      try {
        await _authRepository.initAvatar();
      } catch (_) {}
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final hasAcceptedPrivacy = await PrivacyConsentStorage.hasAccepted();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        hasAcceptedPrivacy ? AppRoutes.home : AppRoutes.privacyConsentGate,
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _error = _extractDioMessage(e, '인증에 실패했습니다.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFDA4AF),
        Color(0xFFF9A8D4),
        Color(0xFFFB7185),
      ],
    );

    if (!_environmentsLoaded) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: gradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : null,
      body: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF111827) : null,
          gradient: dark
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF1F2),
                    Color(0xFFFDF2F8),
                    Color(0xFFFFE4E6),
                  ],
                ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const Text(
                        '학생 인증',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _progressStep(
                        icon: LucideIcons.check,
                        label: '프로필',
                        active: false,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      _progressStep(
                        icon: LucideIcons.mail,
                        label: '메일 인증',
                        active: true,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      _progressStep(
                        icon: null,
                        label: '완료',
                        active: false,
                        text: '3',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '학생 메일 인증이 필요해요',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedEnvironmentName != null
                          ? '$_selectedEnvironmentName 학생 메일로 인증해주세요'
                          : '학교 학생 메일로 인증해주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: dark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '학생 메일',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      readOnly: _isCodeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _emailHint,
                        filled: true,
                        fillColor: dark ? const Color(0xFF1F2937) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: dark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: _isCodeSent
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TextButton(
                                  onPressed: (_isRequesting ||
                                          _emailController.text.trim().isEmpty)
                                      ? null
                                      : _requestCode,
                                  child: _isRequesting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('전송'),
                                ),
                              ),
                      ),
                      style: TextStyle(
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailHelpText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (_isCodeSent) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '인증번호',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          if (_timer > 0)
                            Text(
                              _formatTimer(_timer),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: dark ? Colors.white : const Color(0xFF111827),
                        ),
                        cursorColor:
                            dark ? Colors.white : const Color(0xFF111827),
                        decoration: InputDecoration(
                          hintText: '',
                          counterText: '',
                          filled: true,
                          fillColor: dark ? const Color(0xFF1F2937) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: dark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '메일로 전송된 6자리 숫자를 입력해주세요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          TextButton(
                            onPressed: _isCodeSent ? _requestCode : null,
                            child: Text(
                              '재전송',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: dark
                                    ? const Color(0xFFF472B6)
                                    : const Color(0xFFEC4899),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.circleAlert,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_success.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.check,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _success,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF1F2937).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFEC4899),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.mail,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '인증 안내',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: dark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '학교 학생 메일만 인증 가능합니다.\n인증번호는 3분간 유효합니다.\n메일이 오지 않으면 스팸함을 확인해주세요.\n재전송은 여러 번 가능합니다.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: dark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF1F2937).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(
                    color: dark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_isCodeSent &&
                            _codeController.text.length == 6 &&
                            !_isConfirming)
                        ? _confirmCode
                        : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isCodeSent &&
                                _codeController.text.length == 6 &&
                                !_isConfirming
                            ? null
                            : (dark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB)),
                        gradient: _isCodeSent &&
                                _codeController.text.length == 6 &&
                                !_isConfirming
                            ? const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFFDA4AF),
                                  Color(0xFFF9A8D4),
                                  Color(0xFFFB7185),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isConfirming
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '인증 중...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '인증 완료',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isCodeSent &&
                                        _codeController.text.length == 6 &&
                                        !_isConfirming
                                    ? Colors.white
                                    : (dark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280)),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressStep({
    required String label,
    required bool active,
    IconData? icon,
    String? text,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: active
                ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                : null,
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: active ? const Color(0xFFEC4899) : Colors.white,
                )
              : Center(
                  child: Text(
                    text ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
