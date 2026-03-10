/// DiceBear 9.x lorelei SVG, no API key.
/// Same seed => same avatar. 옵션으로 사용자가 꾸미기 가능 (hair, eyes, glasses, backgroundColor 등).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// DiceBear v9 API base (style is injected: lorelei, etc.)
String _diceBearBase(String style) => 'https://api.dicebear.com/9.x/$style/svg';

String diceBearAvatarUrl(
  String seed, {
  String style = 'lorelei',
  Map<String, String>? options,
  int scalePercent = 100,
}) {
  final params = <String, String>{'seed': seed};
  if (options != null && options.isNotEmpty) {
    for (final e in options.entries) {
      if (e.value.isNotEmpty) params[e.key] = e.value;
    }
    // lorelei: 선택된 옵션이 보이도록 확률 100%로 고정
    if (params.containsKey('glasses') && params['glasses']!.isNotEmpty) {
      params['glassesProbability'] = '100';
    }
    if (params.containsKey('beard') && params['beard']!.isNotEmpty) {
      params['beardProbability'] = '100';
    }
    if (params.containsKey('earrings') && params['earrings']!.isNotEmpty) {
      params['earringsProbability'] = '100';
    }
    if (params.containsKey('hairAccessories') && params['hairAccessories']!.isNotEmpty) {
      params['hairAccessoriesProbability'] = '100';
    }
  }
  if (scalePercent != 100) {
    params['scale'] = scalePercent.clamp(0, 200).toString();
  }
  final query = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '${_diceBearBase(style)}?$query';
}

/// 위젯: seed/style로 DiceBear 아바타 표시
class DiceBearAvatar extends StatelessWidget {
  final String seed;
  final String style;
  final Map<String, String>? options;
  final double size;

  const DiceBearAvatar({
    super.key,
    required this.seed,
    this.style = 'lorelei',
    this.options,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final url = diceBearAvatarUrl(seed, style: style, options: options);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholderBuilder: (_) => Icon(LucideIcons.user, size: size * 0.6, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
