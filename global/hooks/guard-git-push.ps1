# PreToolUse hook (Bash, if: git *) - native PowerShell port of guard-git-push.sh for
# Windows without Git Bash. Denies `git push` when the target branch is main/master -
# either named in the command or implied by the checked-out branch. Fail-open by design:
# if anything cannot be parsed, the command proceeds and the prose rule + permission
# deny list (force push) still apply.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$cmd = ''
$cwd = ''
try {
    $d = $raw | ConvertFrom-Json
    if ($d.tool_input -and $d.tool_input.command) { $cmd = [string]$d.tool_input.command }
    if ($d.cwd) { $cwd = [string]$d.cwd }
} catch { }

if (-not $cmd -or $cmd.IndexOf('git push') -lt 0) { Write-Output '{}'; exit 0 }

function Deny {
    Write-Output '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Blocked by policy (global CLAUDE.md): never push directly to main/master. Push from a feature branch; if this push is really intended, the user must run it themselves in a terminal."}}'
    exit 0
}

# Analyze the segment after the last `git push` up to any command separator.
$segment = $cmd.Substring($cmd.LastIndexOf('git push') + 'git push'.Length)
$segment = ($segment -split '[;&|]')[0]

# Tokens that are not flags: first is the remote, the rest are refspecs.
$refspecs = @()
$seenRemote = $false
foreach ($tok in ($segment -split '\s+')) {
    if (-not $tok) { continue }
    if ($tok.StartsWith('-')) { continue }
    if (-not $seenRemote) { $seenRemote = $true } else { $refspecs += $tok }
}

# Explicit refspec targeting main/master (src, dst of src:dst, or deletion :dst).
foreach ($ref in $refspecs) {
    $dst = $ref.Substring($ref.LastIndexOf(':') + 1)
    if ($dst -in 'main', 'master', 'refs/heads/main', 'refs/heads/master') { Deny }
}

# No explicit branch (bare push, or HEAD): the checked-out branch decides.
$needBranchCheck = ($refspecs.Count -eq 0) -or ($refspecs -contains 'HEAD')
if ($needBranchCheck -and $cwd) {
    $branch = git -C $cwd branch --show-current 2>$null
    if ($branch -in 'main', 'master') { Deny }
}

Write-Output '{}'
