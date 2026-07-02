@echo off
setlocal enabledelayedexpansion

set "SCAN_DIR=%CD%"
if not defined SCAN_DIR (
    echo Scan directory is not defined.
    timeout /t 5 /nobreak
    exit /b 3
)
if not exist "%SCAN_DIR%\" (
    echo Scan directory does not exist: %SCAN_DIR%
    timeout /t 5 /nobreak
    exit /b 3
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Running git commit and push on all repositories in %SCAN_DIR%...

set /p COMMIT_MSG="Enter commit message: "
if "!COMMIT_MSG!"=="" (
    echo Commit message cannot be empty.
    timeout /t 5 /nobreak
    exit /b 2
)

set "REPO_COUNT=0"
set "SUCCESS_COUNT=0"
set "FAIL_COUNT=0"
set "SKIP_COUNT=0"

for /d %%D in ("%SCAN_DIR%\*") do (
    echo Checking directory: %%~nxD
    if exist "%%D\.git" (
        set /a REPO_COUNT+=1
        echo Found Git repository in %%~nxD, committing and pushing...
        pushd "%%D"
        git add .
        set "CMD_ERR=!errorlevel!"
        if !CMD_ERR! neq 0 (
            set /a FAIL_COUNT+=1
            echo Failed git add in %%~nxD.  Error code: !CMD_ERR!
            popd
            echo.
        ) else (
            git diff --cached --quiet
            set "CMD_ERR=!errorlevel!"
            if !CMD_ERR! equ 0 (
                set /a SKIP_COUNT+=1
                echo No changes to commit in %%~nxD, skipping...
                popd
                echo.
            ) else (
                git commit -m "!COMMIT_MSG!"
                set "CMD_ERR=!errorlevel!"
                if !CMD_ERR! neq 0 (
                    set /a FAIL_COUNT+=1
                    echo Failed git commit in %%~nxD.  Error code: !CMD_ERR!
                    popd
                    echo.
                ) else (
                    git push
                    set "CMD_ERR=!errorlevel!"
                    if !CMD_ERR! equ 0 (
                        set /a SUCCESS_COUNT+=1
                        echo Finished %%~nxD
                    ) else (
                        set /a FAIL_COUNT+=1
                        echo Failed git push in %%~nxD.  Error code: !CMD_ERR!
                    )
                    popd
                    echo.
                )
            )
        )
    ) else (
        echo No Git repository found in %%~nxD, skipping...
        echo.
    )
)

echo Summary: %REPO_COUNT% repositories processed, %SUCCESS_COUNT% succeeded, %SKIP_COUNT% skipped, %FAIL_COUNT% failed.

timeout /t 5 /nobreak
if %FAIL_COUNT% gtr 0 (
    endlocal
    exit /b 1
)
endlocal
exit /b 0
