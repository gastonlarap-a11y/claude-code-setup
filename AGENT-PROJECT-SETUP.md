# AGENT-PROJECT-SETUP — Configure any project using this directory

You are an AI agent configuring a TARGET project (new or existing, any stack, any owner)
for Claude Code — and, opt-in, with bridges for other agent CLIs (Codex, Antigravity) — using
this directory as your toolbox. If the user has not said which
project, ask. (Reached via `START.md`? The interview already settled who the user is and
which project — don't re-ask.)

1. **Execute the protocol.** Read `global/skills/setup-project/SKILL.md` (and its
   `references/templates.md`) and follow it against the target project. It handles all
   three cases — new project, existing project without AI config, existing project with
   AI config (audit and improve; never discard what works) — and guarantees the result
   stays token-lean and adapted to that project's real conventions.

2. **Offer the marketplace (optional).** If this directory is available on the machine,
   registering it gives per-stack/domain plugins that load knowledge only where enabled:

   ```bash
   claude plugin marketplace add <path-to-this-directory>
   ```

   Then enable per project only what the protocol maps to the detected stack. If the user
   declines (or the directory won't stay on this machine), the protocol generates
   self-sufficient local config instead — never leave a project depending on files that
   exist only elsewhere.

3. **Do NOT run `install.sh` for anyone but the owner of this setup.** It overwrites
   `~/.claude/` (global CLAUDE.md, settings, hooks, statusline) with the owner's personal
   configuration. Machine restore for the owner is a different flow: `AGENT-INSTALL.md`.

4. **Keep scopes clean.** Personal preferences (language, authorship rules, formatting
   habits) belong in the current user's own `~/.claude/CLAUDE.md` — never in the target
   project's shared files. Project files carry only team-shared, project-derived facts.
