# Restores the Claude Code global configuration from this directory - native Windows port
# of install.sh (PowerShell 5.1+, no Git Bash required). Safe to re-run: it overwrites
# ~/.claude config files with the versions here.
# OWNER-ONLY: this replaces ~/.claude (CLAUDE.md, settings, hooks, statusline) with the
# owner's personal setup. To configure a single project or use only the plugins, do NOT
# run this - see AGENT-PROJECT-SETUP.md instead.
param([switch]$DryRun)  # -DryRun: print backup/copy/prune/language preview, write nothing

$ErrorActionPreference = 'Continue'

$Src = $PSScriptRoot
if ($env:CLAUDE_HOME) { $Dest = $env:CLAUDE_HOME } else { $Dest = Join-Path $HOME '.claude' }

# The manifest records exactly what the copy block ships; computed once, shared by the
# dry-run preview and by the orphan pruning after the real copy.
$ManifestPath = Join-Path $Dest '.install-manifest'
$GlobalRoot = Join-Path $Src 'global'
$newManifest = @('CLAUDE.md', 'settings.json', 'statusline.sh')
foreach ($dir in 'skills', 'agents', 'hooks', 'rules') {
    $newManifest += Get-ChildItem -Path (Join-Path $GlobalRoot $dir) -Recurse -File |
        Where-Object { $_.Name -ne '.DS_Store' } |
        ForEach-Object { $_.FullName.Substring($GlobalRoot.Length + 1) -replace '\\', '/' }
}
$newManifest = @($newManifest | Sort-Object)

Write-Host "Restoring Claude Code config: $Src -> $Dest"
Write-Host '  (owner-only: overwrites the global config; project setup lives in AGENT-PROJECT-SETUP.md)'

if ($DryRun) {
    Write-Host 'DRY-RUN: nothing will be written.'
    foreach ($item in 'CLAUDE.md', 'settings.json', 'statusline.sh', 'skills', 'agents', 'hooks', 'rules') {
        if (Test-Path (Join-Path $Dest $item)) {
            Write-Host "  would back up: $item -> $Dest\.backup-<timestamp>\"
        }
    }
    Write-Host "  would copy: global/{CLAUDE.md,settings.json,statusline.sh,skills,agents,hooks,rules} -> $Dest"
    if (Test-Path $ManifestPath) {
        foreach ($rel in Get-Content $ManifestPath) {
            if (-not $rel) { continue }
            if ($rel.StartsWith('/') -or $rel.Contains('..')) { continue }
            if ($newManifest -notcontains $rel) {
                Write-Host "  would prune (no longer shipped): $rel"
            }
        }
    }
    $LangPreview = ''
    if ($env:CLAUDE_LANGUAGE) { $LangPreview = $env:CLAUDE_LANGUAGE }
    elseif (Test-Path (Join-Path $Dest '.install-profile')) {
        foreach ($line in Get-Content (Join-Path $Dest '.install-profile')) {
            if ($line -match '^CLAUDE_LANGUAGE=(.+)$') { $LangPreview = $Matches[1] }
        }
    }
    if (-not $LangPreview) { $LangPreview = 'spanish (default)' }
    Write-Host "  would apply language: $LangPreview"
    Write-Host '  would register: MCP servers from global/mcp-servers.json (user scope), dev-plugins marketplace, plugins from plugins.txt'
    exit 0
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# --- Backup what this run will replace (last 3 backups kept) -------------------
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Backup = Join-Path $Dest ".backup-$Stamp"
foreach ($item in 'CLAUDE.md', 'settings.json', 'statusline.sh', 'skills', 'agents', 'hooks', 'rules') {
    $existing = Join-Path $Dest $item
    if (Test-Path $existing) {
        New-Item -ItemType Directory -Force -Path $Backup | Out-Null
        Copy-Item $existing (Join-Path $Backup $item) -Recurse -Force
    }
}
if (Test-Path $Backup) {
    Write-Host "  backup: $Backup (rollback: copy its contents back into $Dest)"
}
Get-ChildItem -Path $Dest -Directory -Filter '.backup-*' -Force -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -Skip 3 |
    Remove-Item -Recurse -Force

Copy-Item (Join-Path $Src 'global/CLAUDE.md') (Join-Path $Dest 'CLAUDE.md') -Force
Copy-Item (Join-Path $Src 'global/settings.json') (Join-Path $Dest 'settings.json') -Force
foreach ($dir in 'skills', 'agents', 'hooks', 'rules') {
    Copy-Item (Join-Path $Src "global/$dir") $Dest -Recurse -Force
}
Copy-Item (Join-Path $Src 'global/statusline.sh') (Join-Path $Dest 'statusline.sh') -Force

# --- Orphan pruning (manifest-listed paths ONLY - never unknown user files) ----
# Files listed in a previous manifest but no longer shipped are removed, so
# renamed/deleted skills or rules stop loading into every session instead of
# lingering forever. ManifestPath/newManifest are computed at the top (shared with
# the dry-run preview).
if (Test-Path $ManifestPath) {
    foreach ($rel in Get-Content $ManifestPath) {
        if (-not $rel) { continue }
        if ($rel.StartsWith('/') -or $rel.Contains('..')) { continue }  # relative only, no traversal
        if ($newManifest -notcontains $rel) {
            $orphan = Join-Path $Dest ($rel -replace '/', '\')
            if (Test-Path $orphan) {
                Remove-Item $orphan -Force
                Write-Host "  pruned (no longer shipped): $rel"
            }
        }
    }
    foreach ($dir in 'skills', 'agents', 'hooks', 'rules') {
        $root = Join-Path $Dest $dir
        if (Test-Path $root) {
            Get-ChildItem -Path $root -Recurse -Directory |
                Sort-Object { $_.FullName.Length } -Descending |
                Where-Object { -not (Get-ChildItem -Path $_.FullName -Force) } |
                Remove-Item -Force
        }
    }
}
[IO.File]::WriteAllText($ManifestPath, (($newManifest -join "`n") + "`n"))

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Warning ('bash not found: the bash-based hooks and statusline stay inert on this machine. ' +
        'They activate if you install Git for Windows (optional): winget install --id Git.Git -e')
}

# --- Response language (CLAUDE_LANGUAGE, persisted machine-locally) ------------
# Applies to the COPIES in $Dest only; the repo sources stay Spanish-default. The
# anchor literals live in scripts/language-anchors.env (single source, asserted
# by CI via scripts/check-language-anchors.sh).
$InstallProfile = Join-Path $Dest '.install-profile'
$Lang = ''
if ($env:CLAUDE_LANGUAGE) { $Lang = $env:CLAUDE_LANGUAGE }
elseif (Test-Path $InstallProfile) {
    foreach ($line in Get-Content $InstallProfile) {
        if ($line -match '^CLAUDE_LANGUAGE=(.+)$') { $Lang = $Matches[1] }
    }
}
$Lang = ($Lang -replace '\s', '').ToLowerInvariant()
if ($Lang -and $Lang -notmatch '^[a-z-]+$') {
    Write-Warning "invalid CLAUDE_LANGUAGE '$Lang' (letters/hyphens only) - keeping Spanish."
    $Lang = ''
}
if ($Lang) { [IO.File]::WriteAllText($InstallProfile, "CLAUDE_LANGUAGE=$Lang`n") }
if ($Lang -and $Lang -ne 'spanish') {
    $MdAnchor = ''
    $SettingsAnchor = ''
    $AnchorsFile = Join-Path $Src 'scripts/language-anchors.env'
    if (Test-Path $AnchorsFile) {
        foreach ($line in Get-Content $AnchorsFile) {
            if ($line -match "^CLAUDE_MD_LANGUAGE_ANCHOR='(.+)'$") { $MdAnchor = $Matches[1] }
            if ($line -match "^SETTINGS_LANGUAGE_ANCHOR='(.+)'$") { $SettingsAnchor = $Matches[1] }
        }
    }
    $LangCap = $Lang.Substring(0, 1).ToUpperInvariant() + $Lang.Substring(1)
    $SettingsPath = Join-Path $Dest 'settings.json'
    $SettingsText = [IO.File]::ReadAllText($SettingsPath)
    if ($SettingsAnchor -and $SettingsText.Contains($SettingsAnchor)) {
        # Literal replace on purpose: a ConvertFrom/To-Json round-trip under PS 5.1
        # reformats the whole file and mangles non-ASCII; WriteAllText keeps UTF-8 no-BOM.
        $NewSettings = $SettingsText.Replace($SettingsAnchor, $SettingsAnchor.Replace('spanish', $Lang))
        [IO.File]::WriteAllText($SettingsPath, $NewSettings)
    } else {
        Write-Warning "language anchor not found in settings.json - set `"language`": `"$Lang`" manually."
    }
    $MdPath = Join-Path $Dest 'CLAUDE.md'
    $MdText = [IO.File]::ReadAllText($MdPath)
    if ($MdAnchor -and $MdText.Contains($MdAnchor)) {
        [IO.File]::WriteAllText($MdPath, $MdText.Replace($MdAnchor, $MdAnchor.Replace('Spanish', $LangCap)))
        Write-Host "  language: $Lang (persisted in .install-profile; plain re-runs keep it)"
    } else {
        Write-Warning 'language anchor not found in CLAUDE.md - edit its Language section manually.'
    }
}

# --- Secrets -----------------------------------------------------------------
# secrets.env is parsed here and injected directly into the MCP registration
# below (~/.claude.json, machine-local, never committed). Note: a user-level
# settings.local.json is NOT read by Claude Code (only project-level is) - never
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
    # Data-driven: every server in global/mcp-servers.json registers at user scope; each
    # env var it declares resolves from secrets.env when present and is dropped when not
    # (the server still registers, keyless). Adding a keyed server = one JSON entry + one
    # secrets.env line, zero installer changes.
    $mcp = Get-Content (Join-Path $Src 'global/mcp-servers.json') -Raw | ConvertFrom-Json
    foreach ($entry in $mcp.mcpServers.PSObject.Properties) {
        $name = $entry.Name
        $server = $entry.Value
        $keyState = 'keyless'
        if ($server.PSObject.Properties['env']) {
            foreach ($envKey in @($server.env.PSObject.Properties.Name)) {
                if ($secrets.ContainsKey($envKey) -and $secrets[$envKey]) {
                    $server.env.$envKey = $secrets[$envKey]
                    $keyState = 'with API key'
                } else {
                    $server.env.PSObject.Properties.Remove($envKey)
                }
            }
            if (-not @($server.env.PSObject.Properties).Count) { $server.PSObject.Properties.Remove('env') }
        }
        $serverJson = $server | ConvertTo-Json -Depth 10 -Compress
        # PS 5.1 does not escape embedded quotes when passing args to native commands.
        $serverArg = $serverJson -replace '"', '\"'
        # Remove-then-add so config/key updates take effect (add-json fails if it exists).
        claude mcp remove $name --scope user 2>&1 | Out-Null
        claude mcp add-json $name $serverArg --scope user 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "  MCP: $name registered (user scope, $keyState)" }
        else { Write-Host "  MCP: $name registration failed - check with 'claude mcp list'" }
    }

    # Personal marketplace (this repo) - register or refresh, idempotent.
    claude plugin marketplace add $Src 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host '  marketplace: dev-plugins registered'
    } else {
        claude plugin marketplace update dev-plugins 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host '  marketplace: dev-plugins refreshed' }
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
    # (honored since CLI 2.1.154 - below our documented floor of 2.1.187) plus explicit false entries
    # in global/settings.json enabledPlugins. Projects re-enable their own.
    Write-Host '  stack plugins installed globally, disabled by default (enable per project)'
} else {
    Write-Warning ("'claude' CLI not found. Install Claude Code first (native installer, auto-updates):`n" +
        '    irm https://claude.ai/install.ps1 | iex' + "`n" +
        '  then re-run this script to register MCP servers and plugins.')
}

Write-Host 'Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin).'
Write-Host 'Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config.'
