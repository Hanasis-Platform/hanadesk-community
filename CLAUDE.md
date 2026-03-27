# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소(HanaDesk Community)의 코드를 다룰 때 참고하는 안내서입니다.
이 프로젝트는 RustDesk를 기반으로 한 커뮤니티 포크이며, 프로젝트 이름은 **HanaDesk Community**입니다.

## 언어 규칙
- 모든 응답과 작성 내용은 **한국어**로 작성해야 합니다.
- 코드, 명령어, 파일 경로 등 기술적 용어는 원문 그대로 유지합니다.

## 개발 명령어

### 빌드 명령어
- `cargo run` - 데스크톱 애플리케이션 빌드 및 실행 (libsciter 라이브러리 필요)
- `python3 build.py --flutter` - Flutter 버전 빌드 (데스크톱)
- `python3 build.py --flutter --release` - Flutter 릴리스 모드 빌드
- `python3 build.py --hwcodec` - 하드웨어 코덱 지원 빌드
- `python3 build.py --vram` - VRAM 기능 빌드 (Windows 전용)
- `cargo build --release` - Rust 바이너리 릴리스 모드 빌드
- `cargo build --features hwcodec` - 특정 기능 플래그를 활성화하여 빌드

### Flutter 모바일 명령어
- `cd flutter && flutter build android` - Android APK 빌드
- `cd flutter && flutter build ios` - iOS 앱 빌드
- `cd flutter && flutter run` - Flutter 앱 개발 모드 실행
- `cd flutter && flutter test` - Flutter 테스트 실행

### 테스트
- `cargo test` - Rust 테스트 실행
- `cd flutter && flutter test` - Flutter 테스트 실행

### 플랫폼별 빌드 스크립트
- `flutter/build_android.sh` - Android 빌드 스크립트
- `flutter/build_ios.sh` - iOS 빌드 스크립트
- `flutter/build_fdroid.sh` - F-Droid 빌드 스크립트

## 프로젝트 아키텍처

### 디렉토리 구조
- **`src/`** - Rust 메인 애플리케이션 코드
  - `src/ui/` - 레거시 Sciter UI (더 이상 사용되지 않음, Flutter 사용 권장)
  - `src/server/` - 오디오/클립보드/입력/비디오 서비스 및 네트워크 연결
  - `src/client.rs` - 피어 연결 처리
  - `src/platform/` - 플랫폼별 코드
- **`flutter/`** - 데스크톱 및 모바일용 Flutter UI 코드
- **`libs/`** - 핵심 라이브러리
  - `libs/hbb_common/` - 비디오 코덱, 설정, 네트워크 래퍼, protobuf, 파일 전송 유틸리티
  - `libs/scrap/` - 화면 캡처 기능
  - `libs/enigo/` - 플랫폼별 키보드/마우스 제어
  - `libs/clipboard/` - 크로스 플랫폼 클립보드 구현

### 주요 컴포넌트
- **원격 데스크톱 프로토콜**: `src/rendezvous_mediator.rs`에 구현된 rustdesk-server 통신용 커스텀 프로토콜
- **화면 캡처**: `libs/scrap/`의 플랫폼별 화면 캡처
- **입력 처리**: `libs/enigo/`의 크로스 플랫폼 입력 시뮬레이션
- **오디오/비디오 서비스**: `src/server/`의 실시간 오디오/비디오 스트리밍
- **파일 전송**: `libs/hbb_common/`의 보안 파일 전송 구현

### UI 아키텍처
- **레거시 UI**: Sciter 기반 (더 이상 사용되지 않음) - `src/ui/` 파일
- **모던 UI**: Flutter 기반 - `flutter/` 파일
  - 데스크톱: `flutter/lib/desktop/`
  - 모바일: `flutter/lib/mobile/`
  - 공유: `flutter/lib/common/` 및 `flutter/lib/models/`

## 빌드 관련 주요 사항

### 의존성
- C++ 의존성을 위해 vcpkg 필요: `libvpx`, `libyuv`, `opus`, `aom`
- `VCPKG_ROOT` 환경 변수 설정 필요
- 레거시 UI 지원을 위해 적절한 Sciter 라이브러리 다운로드 필요

### 무시할 패턴
파일 작업 시 다음 디렉토리를 무시합니다:
- `target/` - Rust 빌드 결과물
- `flutter/build/` - Flutter 빌드 출력
- `flutter/.dart_tool/` - Flutter 도구 파일

### 크로스 플랫폼 고려사항
- Windows 빌드는 추가 DLL 및 가상 디스플레이 드라이버 필요
- macOS 빌드는 배포를 위해 적절한 서명 및 공증 필요
- Linux 빌드는 여러 패키지 형식 지원 (deb, rpm, AppImage)
- 모바일 빌드는 플랫폼별 툴체인 필요 (Android SDK, Xcode)

### 기능 플래그
- `hwcodec` - 하드웨어 비디오 인코딩/디코딩
- `vram` - VRAM 최적화 (Windows 전용)
- `flutter` - Flutter UI 활성화
- `unix-file-copy-paste` - Unix 파일 클립보드 지원
- `screencapturekit` - macOS ScreenCaptureKit (macOS 전용)

### 설정
모든 설정 및 옵션은 `libs/hbb_common/src/config.rs` 파일에 있으며, 4가지 유형이 있습니다:
- Settings
- Local
- Display
- Built-in
