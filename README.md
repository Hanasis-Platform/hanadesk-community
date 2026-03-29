# HanaDesk Community

<a href="docs/BUILD_GUIDE.md">빌드 가이드</a> •
<a href="#프로젝트-구조">프로젝트 구조</a> •
<a href="#스크린샷">스크린샷</a>

[RustDesk](https://github.com/rustdesk/rustdesk) 기반의 커뮤니티 원격 데스크톱 솔루션입니다. Rust로 작성되었으며, 별도의 설정 없이 바로 사용할 수 있습니다.

> **면책 조항:** 이 소프트웨어의 비윤리적이거나 불법적인 사용을 지지하지 않습니다. 무단 접근, 제어 또는 개인정보 침해 등의 오용은 지침에 위배됩니다.

## 다운로드

- [**최신 릴리스**](https://github.com/Hanasis-Platform/hanadesk-community/releases)
- [**Nightly 빌드**](https://github.com/Hanasis-Platform/hanadesk-community/releases/tag/nightly)

## 빌드

이 프로젝트는 Flutter UI와 Rust 백엔드로 구성되어 있습니다. 자세한 빌드 방법은 [빌드 가이드](docs/BUILD_GUIDE.md)를 참고하세요.

### 빠른 시작 (로컬 Rust 빌드)

```sh
# 의존성 설치
# vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static

# 빌드 (Windows)
.\build.bat          # 디버그 빌드
.\build.bat release  # 릴리스 빌드
```

### CI 빌드 (Flutter UI 포함, 권장)

```sh
gh workflow run flutter-nightly.yml --ref hanadesk -R Hanasis-Platform/hanadesk-community
```

## 프로젝트 구조

- **[libs/hbb_common](libs/hbb_common)**: 비디오 코덱, 설정, TCP/UDP 래퍼, protobuf, 파일 전송 유틸리티
- **[libs/scrap](libs/scrap)**: 화면 캡처
- **[libs/enigo](libs/enigo)**: 플랫폼별 키보드/마우스 제어
- **[libs/clipboard](libs/clipboard)**: 크로스 플랫폼 클립보드 구현
- **[src/server](src/server)**: 오디오/클립보드/입력/비디오 서비스 및 네트워크 연결
- **[src/client.rs](src/client.rs)**: 피어 연결 처리
- **[src/rendezvous_mediator.rs](src/rendezvous_mediator.rs)**: 서버 통신 및 연결 중개
- **[src/platform](src/platform)**: 플랫폼별 코드
- **[flutter](flutter)**: 데스크톱 및 모바일용 Flutter UI
- **[src/ui](src/ui)**: 레거시 Sciter UI (deprecated)

## 스크린샷

![Connection Manager](https://github.com/rustdesk/rustdesk/assets/28412477/db82d4e7-c4bc-4823-8e6f-6af7eadf7651)

![Connected to a Windows PC](https://github.com/rustdesk/rustdesk/assets/28412477/9baa91e9-3362-4d06-aa1a-7518edcbd7ea)

![File Transfer](https://github.com/rustdesk/rustdesk/assets/28412477/39511ad3-aa9a-4f8c-8947-1cce286a46ad)

## 라이선스

이 프로젝트는 [GNU Affero General Public License v3.0 (AGPL-3.0)](./LICENCE)에 따라 라이선스됩니다.

### 원본 프로젝트

이 프로젝트는 [RustDesk](https://github.com/rustdesk/rustdesk) (Copyright © Purslane Ltd.)를 기반으로 한 커뮤니티 포크입니다.

### AGPL-3.0 주요 의무사항

- 이 소프트웨어를 수정하여 배포하거나 네트워크 서버에서 운영하는 경우, 수정된 소스 코드를 동일한 AGPL-3.0 라이선스로 공개해야 합니다.
- 원본 저작권 고지 및 라이선스 전문을 유지해야 합니다.
- 상세한 내용은 [LICENCE](./LICENCE) 파일 및 [NOTICE](./NOTICE) 파일을 참고하세요.

### 서드파티 라이선스

이 프로젝트에 포함된 서드파티 라이브러리의 라이선스는 [NOTICE](./NOTICE) 파일을 참고하세요.
