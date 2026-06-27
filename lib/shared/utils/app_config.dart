/// 로컬: http://PC_IP:3000  |  Cloudflare: https://xxxx.trycloudflare.com  |  ngrok: https://xxxx.ngrok-free.dev
class AppConfig {
  static const String baseUrl = 'https://nearo-server-zpnz46qxuq-du.a.run.app';

  // Supabase 직접 호출용 (경량 읽기 API)
  static const String supabaseUrl = 'https://ohwrdkpgetsonbowyqck.supabase.co';
  // TODO: Supabase Dashboard → Settings → API → anon (public) key 값으로 교체
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
}
