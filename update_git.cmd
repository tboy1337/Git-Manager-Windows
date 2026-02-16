@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended for per-user installation. Please run without administrator privileges.  Error code: 10
    timeout /t 10 /nobreak
    endlocal
    exit /b 10
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.  Error code: 11
    timeout /t 10 /nobreak
    endlocal
    exit /b 11
)

echo Updating Git using built-in updater...
git update-git-for-windows --yes >nul 2>&1
set UPDATE_RESULT=%errorlevel%

if %UPDATE_RESULT% equ 0 (
    echo No Git update available. You are already running the latest version.
    timeout /t 10 /nobreak
    endlocal
    exit /b %UPDATE_RESULT%
) else if %UPDATE_RESULT% equ 2 (
    echo Git update was available and has been installed.
    timeout /t 10 /nobreak
    endlocal
    exit /b %UPDATE_RESULT%
) else (
    echo Git update encountered an unexpected error.  Error code: %UPDATE_RESULT%
    timeout /t 10 /nobreak
    endlocal
    exit /b %UPDATE_RESULT%
)
