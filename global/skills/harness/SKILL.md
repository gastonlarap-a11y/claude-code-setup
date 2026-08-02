---
name: harness
description: Show what this agent configuration actually gives you — every skill and what it is for, which guards run silently, which rules load per file type, which plugins are on, and what carries over to Codex and Antigravity. Use when the user asks what they can do, what commands exist, what a particular skill or guard is for, or how to use this setup.
argument-hint: "[term to look up, e.g. setup or guard]"
---

# Harness catalogue

Run the generator and show its output. It reads the installed files, so it is never a
hand-maintained list that can drift:

```sh
bash "$HOME/.claude/skills/harness/show.sh" $ARGUMENTS
```

If `$HOME/.claude` does not exist (another agent, or a checkout being inspected), run the
script from wherever this skill lives — it falls back to the sources next to it.

## Reading the output

- **YOU INVOKE THESE** — side-effectful or expensive; they never fire on their own. Type
  `/name`.
- **THESE TRIGGER THEMSELVES** — the agent picks them up when the description matches the
  task. Naming one explicitly still works and is faster than hoping.
- **SUBAGENTS** — run in their own context window; their noise never reaches this one.
- **PER-LANGUAGE RULES** — load only when a touched file matches the glob, so they cost
  nothing the rest of the time.
- **GUARDS** — deterministic, no model in the loop. They block rather than advise.
- **PLUGINS** — nothing is on globally by design; each repo enables its own in
  `.claude/settings.json`.

With an argument, only matching entries are shown, with their full description instead of the
first sentence.

## Answering follow-ups

The catalogue is the map, not the territory. When the user asks *how* something works, open
the file itself — `~/.claude/skills/<name>/SKILL.md` for a skill,
`~/.claude/hooks/<name>.sh` for a guard — and answer from what it actually does. Never
describe behaviour the file does not have.
