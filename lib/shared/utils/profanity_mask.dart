final List<String> _profanityWords = [
  '개새끼',
  '개새키',
  '씨발',
  '시발',
  '병신',
  '븅신',
  '미친놈',
  '미친년',
  '지랄',
  '존나',
  '좆',
  '새끼',
  '꺼져',
  'fuck',
];

String maskProfanity(String text) {
  var masked = text;
  final sortedWords = [..._profanityWords]
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final word in sortedWords) {
    final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
    masked = masked.replaceAllMapped(
      pattern,
      (match) => '*' * match.group(0)!.length,
    );
  }

  return masked;
}
