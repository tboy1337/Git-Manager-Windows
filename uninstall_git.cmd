@echo off
setlocal enabledelayedexpansion

:: Array of possible Git installation locations
set "locations[0]=%ProgramFiles%\Git"
set "locations[1]=%SystemDrive%\Program Files (x64)\Git"
set "locations[2]=%ProgramFiles(x86)%\Git"
set "locations[3]=%SystemDrive%\Git"
set "locations[4]=%LOCALAPPDATA%\Programs\Git"

set "found_installations=0"
set "user_locations_count=0"

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.
)

:: Get the original user who invoked this script (when running as admin)
:: This helps find Git installations in user directories
for /f "skip=1 tokens=2 delims= " %%u in ('query user ^| findstr "Active"') do (
    if not defined original_user set "original_user=%%u"
)

:: Also check if SUDO_USER is set (for newer Windows versions with sudo)
if defined SUDO_USER set "original_user=%SUDO_USER%"

:: If we found an original user, add their local app data location
if defined original_user (
    set "user_locations[!user_locations_count!]=%SystemDrive%\Users\!original_user!\AppData\Local\Programs\Git"
    set /a user_locations_count+=1
)

:: Additionally, scan all user directories for Git installations
echo Scanning user directories for Git installations...
for /d %%u in ("%SystemDrive%\Users\*") do (
    if exist "%%u\AppData\Local\Programs\Git\unins*.exe" (
        set "user_locations[!user_locations_count!]=%%u\AppData\Local\Programs\Git"
        set /a user_locations_count+=1
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

:: Check standard system locations
for /L %%i in (0,1,4) do (
    if exist "!locations[%%i]!\unins*.exe" (
        set "uninstaller=!locations[%%i]!\unins*.exe"
        for %%f in ("!uninstaller!") do (
            set "found_uninstaller=%%f"
            set /a found_installations+=1
        )
    )
)

:: Check user-specific locations
if %user_locations_count% gtr 0 (
    for /L %%i in (0,1,50) do (
        if %%i lss %user_locations_count% (
            if exist "!user_locations[%%i]!\unins*.exe" (
                set "uninstaller=!user_locations[%%i]!\unins*.exe"
                for %%f in ("!uninstaller!") do (
                    set "found_uninstaller=%%f"
                    set /a found_installations+=1
                )
            )
        )
    )
)

if %found_installations% equ 0 (
    echo No Git installations found in standard locations.
    echo This might be because Git is installed in a non-standard location.
    echo If you think Git is still installed, try to uninstall it through Control Panel or locate the installation folder and run the uninstaller manually.
    timeout /t 10 /nobreak
    exit /b 2
)

:: Process standard system locations
for /L %%i in (0,1,4) do (
    if exist "!locations[%%i]!\unins*.exe" (
        call :uninstall_git_from_location "!locations[%%i]!"
    )
)

:: Process user-specific locations  
if %user_locations_count% gtr 0 (
    for /L %%i in (0,1,50) do (
        if %%i lss %user_locations_count% (
            if exist "!user_locations[%%i]!\unins*.exe" (
                call :uninstall_git_from_location "!user_locations[%%i]!"
            )
        )
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
goto :eof
