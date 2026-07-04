# Restores the Claude Code global configuration from this directory — native Windows port
# of install.sh (PowerShell 5.1+, no Git Bash required). Safe to re-run: it overwrites
# ~/.claude config files with the versions here.
# OWNER-ONLY: this replaces ~/.claude (CLAUDE.md, settings, hooks, statusline) with the
# owner's personal setup. To configure a single project or use only the plugins, do NOT
# run this — see AGENT-PROJECT-SETUP.md instead.
$ErrorActionPreference = 'Continue'

$Src = $PSScriptRoot
if ($env:CLAUDE_HOME) { $Dest = $env:CLAUDE_HOME } else { $Dest = Join-Path $HOME '.claude' }

Write-Host "Restoring Claude Code config: $Src -> $Dest"
Write-Host '  (owner-only: overwrites the global config; project setup lives in AGENT-PROJECT-SETUP.md)'
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Copy-Item (Join-Path $Src 'global/CLAUDE.md') (Join-Path $Dest 'CLAUDE.md') -Force
Copy-Item (Join-Path $Src 'global/settings.json') (Join-Path $Dest 'settings.json') -Force
foreach ($dir in 'skills', 'agents', 'hooks', 'rules') {
    Copy-Item (Join-Path $Src "global/$dir") $Dest -Recurse -Force
}
Copy-Item (Join-Path $Src 'global/statusline.sh') (Join-Path $Dest 'statusline.sh') -Force

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Warning ('bash not found: the bash-based hooks and statusline stay inert on this machine. ' +
        'They activate if you install Git for Windows (optional): winget install --id Git.Git -e')
}

# --- Secrets -> ~/.claude/settings.local.json (env block, machine-local) ----
$SecretsFile = Join-Path $Src 'secrets.env'
if (Test-Path $SecretsFile) {
    $secrets = @{}
    foreach ($line in Get-Content $SecretsFile) {
        if ($line -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $secrets[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
    $LocalPath = Join-Path $Dest 'settings.local.json'
    $local = $null
    if (Test-Path $LocalPath) {
        try { $local = Get-Content $LocalPath -Raw | ConvertFrom-Json } catch { $local = $null }
    }
    if ($null -eq $local) { $local = New-Object PSObject }
    if (-not ($local.PSObject.Properties.Name -contains 'env')) {
        $local | Add-Member -MemberType NoteProperty -Name 'env' -Value (New-Object PSObject)
    }
    foreach ($k in $secrets.Keys) {
        if (-not $secrets[$k]) { continue }
        if ($local.env.PSObject.Properties.Name -contains $k) { $local.env.$k = $secrets[$k] }
        else { $local.env | Add-Member -MemberType NoteProperty -Name $k -Value $secrets[$k] }
    }
    $json = $local | ConvertTo-Json -Depth 10
    # WriteAllText without BOM: PS 5.1's Set-Content -Encoding UTF8 adds one, breaking JSON parsers.
    [System.IO.File]::WriteAllText($LocalPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host '  settings.local.json: secrets applied'
} else {
    Write-Warning 'secrets.env not found - copy secrets.env.example to secrets.env and re-run.'
}

# --- MCP servers (user scope) + marketplace + plugins ------------------------
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $mcp = Get-Content (Join-Path $Src 'global/mcp-servers.json') -Raw | ConvertFrom-Json
    $ctx7 = $mcp.mcpServers.context7 | ConvertTo-Json -Depth 10 -Compress
    # PS 5.1 does not escape embedded quotes when passing args to native commands.
    $ctx7Arg = $ctx7 -replace '"', '\"'
    claude mcp add-json context7 $ctx7Arg --scope user 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host '  MCP: context7 registered (user scope)' }
    else { Write-Host "  MCP: context7 already exists or CLI refused - check with 'claude mcp list'" }

    # Personal marketplace (this repo) - register or refresh, idempotent.
    claude plugin marketplace add $Src 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host '  marketplace: gaston-plugins registered'
    } else {
        claude plugin marketplace update gaston-plugins 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host '  marketplace: gaston-plugins refreshed' }
        else { Write-Host "  marketplace: could not register - check 'claude plugin marketplace list'" }
    }

    foreach ($plugin in Get-Content (Join-Path $Src 'plugins.txt')) {
        $plugin = $plugin.Trim()
        if (-not $plugin -or $plugin.StartsWith('#')) { continue }
        claude plugin install $plugin 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "  plugin installed: $plugin" }
        else { Write-Host "  plugin skipped (already installed?): $plugin" }
    }

    # Stack/domain plugins install disabled: defaultEnabled:false in the manifests
    # (honored since CLI 2.1.154, our documented minimum) plus explicit false entries
    # in global/settings.json enabledPlugins. Projects re-enable their own.
    Write-Host '  stack plugins installed globally, disabled by default (enable per project)'
} else {
    Write-Warning ("'claude' CLI not found. Install Claude Code first (native installer, auto-updates):`n" +
        '    irm https://claude.ai/install.ps1 | iex' + "`n" +
        '  then re-run this script to register MCP servers and plugins.')
}

Write-Host 'Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin).'
Write-Host 'Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config.'
