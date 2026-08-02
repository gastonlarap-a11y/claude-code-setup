# PreToolUse hook (Bash, if: git *) - native PowerShell port of guard-git-add-all.sh for
# Windows without Git Bash. Denies bulk staging (`git add -A`, `--all`, `.`, `:/`) which
# can sweep secrets or runtime files into the index unseen; targeted staging and
# `git add -u` pass. Fail-open by design.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$cmd = ''
try {
    $d = $raw | ConvertFrom-Json
    if ($d.tool_input -and $d.tool_input.command) { $cmd = [string]$d.tool_input.command }
} catch { }

if (-not $cmd -or $cmd.IndexOf('git add') -lt 0) { Write-Output '{}'; exit 0 }

function Deny {
    Write-Output '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Blocked by policy: bulk staging (git add -A/--all/./:/) can sweep secrets or runtime files into the commit unseen. Stage the intended paths by name (git add <file> ...); if bulk staging is really intended, the user must run it themselves in a terminal."}}'
    exit 0
}

# Analyze the segment after the last `git add` up to any command separator.
$segment = $cmd.Substring($cmd.LastIndexOf('git add') + 'git add'.Length)
$segment = ($segment -split "`r?`n")[0]      # stop at the end of this line first
$segment = ($segment -split '[;&|]')[0]

foreach ($tok in ($segment -split '\s+')) {
    if ($tok -in '-A', '--all', '.', ':/') { Deny }
}

Write-Output '{}'
