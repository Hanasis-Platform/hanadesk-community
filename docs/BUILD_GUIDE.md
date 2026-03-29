# HanaDesk Community 빌드 가이드

이 문서는 HanaDesk Community (RustDesk 기반) 프로젝트의 빌드 절차, 방법, CI 구조를 설명합니다.

## 목차

- [개요](#개요)
- [빌드 환경 요구사항](#빌드-환경-요구사항)
- [로컬 빌드](#로컬-빌드)
- [CI 빌드 (권장)](#ci-빌드-권장)
- [CI 워크플로우 구조](#ci-워크플로우-구조)
- [빌드 아티팩트](#빌드-아티팩트)
- [빌드 스크립트 설명](#빌드-스크립트-설명)
- [문제 해결](#문제-해결)

---

## 개요

이 프로젝트는 두 가지 UI를 가지고 있습니다:

| UI | 상태 | 설명 |
|---|---|---|
| **Flutter UI** | 활성 (권장) | 데스크톱 및 모바일용 현대적 UI |
| **Sciter UI** | deprecated | 레거시 UI, Sciter Classic DLL 필요 (무료 배포 중단) |

**Flutter UI 빌드는 CI 환경에서만 정상 동작합니다.** 로컬에서는 Rust 코드 컴파일 및 테스트만 가능합니다.

### 로컬 vs CI 빌드 비교

| | 로컬 빌드 | CI 빌드 |
|---|---|---|
| **Rust 컴파일** | 가능 | 가능 |
| **Flutter UI 앱** | 불가 (bridge 호환성 문제) | 가능 |
| **Sciter UI 앱** | 불가 (DLL 없음) | 가능 |
| **멀티 플랫폼** | Windows만 | Windows/macOS/Linux/Android/iOS |

---

## 빌드 환경 요구사항

### 로컬 빌드 (Windows)

| 도구 | 버전 | 용도 |
|---|---|---|
| Rust (rustc, cargo) | 1.94+ | Rust 컴파일러 |
| Visual Studio 2022 | Community 이상 | MSVC 컴파일러 |
| vcpkg | 최신 | C++ 의존성 관리 |
| Python | 3.x | 빌드 스크립트 실행 |
| Flutter SDK | 3.24.5 | Flutter UI 빌드 (CI에서만 사용) |
| LLVM/Clang | VS 2022 포함 | `libclang.dll` (bindgen용) |

### 환경 변수 (PowerShell 프로필에 설정됨)

```powershell
# Rust cargo
$env:Path += ";$env:USERPROFILE\.cargo\bin"

# Flutter SDK
$env:Path += ";d:\Projects\flutter\bin"

# VCPKG
$env:VCPKG_ROOT = "<프로젝트경로>\vcpkg"  # 예: d:\Projects\HanaDeskCommunity\vcpkg

# libclang for bindgen
$env:LIBCLANG_PATH = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin"

# GitHub CLI
$env:Path += ";C:\Program Files\GitHub CLI"
```

### vcpkg 의존성 패키지

```powershell
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static
```

---

## 로컬 빌드

### build.bat 사용법

`build.bat`은 Visual Studio 개발자 환경을 자동으로 로드하고 빌드를 수행합니다.

```powershell
.\build.bat                # Rust 디버그 빌드
.\build.bat release        # Rust 릴리스 빌드
.\build.bat flutter        # Flutter 디버그 빌드 (CI 환경 필요)
.\build.bat flutter-release # Flutter 릴리스 빌드 (CI 환경 필요)
```

### build.bat 내부 동작

1. Visual Studio 2022 `vcvars64.bat` 로드
2. `VCPKG_ROOT`, `LIBCLANG_PATH`, `RUSTFLAGS` 설정
3. Cargo/Flutter PATH 추가
4. 선택된 모드에 따라 빌드 실행

### 직접 Cargo 빌드

```powershell
cargo build                        # 디버그 빌드
cargo build --release              # 릴리스 빌드
cargo build --features flutter     # Flutter 기능 포함 빌드
cargo build --features hwcodec     # 하드웨어 코덱 포함 빌드
cargo test                         # 테스트 실행
```

---

## CI 빌드 (권장)

### CI 빌드 트리거 방법

```powershell
# GitHub CLI로 수동 트리거
gh workflow run flutter-nightly.yml --ref hanadesk -R Hanasis-Platform/hanadesk-community

# 빌드 상태 확인
gh run list -R Hanasis-Platform/hanadesk-community --limit 5

# 특정 빌드 상세 확인
gh run view <RUN_ID> -R Hanasis-Platform/hanadesk-community
```

### 아티팩트 다운로드

```powershell
# 모든 아티팩트 다운로드
gh run download <RUN_ID> -R Hanasis-Platform/hanadesk-community -D artifacts

# 특정 아티팩트만 다운로드
gh run download <RUN_ID> -R Hanasis-Platform/hanadesk-community -n rustdesk-unsigned-windows-x86_64 -D artifacts
```

### 일반적인 개발 워크플로우

```
1. 코드 수정
2. 로컬에서 cargo build / cargo test 로 컴파일 확인
3. git commit & push
4. gh workflow run 으로 CI 빌드 트리거
5. 빌드 완료 후 아티팩트 다운로드
6. 테스트 및 배포
```

---

## CI 워크플로우 구조

### 워크플로우 파일 관계

```
flutter-nightly.yml          (트리거: 매일 자정 / 수동)
  └─ flutter-build.yml       (실제 빌드 로직)
       ├─ bridge.yml          (flutter_rust_bridge 코드 생성)
       ├─ Windows 빌드        (x86, x86_64)
       ├─ macOS 빌드          (x86_64, aarch64)
       ├─ Linux 빌드          (x86_64, aarch64)
       ├─ Android 빌드        (arm64, armv7, x86_64)
       ├─ iOS 빌드            (arm64)
       └─ 패키징              (AppImage, Flatpak, MSI, DMG)

flutter-tag.yml              (트리거: git tag)
  └─ flutter-build.yml

flutter-ci.yml               (트리거: workflow_dispatch)
  └─ flutter-build.yml
```

### bridge.yml - Flutter-Rust Bridge 코드 생성

| 항목 | 값 |
|---|---|
| **실행 환경** | Ubuntu 22.04 (Linux) |
| **Flutter 버전** | 3.22.3 |
| **flutter_rust_bridge** | 1.80.1 |
| **Rust 버전** | 1.75 |

**생성 명령:**
```bash
flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/macos/Runner/bridge_generated.h
```

**생성되는 파일:**
- `src/bridge_generated.rs` - Rust wire 코드
- `src/bridge_generated.io.rs` - Rust IO 코드
- `flutter/lib/generated_bridge.dart` - Dart bridge 코드
- `flutter/lib/generated_bridge.freezed.dart` - Dart freezed 코드
- `flutter/macos/Runner/bridge_generated.h` - macOS/iOS C 헤더

> **참고:** bridge 코드 생성은 반드시 Linux 환경에서 실행해야 합니다.
> Windows에서 실행하면 X11 헤더의 `typedef bool` 등이 잘못 포함되어
> Dart 컴파일 에러가 발생합니다.

### flutter-build.yml - 주요 빌드 단계 (Windows 기준)

1. **환경 설정** - Rust, Flutter, LLVM, VCPKG 설치
2. **Flutter 엔진 교체** - RustDesk 커스텀 Flutter 엔진 적용
3. **Bridge 코드 다운로드** - bridge.yml에서 생성된 아티팩트 사용
4. **Rust 빌드** - `python3 build.py --portable --hwcodec --flutter --vram --skip-portable-pack`
5. **Flutter 빌드** - `flutter build windows --release`
6. **패키징** - 포터블 EXE, MSI 설치 프로그램 생성
7. **아티팩트 업로드** - GitHub Releases에 배포

### CI 빌드 환경 변수

```yaml
SCITER_RUST_VERSION: "1.75"
RUST_VERSION: "1.75"
MAC_RUST_VERSION: "1.81"
CARGO_NDK_VERSION: "3.1.2"
LLVM_VERSION: "15.0.6"
FLUTTER_VERSION: "3.24.5"
ANDROID_FLUTTER_VERSION: "3.24.5"
FLUTTER_RUST_BRIDGE_VERSION: "1.80.1"
```

---

## 빌드 아티팩트

CI 빌드 완료 후 다음 아티팩트가 생성됩니다:

### 실행 가능한 앱 (설치/실행용)

| 아티팩트 | 플랫폼 | UI |
|---|---|---|
| `rustdesk-unsigned-windows-x86_64` | Windows 64비트 | Flutter |
| `rustdesk-unsigned-windows-x86` | Windows 32비트 | Flutter |
| `rustdesk-unsigned-macos-aarch64` | macOS Apple Silicon | Flutter |
| `rustdesk-unsigned-macos-x86_64` | macOS Intel | Flutter |
| `rustdesk-1.4.6-x86_64.deb` | Linux x64 | Flutter |
| `rustdesk-1.4.6-aarch64.deb` | Linux ARM64 | Flutter |
| `rustdesk-1.4.6-x86_64-sciter.deb` | Linux x64 | Sciter |
| `rustdesk-1.4.6-armv7-sciter.deb` | Linux ARM32 | Sciter |

### 모바일용 네이티브 라이브러리

| 아티팩트 | 용도 |
|---|---|
| `librustdesk.so.aarch64-linux-android` | Android ARM64 |
| `librustdesk.so.armv7-linux-androideabi` | Android ARM32 |
| `librustdesk.so.x86_64-linux-android` | Android x64 에뮬레이터 |
| `liblibrustdesk.a` | iOS 정적 라이브러리 |

### 빌드 중간 산출물

| 아티팩트 | 용도 |
|---|---|
| `bridge-artifact` | flutter_rust_bridge 생성 코드 |
| `topmostwindow-artifacts` | Windows 최상위 윈도우 헬퍼 DLL |

---

## 빌드 스크립트 설명

### build.bat

Windows 로컬 빌드를 위한 배치 파일입니다.

**주요 기능:**
- Visual Studio 2022 개발자 환경 자동 로드
- `VCPKG_ROOT`, `LIBCLANG_PATH` 등 환경 변수 설정 (vcvars64 이후에 설정하여 덮어쓰기 방지)
- 비심각 경고 억제 (`RUSTFLAGS`)
- Flutter/Rust 빌드 모드 선택

### build.py

Python 기반 크로스 플랫폼 빌드 스크립트입니다.

**주요 옵션:**
```
--flutter              Flutter UI 활성화
--release              릴리스 모드
--hwcodec              하드웨어 코덱 지원
--vram                 VRAM 최적화 (Windows 전용)
--portable             포터블 빌드 (Windows)
--skip-cargo           Cargo 빌드 스킵
--skip-portable-pack   포터블 패킹 스킵
--unix-file-copy-paste Unix 파일 복사-붙여넣기
--screencapturekit     macOS ScreenCaptureKit
```

**플랫폼별 출력 경로:**
- Windows: `build/windows/x64/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`
- Linux: `build/linux/x64/release/bundle/`

### fix_bridge.ps1

Windows에서 `flutter_rust_bridge_codegen`을 실행했을 때 발생하는 호환성 문제를 수정하는 PowerShell 스크립트입니다.

**수정 내용:**
1. X11 헤더 아티팩트 제거: `typedef bool = ffi.NativeFunction<...>` 삭제
2. `ffi.Pointer<bool>` → `ffi.Pointer<ffi.Bool>` 치환
3. `ffi.Bool Function(DartPort` → `ffi.Uint8 Function(DartPort` 치환

> **참고:** 이 스크립트는 Windows에서 bridge 코드를 생성할 때만 필요합니다.
> CI에서는 Linux 환경에서 bridge를 생성하므로 이 문제가 발생하지 않습니다.

---

## 문제 해결

### `cargo` 명령어를 찾을 수 없음

PowerShell에서 PATH가 로드되지 않았을 수 있습니다:
```powershell
. $PROFILE
# 또는 새 터미널 열기
```

### `VCPKG_ROOT` 관련 에러

`vcvars64.bat`이 `VCPKG_ROOT`를 덮어쓸 수 있습니다. `build.bat`에서는 vcvars64 호출 이후에 설정하도록 되어 있습니다.

### `libclang.dll` 을 찾을 수 없음

`LIBCLANG_PATH` 환경 변수가 올바른 경로를 가리키는지 확인:
```powershell
echo $env:LIBCLANG_PATH
# 예: C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin
```

### Flutter bridge 생성 시 `typedef bool` 에러

Windows에서 bridge 코드를 생성하면 X11 헤더 타입이 잘못 포함됩니다.
- **해결:** WSL(Linux)에서 bridge 생성 또는 CI 사용
- **임시 해결:** `fix_bridge.ps1` 실행 (완전한 해결은 아님)

### CI 빌드 트리거 실패

워크플로우가 비활성화되어 있을 수 있습니다:
```powershell
# 워크플로우 활성화
gh api -X PUT repos/Hanasis-Platform/hanadesk-community/actions/workflows/<WORKFLOW_ID>/enable
```

### Sciter Classic DLL 호환성

Sciter JS SDK 6.x는 이 프로젝트와 **호환되지 않습니다**. 프로젝트는 Sciter Classic API를 사용하며, Sciter Classic은 더 이상 무료로 배포되지 않습니다. Flutter UI를 사용하세요.
