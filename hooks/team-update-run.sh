#!/usr/bin/env bash
# Detached worker for team-update.sh. Builds last week's team update from the
# daily logs via headless Claude. Never overwrites an existing update: if you
# already ran /personal-os:team-update for that week, this does nothing.
set -u
VAULT="$1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-valid-log.sh"
. "$HERE/lib-folders.sh"
cd "$VAULT" || exit 0
logs="$(pos_rel . daily-logs)"
updates="$(pos_rel . team-updates)"

CLAUDE_BIN="$(claude_bin)"; [ -n "$CLAUDE_BIN" ] || exit 0

# Portable date math: BSD/macOS first, then GNU.
date_add() {  # $1 = YYYY-MM-DD, $2 = days (signed)
  # BSD -v needs an explicit sign: -v3d SETS the day to 3, -v+3d adds three.
  local n="$2"; case "$n" in -*|+*) ;; *) n="+$n" ;; esac
  date -j -v"${n}d" -f %F "$1" +%F 2>/dev/null || date -d "$1 $n days" +%F 2>/dev/null
}
dow() {  # 1 = Monday ... 7 = Sunday
  date -j -f %F "$1" +%u 2>/dev/null || date -d "$1" +%u 2>/dev/null
}

today="$(date +%F)"
this_monday="$(date_add "$today" "-$(( $(dow "$today") - 1 ))")"
monday="$(date_add "$this_monday" -7)"
[ -n "$monday" ] || exit 0
out="$updates/week-of-$monday.md"
[ -e "$out" ] && exit 0

src="$(mktemp)"; tmp="$(mktemp)"
trap 'rm -f "$src" "$tmp"' EXIT
for i in 0 1 2 3 4 5 6; do
  cat "$logs"/"$(date_add "$monday" "$i")"*.md 2>/dev/null
done > "$src"
[ -s "$src" ] || exit 0

{
  cat "$HERE/team-update-prompt.md"
  printf '\n\nPeriod: week of %s (Monday to Sunday).\n\n=== DAILY LOGS ===\n' "$monday"
  cat "$src"
} | CC_AUTO_SHUTDOWN=1 "$CLAUDE_BIN" -p --model sonnet > "$tmp" 2>/dev/null

[ -s "$tmp" ] || exit 0
grep -q '^NO_UPDATE' "$tmp" && exit 0
grep -q '^## ' "$tmp" || exit 0
strip_em_dashes "$tmp"
redact_emails "$tmp"
mkdir -p "$updates"
[ -e "$out" ] || mv "$tmp" "$out"
exit 0
