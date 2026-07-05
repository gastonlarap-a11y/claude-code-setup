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

# --- Secrets -----------------------------------------------------------------
# secrets.env is parsed here and injected directly into the MCP registration
# below (~/.claude.json, machine-local, never committed). Note: a user-level
# settings.local.json is NOT read by Claude Code (only project-level is) — never
# rely on an env block there.
$secrets = @{}
$SecretsFile = Join-Path $Src 'secrets.env'
if (Test-Path $SecretsFile) {
    foreach ($line in Get-Content $SecretsFile) {
        if ($line -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $secrets[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
} else {
    Write-Warning ('secrets.env not found - context7 will be registered keyless (lower rate limits). ' +
        'Copy secrets.env.example to secrets.env and re-run to add the key.')
}

# --- MCP servers (user scope) + marketplace + plugins ------------------------
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $mcp = Get-Content (Join-Path $Src 'global/mcp-servers.json') -Raw | ConvertFrom-Json
    $ctx7obj = $mcp.mcpServers.context7
    $key = ''
    if ($secrets.ContainsKey('CONTEXT7_API_KEY')) { $key = $secrets['CONTEXT7_API_KEY'] }
    if ($key) { $ctx7obj.env.CONTEXT7_API_KEY = $key }
    else { $ctx7obj.PSObject.Properties.Remove('env') }
    $ctx7 = $ctx7obj | ConvertTo-Json -Depth 10 -Compress
    # PS 5.1 does not escape embedded quotes when passing args to native commands.
    $ctx7Arg = $ctx7 -replace '"', '\"'
    # Remove-then-add so config/key updates take effect (add-json fails if it exists).
    claude mcp remove context7 --scope user 2>&1 | Out-Null
    claude mcp add-json context7 $ctx7Arg --scope user 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        if ($key) { Write-Host '  MCP: context7 registered (user scope, with API key)' }
        else { Write-Host '  MCP: context7 registered (user scope, keyless - lower rate limits)' }
    }
    else { Write-Host "  MCP: context7 registration failed - check with 'claude mcp list'" }

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
