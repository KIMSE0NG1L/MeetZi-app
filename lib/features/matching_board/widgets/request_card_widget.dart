import 'dart:ui';

import 'package:flutter/material.dart';

/// 공통 카드 컴포넌트 (ad 디자인)
class RequestCardWidget extends StatelessWidget {
  const RequestCardWidget({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.message,
    required this.footer,
    this.badge,
    this.onTap,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final String? timestamp;
  final String? message;
  final Widget footer;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final outerBg = dark ? const Color(0xFF1F2937) : Colors.white;
    final innerBg = dark
        ? const Color(0xFF374151)
        : const Color(0xFFF3F4F6);
    final onTitle = dark ? Colors.white : const Color(0xFF111827);
    final onSub = dark ? Colors.grey.shade300 : Colors.grey.shade600;
    final onMsg = dark ? Colors.grey.shade200 : const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: outerBg,
              border: Border.all(
                color: dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dark ? Colors.white24 : Colors.white70,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 6)),
                              ],
                            ),
                            child: avatar,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: onTitle),
                                      ),
                                    ),
                                    if (badge != null) ...[
                                      const SizedBox(width: 8),
                                      badge!,
                                    ],
                                  ],
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: onSub),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (timestamp != null && timestamp!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                timestamp!,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSub),
                              ),
                            ),
                        ],
                      ),
                      if (message != null && message!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: dark
                                ? null
                                : const [
                                    BoxShadow(
                                        color: Color(0x0D000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2)),
                                  ],
                          ),
                          child: Text(
                            message!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, height: 1.3, color: onMsg),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      footer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}