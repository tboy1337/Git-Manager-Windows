@echo off
setlocal enabledelayedexpansion

:: Set variables for easy updating
set "GIT_VERSION=2.51.0"
set "INSTALLER_NAME=Git-%GIT_VERSION%-64-bit.exe"
set "DOWNLOAD_URL=https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/%INSTALLER_NAME%"

set "TEMP_DIR=%TEMP%\GitInstall_%RANDOM%_%RANDOM%"
set "DOWNLOAD_TASK=DownloadTask_%RANDOM%_%RANDOM%"
set "SCHTASK_NAME=GitMgrDownload_%RANDOM%_%RANDOM%"
set "WAIT_COUNT=0"
set "WAIT_MAX=90"

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended for per-user installation. Please run without administrator privileges.
    timeout /t 10 /nobreak
    endlocal
    exit /b 1
)

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo Git is already installed and in PATH.
    timeout /t 10 /nobreak
    endlocal
    exit /b 2
)

mkdir "%TEMP_DIR%" >nul 2>nul
if %errorlevel% neq 0 (
    echo Failed to create temporary Git install directory.
    timeout /t 10 /nobreak
    endlocal
    exit /b 3
)

cd /d "%TEMP_DIR%" >nul 2>nul
if %errorlevel% neq 0 (
    echo Failed to change to temporary Git install directory.
    timeout /t 10 /nobreak
    endlocal
    exit /b 4
)

where curl >nul 2>nul
if %errorlevel% equ 0 (
    echo Attempting to download %INSTALLER_NAME% with curl...
    curl -o "%INSTALLER_NAME%" -L "%DOWNLOAD_URL%" >nul 2>nul
    if %errorlevel% equ 0 goto :verify_download
    echo Curl download failed, trying PowerShell...
)

where powershell >nul 2>nul
if %errorlevel% equ 0 (
    echo Attempting to download %INSTALLER_NAME% with PowerShell...
    start /wait powershell -WindowStyle Hidden -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -OutFile '%INSTALLER_NAME%' -Uri '%DOWNLOAD_URL%'"
    if %errorlevel% equ 0 goto :verify_download
    echo PowerShell download failed, trying bitsadmin...
)

echo Attempting to download %INSTALLER_NAME% with bitsadmin...
(
echo bitsadmin /transfer %DOWNLOAD_TASK% /download /priority FOREGROUND /DYNAMIC "%DOWNLOAD_URL%" "%TEMP_DIR%\%INSTALLER_NAME%"
) > "set_task.cmd" 2>nul

if %errorlevel% neq 0 (
    echo Failed to write to temporary directory.
    goto :giterror
)

start /wait schtasks /create /tn "%SCHTASK_NAME%" /tr "cmd /c %TEMP_DIR%\set_task.cmd" /sc once /st 23:59 /ru SYSTEM >nul 2>nul
if %errorlevel% neq 0 (
    echo All download methods failed.
    goto :giterror
)

start /wait schtasks /run /tn "%SCHTASK_NAME%" >nul 2>nul
if %errorlevel% neq 0 (
    echo All download methods failed.
    call :delete_schtask
    goto :giterror
)

:waitloop
if exist "%TEMP_DIR%\%INSTALLER_NAME%" goto :waitloop_done
set /a WAIT_COUNT+=1
if !WAIT_COUNT! geq %WAIT_MAX% (
    echo Download timed out after 3 minutes.
    call :delete_schtask
    goto :giterror
)
timeout /t 2 /nobreak >nul 2>nul
goto :waitloop

:waitloop_done
timeout /t 2 /nobreak >nul 2>nul
call :delete_schtask

:verify_download
if not exist "%TEMP_DIR%\%INSTALLER_NAME%" (
    echo Download appears to have failed - installer not found.
    goto :giterror
)

echo Creating temporary git_options.ini file...
(
echo [Setup]
echo Lang=default
echo Dir=%LOCALAPPDATA%\Programs\Git
echo Group=Git
echo NoIcons=0
echo SetupType=default
echo Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh
echo Tasks=
echo EditorOption=VIM
echo CustomEditorPath=
echo DefaultBranchOption=main
echo PathOption=Cmd
echo SSHOption=OpenSSH
echo TortoiseOption=false
echo CURLOption=OpenSSL
echo CRLFOption=CRLFAlways
echo BashTerminalOption=ConHost
echo GitPullBehaviorOption=Merge
echo UseCredentialManager=Enabled
echo PerformanceTweaksFSCache=Enabled
echo EnableSymlinks=Disabled
echo EnableFSMonitor=Disabled
) > "git_options.ini" 2>nul

if %errorlevel% neq 0 (
    echo Failed to create temporary git_options.ini file.
    goto :giterror
)

echo Installing %INSTALLER_NAME%...
start /wait %INSTALLER_NAME% /VERYSILENT /NORESTART /NOCANCEL /LOADINF="git_options.ini"
if %errorlevel% neq 0 (
    echo Failed to install Git.
    goto :giterror
)

echo Git installation completed successfully.
call :gitcleanup

call :refresh_env

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Unable to configure Git settings.
    echo Git was installed but is not yet available in PATH. You may need to restart your command prompt.
    echo Manual configuration will be required.
    timeout /t 10 /nobreak
    endlocal
    exit /b 5
)

call :configure_git

timeout /t 10 /nobreak
endlocal
exit /b 0

:giterror
echo An error occurred during the Git installation process.
call :gitcleanup
endlocal
exit /b 5

:refresh_env
set "SystemPath="
for /f "usebackq skip=2 tokens=1,2*" %%A in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul`) do (
    if /i "%%A"=="PATH" set "SystemPath=%%C"
)

set "UserPath="
for /f "usebackq skip=2 tokens=1,2*" %%A in (`reg query "HKCU\Environment" /v PATH 2^>nul`) do (
    if /i "%%A"=="PATH" set "UserPath=%%C"
)

if defined SystemPath (
    set "PATH=!SystemPath!"
) else (
    set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

if defined UserPath (
    set "PATH=!PATH!;!UserPath!"
)

if not defined PATH (
    set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

call set "PATH=%PATH%"

if exist "%LOCALAPPDATA%\Programs\Git\cmd" (
    echo !PATH! | find /I "%LOCALAPPDATA%\Programs\Git\cmd" >nul 2>&1
    if errorlevel 1 set "PATH=!PATH!;%LOCALAPPDATA%\Programs\Git\cmd"
)
exit /b

:configure_git
echo Configuring Git settings...

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

git config --global credential.helper manager >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set credential.helper.  Error code: %errorlevel%
)

git config --global core.preloadindex true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.preloadindex.  Error code: %errorlevel%
)

git config --global core.fscache true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.fscache.  Error code: %errorlevel%
)

git config --global pull.rebase false >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set pull.rebase.  Error code: %errorlevel%
)

git config --global core.longpaths true >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set core.longpaths.  Error code: %errorlevel%
)

echo Git configuration finished.
exit /b

:delete_schtask
start /wait schtasks /delete /tn "%SCHTASK_NAME%" /f >nul 2>nul
if %errorlevel% neq 0 (
    echo Failed to delete scheduled task, please delete "%SCHTASK_NAME%" manually.
)
exit /b

:gitcleanup
echo Cleaning up...
timeout /t 2 /nobreak >nul 2>nul
cd /d "%TEMP%" >nul 2>nul
if %errorlevel% neq 0 (
    echo Failed to change to temporary directory for Git install cleanup.
)
rd /s /q "%TEMP_DIR%" >nul 2>nul
if %errorlevel% neq 0 (
    echo Failed to remove temporary Git install directory. Please delete "%TEMP_DIR%" manually.
) else (
    echo Clean up successful.
)
exit /b
