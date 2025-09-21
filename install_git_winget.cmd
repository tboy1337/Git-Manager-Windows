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
:: Refresh environment variables without requiring a restart
:: Instead of completely replacing PATH, ensure critical directories are present
if not defined PATH set "PATH="

:: Ensure system32 is in PATH (needed for timeout and other system commands)
set "PathUpper=!PATH!"
call :to_upper PathUpper
if "!PathUpper!" == "!PathUpper:SYSTEM32=!" (
    set "PATH=!PATH!;%SystemRoot%\system32"
)

:: Ensure basic Windows directories are in PATH
set "SystemRootUpper=%SystemRoot%"
call :to_upper SystemRootUpper
if "!PathUpper!" == "!PathUpper:%SystemRootUpper%=!" (
    set "PATH=!PATH!;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

:: Read user PATH from registry and append if not already present
set "UserPath="
for /f "tokens=2,*" %%A in ('reg query HKCU\Environment /v PATH 2^>nul') do set "UserPath=%%B"
if defined UserPath (
    set "UserPathUpper=!UserPath!"
    call :to_upper UserPathUpper
    if "!PathUpper!" == "!PathUpper:%UserPathUpper%=!" set "PATH=!PATH!;!UserPath!"
)
exit /b

:to_upper
:: Convert string to uppercase for case-insensitive comparison
set "str=!%1!"
set "str=!str:a=A!"
set "str=!str:b=B!"
set "str=!str:c=C!"
set "str=!str:d=D!"
set "str=!str:e=E!"
set "str=!str:f=F!"
set "str=!str:g=G!"
set "str=!str:h=H!"
set "str=!str:i=I!"
set "str=!str:j=J!"
set "str=!str:k=K!"
set "str=!str:l=L!"
set "str=!str:m=M!"
set "str=!str:n=N!"
set "str=!str:o=O!"
set "str=!str:p=P!"
set "str=!str:q=Q!"
set "str=!str:r=R!"
set "str=!str:s=S!"
set "str=!str:t=T!"
set "str=!str:u=U!"
set "str=!str:v=V!"
set "str=!str:w=W!"
set "str=!str:x=X!"
set "str=!str:y=Y!"
set "str=!str:z=Z!"
set "%1=!str!"
exit /b
