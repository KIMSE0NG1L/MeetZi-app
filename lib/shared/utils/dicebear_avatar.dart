/// DiceBear 9.x notionists SVG, no API key.
/// Same seed => same avatar. 옵션으로 사용자가 꾸미기 가능 (hair, eyes, glasses, backgroundColor 등).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    // 안경/수염/제스처가 선택돼 있으면 확률 100%로 고정 (DiceBear 기본 확률 때문에 안 보일 수 있음)
    if (params.containsKey('glasses') && params['glasses']!.isNotEmpty) {
      params['glassesProbability'] = '100';
    }
    if (params.containsKey('beard') && params['beard']!.isNotEmpty) {
      params['beardProbability'] = '100';
    }
    if (params.containsKey('gesture') && params['gesture']!.isNotEmpty) {
      params['gestureProbability'] = '100';
    }
  }
  final query = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '$_base?$query';
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
    this.style = 'notionists',
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
