# PreToolUse hook (Bash) - native PowerShell port of guard-shell-edit.sh for Windows
# without Git Bash. Denies shell commands that write to source files inside the repo
# (pathlib.write_text, open(...,'w'), sed -i, tee, redirections into source files) and
# tells the model to use Edit/Write instead. Generated/temp paths pass.
# Fail-open by design.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$cmd = ''
# Dialect: 'claude' covers Claude Code and Codex CLI (identical contract);
# 'antigravity' is agy, which reads .toolCall.args.CommandLine and answers {"decision":...}.
$dialect = 'claude'
try {
    $d = $raw | ConvertFrom-Json
    if ($d.tool_input -and $d.tool_input.command) {
        $cmd = [string]$d.tool_input.command
    } elseif ($d.toolCall -and $d.toolCall.args -and $d.toolCall.args.CommandLine) {
        $cmd = [string]$d.toolCall.args.CommandLine
        $dialect = 'antigravity'
    }
} catch { }

function Write-Allow {
    if ($dialect -eq 'antigravity') { Write-Output '{"decision": "allow"}' } else { Write-Output '{}' }
    exit 0
}

if (-not $cmd) { Write-Allow }

$exts = 'cs|ts|tsx|js|jsx|mjs|cjs|json|md|csproj|props|targets|go|kt|kts|dart|py|rb|java|swift|rs|vue|svelte|css|scss|html'

# 1. Is this a file-writing command? Redirections only count when aimed at a source file,
#    so `cmd > $null` and `2>&1` never match.
$writeSignal = $false
if ($cmd -match "write_text\s*\(|\.writeFileSync|open\s*\([^)]*[`"'][wa]|sed\s+-i|(^|\s)tee\s") {
    $writeSignal = $true
} elseif ($cmd -match ">>?\s*[`"']?[^\s|&;<>]*\.($exts)([`"']|\s|$)") {
    $writeSignal = $true
}
if (-not $writeSignal) { Write-Allow }

# 2. Which source files does it mention? All generated/temp -> legitimate tooling work.
$targets = [regex]::Matches($cmd, "[A-Za-z0-9_.~`$@{}/\\-]+\.($exts)") | ForEach-Object { $_.Value }
if (-not $targets) { Write-Allow }

$exempt = '(^|[/\\])(dist|build|out|bin|obj|target|coverage|node_modules|vendor|\.git|\.next|\.venv|__pycache__|scratchpad)([/\\]|$)|^/tmp/|^/private/tmp/|^/var/folders/|\$TMPDIR|\$\{TMPDIR|\$env:TEMP|[A-Za-z]:\\Users\\[^\\]+\\AppData\\Local\\Temp'

$protected = $null
foreach ($t in $targets) {
    if ($t -match $exempt) { continue }
    $protected = $t
    break
}
if (-not $protected) { Write-Allow }

# The reason doubles as an instruction: the model reads it and retries correctly.
$reason = "Blocked by policy: this command writes to '$protected' through the shell. " +
          "Use Edit (or Write for a brand-new file) instead - they emit a diff rather than " +
          "re-serializing the whole file, and the harness tracks their state. Read files with " +
          "Read and search with Grep/Glob for the same reason. Shell writes are only for " +
          'generated or temporary paths (dist, build, bin, obj, node_modules, $TMPDIR, /tmp).'

if ($dialect -eq 'antigravity') {
    $out = @{ decision = 'deny'; reason = $reason }
} else {
    $out = @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $reason
        }
    }
}
Write-Output ($out | ConvertTo-Json -Compress -Depth 5)
