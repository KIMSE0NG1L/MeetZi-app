import 'package:nearo_app/shared/utils/app_config.dart';

/// storageKey(서버에서 오는 값)를 실제 이미지 URL로 변환.
/// - / 로 시작하면 서버 로컬 업로드 → baseUrl 사용
/// - 그 외에는 S3 키로 간주
String? photoUrlFromStorageKey(String? storageKey) {
  if (storageKey == null || storageKey.isEmpty) return null;
  if (storageKey.startsWith('http')) return storageKey;
  if (storageKey.startsWith('/')) return '${AppConfig.baseUrl}$storageKey';
  return 'https://nearo-image.s3.ap-northeast-2.amazonaws.com/$storageKey';
}
