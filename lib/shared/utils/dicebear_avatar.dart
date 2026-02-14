/// DiceBear 9.x notionists SVG, no API key.
/// Same seed => same avatar.
const String _base = 'https://api.dicebear.com/9.x/notionists/svg';

String diceBearAvatarUrl(String seed, {String style = 'notionists'}) {
  return '$_base?seed=${Uri.encodeComponent(seed)}';
}
