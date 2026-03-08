import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';

/// last EmailVerification 1:1 — gradient header, 3-step progress, 학생 메일 입력/전송, 인증번호 입력, 인증 완료 버튼.
class MeetzyEmailVerificationPage extends StatefulWidget {
  const MeetzyEmailVerificationPage({
    super.key,
    required this.onBack,
    required this.onComplete,
    this.darkMode = false,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;
  final bool darkMode;

  @override
  State<MeetzyEmailVerificationPage> createState() => _MeetzyEmailVerificationPageState();
}

class _MeetzyEmailVerificationPageState extends State<MeetzyEmailVerificationPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _envRepository = EnvironmentRepository();
  bool _isCodeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  int _timer = 0;
  String _error = '';
  String _success = '';
  bool _didLoadDomain = false;
  String? _emailDomain;
  String? _environmentId;
  String? _environmentName;

  /// 라우트 인자(선택한 학교명)로 DB에서 도메인 로드
  Future<void> _loadEmailDomain() async {
    if (_didLoadDomain) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final selectedName = args is String ? args.toString().trim() : null;
    try {
      final list = await _envRepository.getEnvironments();
      if (!mounted) return;
      final universities = list
          .where((e) => e is Map && e['type']?.toString() == 'university')
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      Map<String, dynamic>? matched;
      if (selectedName != null && selectedName.isNotEmpty) {
        try {
          matched = universities.firstWhere(
            (e) => e['name']?.toString().trim() == selectedName,
          );
        } catch (_) {
          matched = null;
        }
      }
      matched ??= universities.isNotEmpty ? universities.first : null;
      if (mounted && matched != null) {
        setState(() {
          _emailDomain = matched!['emailDomain']?.toString().trim();
          _environmentId = matched['id']?.toString();
          _environmentName = matched['name']?.toString();
          _didLoadDomain = true;
        });
      } else if (mounted) {
        setState(() => _didLoadDomain = true);
      }
    } catch (_) {
      if (mounted) setState(() => _didLoadDomain = true);
    }
  }

  String get _fullEmail {
    final local = _emailController.text.trim();
    if (_emailDomain == null || _emailDomain!.isEmpty) return local;
    return local.isEmpty ? '' : '$local@$_emailDomain';
  }

  bool get _isValidEmail {
    final full = _fullEmail;
    if (full.isEmpty) return false;
    if (_emailDomain != null && _emailDomain!.isNotEmpty) {
      return full.endsWith('@$_emailDomain');
    }
    return full.endsWith('@sju.ac.kr') || full.endsWith('@sejong.ac.kr');
  }

  /// 전송 버튼 활성화: 도메인 로드됨 + 아이디 입력됨 + 전송 중 아님
  bool get _canTapSend =>
      !_isSending &&
      _emailController.text.trim().isNotEmpty &&
      _emailDomain != null &&
      _emailDomain!.isNotEmpty;

  void _sendCode() async {
    setState(() {
      _error = '';
      _success = '';
    });
    final local = _emailController.text.trim();
    if (local.isEmpty) {
      setState(() => _error = '학생 메일 아이디를 입력해주세요');
      return;
    }
    if (_emailDomain == null || _emailDomain!.isEmpty) {
      setState(() => _error = '도메인 정보를 불러오는 중이에요. 잠시 후 다시 시도해주세요.');
      return;
    }
    if (!_isValidEmail) {
      setState(() => _error = '$_environmentName 학생 메일 주소를 입력해주세요\n(@$_emailDomain)');
      return;
    }
    final fullEmail = _fullEmail;
    setState(() => _isSending = true);
    try {
      if (_environmentId != null && _environmentId!.isNotEmpty) {
        await _envRepository.requestEmailVerification(
          environmentId: _environmentId!,
          email: fullEmail,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _isCodeSent = true;
      _success = '인증번호가 발송되었습니다!';
      _timer = 180;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_timer <= 1) {
          _timer = 0;
          return;
        }
        _timer--;
      });
      return _timer > 0;
    });
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _verify() async {
    setState(() {
      _error = '';
      _success = '';
    });
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '인증번호를 입력해주세요');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = '인증번호 6자리를 입력해주세요');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      if (_environmentId != null && _environmentId!.isNotEmpty) {
        await _envRepository.confirmEmailVerification(
          environmentId: _environmentId!,
          code: code,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _success = '인증이 완료되었습니다! 🎉';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEmailDomain();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.darkMode;
    final gradient = UniversityTheme.designPinkGradient;
    final bgGradient = dark ? null : UniversityTheme.screenBgGradient;
    final surface = dark ? const Color(0xFF111827) : null;

    return Scaffold(
      backgroundColor: surface,
      body: Container(
        decoration: BoxDecoration(
          color: surface,
          gradient: bgGradient,
        ),
        child: Column(
        children: [
          // Header (last: gradient px-5 pt-14 pb-6)
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 56, bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFDA4AF),
                  Color(0xFFF9A8D4),
                  Color(0xFFFB7185),
                ],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Text(
                      '학생 인증',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress: 메일 인증 → 프로필 → 완료 (ad 순서)
                Row(
                  children: [
                    _progressStep(icon: LucideIcons.mail, label: '메일 인증', active: true),
                    Expanded(child: Container(height: 2, color: Colors.white.withValues(alpha: 0.3))),
                    _progressStep(icon: null, label: '프로필', active: false, text: '2'),
                    Expanded(child: Container(height: 2, color: Colors.white.withValues(alpha: 0.3))),
                    _progressStep(icon: LucideIcons.check, label: '완료', active: false),
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
                    '학생 메일 인증이\n필요해요 📧',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _environmentName != null
                        ? '$_environmentName 학생 메일로 인증해주세요'
                        : '학생 메일로 인증해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                  Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            readOnly: _isCodeSent,
                            decoration: InputDecoration(
                              hintText: _emailDomain != null ? '아이디' : '로딩 중...',
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            style: TextStyle(
                              color: dark ? Colors.white : const Color(0xFF111827),
                              fontSize: 16,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: dark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _emailDomain != null ? '@$_emailDomain' : '@',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: dark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        if (!_isCodeSent)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _canTapSend ? _sendCode : null,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_canTapSend
                                      ? (dark ? Colors.grey.shade700 : Colors.grey.shade300)
                                      : null,
                                  gradient: _canTapSend
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFB7185)],
                                        )
                                      : null,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(14),
                                    bottomRight: Radius.circular(14),
                                  ),
                                ),
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('전송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailDomain != null
                        ? '@$_emailDomain 메일 아이디만 입력하세요'
                        : '선택한 학교의 메일 도메인을 불러오는 중이에요',
                    style: TextStyle(fontSize: 12, color: dark ? const Color(0xFF6B7280) : const Color(0xFF6B7280)),
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                      decoration: InputDecoration(
                        hintText: '',
                        counterText: '',
                        filled: true,
                        fillColor: dark ? const Color(0xFF1F2937) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '메일로 전송된 6자리 숫자를 입력하세요',
                          style: TextStyle(fontSize: 12, color: dark ? const Color(0xFF6B7280) : const Color(0xFF6B7280)),
                        ),
                        TextButton(
                          onPressed: _sendCode,
                          child: Text(
                            '재전송',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: dark ? const Color(0xFFF472B6) : const Color(0xFFEC4899),
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
                          const Icon(LucideIcons.circleAlert, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error, style: const TextStyle(fontSize: 14, color: Color(0xFFEF4444), fontWeight: FontWeight.w500))),
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
                          const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_success, style: const TextStyle(fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1F2937).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
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
                              colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.mail, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '인증 안내',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: dark ? Colors.white : const Color(0xFF111827)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _environmentName != null
                                    ? '• $_environmentName 학생 메일만 인증 가능합니다\n• 인증번호는 3분간 유효합니다\n• 메일이 오지 않으면 스팸함을 확인해주세요\n• 재전송은 여러 번 가능합니다'
                                    : '• 학생 메일만 인증 가능합니다\n• 인증번호는 3분간 유효합니다\n• 메일이 오지 않으면 스팸함을 확인해주세요\n• 재전송은 여러 번 가능합니다',
                                style: TextStyle(fontSize: 12, color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), height: 1.5),
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
          // Bottom button: 배경 없이 버튼만 (하얀 박스 제거)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: (_isCodeSent &&
                            _codeController.text.length == 6 &&
                            !_isVerifying)
                    ? _verify
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _isCodeSent && _codeController.text.length == 6 && !_isVerifying
                      ? Theme.of(context).colorScheme.primary
                      : (dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  foregroundColor: _isCodeSent && _codeController.text.length == 6 && !_isVerifying
                      ? Colors.white
                      : (dark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide.none,
                ),
                child: _isVerifying
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text('인증 중...'),
                        ],
                      )
                    : const Text('인증 완료'),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _progressStep({required String label, required bool active, IconData? icon, String? text}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: active ? [const BoxShadow(color: Colors.black26, blurRadius: 8)] : null,
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: active ? const Color(0xFFEC4899) : Colors.white)
              : Center(
                  child: Text(
                    text ?? '',
                    style: TextStyle(
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
