# NEARO App

Flutter 기반 NEARO 모바일 앱 저장소입니다.

## 핵심 기능
- 학교/소속 기반 인증 및 커뮤니티
- 매칭 보드, 채팅, 알림, 프로필 관리
- 커뮤니티 글/댓글/좋아요/투표
- 커뮤니티 태그 필터
  - `전체`
  - `자유`
  - `연애·썸`
  - `소개팅·매칭후기`
  - `고민상담`
  - `유머·밈`

## 기술 스택
- Flutter (Dart)
- Dio
- Firebase Messaging
- flutter_local_notifications
- socket_io_client

## 실행 방법
```bash
flutter pub get
flutter run
```

릴리즈 APK:
```bash
flutter build apk --release
```

## 필수 설정
1. API 서버 주소 설정
- 파일: `lib/shared/utils/app_config.dart`
- `AppConfig.baseUrl` 값을 서버 주소로 설정

2. Firebase 설정
- Android: `android/app/google-services.json` 배치
- FCM 활성화

## 커뮤니티 태그 동작
- 글 작성 화면에서 태그를 선택해 업로드
- 커뮤니티 목록 카드에서 태그 뱃지 표시
- 하단 태그 바를 눌러 태그별 글만 필터링

## 디렉터리 개요
- `lib/features/`: 도메인별 기능
- `lib/shared/`: 공통 API/테마/유틸
- `assets/`: 이미지/아이콘/애니메이션
