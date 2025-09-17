@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended for per-user installation. Please run without administrator privileges.
    timeout /t 10 /nobreak
    exit /b 3
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 10 /nobreak
    exit /b 4
)

echo Updating Git using built-in updater...
git update-git-for-windows --yes >nul 2>&1
set UPDATE_RESULT=%errorlevel%

if %UPDATE_RESULT% equ 0 (
    echo No Git update available. You are already running the latest version.
    timeout /t 10 /nobreak
    exit /b 0
) else if %UPDATE_RESULT% equ 2 (
    echo Git update was available and has been installed.
    timeout /t 10 /nobreak
    exit /b 2
) else (
    echo Git update encountered an unexpected error. Error code: %UPDATE_RESULT%
    timeout /t 10 /nobreak
    exit /b %UPDATE_RESULT%
)
