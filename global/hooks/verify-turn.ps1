# Stop hook - native PowerShell port of verify-turn.sh for Windows without Git Bash.
# Runs the project's cheap checks when the turn is about to close and refuses to let it end
# if one fails, handing the failure back to the model while the context is still alive.
# Commands come as arguments, declared per repo in its .claude/settings.json.
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

foreach ($cmd in $Commands) {
    if (-not $cmd) { continue }
    $out = & cmd /c "$cmd" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        # Hand back the tail: enough to act on, not the whole build log.
        $tail = ($out -split "`r?`n" | Select-Object -Last 40) -join "`n"
        $reason = "Turn blocked: ``$cmd`` failed. Fix it before finishing - the work is not done while this is red.`n`n$tail"
        Write-Output (@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress -Depth 5)
        exit 0
    }
}

Pop-Location
Write-Output '{}'
