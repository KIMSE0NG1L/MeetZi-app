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
    this.gradient,
  });

  final String label;
  final int count;
  final String emoji;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFDBEAFE); // blue-100
    final fg = foregroundColor ?? const Color(0xFF2563EB);   // blue-600

    return Container(
      padding: MeetzyDesignTokens.ticketChipPadding,
      decoration: BoxDecoration(
        color: gradient != null ? null : bg,
        gradient: gradient,
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
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
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
      gradient: const LinearGradient(
        colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
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
      gradient: const LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
    );
  }
}
