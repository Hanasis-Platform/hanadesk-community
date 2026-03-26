@echo off
chcp 65001 >nul 2>&1
setlocal

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
set VCPKG_ROOT=d:\Projects\vcpkg

:: Add cargo to PATH
set PATH=%USERPROFILE%\.cargo\bin;%PATH%

:: Set libclang path for bindgen
set LIBCLANG_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin

:: Suppress non-critical warnings (dead_code, unused_imports, unused_variables)
set RUSTFLAGS=-A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated

:: Add Flutter to PATH
set PATH=d:\Projects\flutter\bin;%PATH%

:: Select build mode
if "%1"=="flutter" (
    echo [BUILD] Flutter debug mode...
    python build.py --flutter
) else if "%1"=="flutter-release" (
    echo [BUILD] Flutter release mode...
    python build.py --flutter --release
) else if "%1"=="release" (
    echo [BUILD] Release mode...
    cargo build --release
) else (
    echo [BUILD] Debug mode...
    cargo build
)

if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    exit /b %errorlevel%
)

echo [DONE] Build completed successfully.
endlocal
