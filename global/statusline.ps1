# Claude Code status line - native PowerShell port of statusline.sh for Windows without
# Git Bash: [Model] dir | branch | bar NN% ctx | 5h: NN% | 7d: NN%
# Receives session JSON on stdin (see code.claude.com/docs/en/statusline). Bar glyphs are
# built from char codes so this file stays pure ASCII (PS 5.1 reads BOM-less as ANSI).
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$d = $null
try { $d = $raw | ConvertFrom-Json } catch { }
if (-not $d) {
    # Degraded fallback: just show the working directory name.
    Write-Host -NoNewline (Split-Path -Leaf (Get-Location).Path)
    exit 0
}

$model = 'Claude'
if ($d.model -and $d.model.display_name) { $model = [string]$d.model.display_name }
$dir = '.'
if ($d.workspace -and $d.workspace.current_dir) { $dir = [string]$d.workspace.current_dir }
$ctx = 0
if ($d.context_window -and $null -ne $d.context_window.used_percentage) {
    $ctx = [int][math]::Floor([double]$d.context_window.used_percentage)
}
$fiveH = $null
$sevenD = $null
if ($d.rate_limits) {
    if ($d.rate_limits.five_hour -and $null -ne $d.rate_limits.five_hour.used_percentage) {
        $fiveH = [int][math]::Floor([double]$d.rate_limits.five_hour.used_percentage)
    }
    if ($d.rate_limits.seven_day -and $null -ne $d.rate_limits.seven_day.used_percentage) {
        $sevenD = [int][math]::Floor([double]$d.rate_limits.seven_day.used_percentage)
    }
}

$branch = git -C $dir branch --show-current 2>$null

# 10-char context usage bar with color thresholds (same as the bash version).
$filled = [math]::Min([math]::Floor($ctx / 10), 10)
$full = [string][char]0x2593
$empty = [string][char]0x2591
$bar = ($full * $filled) + ($empty * (10 - $filled))

$esc = [char]27
if ($ctx -ge 85) { $color = "$esc[31m" }        # red
elseif ($ctx -ge 60) { $color = "$esc[33m" }    # yellow
else { $color = "$esc[32m" }                    # green
$reset = "$esc[0m"

$out = "[$model] " + (Split-Path -Leaf $dir)
if ($branch) { $out += " | $branch" }
$out += " | $color$bar $ctx% ctx$reset"
if ($null -ne $fiveH) { $out += " | 5h: $fiveH%" }
if ($null -ne $sevenD) { $out += " | 7d: $sevenD%" }

Write-Host -NoNewline $out
