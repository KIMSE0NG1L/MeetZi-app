# NEARO App

Flutter 기반 NEARO 모바일 앱 저장소입니다.

## 주요 기능
- 학교/소속 기반 가입과 프로필 관리
- 매칭 보드, 랜덤 매칭, 매칭 대기함
- 채팅, 알림, 신고/차단
- 커뮤니티 글, 댓글, 대댓글, 좋아요, 투표
- 커뮤니티 태그 필터
  - `전체`
  - `자유`
  - `연애·썸`
  - `소개팅·매칭후기`
  - `고민상담`
  - `유머·밈`

## 최근 반영 사항
- 랜덤 매칭과 커뮤니티 프로필 카드 UI 통일
- 매칭 대기함 받은 요청 상태 유지
- 받은 요청 수락 시 확인 팝업으로 처리
- 매칭 대기함 프로필/아바타 해석 로직 공용화
- 커뮤니티 작성자, 댓글 작성자 아바타 로직 공용화
- 아이스브레이킹 추천 문구 비활성화

## 기술 스택
- Flutter
- Dart
- Dio
- Firebase Messaging
- flutter_local_notifications
- socket_io_client

## 실행
```bash
flutter pub get
flutter run
```

## APK 빌드
디버그 APK:
```bash
flutter build apk --debug
```

릴리즈 APK:
```bash
flutter build apk
```

출력 경로:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

## 필수 설정
1. API 서버 주소 설정
- [app_config.dart](/c:/Users/USER-PC/project/nearo-app/lib/shared/utils/app_config.dart)
- `AppConfig.baseUrl` 값을 서버 주소로 변경

2. Firebase 설정
- Android: `android/app/google-services.json`
- FCM 활성화

## 디렉터리
- `lib/features/`: 도메인별 기능
- `lib/shared/`: 공통 API, 테마, 유틸
- `assets/`: 이미지, 아이콘, 애니메이션
