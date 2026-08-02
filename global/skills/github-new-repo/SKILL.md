---
name: github-new-repo
description: Publish a local repo to GitHub with the standard protection (main cannot be deleted, PR-only merges, branch auto-delete). Use whenever the user asks to create a GitHub repository or publish/upload a local project that has no remote yet.
---

# GitHub new repo — protected by default

Standard for every new repo of this user: public visibility, `protect-main`
ruleset (deletion + non_fast_forward + pull_request with 0 required approvals,
targeting `~DEFAULT_BRANCH`), and delete-branch-on-merge.

## Procedure

1. Preflight: `git ls-files` scan for secrets (`.env`, `*.pem`, `*.db`,
   credential-like names) — never publish if anything suspicious is tracked.
   Also check commit emails: GitHub's email-privacy protection (GH007) rejects
   pushes whose commits carry the user's real address. Every repo must commit
   with the account noreply (`gh api user --jq
   '"\(.id)+\(.login)@users.noreply.github.com"'`) set as repo-local
   `user.email`; if existing commits carry another email and the repo was
   never pushed, rewrite with `git filter-branch --env-filter` before
   publishing.
2. The one-command path is the gh alias (runs `~/Documents/Git/github-defaults/new-repo.sh`):

   ```bash
   gh new-repo <name> ["description"]
   ```

   It creates the repo public from the current directory, pushes, enables
   branch auto-delete and applies the ruleset from
   `~/Documents/Git/github-defaults/ruleset-protect-main.json`.
3. **The initial `git push` of main is blocked for Claude** by the global
   no-push-to-main policy hook — it also breaks the push inside
   `gh repo create`. Have the USER run the command themselves (suggest typing
   `! gh new-repo <name>` so it runs in-session), or split it: Claude runs
   `gh repo create --source . --remote origin` WITHOUT `--push`, the user runs
   `git push -u origin main`, then Claude applies steps 4–5.
4. Apply the ruleset only AFTER main exists on the remote (the pull_request
   rule would reject the branch-creating push):

   ```bash
   gh api "repos/<owner>/<name>/rulesets" -X POST \
     --input ~/Documents/Git/github-defaults/ruleset-protect-main.json
   gh repo edit "<owner>/<name>" --delete-branch-on-merge
   ```

5. Verify: `gh api repos/<owner>/<name>/rules/branches/main` must list
   `deletion`, `non_fast_forward` and `pull_request`.

## Constraints (GitHub Free)

- Rulesets are only ENFORCED on public repos; on a private repo the ruleset is
  ignored unless the account has Pro/Team. If the user wants a private repo,
  warn that protection will not apply and let them choose.
- Org-wide automatic rulesets are Enterprise-only; this per-repo command is
  the free equivalent.
- After the ruleset is active, all work lands via feature branch + PR
  (`gh pr create` → `gh pr merge`); direct pushes to main are rejected for
  everyone, including the owner.
