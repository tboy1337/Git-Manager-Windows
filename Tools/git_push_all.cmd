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

echo Running git commit and push on all repositories...

set /p COMMIT_MSG="Enter commit message: "
if "%COMMIT_MSG%"=="" (
    echo Commit message cannot be empty.
    timeout /t 5 /nobreak
    exit /b 2
)

for /d %%D in (*) do (
    echo Checking directory: %%D
    if exist "%%D\.git" (
        echo Found Git repository in %%D, committing and pushing...
        pushd "%%D"
        git add .
        git commit -m "%COMMIT_MSG%"
        git push
        popd
        echo Finished %%D
        echo.
    ) else (
        echo No Git repository found in %%D, skipping...
        echo.
    )
)

timeout /t 5 /nobreak
endlocal
exit /b 0
