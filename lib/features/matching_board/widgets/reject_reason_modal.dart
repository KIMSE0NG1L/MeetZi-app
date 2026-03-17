import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// ad 디자인: 거절 사유 작성 모달 (그라데이션 헤더, 프로필 카드, 5자 이상/200자, 정중하게 거절하기)
class RejectReasonModal extends StatefulWidget {
  const RejectReasonModal({
    super.key,
    required this.nickname,
    required this.subtitle,
    required this.avatarWidget,
    required this.onSubmit,
  });

  final String nickname;
  final String subtitle;
  final Widget avatarWidget;
  final Future<void> Function(String message) onSubmit;

  @override
  State<RejectReasonModal> createState() => _RejectReasonModalState();
}

class _RejectReasonModalState extends State<RejectReasonModal> {
  final _controller = TextEditingController();
  static const int _minLength = 5;
  static const int _maxLength = 200;

  bool get _isValid => _controller.text.trim().length >= _minLength;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final msg = _controller.text.trim();
    await widget.onSubmit(msg);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = dark
        ? const Color(0xFF374151).withOpacity(0.5)
        : const Color(0xFFF3F4F6);
    final borderColor =
        dark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewPadding.top -
              MediaQuery.of(context).viewInsets.bottom -
              48,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 그라데이션 (고정)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                gradient: ThemeController.getHeaderGradient(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '거절 사유 작성',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            size: 24, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(false),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '상대방에게 정중하게 거절 사유를 전달해주세요',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            // 본문 (키보드 시 스크롤)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 프로필 카드
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          widget.avatarWidget,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.nickname,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface),
                                ),
                                if (widget.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle,
                                    style: TextStyle(
                                        fontSize: 12, color: onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 사유 입력
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: 4,
                          maxLength: _maxLength,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 14, color: onSurface),
                          decoration: InputDecoration(
                            hintText: '',
                            filled: true,
                            fillColor: dark ? const Color(0xFF374151) : surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2),
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            counterText: '',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 8),
                          child: Text(
                            '${_controller.text.trim().length}/$_maxLength',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isValid
                                  ? const Color(0xFF059669)
                                  : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 검증 메시지
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isValid
                            ? (dark
                                ? const Color(0xFF064E3B).withOpacity(0.3)
                                : const Color(0xFFD1FAE5).withOpacity(0.8))
                            : (dark
                                ? const Color(0xFF78350F).withOpacity(0.3)
                                : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isValid
                              ? (dark
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFA7F3D0))
                              : (dark
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFFDE68A)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isValid
                                ? LucideIcons.heartCrack
                                : LucideIcons.circleAlert,
                            size: 20,
                            color: _isValid
                                ? const Color(0xFF059669)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isValid
                                  ? '정중한 사유네요. 이제 전송할 수 있어요'
                                  : '최소 $_minLength자 이상 입력해주세요 (현재 ${_controller.text.trim().length}자)',
                              style: TextStyle(
                                fontSize: 13,
                                color: _isValid
                                    ? (dark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF047857))
                                    : (dark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFB45309)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 전송 버튼
                    FilledButton.icon(
                      onPressed: _isValid ? _submit : null,
                      icon: const Icon(LucideIcons.send, size: 18),
                      label: Text(_isValid ? '정중하게 거절하기' : '사유를 입력해주세요'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}