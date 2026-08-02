#!/usr/bin/env bash
# PreToolUse hook: keep the shell out of the editing business.
# Measured problem: an agent rewrote whole React/C# files through `python3 -c` +
# pathlib.write_text() heredocs instead of Edit/Write — 229 such commands in a single
# session, averaging 14 lines each, against only 245 Edit calls. That burns output tokens
# (whole file vs diff), loses the edit-tracking the harness does for Edit/Write, and is
# error-prone. This denies shell writes that target source files inside the repo and tells
# the model what to use instead. Generated/temp paths pass.
# Works on Claude Code, Codex CLI and Antigravity CLI via lib/agent-io.sh.
# Fail-open by design: anything unparseable proceeds untouched.
set -uo pipefail

# shellcheck source=lib/agent-io.sh disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/lib/agent-io.sh" 2>/dev/null || { echo '{}'; exit 0; }

hook_read_command
[ -n "${HOOK_CMD:-}" ] || hook_allow

cmd="$HOOK_CMD"

# Source extensions worth protecting. Data/log/text files are deliberately absent:
# scripting those is normal shell work.
exts='cs|ts|tsx|js|jsx|mjs|cjs|json|md|csproj|props|targets|go|kt|kts|dart|py|rb|java|swift|rs|vue|svelte|css|scss|html'

# 1. Is this a file-writing command at all? Redirections are only counted when they point
#    at a source file, so `cmd > /dev/null` and `2>&1` never match here.
write_signal=0
if printf '%s' "$cmd" | grep -qE 'write_text[[:space:]]*\(|\.writeFileSync|open[[:space:]]*\([^)]*["'"'"'][wa]|sed[[:space:]]+-i|(^|[[:space:]])tee[[:space:]]'; then
  write_signal=1
elif printf '%s' "$cmd" | grep -qE '>>?[[:space:]]*["'"'"']?[^[:space:]|&;<>]*\.('"$exts"')(["'"'"']|[[:space:]]|$)'; then
  write_signal=1
fi
[ "$write_signal" -eq 1 ] || hook_allow

# 2. Which source files does it mention? If every one of them is a generated/temp path,
#    the write is legitimate tooling work.
set -f  # the command may contain globs; do not let the shell expand them
targets="$(printf '%s' "$cmd" | grep -oE '[A-Za-z0-9_.~$@{}/-]+\.('"$exts"')' || true)"
[ -n "$targets" ] || hook_allow

# shellcheck disable=SC2016  # this is a regex: $TMPDIR must stay literal, not expand
exempt='(^|/)(dist|build|out|bin|obj|target|coverage|node_modules|vendor|\.git|\.next|\.venv|__pycache__|scratchpad)(/|$)|^/tmp/|^/private/tmp/|^/var/folders/|\$TMPDIR|\$\{TMPDIR'

protected=""
while IFS= read -r t; do
  [ -n "$t" ] || continue
  printf '%s' "$t" | grep -qE "$exempt" && continue
  protected="$t"
  break
done <<EOF
$targets
EOF

[ -n "$protected" ] || hook_allow

hook_deny "Blocked by policy: this command writes to '$protected' through the shell. Use Edit (or Write for a brand-new file) instead — they emit a diff rather than re-serializing the whole file, and the harness tracks their state. Read files with Read and search with Grep/Glob for the same reason. Shell writes are only for generated or temporary paths (dist, build, bin, obj, node_modules, \$TMPDIR, /tmp)."
