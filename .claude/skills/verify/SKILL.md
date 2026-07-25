---
name: verify
description: Run the full validate.yml check suite locally (JSON well-formedness, version parity, shellcheck, language anchors, subagent model, template skeletons, plugin schemas). Use before declaring any change to this repo done.
---

# Verify (local mirror of validate.yml)

Run from the repo root. Report each real result; a single failure means the work is not done.

1. JSON well-formedness:
   `jq empty .claude-plugin/marketplace.json global/settings.json global/mcp-servers.json plugins/*/.claude-plugin/plugin.json`
   (also any `plugins/*/.mcp.json` / `plugins/*/.lsp.json` that exist).
2. Check scripts:
   `bash scripts/check-versions.sh && bash scripts/check-language-anchors.sh && bash scripts/check-subagent-model.sh && bash scripts/check-templates.sh`
   On a feature branch also: `bash scripts/check-plugin-version-bump.sh origin/main`.
3. Shell lint: `shellcheck install.sh scripts/*.sh global/hooks/*.sh global/statusline.sh`
4. PowerShell lint: needs `pwsh` (not installed on the Mac — CI's PSScriptAnalyzer step in
   `validate.yml` covers it; on Windows run `Invoke-ScriptAnalyzer` as that step does,
   excluding `PSAvoidUsingWriteHost`, plus `PSAvoidUsingEmptyCatchBlock` for hooks/statusline).
5. For each changed plugin: `claude plugin validate ./plugins/<name> --strict`.
6. Installer changes only: the real-execution smoke matrix runs in CI
   (`installer-smoke.yml`); locally you can preview with `./install.sh --dry-run`.
