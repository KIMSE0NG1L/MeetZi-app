/// 로컬: http://PC_IP:3000  |  Cloudflare: https://xxxx.trycloudflare.com  |  ngrok: https://xxxx.ngrok-free.dev
class AppConfig {
  static const String baseUrl = 'https://nearo-server-zpnz46qxuq-du.a.run.app';

  // Supabase 직접 호출용 (경량 읽기 API)
  static const String supabaseUrl = 'https://ohwrdkpgetsonbowyqck.supabase.co';
  // TODO: Supabase Dashboard → Settings → API → anon (public) key 값으로 교체
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9od3Jka3BnZXRzb25ib3d5cWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MjYxMzksImV4cCI6MjA4OTMwMjEzOX0.13dlwWE_jBL4MIC3BO7M595D54rH1-DTPa2qQSHgov4';

  // Google Cloud Console → API 및 서비스 → 사용자 인증 정보 → OAuth 클라이언트 ID(웹 애플리케이션)
  // iOS/Android 모두 이 값을 serverClientId로 넘겨야 idToken의 aud가 서버 검증값과 일치함.
  // TODO: YOUR_GOOGLE_WEB_CLIENT_ID를 Google Cloud Console의 웹 클라이언트 ID로 교체
  static const String googleServerClientId =
      'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
}
