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

## Android Build Guide (Current Local Setup)

Recommended project path:
- `C:\develop\MeetZi\MeetZi-app`

Recommended Flutter SDK path:
- `C:\Users\t8928\dev\flutter`

Important:
- On Windows, Flutter/Gradle builds can fail if the project path contains non-ASCII characters.
- Build from an ASCII-only path such as `C:\develop\MeetZi\MeetZi-app`.

### 1. Open PowerShell and set local build environment

```powershell
$env:JAVA_HOME='C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot'
$sdk='C:\Users\t8928\AppData\Local\Android\Sdk'
$env:ANDROID_HOME=$sdk
$env:ANDROID_SDK_ROOT=$sdk
$env:PATH='C:\Users\t8928\dev\flutter\bin;C:\Program Files\Git\cmd;C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot\bin;'+$sdk+'\platform-tools;'+$sdk+'\cmdline-tools\latest\bin;'+$env:PATH
```

### 2. Install packages

```powershell
flutter pub get
```

### 3. Build APK

Debug APK:

```powershell
flutter build apk --debug
```

Release APK:

```powershell
flutter build apk
```

Faster release build for most Android devices (arm64 only):

```powershell
flutter build apk --release --target-platform android-arm64
```

### 4. Output files

- `build\app\outputs\flutter-apk\app-debug.apk`
- `build\app\outputs\flutter-apk\app-release.apk`

### 5. Notes

- If `flutter` commands feel stuck on Windows, confirm that the Flutter SDK is installed in a user-owned ASCII path.
- If Android Gradle reports a path-character issue, make sure the repository itself is not under a Korean or other non-ASCII directory name.
