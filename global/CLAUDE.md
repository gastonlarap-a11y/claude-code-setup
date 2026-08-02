# Global instructions

## About me
Senior polyglot developer. Main stacks: NestJS (TypeScript/Fastify), Go, Android (Kotlin), React/Next.js, Flutter/Dart. I also work with SQL/NoSQL databases, Docker, Kubernetes, testing at every level, and CI/CD with GitHub Actions. I maintain per-stack template repos under `~/Documents/Git/`.

## Language
- Always answer **in Spanish** (explanations, summaries, questions).
- Internal reasoning and all research: **English**. Code, identifiers, code comments, commit messages, and config files: **English**.

## Engineering standards (every project)
- Code must communicate its intent to the compiler as much as to other developers: encode invariants in types, self-documenting names, small focused functions, clear module boundaries. The most frequent reader is me months later — someone else must understand this code without me.
- Apply design patterns only when they solve a real problem, and say which pattern and why. No over-engineering, no speculative abstractions.
- Every feature ships with its tests. Run the repo's lint/typecheck/test commands before declaring work done, and report their real results.
- Prefer running single tests (the repo's single-test command) over full suites while iterating; run the full suite before declaring done.
- Respect each repo's existing architecture (its `CLAUDE.md` / `ARCHITECTURE.md`); never introduce a competing style.
- Handle errors explicitly at boundaries; never swallow exceptions or ignore returned errors.

## Workflow rules
- **Never assume**: if a request is ambiguous, incomplete, or contradictory, ask targeted questions before acting.
- **Counter-propose**: if what I asked is incorrect, suboptimal, or a more efficient route exists, say so with the why BEFORE acting, and let me choose between my version and yours; once I pick, execute without re-litigating.
- Research proactively without being asked: for any third-party API surface, version, or "how do I X" not fully covered by a loaded skill, use the `research` skill — official sources in English, latest stable, only the relevant section. Never a version or signature from memory.
- VCS via CLI: use `gh` for GitHub remotes and `az repos` / `az devops` for Azure DevOps remotes (detect from `git remote -v`). If the required CLI is missing, install it or give me the exact install steps and pause until I confirm.
- Prefer editing existing files over creating new ones. No README/docs files unless asked — except when creating or setting up a project, which always includes its README (setup-project protocol).
- **Tools have jobs**: read with Read, search with Grep/Glob, change with Edit/Write. Bash runs things — never use it to read, write or patch repo files: a shell heredoc re-serializes a whole file where an Edit would have sent a diff.
- **Nothing is enabled globally**: no plugin or LSP is on by default. Each repo turns on what its own stack needs in its `.claude/settings.json` — `setup-project` maps stack → plugins. A plugin loaded where it does not apply is pure context cost.
- **Scope contract**: before the first edit of a task touching 3+ files, state in ≤5 lines which files you will touch (grouped by area), what is out of scope, and your confidence line; wait for the go-ahead. Skip for single-file or already-scoped fixes.
- **Confidence**: close every plan, "work is done" report, research answer and config proposal with `Confianza: NN% — <what stayed unverified>`. Never a bare number: name an unverified assumption, or claim none only when everything really ran. Below 70%, say human review is needed before merging.

## Git conventions
- **Authorship rule (absolute): commits, PRs, MRs, issues and their descriptions carry ONLY my identity — no `Co-Authored-By` trailers, no "Generated with" footers, no AI attribution of any kind, anywhere.**
- **Publish only on explicit order**: never commit, push, or open PRs/MRs on your own initiative — on any platform (GitHub via `gh`, Azure DevOps via `az repos`, or other). Only when I explicitly ask ("sube los cambios" or equivalent); then run the full flow (commit → push → PR/MR) with the CLI detected from `git remote -v`.
- Conventional Commits style: `feat|fix|refactor|test|chore(scope): message`.
- After a merge is confirmed, or a local branch shows `[gone]` upstream → `post-merge-cleanup`
  skill (verifies the merge, then prunes and branches off a fresh main).

# Compact instructions
When compacting, preserve: the list of modified files, the exact build/test commands used and their latest results, key architectural decisions made this session, and any unresolved errors or pending steps.
