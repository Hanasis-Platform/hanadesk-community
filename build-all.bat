@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================================
:: HanaDesk Community - Build all 3 editions
::
:: Output:
::   ..\test-client\    - Client (incoming only, asInvoker)
::   ..\test-support\   - Support (outgoing only, asInvoker)
::   ..\test-standard\  - Standard (full mode, asInvoker)
::
:: Note: requireAdministrator manifest is NOT used because it
::   prevents the service (SYSTEM) from launching the Connection
::   Manager (--cm) in user sessions (os error 740).
::   Remote admin tasks are handled via SoftwareSASGeneration=1.
::
:: Build rules:
::   - All .exe and .dll files are code-signed with signtool
::   - Installers are code-signed after packing
::   - Signing uses certificate from Windows Personal store (/s my /a)
::   - Timestamp server: http://timestamp.digicert.com (SHA256)
:: ============================================================

:: Load Visual Studio 2022 developer environment
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else (
    echo [ERROR] Visual Studio 2022 not found.
    exit /b 1
)

set "VCPKG_ROOT=%~dp0..\vcpkg"
set "LOCAL_BUILD=1"
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
set "LIBCLANG_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin"
set "RUSTFLAGS=-C target-feature=+crt-static -A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated"
set "PATH=d:\Projects\flutter\bin;%PATH%"

set "OUTPUT_BASE=%~dp0.."

:: --- Read version from Cargo.toml ---
for /f "tokens=3 delims= " %%V in ('findstr /b "version" Cargo.toml') do (
    set "VERSION=%%~V"
    goto :got_version
)
:got_version
echo ================================================================
echo  HanaDesk Community Build - Version %VERSION%
echo  Building 3 editions (Client, Support, Standard)
echo ================================================================
echo.

set "STEP=0"
set "TOTAL=3"

:: ============================================================
:: 1/3  CLIENT (incoming only)
:: ============================================================
set /a STEP+=1
echo ================================================================
echo [!STEP!/%TOTAL%] CLIENT (incoming only)
echo ================================================================
python build.py --flutter --extra-features client-mode --portable
if !errorlevel! neq 0 ( echo [ERROR] Build failed. & exit /b !errorlevel! )
call :sign_and_copy "test-client" "HanaDeskCommunityClient"

:: ============================================================
:: 2/3  SUPPORT (outgoing only)
:: ============================================================
set /a STEP+=1
echo ================================================================
echo [!STEP!/%TOTAL%] SUPPORT (outgoing only)
echo ================================================================
python build.py --flutter --extra-features support-mode --portable
if !errorlevel! neq 0 ( echo [ERROR] Build failed. & exit /b !errorlevel! )
call :sign_and_copy "test-support" "HanaDeskCommunitySupport"

:: ============================================================
:: 3/3  STANDARD (full mode)
:: ============================================================
set /a STEP+=1
echo ================================================================
echo [!STEP!/%TOTAL%] STANDARD (full mode)
echo ================================================================
python build.py --flutter --portable
if !errorlevel! neq 0 ( echo [ERROR] Build failed. & exit /b !errorlevel! )
call :sign_and_copy "test-standard" "HanaDeskCommunity"

:: ============================================================
echo.
echo ================================================================
echo [DONE] All %TOTAL% editions built and signed successfully.
echo.
echo   %OUTPUT_BASE%\test-client\HanaDeskCommunityClient-%VERSION%-install.exe
echo   %OUTPUT_BASE%\test-support\HanaDeskCommunitySupport-%VERSION%-install.exe
echo   %OUTPUT_BASE%\test-standard\HanaDeskCommunity-%VERSION%-install.exe
echo ================================================================
endlocal
exit /b 0

:: ============================================================
:: Subroutine: sign installer and copy to output directory
:: ============================================================
:sign_and_copy
set "OUT_DIR=%OUTPUT_BASE%\%~1"
set "OUT_NAME=%~2-%VERSION%-install.exe"

echo [SIGN] Signing installer...
signtool sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a "hanadesk-%VERSION%-install.exe"
if !errorlevel! neq 0 (
    echo [WARN] Installer signing failed.
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
copy /y "hanadesk-%VERSION%-install.exe" "%OUT_DIR%\%OUT_NAME%" >nul
echo [OK] %~1\%OUT_NAME%
echo.
exit /b 0
