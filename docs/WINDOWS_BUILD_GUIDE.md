# HanaDesk Community Windows 로컬 빌드 가이드

이 문서는 Windows 개발 PC에서 서버(hbbs/hbbr)와 클라이언트(Flutter UI 포함)를 빌드하는 방법을 설명합니다.

---

## 1. 빌드 환경 요구사항

| 도구 | 버전 | 용도 |
|------|------|------|
| Windows 11 | — | 개발 OS |
| Visual Studio 2022 | Community 이상 | MSVC 컴파일러 (vcvars64) |
| Rust | stable (1.94+) | Rust 컴파일러 |
| Flutter SDK | 3.24.5 | Flutter UI 빌드 |
| vcpkg | commit `120deac306` | C++ 의존성 관리 |
| Python | 3.x | 빌드 스크립트 실행 |
| LLVM/Clang | VS 2022 포함 | `libclang.dll` (bindgen용) |

---

## 2. 초기 환경 설정 (최초 1회)

### 2.1 vcpkg 설치

vcpkg는 프로젝트 루트(`HanaDeskCommunity/vcpkg/`)에 위치합니다.

```powershell
cd d:\Projects\HanaDeskCommunity
git clone https://github.com/microsoft/vcpkg.git vcpkg
cd vcpkg
git checkout 120deac3062162151622ca4860575a33844ba10b
.\bootstrap-vcpkg.bat
```

### 2.2 vcpkg 의존성 빌드

프로젝트의 `vcpkg.json`에 정의된 의존성(libvpx, libyuv, opus, aom, ffmpeg 등)을 빌드합니다.

```powershell
# 반드시 LOCAL_BUILD 환경변수 설정 (aom AVX2 호환성 문제 우회)
$env:LOCAL_BUILD = "1"

cd d:\Projects\HanaDeskCommunity\hanadesk-community
d:\Projects\HanaDeskCommunity\vcpkg\vcpkg.exe install --triplet x64-windows-static --host-triplet x64-windows-static --x-install-root="d:\Projects\HanaDeskCommunity\vcpkg\installed"
```

> **주의**: `--host-triplet x64-windows-static`을 반드시 함께 지정해야 FFmpeg가 설치됩니다.
> **소요 시간**: 30~60분 (FFmpeg, aom 등 소스 빌드 포함). 최초 1회만 필요합니다.

### 2.3 Flutter 커스텀 엔진 교체 (최초 1회)

RustDesk 커스텀 Flutter 엔진으로 교체해야 합니다. 원본 엔진을 먼저 백업합니다.

```powershell
# 1. 원본 엔진 백업
$engineDir = "D:\Projects\flutter\bin\cache\artifacts\engine\windows-x64-release"
Copy-Item -Recurse $engineDir "${engineDir}-backup-original"

# 2. 커스텀 엔진 다운로드 및 교체
Invoke-WebRequest -Uri "https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip" -OutFile windows-x64-release.zip
Expand-Archive -Path windows-x64-release.zip -DestinationPath windows-x64-release -Force
Copy-Item -Force windows-x64-release\* $engineDir
Remove-Item -Recurse windows-x64-release, windows-x64-release.zip
```

> **원본 복원 방법**: `Copy-Item -Recurse -Force "${engineDir}-backup-original\*" $engineDir`

### 2.4 Flutter-Rust Bridge 파일 복사

Bridge 코드 생성은 Linux에서만 정상 동작합니다. builder VM에서 생성한 파일을 복사합니다.

```powershell
scp builder:~/hanadesk-community/src/bridge_generated.rs src/
scp builder:~/hanadesk-community/src/bridge_generated.io.rs src/
scp builder:~/hanadesk-community/flutter/lib/generated_bridge.dart flutter/lib/
scp builder:~/hanadesk-community/flutter/lib/generated_bridge.freezed.dart flutter/lib/
```

> Bridge 파일은 소스 코드가 변경될 때마다 다시 생성해야 합니다.

---

## 3. 빌드 명령어

### 3.1 build.bat 사용법

`build.bat`은 VS 개발자 환경을 자동으로 로드하고 빌드를 수행합니다.

```powershell
cd d:\Projects\HanaDeskCommunity\hanadesk-community

.\build.bat                # Rust 디버그 빌드
.\build.bat release        # Rust 릴리스 빌드
.\build.bat flutter        # Flutter UI 포함 Windows 앱 (기본 코덱)
.\build.bat flutter-full   # Flutter UI + hwcodec + vram (vcpkg 의존성 필요)
```

### 3.2 빌드 모드 비교

| 모드 | 하드웨어 코덱 | 용도 | vcpkg FFmpeg 필요 |
|------|-------------|------|-------------------|
| `flutter` | 소프트웨어 코덱만 | 빠른 개발/테스트 | 아니오 (기본 의존성만) |
| `flutter-full` | GPU 인코딩/디코딩 (NVENC, AMF, QSV) | **상용 배포** | **예** (FFmpeg, aom 등) |

> `flutter-full`은 vcpkg 의존성 설치(2.2절) 완료 후 사용 가능합니다.

### 3.3 서버 빌드

서버는 별도의 vcpkg 의존성 없이 바로 빌드 가능합니다.

```powershell
cd d:\Projects\HanaDeskCommunity\hanadesk-community-server
cargo build --release
```

**출력 파일:**
- `target\release\hbbs.exe` — ID/Rendezvous 서버
- `target\release\hbbr.exe` — 릴레이 서버
- `target\release\rustdesk-utils.exe` — CLI 유틸리티

### 3.4 빌드 결과물 위치

| 프로젝트 | 결과물 | 경로 |
|---------|--------|------|
| 클라이언트 (Flutter) | rustdesk.exe + DLL | `flutter\build\windows\x64\runner\Release\` |
| 클라이언트 (Rust만) | rustdesk.exe | `target\release\` |
| 서버 | hbbs.exe, hbbr.exe | `target\release\` |

---

## 4. LOCAL_BUILD 환경변수

`build.bat`은 자동으로 `LOCAL_BUILD=1`을 설정합니다. 이 변수의 역할:

| 영향 | LOCAL_BUILD=1 (로컬) | 미설정 (CI) |
|------|---------------------|------------|
| aom AVX2 | OFF (MSVC 17.x 호환성) | ON (최대 성능) |
| 결과물 성능 | AV1 인코딩 10~20% 느림 | 최대 성능 |
| 실사용 영향 | **체감 차이 없음** (H.264/H.265 GPU 인코딩이 주력) | — |

### 왜 필요한가?

- aom 3.12.1의 AVX2 인트린직 코드가 최신 MSVC 17.x (VS 2022 14.44+)에서 컴파일 에러 발생
- CI에서는 VS 2022 17.0 (이전 MSVC 버전)을 사용하여 문제 없음
- 로컬에서만 AVX2를 비활성화하여 우회

---

## 5. 빌드 환경 구성도

```
[Windows 개발 PC]
│
├── build.bat flutter        ← 기본 빌드 (hwcodec 없이)
│   ├── Rust 빌드 (cargo build --features flutter --lib --release)
│   └── Flutter 빌드 (flutter build windows --release)
│
├── build.bat flutter-full   ← 전체 빌드 (hwcodec+vram)
│   ├── vcpkg 의존성 필요 (FFmpeg, aom, libvpx, opus 등)
│   ├── Rust 빌드 (cargo build --features hwcodec,vram,flutter --lib --release)
│   └── Flutter 빌드 (flutter build windows --release)
│
└── cargo build --release    ← 서버 빌드 (별도 의존성 불필요)

[builder VM (Ubuntu 22.04)]
│
├── Bridge 코드 생성         ← flutter_rust_bridge_codegen
├── Linux 전체 빌드          ← 02-build.sh
└── .deb 패키지 생성
```

---

## 6. 문제 해결

### 6.1 `stdint.h` / `stddef.h` 파일을 찾을 수 없음

VS 개발자 환경이 로드되지 않았습니다. 반드시 `build.bat`을 통해 빌드하세요.

```powershell
# 잘못된 방법 (bash에서 직접 cargo)
cargo build  # ← stdint.h 에러 발생

# 올바른 방법
.\build.bat release
```

### 6.2 `libavutil/pixfmt.h` 파일을 찾을 수 없음

vcpkg에서 FFmpeg가 빌드되지 않았습니다. `flutter-full` 모드에만 필요합니다.
`--host-triplet`을 반드시 함께 지정해야 합니다.

```powershell
$env:LOCAL_BUILD = "1"
d:\Projects\HanaDeskCommunity\vcpkg\vcpkg.exe install --triplet x64-windows-static --host-triplet x64-windows-static --x-install-root="d:\Projects\HanaDeskCommunity\vcpkg\installed"
```

### 6.3 aom 빌드 실패 (AVX2 관련)

`LOCAL_BUILD` 환경변수가 설정되지 않았습니다. `build.bat`을 사용하면 자동 설정됩니다.
수동 vcpkg install 시에는 `$env:LOCAL_BUILD = "1"`을 먼저 설정하세요.

### 6.4 CRT 링킹 충돌 (LNK2038: RuntimeLibrary 불일치)

```
'MT_StaticRelease' 값이 'MD_DynamicRelease' 값과 일치하지 않습니다.
```

`build.bat`의 `RUSTFLAGS`에 `-C target-feature=+crt-static`이 빠져 있습니다.
이 플래그가 없으면 Rust는 동적 CRT(`/MD`)로 컴파일하고, vcpkg static 라이브러리는 정적 CRT(`/MT`)를 사용하여 충돌합니다.

`build.bat`의 RUSTFLAGS 줄에 `-C target-feature=+crt-static`이 포함되어 있는지 확인하세요:

```batch
set "RUSTFLAGS=-C target-feature=+crt-static -A dead_code -A unused_imports ..."
```

> **참고**: 환경변수 `RUSTFLAGS`가 설정되면 `.cargo/config.toml`의 `rustflags`는 무시됩니다.

### 6.5 Bridge 파일이 없어서 빌드 실패 (bridge_generated.rs)

builder VM에서 bridge 파일을 복사해야 합니다. 2.4 절을 참고하세요.

### 6.6 Flutter 엔진 미교체로 렌더링 이상

커스텀 Flutter 엔진이 교체되지 않았습니다. 2.3 절을 참고하세요.

### 6.7 VCPKG_ROOT 관련 에러

`build.bat`이 자동으로 `%~dp0..\vcpkg` (프로젝트 루트의 vcpkg)를 설정합니다.
수동으로 사용할 때는 `$env:VCPKG_ROOT = "d:\Projects\HanaDeskCommunity\vcpkg"`를 설정하세요.

---

## 7. 빌드 서버 (builder VM) 연동

Windows에서 직접 빌드할 수 없는 작업은 builder VM(Ubuntu 22.04)에서 수행합니다.

| 작업 | 환경 |
|------|------|
| Bridge 코드 생성 | builder VM (Linux 전용) |
| Linux .deb 패키지 빌드 | builder VM |
| Windows 앱 빌드 | 개발 PC (Windows) |
| 서버 Linux 바이너리 | builder VM |
| 서버 Windows 바이너리 | 개발 PC (Windows) |

```powershell
# bridge 파일 갱신
scp builder:~/hanadesk-community/src/bridge_generated.rs src/
scp builder:~/hanadesk-community/src/bridge_generated.io.rs src/
scp builder:~/hanadesk-community/flutter/lib/generated_bridge.dart flutter/lib/
scp builder:~/hanadesk-community/flutter/lib/generated_bridge.freezed.dart flutter/lib/
```
