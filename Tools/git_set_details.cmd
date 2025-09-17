@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Setting global Git user details...

set /p USER_NAME="Enter Git user name: "
if "%USER_NAME%"=="" (
    echo User name cannot be empty.
    timeout /t 5 /nobreak
    exit /b 2
)

git config --global user.name "%USER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set global Git user name.  Error code: %errorlevel%
)

set /p USER_EMAIL="Enter Git user email: "
if "%USER_EMAIL%"=="" (
    echo User email cannot be empty.
    timeout /t 5 /nobreak
    exit /b 3
)

git config --global user.email "%USER_EMAIL%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set global Git user email.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit /b 0
