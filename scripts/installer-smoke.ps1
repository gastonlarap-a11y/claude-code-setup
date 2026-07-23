# Smoke matrix for install.ps1 - the SAME runs execute locally (any Windows box) and in CI
# under Windows PowerShell 5.1 (installer-smoke.yml, shell: powershell), which is the engine
# whose encoding behavior the installer must survive. Isolation: CLAUDE_HOME redirects the
# file copies; the `claude` CLI is expected to be absent (that block degrades with a warning).
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$T = Join-Path ([IO.Path]::GetTempPath()) ('claude-smoke-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $T | Out-Null

function Fail([string]$Message) {
    Write-Host "SMOKE FAIL: $Message"
    exit 1
}
function Assert-NoBom([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Fail "BOM found in $Path"
    }
}

$Installer = Join-Path $RepoRoot 'install.ps1'
$env:CLAUDE_HOME = Join-Path $T 'home'
Remove-Item Env:CLAUDE_LANGUAGE -ErrorAction SilentlyContinue

Write-Host '== run 1: fresh install (no backup expected, manifest written) =='
& $Installer
if (-not (Test-Path (Join-Path $env:CLAUDE_HOME '.install-manifest'))) { Fail 'manifest not created' }
if (Get-ChildItem -Path $env:CLAUDE_HOME -Directory -Filter '.backup-*' -Force -ErrorAction SilentlyContinue) {
    Fail 'backup created on a fresh install'
}

Write-Host '== run 2: CLAUDE_LANGUAGE=english (backup + rewrite, no BOM, 5.1-parseable) =='
$env:CLAUDE_LANGUAGE = 'english'
& $Installer
$SettingsPath = Join-Path $env:CLAUDE_HOME 'settings.json'
$MdPath = Join-Path $env:CLAUDE_HOME 'CLAUDE.md'
if (-not (Get-ChildItem -Path $env:CLAUDE_HOME -Directory -Filter '.backup-*' -Force)) { Fail 'no backup on overwrite run' }
Assert-NoBom $SettingsPath
Assert-NoBom $MdPath
$json = [IO.File]::ReadAllText($SettingsPath) | ConvertFrom-Json
if ($json.language -ne 'english') { Fail 'settings.json language not set' }
if (-not ([IO.File]::ReadAllText($MdPath).Contains('Always answer **in English**'))) { Fail 'CLAUDE.md not rewritten' }
if (-not ((Get-Content (Join-Path $env:CLAUDE_HOME '.install-profile') -Raw).Contains('CLAUDE_LANGUAGE=english'))) {
    Fail 'language not persisted'
}

Write-Host '== run 3: no variable - persisted language must hold =='
Remove-Item Env:CLAUDE_LANGUAGE
& $Installer
$json = [IO.File]::ReadAllText($SettingsPath) | ConvertFrom-Json
if ($json.language -ne 'english') { Fail 'persisted language lost on re-run' }

Write-Host '== run 4: orphan (manifest-listed) pruned, user file (unlisted) survives =='
Add-Content (Join-Path $env:CLAUDE_HOME '.install-manifest') 'skills/obsolete/SKILL.md'
New-Item -ItemType Directory -Force -Path (Join-Path $env:CLAUDE_HOME 'skills\obsolete') | Out-Null
Set-Content (Join-Path $env:CLAUDE_HOME 'skills\obsolete\SKILL.md') 'x'
Set-Content (Join-Path $env:CLAUDE_HOME 'skills\my-own-note.md') 'keep'
& $Installer
if (Test-Path (Join-Path $env:CLAUDE_HOME 'skills\obsolete\SKILL.md')) { Fail 'orphan not pruned' }
if (-not (Test-Path (Join-Path $env:CLAUDE_HOME 'skills\my-own-note.md'))) { Fail 'user file was deleted' }

Write-Host '== run 5: backups capped at 3, edited JSON still valid =='
& $Installer
$backups = @(Get-ChildItem -Path $env:CLAUDE_HOME -Directory -Filter '.backup-*' -Force)
if ($backups.Count -gt 3) { Fail "more than 3 backups kept ($($backups.Count))" }
if ($backups.Count -lt 1) { Fail 'expected at least one backup' }
[IO.File]::ReadAllText($SettingsPath) | ConvertFrom-Json | Out-Null

Write-Host '== run 6: -DryRun previews and writes nothing =='
$ManifestFile = Join-Path $env:CLAUDE_HOME '.install-manifest'
$BeforeSettings = [IO.File]::ReadAllText($SettingsPath)
$BeforeManifest = [IO.File]::ReadAllText($ManifestFile)
$BeforeBackups = @(Get-ChildItem -Path $env:CLAUDE_HOME -Directory -Filter '.backup-*' -Force).Count
# Write-Host output lives in the information stream: merge it (6>&1) to capture the banner.
$DryLog = & $Installer -DryRun 6>&1 | Out-String
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Fail '-DryRun exited non-zero' }
if (-not $DryLog.Contains('DRY-RUN')) { Fail '-DryRun banner missing' }
if ($BeforeSettings -ne [IO.File]::ReadAllText($SettingsPath)) { Fail '-DryRun modified settings.json' }
if ($BeforeManifest -ne [IO.File]::ReadAllText($ManifestFile)) { Fail '-DryRun modified the manifest' }
if (@(Get-ChildItem -Path $env:CLAUDE_HOME -Directory -Filter '.backup-*' -Force).Count -ne $BeforeBackups) {
    Fail '-DryRun created a backup'
}

Write-Host '== run 7: FAILURE PATH - anchor mutated in the SOURCE kit =='
# The real-world failure vector is a reworded source file (a mutated installed copy is
# simply overwritten by the next run), so the guard is exercised on a temp kit copy.
$Kit = Join-Path $T 'kit'
New-Item -ItemType Directory -Force -Path $Kit | Out-Null
Copy-Item $Installer $Kit
Copy-Item (Join-Path $RepoRoot 'global') (Join-Path $Kit 'global') -Recurse
Copy-Item (Join-Path $RepoRoot 'scripts') (Join-Path $Kit 'scripts') -Recurse
$KitMd = Join-Path $Kit 'global\CLAUDE.md'
[IO.File]::WriteAllText($KitMd, [IO.File]::ReadAllText($KitMd).Replace('Always answer', 'ALWAYS answer'))
$env:CLAUDE_HOME = Join-Path $T 'home2'
$env:CLAUDE_LANGUAGE = 'english'
$WarningLog = Join-Path $T 'run6-warnings.txt'
& (Join-Path $Kit 'install.ps1') 3> $WarningLog
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Fail 'installer exited non-zero on a missing anchor' }
$warnings = Get-Content $WarningLog -Raw -ErrorAction SilentlyContinue
if (-not ($warnings -match 'language anchor not found in CLAUDE.md')) { Fail 'missing-anchor warning not emitted' }
$Home2Md = [IO.File]::ReadAllText((Join-Path $env:CLAUDE_HOME 'CLAUDE.md'))
# 'in English' alone would false-positive: the source file legitimately contains it
# ("Research and doc lookups: always in English"); match the rewritten anchor context.
if ($Home2Md.Contains('answer **in English**')) { Fail 'partial rewrite happened despite missing anchor' }
if (-not $Home2Md.Contains('ALWAYS answer')) { Fail 'installed copy does not match the mutated source' }
$json2 = [IO.File]::ReadAllText((Join-Path $env:CLAUDE_HOME 'settings.json')) | ConvertFrom-Json
if ($json2.language -ne 'english') { Fail 'settings.json skipped (its own anchor was intact)' }

Remove-Item -Recurse -Force $T
Write-Host 'SMOKE OK: all 7 runs passed (PowerShell)'
