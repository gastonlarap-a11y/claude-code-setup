---
name: refresh-knowledge
description: Re-verify and update the curated knowledge in the dev-plugins marketplace (recipes, references, tooling versions) against the latest stable official docs, then republish the plugins.
disable-model-invocation: true
---

# Refresh marketplace knowledge

Target: the marketplace repo — resolve its path from `claude plugin marketplace list` (the `source` of `dev-plugins`); if that fails and the current directory contains `.claude-plugin/marketplace.json` naming `dev-plugins`, use it. Scope: $ARGUMENTS (a plugin name, a specific skill, or empty = the highest-drift-risk files: every `recipes` skill and every `references/*.md`).

## Procedure
1. **Inventory**: list the in-scope files under `plugins/*/skills/**` AND `global/skills/**` (the cross-stack skills — ci-cd action pins, cloud CLI flags — drift just like plugin recipes). For each, extract the concrete claims: package names, APIs/methods, action/image version tags, version-sensitive statements, limits/quotas. On a full pass, also include the repo's own Claude Code claims (README "Novedades"/version minimums, START.md/AGENT-INSTALL.md) — verify those against `code.claude.com/docs/en/changelog` and `code.claude.com/docs/en/whats-new`.
2. **Verify** each claim against the latest stable official source (official docs on the web — research in English; use the `docs-researcher` agent for batches to keep context clean). A claim is stale if: the recommended package changed, the API surface changed, a limit/flow changed, or a clearly better official approach now exists.
3. **Update** stale entries in place, keeping the existing format and conventions: concise pointer-style recipes (lib + minimal pattern + official source), English, same file structure. Do not grow files with tutorials — recipes stay recipes.
4. **Version bump**: for each modified plugin, bump `version` (patch) in BOTH `.claude-plugin/marketplace.json` (that plugin's entry) and the plugin's own `plugin.json`. Then run `claude plugin details <name>` per modified plugin and note its token cost (always-on vs on-invoke) in the report — flag any regression.
5. **Republish**:
   ```bash
   claude plugin marketplace update dev-plugins
   claude plugin update <name>@dev-plugins   # per modified plugin
   ```
6. **Commit** in the marketplace repo, Conventional Commits, one commit for the whole refresh:
   `chore(plugins): refresh <names> against latest stable docs` — never any AI attribution.
7. **Report** (in the user's configured language): table of what changed (file → claim → old → new → source), what was verified-and-current, and anything that needs my decision (e.g. a recommended package deprecated with two successors).

Nothing stale? Say so explicitly, with the verification date — that is a valid result.
