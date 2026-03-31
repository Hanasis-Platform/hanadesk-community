@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: HanaDesk Community - Build CLIENT edition
:: Output: ..\test-client\ - Client (incoming only, asInvoker)

call :setup_env
if !errorlevel! neq 0 exit /b 1

set "OUTPUT_BASE=%~dp0.."
call :get_version

echo ================================================================
echo  Building CLIENT edition - Version %VERSION%
echo ================================================================
echo.

python build.py --flutter --extra-features client-mode --portable
if !errorlevel! neq 0 ( echo [ERROR] Build failed. & exit /b !errorlevel! )
call :sign_and_copy "test-client" "HanaDeskCommunityClient"

echo [DONE] %OUTPUT_BASE%\test-client\HanaDeskCommunityClient-%VERSION%-install.exe
endlocal
exit /b 0

:: ============================================================
:setup_env
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else ( echo [ERROR] Visual Studio 2022 not found. & exit /b 1 )
set "VCPKG_ROOT=%~dp0..\vcpkg"
set "LOCAL_BUILD=1"
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
set "LIBCLANG_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin"
set "RUSTFLAGS=-C target-feature=+crt-static -A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated"
set "PATH=d:\Projects\flutter\bin;%PATH%"
exit /b 0

:get_version
for /f "tokens=3 delims= " %%V in ('findstr /b "version" Cargo.toml') do ( set "VERSION=%%~V" & goto :eof )
goto :eof

:sign_and_copy
signtool sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a "hanadesk-%VERSION%-install.exe"
if not exist "%OUTPUT_BASE%\%~1" mkdir "%OUTPUT_BASE%\%~1"
copy /y "hanadesk-%VERSION%-install.exe" "%OUTPUT_BASE%\%~1\%~2-%VERSION%-install.exe" >nul
echo [OK] %~1\%~2-%VERSION%-install.exe
echo.
exit /b 0
