# MeetZy 디자인 폰트 (Pretendard)

last 폴더 UI 1:1 재현을 위해 **Pretendard** 폰트를 사용합니다.

## 설정 방법

1. [Pretendard](https://github.com/orioncactus/pretendard)에서 폰트 파일을 다운로드합니다.
2. 다음 파일을 이 폴더(`assets/fonts/`)에 넣습니다.
   - `Pretendard-Regular.ttf` (400)
   - `Pretendard-Medium.ttf` (500)
   - `Pretendard-SemiBold.ttf` (600)
   - `Pretendard-Bold.ttf` (700)
3. `pubspec.yaml`의 `flutter.fonts`에 위 파일이 등록되어 있는지 확인합니다.

폰트를 추가하지 않으면 앱은 시스템 기본 폰트로 표시됩니다. (일부 환경에서는 오류가 날 수 있으니, 가능하면 폰트 파일을 추가하는 것을 권장합니다.)
