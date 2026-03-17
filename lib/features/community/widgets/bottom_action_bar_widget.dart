import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 하단 액션 바: 투표 토글 버튼 + 게시 버튼
class BottomActionBarWidget extends StatelessWidget {
  final bool pollEnabled;
  final VoidCallback onTogglePoll;
  final bool isSending;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const BottomActionBarWidget({
    super.key,
    required this.pollEnabled,
    required this.onTogglePoll,
    required this.isSending,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? Colors.grey.shade800 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 투표 토글 버튼
            Material(
              color: pollEnabled
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTogglePoll,
                borderRadius: BorderRadius.circular(12),
                child: Tooltip(
                  message: pollEnabled ? '투표 제거' : '투표 추가',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        pollEnabled ? LucideIcons.vote : LucideIcons.plus,
                        size: 24,
                        color: pollEnabled
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 게시 버튼
            Expanded(
              child: Material(
                color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: isSending || !canSubmit ? null : onSubmit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSending)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          Icon(
                            LucideIcons.send,
                            size: 20,
                            color: canSubmit
                                ? (dark ? Colors.grey.shade200 : const Color(0xFF4B5563))
                                : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '게시하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: canSubmit
                                  ? (dark ? Colors.grey.shade200 : const Color(0xFF4B5563))
                                  : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ],
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
}
