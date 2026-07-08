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
- Research proactively without being asked: for any third-party API surface, version, or "how do I X" not fully covered by a loaded skill, use the `research` skill (context7 + official docs) and fetch only the relevant section — never whole docs, never training-data guesses.
- Research and doc lookups: always in English, preferring the latest stable release and official sources (docs, changelogs, release notes). Never assume versions from memory.
- VCS via CLI: use `gh` for GitHub remotes and `az repos` / `az devops` for Azure DevOps remotes (detect from `git remote -v`). If the required CLI is missing, install it or give me the exact install steps and pause until I confirm.
- Prefer editing existing files over creating new ones. No README/docs files unless asked —
  exception: creating or setting up a project always includes creating/updating its README
  (setup-project protocol).
- For Docker/Kubernetes, CI/CD, database, or architecture-decision tasks, consult the matching global skill (`docker-kubernetes`, `ci-cd`, `databases`, `architecture`).
- If the project has no `CLAUDE.md`/`.claude/` config, or its config has drifted (a documented command fails, a stated convention contradicts the code), offer `/setup-project` — it creates/audits/improves project config without discarding what exists.

## Git conventions
- **Authorship rule (absolute): commits, PRs, MRs, issues and their descriptions carry ONLY my identity — no `Co-Authored-By` trailers, no "Generated with" footers, no AI attribution of any kind, anywhere.**
- **Publish only on explicit order**: never commit, push, or open PRs/MRs on your own initiative — on any platform (GitHub via `gh`, Azure DevOps via `az repos`, or other). Only when I explicitly ask ("sube los cambios" or equivalent); then run the full flow (commit → push → PR/MR) with the CLI detected from `git remote -v`.
- Conventional Commits style: `feat|fix|refactor|test|chore(scope): message`.
- Never commit secrets; `.env*` and `secrets*` files stay out of git.
- Never push directly to `main`; never `git push --force` unless I explicitly ask.
- **Post-merge cleanup (automatic)**: remotes auto-delete branches on PR merge. When I confirm
  a merge or a local branch shows `[gone]` upstream, first verify with
  `gh pr view <branch> --json state` (or `az repos pr show`) that state is MERGED, then clean
  up without asking: `git checkout main && git pull && git fetch --prune`, delete the local
  branch (`git branch -D` — safe only because the merge was verified), and start the next work
  from a fresh branch off main.

# Compact instructions
When compacting, preserve: the list of modified files, the exact build/test commands used and their latest results, key architectural decisions made this session, and any unresolved errors or pending steps.
