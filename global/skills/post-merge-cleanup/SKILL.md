---
name: post-merge-cleanup
description: Clean up after a pull/merge request lands — verify the merge really happened, switch back to an up-to-date main, prune the deleted remote branch and delete the local one. Use when the user confirms a PR/MR was merged, when a local branch shows [gone] upstream, or before starting new work on a branch whose PR already landed. Works with GitHub (gh) and Azure DevOps (az repos).
---

# Post-merge cleanup

Remotes auto-delete branches on merge, so local branches linger with a `[gone]` upstream.
Deleting them is safe **only after the merge is verified** — `git branch -D` discards commits
without asking, so the verification step is not optional.

## 1. Verify the merge actually landed

Detect the remote from `git remote -v`, then:

- GitHub → `gh pr view <branch> --json state,mergedAt`
- Azure DevOps → `az repos pr show --id <id>` (or `az repos pr list --source-branch <branch>`)

State must be `MERGED` (Azure: `completed`). Anything else — open, closed, draft, no PR found —
stops the cleanup: report what you found and leave the branch alone.

## 2. Clean up

```bash
git checkout main && git pull && git fetch --prune
git branch -D <branch>          # safe only because step 1 verified the merge
```

## 3. Start the next work from a fresh branch

```bash
git checkout -b <type>/<short-description>   # off the main you just pulled
```

Never continue working on the merged branch, and never start new work directly on `main`.

## Notes

- Several branches merged at once → verify each one separately; a single unverified branch is
  not a reason to skip the others, and a failed verification is not a reason to force it.
- `git push` to `main` and `--force` are denied by `guard-git-push.sh`; this skill never needs
  either.
