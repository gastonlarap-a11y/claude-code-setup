# Native PowerShell port of run-test-filtered.sh: runs the given test command but keeps
# its output small for the model - on success prints only the tail (summary lines); on
# failure prints only the lines around failures. Full output is never lost to the user's
# terminal history, only trimmed from the model's context.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '',
    Justification = 'Executing the already-approved test command string is the whole purpose of this wrapper')]
param([Parameter(Mandatory = $true)][string]$Command)
$ErrorActionPreference = 'SilentlyContinue'

$out = @(Invoke-Expression $Command 2>&1 | ForEach-Object { $_.ToString() })
$status = $LASTEXITCODE
if ($null -eq $status) { $status = if ($?) { 0 } else { 1 } }

if ($status -eq 0) {
    Write-Output 'PASSED (exit 0). Last lines of output:'
    $out | Select-Object -Last 8 | ForEach-Object { Write-Output $_ }
} else {
    # Same failure markers as the bash version; the two cross marks are built from char
    # codes so this file stays pure ASCII (PS 5.1 reads BOM-less files as ANSI).
    $pattern = 'FAIL|ERROR|error|' + [char]0x2715 + '|' + [char]0x2717 + '|Expected|panic:|--- FAIL'
    $include = New-Object 'System.Collections.Generic.HashSet[int]'
    for ($i = 0; $i -lt $out.Count; $i++) {
        if ($out[$i] -match $pattern) {
            $from = [math]::Max(0, $i - 2)
            $to = [math]::Min($out.Count - 1, $i + 10)
            for ($j = $from; $j -le $to; $j++) { [void]$include.Add($j) }
        }
    }
    $printed = 0
    for ($i = 0; $i -lt $out.Count -and $printed -lt 150; $i++) {
        if ($include.Contains($i)) { Write-Output $out[$i]; $printed++ }
    }
    Write-Output "FAILED (exit $status) - output filtered to failure context by ~/.claude/hooks/run-test-filtered.ps1"
}

exit $status
