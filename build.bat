@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Load Visual Studio 2022 developer environment
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else (
    echo [ERROR] Visual Studio 2022 not found.
    exit /b 1
)

:: Set VCPKG_ROOT after vcvars64 (vcvars64 may overwrite it)
set "VCPKG_ROOT=%~dp0..\vcpkg"

:: Mark as local build (enables MSVC workarounds in vcpkg portfiles)
set "LOCAL_BUILD=1"

:: Add cargo to PATH
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"

:: Set libclang path for bindgen
set "LIBCLANG_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin"

:: Static CRT linking (must match vcpkg x64-windows-static) + suppress non-critical warnings
set "RUSTFLAGS=-C target-feature=+crt-static -A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated"

:: Add Flutter to PATH
set "PATH=d:\Projects\flutter\bin;%PATH%"

:: Select build mode
set "MODE=%1"
if "%MODE%"=="" set "MODE=debug"

if "%MODE%"=="client" goto :client
if "%MODE%"=="support" goto :support
if "%MODE%"=="flutter" goto :flutter
if "%MODE%"=="flutter-installer" goto :flutter_installer
if "%MODE%"=="flutter-full" goto :flutter_full
if "%MODE%"=="release" goto :release
goto :debug

:client
echo [BUILD] Flutter CLIENT mode (incoming only, admin manifest)...
python build.py --flutter --extra-features client-mode --portable --admin
if !errorlevel! neq 0 goto :check
for /f "tokens=3 delims= " %%V in ('findstr /b "version" Cargo.toml') do set "VER=%%~V"
signtool sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a "hanadesk-!VER!-install.exe"
if not exist "%~dp0..\test-client-admin" mkdir "%~dp0..\test-client-admin"
copy /y "hanadesk-!VER!-install.exe" "%~dp0..\test-client-admin\HanaDeskCommunityClient-!VER!-install.exe" >nul
echo [OK] test-client-admin\HanaDeskCommunityClient-!VER!-install.exe
goto :check

:support
echo [BUILD] Flutter SUPPORT mode (outgoing only, admin manifest)...
python build.py --flutter --extra-features support-mode --portable --admin
goto :check

:flutter
echo [BUILD] Flutter mode (default, no mode restriction)...
python build.py --flutter --skip-portable-pack
goto :check

:flutter_installer
echo [BUILD] Flutter mode + installer...
python build.py --flutter --portable
goto :check

:flutter_full
echo [BUILD] Flutter full mode (hwcodec+vram, CI environment required)...
python build.py --portable --hwcodec --flutter --vram --skip-portable-pack
goto :check

:release
echo [BUILD] Rust release mode...
cargo build --release
if !errorlevel! neq 0 goto :check
echo [SIGN] Signing release binaries...
for %%F in (target\release\*.exe target\release\*.dll) do (
    signtool sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a "%%F" 2>nul && echo [SIGN] %%F
)
goto :check

:debug
echo [BUILD] Rust debug mode...
cargo build
goto :check

:check
if !errorlevel! neq 0 (
    echo [ERROR] Build failed.
    exit /b !errorlevel!
)

echo [DONE] Build completed successfully.
endlocal
