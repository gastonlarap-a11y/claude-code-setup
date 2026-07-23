# Notification hook (OPT-IN - shipped but NOT wired by default; wiring snippet in the
# README) - native PowerShell port of notify-os.sh. Shows a non-blocking Windows balloon
# notification when Claude Code needs attention (useful matchers: permission_prompt,
# idle_prompt). No-op on any failure.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$title = 'Claude Code'
$message = 'Claude Code needs your attention'
try {
    $d = $raw | ConvertFrom-Json
    if ($d.title) { $title = [string]$d.title }
    if ($d.message) { $message = [string]$d.message }
} catch { }

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $icon = New-Object System.Windows.Forms.NotifyIcon
    $icon.Icon = [System.Drawing.SystemIcons]::Information
    $icon.Visible = $true
    $icon.BalloonTipTitle = $title
    $icon.BalloonTipText = $message
    $icon.ShowBalloonTip(3000)
    Start-Sleep -Seconds 3   # keep the icon alive long enough for the balloon to show
    $icon.Dispose()
} catch { }

Write-Output '{}'
