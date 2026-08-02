# PostToolUse hook (Edit|Write) - native PowerShell port of format-on-edit.sh for
# Windows without Git Bash. Auto-formats the touched file by extension; silently no-ops
# when the formatter is not installed, so the same global config works on any machine.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$file = ''
try {
    $d = $raw | ConvertFrom-Json
    if ($d.tool_input -and $d.tool_input.file_path) { $file = [string]$d.tool_input.file_path }
} catch { }

if (-not $file -or -not (Test-Path -LiteralPath $file -PathType Leaf)) {
    Write-Output '{}'
    exit 0
}

function Find-NodeBin([string]$BinName, [string]$StartDir) {
    # Walk up from the file's directory to find the project-local binary (.cmd shim on Windows).
    $dir = $StartDir
    while ($dir) {
        foreach ($candidate in "$BinName.cmd", "$BinName.ps1", $BinName) {
            $path = Join-Path $dir (Join-Path 'node_modules\.bin' $candidate)
            if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
        }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { return $null }
        $dir = $parent
    }
    return $null
}

switch -Regex ($file) {
    '\.go$' {
        if (Get-Command gofmt -ErrorAction SilentlyContinue) { & gofmt -w $file 2>$null | Out-Null }
        break
    }
    '\.(ts|tsx|js|jsx|mjs|cjs)$' {
        $dir = Split-Path -Parent $file
        $eslint = Find-NodeBin 'eslint' $dir
        if ($eslint) { & $eslint --fix $file 2>$null | Out-Null }
        else {
            $prettier = Find-NodeBin 'prettier' $dir
            if ($prettier) { & $prettier --write $file 2>$null | Out-Null }
        }
        break
    }
    '\.dart$' {
        if (Get-Command dart -ErrorAction SilentlyContinue) { & dart format $file 2>$null | Out-Null }
        break
    }
    '\.(kt|kts)$' {
        if (Get-Command ktlint -ErrorAction SilentlyContinue) { & ktlint -F $file 2>$null | Out-Null }
        break
    }
    '\.cs$' {
        # csharpier only when actually installed. Probing `dotnet csharpier` blindly costs
        # ~0.1s per edit and always fails on repos that format via .editorconfig + analyzers
        # with EnforceCodeStyleInBuild - the common .NET setup, where there is nothing to run.
        $tool = Join-Path $HOME '.dotnet\tools\dotnet-csharpier.exe'
        if (Get-Command csharpier -ErrorAction SilentlyContinue) { & csharpier format $file 2>$null | Out-Null }
        elseif (Test-Path $tool) { & $tool format $file 2>$null | Out-Null }
        break
    }
}

Write-Output '{}'
