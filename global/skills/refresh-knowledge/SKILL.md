---
name: refresh-knowledge
description: Re-verify and update the curated knowledge in the gaston-plugins marketplace (recipes, references, tooling versions) against the latest stable official docs, then republish the plugins.
disable-model-invocation: true
---

# Refresh marketplace knowledge

Target: the marketplace repo at `~/Desktop/claude-code-setup`. Scope: $ARGUMENTS (a plugin name, a specific skill, or empty = the highest-drift-risk files: every `recipes` skill and every `references/*.md`).

## Procedure
1. **Inventory**: list the in-scope files under `plugins/*/skills/**`. For each, extract the concrete claims: package names, APIs/methods, version-sensitive statements, limits/quotas.
2. **Verify** each claim against the latest stable official source (context7 + official docs — research in English; use the `docs-researcher` agent for batches to keep context clean). A claim is stale if: the recommended package changed, the API surface changed, a limit/flow changed, or a clearly better official approach now exists.
3. **Update** stale entries in place, keeping the existing format and conventions: concise pointer-style recipes (lib + minimal pattern + official source), English, same file structure. Do not grow files with tutorials — recipes stay recipes.
4. **Version bump**: for each modified plugin, bump `version` (patch) in BOTH `.claude-plugin/marketplace.json` (that plugin's entry) and the plugin's own `plugin.json`.
5. **Republish**:
   ```bash
   claude plugin marketplace update gaston-plugins
   claude plugin update <name>@gaston-plugins   # per modified plugin
   ```
6. **Commit** in the marketplace repo, Conventional Commits, one commit for the whole refresh:
   `chore(plugins): refresh <names> against latest stable docs` — never any AI attribution.
7. **Report** (in Spanish): table of what changed (file → claim → old → new → source), what was verified-and-current, and anything that needs my decision (e.g. a recommended package deprecated with two successors).

Nothing stale? Say so explicitly, with the verification date — that is a valid result.
