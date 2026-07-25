---
name: new-plugin
description: Scaffold a new plugin for the dev-plugins marketplace — skeleton, marketplace entry, dual version, install list, validate and republish. Use when adding a plugin to this repo.
argument-hint: "<plugin-name>"
---

# New plugin

1. Scaffold `plugins/<name>/` — `claude plugin init <name>` gives the official skeleton, or
   mirror an exemplar: every plugin here ships `.claude-plugin/plugin.json` + `skills/`
   (see `plugins/go/` for the shape). Manifest fields as in `plugins/go/.claude-plugin/plugin.json`,
   including `"defaultEnabled": false` for stack/domain plugins (projects re-enable their own).
2. Add the entry to `.claude-plugin/marketplace.json` (`name`, `source: ./plugins/<name>`,
   `description`, `version`, `defaultEnabled`, `category`). Version MUST match the plugin's
   own `plugin.json` — dual-bump rule, enforced by `scripts/check-versions.sh`.
   Renaming or retiring a plugin later: use the marketplace `renames` map
   (`"old-name": "new-name"` or `null` to retire; requires CLI ≥ 2.1.193) so installed
   copies migrate safely.
3. Wire distribution: add the plugin to `plugins.txt` under its section (the installers
   install from it) and an explicit entry in `global/settings.json` `enabledPlugins`
   (`scripts/check-versions.sh` / CI keep these in sync).
4. Content rules: all config content in English; skill descriptions lead with the words a
   request would contain; heavy reference material goes in `references/` (loads on demand).
5. Test hot without installing: `claude --plugin-dir ./plugins/<name>` and `/reload-plugins`
   while iterating.
6. Validate & publish:
   `claude plugin validate ./plugins/<name> --strict && claude plugin marketplace update dev-plugins && claude plugin update <name>@dev-plugins`
7. Run the `verify` skill and report real results. New plugins rely on the dual-bump rule —
   a `CHANGELOG.md` entry is only needed if the marketplace as a whole changes behavior.
