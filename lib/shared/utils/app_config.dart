/// API·채팅 공통 base URL.
/// - 로컬(Wi‑Fi): http://PC_IPv4:3000 (ipconfig로 확인)
/// - Cloudflare Tunnel: https://xxxx.trycloudflare.com (cloudflared tunnel --url http://localhost:3000)
/// - ngrok: https://xxxx.ngrok-free.dev
class AppConfig {
  static const String baseUrl = 'https://recorders-ordering-axis-daughters.trycloudflare.com';

  /// baseUrl 기준 채팅 소켓 URL (http → ws, https → wss)
  static String get chatSocketUrl {
    final u = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    if (u.startsWith('https://')) return '${u.replaceFirst('https://', 'wss://')}/chat';
    return '${u.replaceFirst('http://', 'ws://')}/chat';
  }
}
