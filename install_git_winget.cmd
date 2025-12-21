@echo off
setlocal enabledelayedexpansion

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended for per-user installation. Please run without administrator privileges.
    timeout /t 10 /nobreak
    exit /b 1
)

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo winget is not available on this system. Please install App Installer from Microsoft Store.
    timeout /t 10 /nobreak
    exit /b 2
)

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo Git is already installed and in PATH.
    timeout /t 10 /nobreak
    exit /b 3
)

echo Installing Git using winget...
winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to install Git via winget.
    timeout /t 10 /nobreak
    exit /b 4
)

echo Git installation completed successfully.

call :refresh_env

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Unable to configure Git settings.
    echo Git was installed but is not yet available in PATH. You may need to restart your command prompt.
    echo Manual configuration will be required.
    timeout /t 10 /nobreak
    exit /b 5
)

echo Configuring Git settings...

:: Core settings
git config --global init.defaultBranch main >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set init.defaultBranch.  Error code: %errorlevel%
)

git config --global core.eol crlf >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.eol.  Error code: %errorlevel%
)

git config --global core.autocrlf true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.autocrlf.  Error code: %errorlevel%
)

git config --global core.editor "vim" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.editor.  Error code: %errorlevel%
)

:: Credential manager
git config --global credential.helper manager >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set credential.helper.  Error code: %errorlevel%
)

:: Performance tweaks
git config --global core.preloadindex true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.preloadindex.  Error code: %errorlevel%
)

git config --global core.fscache true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.fscache.  Error code: %errorlevel%
)

:: Push behavior
git config --global pull.rebase false >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set pull.rebase.  Error code: %errorlevel%
)

:: Enable long paths on Windows
git config --global core.longpaths true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.longpaths.  Error code: %errorlevel%
)

echo Git configuration finished.

timeout /t 10 /nobreak
exit /b 0

:refresh_env
:: Refresh environment variables by reading from registry
:: This gets both system and user PATH variables that winget modifies

:: Read system PATH from registry
set "SystemPath="
for /f "usebackq skip=2 tokens=1,2*" %%A in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul`) do (
    if /i "%%A"=="PATH" set "SystemPath=%%C"
)

:: Read user PATH from registry
set "UserPath="
for /f "usebackq skip=2 tokens=1,2*" %%A in (`reg query "HKCU\Environment" /v PATH 2^>nul`) do (
    if /i "%%A"=="PATH" set "UserPath=%%C"
)

:: Combine system and user PATH
if defined SystemPath (
    set "PATH=!SystemPath!"
) else (
    set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

if defined UserPath (
    set "PATH=!PATH!;!UserPath!"
)

:: Ensure critical system directories are present (fallback)
if not defined PATH (
    set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

exit /b
