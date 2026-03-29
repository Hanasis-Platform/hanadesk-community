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

:: Suppress non-critical warnings
set "RUSTFLAGS=-A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated"

:: Add Flutter to PATH
set "PATH=d:\Projects\flutter\bin;%PATH%"

:: Select build mode
set "MODE=%1"
if "%MODE%"=="" set "MODE=debug"

if "%MODE%"=="flutter" goto :flutter
if "%MODE%"=="flutter-full" goto :flutter_full
if "%MODE%"=="release" goto :release
goto :debug

:flutter
echo [BUILD] Flutter mode...
python build.py --flutter --skip-portable-pack
goto :check

:flutter_full
echo [BUILD] Flutter full mode (hwcodec+vram, CI environment required)...
python build.py --portable --hwcodec --flutter --vram --skip-portable-pack
goto :check

:release
echo [BUILD] Rust release mode...
cargo build --release
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
