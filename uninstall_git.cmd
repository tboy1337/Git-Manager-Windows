@echo off
setlocal enabledelayedexpansion

set "install_paths_count=0"
set "user_locations_count=0"

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.
)

:: Array of possible Git installation locations
set "locations[0]=%ProgramFiles%\Git"
set "locations[1]=%SystemDrive%\Program Files (x64)\Git"
set "locations[2]=%ProgramFiles(x86)%\Git"
set "locations[3]=%SystemDrive%\Git"
set "locations[4]=%LOCALAPPDATA%\Programs\Git"

:: Get the original user who invoked this script (when running as admin)
for /f "skip=1 tokens=2 delims= " %%u in ('query user ^| findstr "Active"') do (
    if not defined original_user set "original_user=%%u"
)

if defined SUDO_USER set "original_user=%SUDO_USER%"

if defined original_user (
    set "user_locations[!user_locations_count!]=%SystemDrive%\Users\!original_user!\AppData\Local\Programs\Git"
    set /a user_locations_count+=1
)

echo Scanning user directories for Git installations...
for /d %%u in ("%SystemDrive%\Users\*") do (
    if exist "%%u\AppData\Local\Programs\Git\unins*.exe" (
        call :add_unique_path "%%u\AppData\Local\Programs\Git"
    )
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo Checking for Git installations...

for /L %%i in (0,1,4) do (
    call :add_unique_path "!locations[%%i]!"
)

if %user_locations_count% gtr 0 (
    for /L %%i in (0,1,50) do (
        if %%i lss %user_locations_count% (
            call :add_unique_path "!user_locations[%%i]!"
        )
    )
)

if %install_paths_count% equ 0 (
    echo No Git installations found in standard locations.
    echo This might be because Git is installed in a non-standard location.
    echo If you think Git is still installed, try to uninstall it through Control Panel or locate the installation folder and run the uninstaller manually.
    timeout /t 10 /nobreak
    exit /b 2
)

for /L %%i in (0,1,50) do (
    if %%i lss %install_paths_count% (
        call :uninstall_git_from_location "!install_paths[%%i]!"
    )
)

if defined uninstall_error (
    echo One or more Git uninstallations failed.
    timeout /t 10 /nobreak
    exit /b 3
) else if defined cleanup_error (
    echo Git was uninstalled but some cleanup operations failed.
    echo Please check the listed locations and remove remaining files manually.
    timeout /t 10 /nobreak
    exit /b 4
) else (
    echo All Git installations were successfully uninstalled and cleaned up.
    timeout /t 10 /nobreak
    exit /b 0
)

:add_unique_path
set "candidate=%~1"
if not exist "!candidate!\unins*.exe" exit /b 0
for %%I in ("!candidate!") do set "normalized=%%~fI"
for /L %%i in (0,1,50) do (
    if %%i geq !install_paths_count! goto :add_unique_store
    if /i "!install_paths[%%i]!"=="!normalized!" exit /b 0
)
:add_unique_store
set "install_paths[!install_paths_count!]=!normalized!"
set /a install_paths_count+=1
exit /b

:uninstall_git_from_location
set "install_location=%~1"
echo Found Git installation in !install_location!
for %%f in ("!install_location!\unins*.exe") do set "current_uninstaller=%%f"
echo With uninstaller !current_uninstaller!

echo Terminating running Git processes...
taskkill /F /IM "bash.exe" >nul 2>nul
taskkill /F /IM "putty.exe" >nul 2>nul
taskkill /F /IM "puttytel.exe" >nul 2>nul
taskkill /F /IM "puttygen.exe" >nul 2>nul
taskkill /F /IM "pageant.exe" >nul 2>nul

echo Uninstalling Git from !install_location!...
start /wait !current_uninstaller! /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS

if !errorlevel! neq 0 (
    echo Failed to uninstall Git from !install_location!
    set "uninstall_error=1"
) else (
    echo Successfully uninstalled Git from !install_location!

    echo Cleaning up remaining files in !install_location!...
    timeout /t 2 /nobreak >nul 2>nul

    rd /s /q "!install_location!" >nul 2>nul
    if !errorlevel! neq 0 (
        echo Warning: Could not remove remaining files in !install_location!
        set "cleanup_error=1"
    ) else (
        echo Successfully removed remaining files in !install_location!
    )
)
exit /b
