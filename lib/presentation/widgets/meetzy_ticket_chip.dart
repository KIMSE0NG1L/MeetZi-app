import 'package:flutter/material.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';

/// last MeetZyBoard 열람권/등록권/매칭권 칩 (px-3 py-2, rounded-xl, gap-2).
class MeetzyTicketChip extends StatelessWidget {
  const MeetzyTicketChip({
    super.key,
    required this.label,
    required this.count,
    this.emoji = '👀',
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final int count;
  final String emoji;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFDBEAFE); // blue-100
    final fg = foregroundColor ?? const Color(0xFF2563EB);   // blue-600

    return Container(
      padding: MeetzyDesignTokens.ticketChipPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.ticketChipRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.ticketLabel(fg)),
          const SizedBox(height: MeetzyDesignTokens.ticketChipGap / 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: MeetzyDesignTokens.ticketChipGap / 2),
              Text('$count', style: AppTextStyles.ticketValue(fg)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 열람권 (파랑)
class MeetzyReadingTicketChip extends StatelessWidget {
  const MeetzyReadingTicketChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return MeetzyTicketChip(
      label: '열람권',
      count: count,
      emoji: '👀',
      backgroundColor: const Color(0xFFDBEAFE),
      foregroundColor: const Color(0xFF2563EB),
    );
  }
}

/// 등록권 (핑크)
class MeetzyRegisterTicketChip extends StatelessWidget {
  const MeetzyRegisterTicketChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return MeetzyTicketChip(
      label: '등록권',
      count: count,
      emoji: '📝',
      backgroundColor: const Color(0xFFFCE7F3),
      foregroundColor: const Color(0xFFDB2777),
    );
  }
}

/// 매칭권 (보라)
class MeetzyMatchingTicketChip extends StatelessWidget {
  const MeetzyMatchingTicketChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return MeetzyTicketChip(
      label: '매칭권',
      count: count,
      emoji: '💝',
      backgroundColor: const Color(0xFFEDE9FE),
      foregroundColor: const Color(0xFF7C3AED),
    );
  }
}
