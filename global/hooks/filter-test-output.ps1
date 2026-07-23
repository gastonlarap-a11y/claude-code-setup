# PreToolUse hook (Bash) - native PowerShell port of filter-test-output.sh for Windows
# without Git Bash (there the shell tool runs commands through PowerShell). When the
# command is a known test runner, rewrite it to run through run-test-filtered.ps1 so
# passing-test noise never reaches the model's context.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$cmd = ''
try {
    $d = $raw | ConvertFrom-Json
    if ($d.tool_input -and $d.tool_input.command) { $cmd = [string]$d.tool_input.command }
} catch { }

$runners = @('npm test', 'npm run test', 'pnpm test', 'pnpm run test', 'go test',
             'flutter test', 'npx jest', './gradlew test', '.\gradlew test', 'gradlew test')
$isRunner = $false
foreach ($prefix in $runners) {
    if ($cmd.StartsWith($prefix)) { $isRunner = $true; break }
}

# Skip compound commands (wrapping changes semantics) and commands with embedded double
# quotes (safe single-argument quoting is not guaranteed across shells).
if (-not $isRunner -or $cmd -match '[;&|><"]') {
    Write-Output '{}'
    exit 0
}

$wrapperScript = Join-Path $PSScriptRoot 'run-test-filtered.ps1'
$wrapped = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $wrapperScript + '" -Command "' + $cmd + '"'

$output = @{
    hookSpecificOutput = @{
        hookEventName = 'PreToolUse'
        permissionDecision = 'allow'
        updatedInput = @{ command = $wrapped }
    }
}
Write-Output ($output | ConvertTo-Json -Compress -Depth 5)
