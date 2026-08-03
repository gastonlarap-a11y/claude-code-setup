# Stop hook - native PowerShell port of verify-turn.sh for Windows without Git Bash.
# Runs the project's cheap checks when the turn is about to close and refuses to let it end
# if one fails, handing the failure back to the model while the context is still alive.
# Commands come as arguments, declared per repo in its .claude/settings.json.
#
# A command can be scoped to the area it verifies with `<globs>::<command>`:
#   'renderer/**::pnpm -C renderer typecheck'   'src/**,*.slnx::dotnet build'
# Comma-separates several globs; they are matched against `git status --porcelain`, i.e.
# relative to the REPO ROOT, and `*` crosses `/` (-like semantics). An argument with no `::`
# - or whose prefix contains whitespace, so `--filter A::B` keeps working - always runs.
# A clean working tree skips the scoped commands; when git cannot answer, everything runs.
# Fail-open by design.
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Commands)

$ErrorActionPreference = 'SilentlyContinue'

if (-not $Commands -or $Commands.Count -eq 0) { Write-Output '{}'; exit 0 }

$raw = [Console]::In.ReadToEnd()
$active = $false
$cwd = ''
try {
    $d = $raw | ConvertFrom-Json
    if ($d.stop_hook_active) { $active = [bool]$d.stop_hook_active }
    if ($d.cwd) { $cwd = [string]$d.cwd }
} catch { }

# Without this guard a failing check re-runs the turn forever.
if ($active) { Write-Output '{}'; exit 0 }

$dir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $cwd }
if (-not $dir -or -not (Test-Path $dir)) { Write-Output '{}'; exit 0 }
Push-Location $dir

# Split every argument into its optional scope and its command.
$specs = @()
$needScope = $false
foreach ($arg in $Commands) {
    if (-not $arg) { continue }
    $globs = ''
    $cmd = $arg
    $idx = $arg.IndexOf('::')
    if ($idx -gt 0) {
        $prefix = $arg.Substring(0, $idx)
        if ($prefix -notmatch '\s') {
            $globs = $prefix
            $cmd = $arg.Substring($idx + 2)
        }
    }
    if (-not $cmd) { continue }
    $specs += [pscustomobject]@{ Globs = $globs; Command = $cmd }
    if ($globs) { $needScope = $true }
}

if ($specs.Count -eq 0) { Pop-Location; Write-Output '{}'; exit 0 }

# The Stop payload carries no file list, so the turn's footprint is read off the working tree.
$changed = @()
$scopeKnown = $false
if ($needScope) {
    & git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $joined = (& git status --porcelain -z 2>$null) -join ''
        $skipNext = $false
        foreach ($record in ($joined -split "`0")) {
            if ($skipNext) { $skipNext = $false; continue }
            if ($record.Length -lt 4) { continue }
            # Porcelain v1: "XY path"; a rename/copy emits the original path as a second record.
            $state = $record.Substring(0, 2)
            if ('R', 'C' -contains $state[0] -or 'R', 'C' -contains $state[1]) { $skipNext = $true }
            $changed += $record.Substring(3)
        }
        $scopeKnown = $true
    }
}

function Test-ScopeHit {
    param([string]$Globs, [string[]]$Files)
    if ($Files.Count -eq 0) { return $false }
    foreach ($pattern in $Globs.Split(',')) {
        if (-not $pattern) { continue }
        foreach ($file in $Files) {
            if ($file -like $pattern) { return $true }
        }
    }
    return $false
}

foreach ($spec in $specs) {
    if ($spec.Globs -and $scopeKnown -and -not (Test-ScopeHit -Globs $spec.Globs -Files $changed)) {
        continue
    }
    $out = & cmd /c "$($spec.Command)" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        # Hand back the tail: enough to act on, not the whole build log.
        $tail = ($out -split "`r?`n" | Select-Object -Last 40) -join "`n"
        $reason = "Turn blocked: ``$($spec.Command)`` failed. Fix it before finishing - the work is not done while this is red.`n`n$tail"
        Write-Output (@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress -Depth 5)
        exit 0
    }
}

Pop-Location
Write-Output '{}'
