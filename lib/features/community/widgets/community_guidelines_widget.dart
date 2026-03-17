import 'package:flutter/material.dart';

/// 커뮤니티 가이드라인을 표시하는 위젯
class CommunityGuidelinesWidget extends StatelessWidget {
  const CommunityGuidelinesWidget({super.key});

  Widget _guideline(String text, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey.shade800.withOpacity(0.4) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📌',
                style: TextStyle(fontSize: 14, color: dark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Text(
                '커뮤니티 가이드라인',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _guideline('타인을 존중하는 표현을 사용해주세요', dark),
          _guideline('개인정보 노출에 주의해주세요', dark),
          _guideline('허위사실 유포는 삼가주세요', dark),
        ],
      ),
    );
  }
}
