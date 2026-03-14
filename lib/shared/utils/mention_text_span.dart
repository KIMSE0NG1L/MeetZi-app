import 'package:flutter/material.dart';

/// 글/댓글 본문에서 @닉네임 멘션을 [mentionColor](기본 파란색)으로 표시한 [TextSpan] 목록을 만듭니다.
List<TextSpan> buildMentionSpans(
  String text, {
  required TextStyle baseStyle,
  Color? mentionColor,
}) {
  if (text.isEmpty) {
    return [TextSpan(text: '', style: baseStyle)];
  }
  final color = mentionColor ?? const Color(0xFF2563EB);
  final mentionStyle = baseStyle.copyWith(
    color: color,
    fontWeight: baseStyle.fontWeight ?? FontWeight.w500,
  );
  final pattern = RegExp(r'@([^\s@]+)');
  final spans = <TextSpan>[];
  int lastEnd = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: baseStyle,
      ));
    }
    spans.add(TextSpan(
      text: match.group(0)!,
      style: mentionStyle,
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: baseStyle,
    ));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }
  return spans;
}
