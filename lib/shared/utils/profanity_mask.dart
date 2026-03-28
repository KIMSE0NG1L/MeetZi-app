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
  '좃',
  '새끼',
  '꺼져',
  '섹스',
  '야스',
  '자지',
  '보지',
  '꼬추',
  '쥬지',
  '잠지',
  '딸딸이',
  '자위',
  '정액',
  '사정',
  '애무',
  '오르가즘',
  '원나잇',
  '조건만남',
  '성매매',
  '몸팔이',
  '걸레',
  '걸창',
  '창녀',
  '호텔가자',
  '자러가자',
  '벗어봐',
  '야동',
  '변태',
  '발기',
  '고추',
  '삽입',
  '후장',
  '애널',
  '오랄',
  '페라',
  '펠라',
  '빨아줘',
  '박아줘',
  '따먹',
  '먹버',
  '몰카',
  '강간',
  '벗방',
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
