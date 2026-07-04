/// 로컬: http://PC_IP:3000  |  Cloudflare: https://xxxx.trycloudflare.com  |  ngrok: https://xxxx.ngrok-free.dev
class AppConfig {
  static const String baseUrl = 'https://nearo-server-zpnz46qxuq-du.a.run.app';

  // Supabase 직접 호출용 (경량 읽기 API)
  static const String supabaseUrl = 'https://ohwrdkpgetsonbowyqck.supabase.co';
  // TODO: Supabase Dashboard → Settings → API → anon (public) key 값으로 교체
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9od3Jka3BnZXRzb25ib3d5cWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MjYxMzksImV4cCI6MjA4OTMwMjEzOX0.13dlwWE_jBL4MIC3BO7M595D54rH1-DTPa2qQSHgov4';
}
