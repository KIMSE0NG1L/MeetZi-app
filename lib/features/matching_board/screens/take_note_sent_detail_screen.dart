import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// 내가 보낸 가져가기 요청 상세 (상태 + 거절 시 상대방 거절 사유 표시)
class TakeNoteSentDetailScreen extends StatelessWidget {
  const TakeNoteSentDetailScreen({
    super.key,
    required this.requestId,
    required this.recipientNickname,
    this.recipient,
    this.profile,
    required this.status,
    this.senderMessage,
    this.rejectionMessage,
  });

  final String requestId;
  final String recipientNickname;
  final Map<String, dynamic>? recipient;
  final Map<String, dynamic>? profile;
  final String status;
  final String? senderMessage;
  final String? rejectionMessage;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final statusLabel = status == 'accepted'
        ? '수락됨'
        : status == 'rejected'
            ? '거절됨'
            : '대기 중';
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    gradient: ThemeController.getHeaderGradient()),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(LucideIcons.arrowLeft),
                      color: Colors.white,
                      tooltip: '뒤로',
                    ),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.send, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '보낸 가져가기 요청',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$recipientNickname님에게 가져가기를 보냈어요.',
                        style: TextStyle(fontSize: 15, color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 16,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRejected
                                  ? LucideIcons.heartCrack
                                  : (status == 'accepted'
                                      ? Icons.favorite
                                      : LucideIcons.clock),
                              size: 18,
                              color: isRejected
                                  ? const Color(0xFF9CA3AF)
                                  : status == 'accepted'
                                      ? const Color(0xFF10B981)
                                      : (dark
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFB45309)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isRejected
                                    ? const Color(0xFF9CA3AF)
                                    : status == 'accepted'
                                        ? const Color(0xFF10B981)
                                        : onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (senderMessage != null &&
                          senderMessage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionLabel('내가 보낸 멘트', onSurfaceVariant),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                dark ? const Color(0xFF1F2937) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6)),
                            ],
                          ),
                          child: Text(
                            senderMessage!.trim(),
                            style: TextStyle(
                                fontSize: 14, height: 1.35, color: onSurface),
                          ),
                        ),
                      ],
                      if (isRejected &&
                          rejectionMessage != null &&
                          rejectionMessage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionLabel('상대방 거절 사유', onSurfaceVariant),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: (dark
                                    ? Colors.red.shade900
                                    : Colors.red.shade50)
                                .withOpacity(0.60),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: dark
                                  ? Colors.red.shade700
                                  : Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            rejectionMessage!.trim(),
                            style: TextStyle(
                                fontSize: 14, height: 1.35, color: onSurface),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }
}