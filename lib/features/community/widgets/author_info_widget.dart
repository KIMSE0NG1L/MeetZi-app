import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 포스트 작성자 정보를 표시하는 위젯
class AuthorInfoWidget extends StatelessWidget {
  final String schoolName;

  const AuthorInfoWidget({
    super.key,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE5E7EB),
            border: Border.all(
              color: dark ? Colors.grey.shade600 : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(LucideIcons.user, size: 24, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '작성자',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                schoolName,
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
