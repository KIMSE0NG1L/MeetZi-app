/// DiceBear 9.x notionists SVG, no API key.
/// Same seed => same avatar. 옵션으로 사용자가 꾸미기 가능 (hair, eyes, glasses, backgroundColor 등).
const String _base = 'https://api.dicebear.com/9.x/notionists/svg';

String diceBearAvatarUrl(
  String seed, {
  String style = 'notionists',
  Map<String, String>? options,
}) {
  final params = <String, String>{'seed': seed};
  if (options != null && options.isNotEmpty) {
    for (final e in options.entries) {
      if (e.value.isNotEmpty) params[e.key] = e.value;
    }
    // 안경/수염이 선택돼 있으면 확률 100%로 고정 (DiceBear 기본 확률 때문에 안 보일 수 있음)
    if (params.containsKey('glasses') && params['glasses']!.isNotEmpty) {
      params['glassesProbability'] = '100';
    }
    if (params.containsKey('beard') && params['beard']!.isNotEmpty) {
      params['beardProbability'] = '100';
    }
  }
  final query = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '$_base?$query';
}
