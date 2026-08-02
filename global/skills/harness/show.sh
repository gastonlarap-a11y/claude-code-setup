#!/usr/bin/env bash
# Prints what this configuration actually gives you, GENERATED from the installed files —
# never a hand-written list, so it cannot drift out of date (the Init Fossilization smell
# the rest of this repo is built to avoid).
#
# Runs anywhere: plain terminal, Claude Code (/harness), Codex or Antigravity. A local LLM
# only needs its stdout.
#
#   show.sh              full catalogue
#   show.sh <term>       only entries matching <term>, with their full description
set -uo pipefail

ROOT="${CLAUDE_HOME:-$HOME/.claude}"
# When run straight from the repo checkout, read the sources instead of the install.
if [ ! -d "$ROOT/skills" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  case "$here" in *"/global/skills/harness") ROOT="${here%/skills/harness}" ;; esac
fi

FILTER="${1:-}"
case "$FILTER" in -h|--help) FILTER="" ;; esac

W=88
say() { printf '%s\n' "$*"; }
wrap() { printf '%s\n' "$1" | fold -s -w "$W" | sed '2,$s/^/      /'; }
head2() { printf '\n\033[1m%s\033[0m\n' "$1" 2>/dev/null || printf '\n%s\n' "$1"; }
[ -t 1 ] || head2() { printf '\n%s\n' "$1"; }

# --- frontmatter helpers ------------------------------------------------------------
fm() { sed -n "s/^$2:[[:space:]]*//p" "$1" 2>/dev/null | head -n1 | sed 's/^"//; s/"$//'; }
# `paths:` is a YAML list on the following lines, not an inline value.
fm_paths() {
  awk '/^paths:/{f=1;next}
       f && /^---[[:space:]]*$/ { exit }
       f && /^[[:space:]]*-/ { sub(/^[[:space:]]*-[[:space:]]*/,""); gsub(/"/,""); printf "%s ", $0; next }
       f && /^[^[:space:]-]/ { exit }' "$1" 2>/dev/null
}
desc_for() { if [ -n "$FILTER" ]; then printf '%s' "$1"; else first_sentence "$1"; fi; }
first_sentence() { printf '%s' "$1" | sed 's/\([.!?]\) .*/\1/'; }
matches() { [ -z "$FILTER" ] && return 0; printf '%s %s' "$1" "$2" | grep -qi -- "$FILTER"; }

jqr() { command -v jq >/dev/null 2>&1 && jq -r "$1" "$2" 2>/dev/null; }

say "Harness — what this configuration gives you"
say "Config root: $ROOT"
[ -n "$FILTER" ] && say "Filter: '$FILTER'"

# --- 1. skills ----------------------------------------------------------------------
manual="" ; auto=""
for f in "$ROOT"/skills/*/SKILL.md; do
  [ -e "$f" ] || continue
  n="$(fm "$f" name)"; [ -n "$n" ] || n="$(basename "$(dirname "$f")")"
  d="$(fm "$f" description)"
  matches "$n" "$d" || continue
  if grep -q '^disable-model-invocation:[[:space:]]*true' "$f"; then
    manual="$manual$n|$d"$'\n'
  else
    auto="$auto$n|$d"$'\n'
  fi
done

if [ -n "$manual" ]; then
  head2 "YOU INVOKE THESE (never run on their own)"
  printf '%s' "$manual" | while IFS='|' read -r n d; do
    [ -n "$n" ] || continue
    say "  /$n"
    wrap "      $(desc_for "$d")"
  done
fi

if [ -n "$auto" ]; then
  head2 "THESE TRIGGER THEMSELVES (or call them with /name)"
  printf '%s' "$auto" | while IFS='|' read -r n d; do
    [ -n "$n" ] || continue
    say "  /$n"
    wrap "      $(desc_for "$d")"
  done
fi

# --- 2. subagents --------------------------------------------------------------------
agents=""
for f in "$ROOT"/agents/*.md; do
  [ -e "$f" ] || continue
  n="$(fm "$f" name)"; d="$(fm "$f" description)"; m="$(fm "$f" model)"
  matches "$n" "$d" || continue
  agents="$agents$n|$m|$d"$'\n'
done
if [ -n "$agents" ]; then
  head2 "SUBAGENTS (run in their own context, keep noise out of yours)"
  printf '%s' "$agents" | while IFS='|' read -r n m d; do
    [ -n "$n" ] || continue
    say "  $n  [$m]"
    wrap "      $(first_sentence "$d")"
  done
fi

# --- 3. rules ------------------------------------------------------------------------
rules=""
for f in "$ROOT"/rules/*.md; do
  [ -e "$f" ] || continue
  n="$(basename "$f" .md)"; p="$(fm_paths "$f")"
  matches "$n" "$p" || continue
  rules="$rules$n|$p"$'\n'
done
if [ -n "$rules" ]; then
  head2 "PER-LANGUAGE RULES (load only when you touch a matching file)"
  printf '%s' "$rules" | while IFS='|' read -r n p; do
    [ -n "$n" ] || continue
    printf '  %-12s %s\n' "$n" "$p"
  done
fi

# --- 4. guards ------------------------------------------------------------------------
S="$ROOT/settings.json"
if [ -f "$S" ] && [ -z "$FILTER" ]; then
  head2 "GUARDS THAT RUN SILENTLY (deterministic, no model involved)"
  # shellcheck disable=SC2016  # jq program: $e is a jq variable, not a shell one
  jqr '.hooks | to_entries[] | .key as $e | .value[] | .hooks[] | "\(.command | capture("(?<n>[a-z-]+)\\.(sh|ps1)").n)|\($e)"' "$S" \
    | sort -u | while IFS='|' read -r hn he; do printf '  %-22s on %s\n' "$hn" "$he"; done
  say ""
  say "  Denied outright: secrets and keys (.env*, *.pem, ~/.ssh, ~/.aws), edits to .git/**"
  say "  and lockfiles, rm -rf, force push, kubectl delete, DROP DATABASE/TABLE."
  net="$(jqr '.sandbox.network.allowedDomains | length' "$S")"
  if [ -n "$net" ] && [ "$net" != "0" ] && [ "$net" != "null" ]; then
    say "  Sandbox on: network limited to $net package-registry domains."
  fi
fi

# --- 5. plugins -----------------------------------------------------------------------
if [ -f "$S" ] && [ -z "$FILTER" ]; then
  on="$(jqr '[.enabledPlugins | to_entries[] | select(.value) | .key] | join(", ")' "$S")"
  off="$(jqr '[.enabledPlugins | to_entries[] | select(.value | not) | .key] | length' "$S")"
  head2 "PLUGINS"
  if [ -n "$on" ] && [ "$on" != "" ]; then
    wrap "  Enabled globally: $on"
  else
    say "  Nothing is enabled globally — by design. A plugin loaded where it does not apply"
    say "  is pure context cost."
  fi
  say "  $off installed and off, waiting to be enabled per project in .claude/settings.json."
  say "  Run /setup-project in a repo and it maps that stack to the plugins it needs."
fi

# --- 6. how to drive it ----------------------------------------------------------------
if [ -z "$FILTER" ]; then
  head2 "DAY TO DAY"
  say "  /harness <term>     detail for one entry (e.g. /harness setup)"
  say "  /setup-project      configure or audit a repo's agent config"
  say "  /doctor             diagnose the installation and rightsize instructions"
  say "  /context            what the current session is actually paying for"
  say "  /usage              which skills and plugins earn their tokens over time"

  head2 "WHAT WORKS OUTSIDE CLAUDE CODE"
  say "  AGENTS.md           read natively by Codex and Antigravity; Claude Code reads the"
  say "                      thin CLAUDE.md that imports it. One source, every agent."
  say "  Skills              this same SKILL.md format works in all three; projects expose"
  say "                      them through the .agents/skills symlink."
  say "  Guards              one script, three dialects — Claude Code and Codex share a"
  say "                      contract, Antigravity gets its own reply shape."
  say "  Permissions         Claude Code only. Each CLI has its own model; nothing is faked."
  say ""
  say "  This catalogue is generated from the files above — it cannot go stale."
fi
