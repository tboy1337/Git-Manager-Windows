BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:ToolsDir = Join-Path $RepoRoot 'Tools'
    $script:BulkScripts = @(
        'git_gc_all.cmd',
        'git_pull_all.cmd',
        'git_push_all.cmd'
    )
}

Describe 'Bulk tool script structure' {
    $bulkScriptCases = @(
        @{ BulkScript = 'git_gc_all.cmd' },
        @{ BulkScript = 'git_pull_all.cmd' },
        @{ BulkScript = 'git_push_all.cmd' }
    )

    It 'Uses SCAN_DIR from current directory instead of SystemDrive root' -TestCases $bulkScriptCases {
        param($BulkScript)
        $content = Get-Content -Path (Join-Path $ToolsDir $BulkScript) -Raw
        $content | Should -Match 'set "SCAN_DIR=%CD%"'
        $content | Should -Match 'for /d %%D in \("%SCAN_DIR%\\\*"\)'
        $content | Should -Not -Match 'cd /d "%SystemDrive%"'
    }

    It 'Tracks per-repository failures and prints a summary' -TestCases $bulkScriptCases {
        param($BulkScript)
        $content = Get-Content -Path (Join-Path $ToolsDir $BulkScript) -Raw
        $content | Should -Match 'FAIL_COUNT'
        $content | Should -Match 'Summary:'
    }

    It 'Exits with code 1 when any repository operation fails' -TestCases $bulkScriptCases {
        param($BulkScript)
        $content = Get-Content -Path (Join-Path $ToolsDir $BulkScript) -Raw
        $content | Should -Match 'if %FAIL_COUNT% gtr 0'
        $content | Should -Match 'exit /b 1'
    }
}

Describe 'git_push_all.cmd commit handling' {
    It 'Skips empty commits after staging changes' {
        $content = Get-Content -Path (Join-Path $ToolsDir 'git_push_all.cmd') -Raw
        $content | Should -Match 'git diff --cached --quiet'
        $content | Should -Match 'SKIP_COUNT'
    }
}

Describe 'install_git.cmd reliability' {
    It 'Uses a unique scheduled task name' {
        $content = Get-Content -Path (Join-Path $RepoRoot 'install_git.cmd') -Raw
        $content | Should -Match 'SCHTASK_NAME=GitMgrDownload_'
        $content | Should -Not -Match 'RunAsSystemTask'
    }

    It 'Limits the bitsadmin download wait loop' {
        $content = Get-Content -Path (Join-Path $RepoRoot 'install_git.cmd') -Raw
        $content | Should -Match 'WAIT_MAX=90'
        $content | Should -Match 'Download timed out'
    }

    It 'Applies post-install configuration inline' {
        $content = Get-Content -Path (Join-Path $RepoRoot 'install_git.cmd') -Raw
        $content | Should -Match 'call :refresh_env'
        $content | Should -Match 'call :configure_git'
        $content | Should -Match ':refresh_env'
        $content | Should -Match ':configure_git'
        $content | Should -Not -Match 'Tools\\_refresh_env\.cmd'
        $content | Should -Not -Match 'Tools\\_configure_git\.cmd'
    }
}

Describe 'Install script self-containment' {
    It 'Keeps refresh and configure logic inline in install_git_winget.cmd' {
        $content = Get-Content -Path (Join-Path $RepoRoot 'install_git_winget.cmd') -Raw
        $content | Should -Match 'call :refresh_env'
        $content | Should -Match 'call :configure_git'
        $content | Should -Match ':refresh_env'
        $content | Should -Match ':configure_git'
        $content | Should -Not -Match 'Tools\\_refresh_env\.cmd'
        $content | Should -Not -Match 'Tools\\_configure_git\.cmd'
    }

    It 'Does not use separate helper scripts in Tools' {
        Test-Path (Join-Path $ToolsDir '_refresh_env.cmd') | Should -BeFalse
        Test-Path (Join-Path $ToolsDir '_configure_git.cmd') | Should -BeFalse
    }
}

Describe 'Config script error handling' {
    It 'Exits non-zero when git config fails' -TestCases @(
        @{ Script = 'git_set_details.cmd'; ExitCode = 'exit /b 4' },
        @{ Script = 'git_set_crlf.cmd'; ExitCode = 'exit /b 2' },
        @{ Script = 'git_set_lf.cmd'; ExitCode = 'exit /b 2' }
    ) {
        param($Script, $ExitCode)
        $content = Get-Content -Path (Join-Path $ToolsDir $Script) -Raw
        $content | Should -Match 'CONFIG_ERROR'
        $content | Should -Match $ExitCode
        $content | Should -Not -Match 'cd /d "%SystemDrive%"'
    }
}

Describe 'uninstall_git.cmd deduplication' {
    It 'Collects unique installation paths before uninstalling' {
        $content = Get-Content -Path (Join-Path $RepoRoot 'uninstall_git.cmd') -Raw
        $content | Should -Match ':add_unique_path'
        $content | Should -Match 'install_paths_count'
        $content | Should -Match 'if /i "!install_paths\[%%i\]!"=="!normalized!"'
    }
}

Describe 'README consistency' {
    It 'References script paths that exist on disk' {
        $readme = Get-Content -Path (Join-Path $RepoRoot 'README.md') -Raw
        $expectedPaths = @(
            'install_git_winget.cmd',
            'install_git.cmd',
            'update_git.cmd',
            'uninstall_git.cmd',
            'Tools\git_pull_all.cmd',
            'Tools\git_push_all.cmd',
            'Tools\git_gc_all.cmd',
            'Tools\git_set_details.cmd',
            'Tools\git_set_crlf.cmd',
            'Tools\git_set_lf.cmd'
        )

        foreach ($relativePath in $expectedPaths) {
            $fullPath = Join-Path $RepoRoot $relativePath
            Test-Path $fullPath | Should -BeTrue -Because "README references $relativePath"
        }

        $readme | Should -Not -Match 'Tools\\set_git_'
        $readme | Should -Match 'v2\.51\.0'
        $readme | Should -Match 'License-CRL'
    }
}

Describe 'Bulk tool directory scanning behavior' {
    BeforeAll {
        $script:SmokeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("GitMgrSmoke_" + [guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $SmokeRoot | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $SmokeRoot 'repo-one\.git') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $SmokeRoot 'repo-two\.git') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $SmokeRoot 'not-a-repo') -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $SmokeRoot) {
            Remove-Item -Path $SmokeRoot -Recurse -Force
        }
    }

    It 'Scans only immediate child repositories in the caller directory' {
        $gcScript = Join-Path $ToolsDir 'git_gc_all.cmd'
        $outputFile = Join-Path $SmokeRoot 'gc-output.txt'

        $process = Start-Process -FilePath 'cmd.exe' `
            -ArgumentList @('/c', "cd /d `"$SmokeRoot`" && `"$gcScript`" > `"$outputFile`" 2>&1") `
            -Wait -PassThru -NoNewWindow

        $output = Get-Content -Path $outputFile -Raw
        $output | Should -Match 'repo-one'
        $output | Should -Match 'repo-two'
        $output | Should -Match "all repositories in $([regex]::Escape($SmokeRoot))"
        $output | Should -Not -Match 'Checking directory: Users'
        $output | Should -Not -Match 'Checking directory: Program Files'
    }
}
