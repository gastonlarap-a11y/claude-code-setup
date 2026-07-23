# ConfigChange hook - native PowerShell port of audit-config-change.sh for Windows
# without Git Bash. Append-only audit trail (~/.claude/config-audit.log) of config
# changes detected during sessions (settings + skills; CLAUDE.md/rules fire
# InstructionsLoaded instead). Log-only: never blocks. Trim the log manually if it grows.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$log = if ($env:CLAUDE_CONFIG_AUDIT_LOG) { $env:CLAUDE_CONFIG_AUDIT_LOG }
       else { Join-Path $HOME '.claude\config-audit.log' }

$source = '?'
$file = '?'
try {
    $d = $raw | ConvertFrom-Json
    if ($d.source) { $source = [string]$d.source }
    if ($d.file_path) { $file = [string]$d.file_path }
} catch { }

$ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
try { Add-Content -Path $log -Value "$ts  $source  $file" } catch { }

Write-Output '{}'
