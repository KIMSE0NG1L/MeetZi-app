/// 글 작성 시각 표시: 방금 전 / N분 전 / 오늘 HH:mm / 날짜
String formatPostTime(dynamic createdAt) {
  if (createdAt == null) return '';
  DateTime dt;
  if (createdAt is DateTime) {
    dt = createdAt.isUtc ? createdAt.toLocal() : createdAt;
  } else if (createdAt is String) {
    try {
      dt = DateTime.parse(createdAt);
      if (dt.isUtc) dt = dt.toLocal();
    } catch (_) {
      return '';
    }
  } else {
    return '';
  }
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';

  final today = DateTime(now.year, now.month, now.day);
  final postDay = DateTime(dt.year, dt.month, dt.day);

  if (postDay == today) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  if (postDay.year == now.year) {
    return '${dt.month}월 ${dt.day}일';
  }
  return '${dt.year}. ${dt.month}. ${dt.day}';
}
