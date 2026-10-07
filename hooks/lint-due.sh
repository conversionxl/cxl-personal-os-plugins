#!/usr/bin/env bash
# SessionStart hook: if the weekly vault lint has lapsed, say so.
#
# /personal-os:lint is the vault's health check, but nothing schedules it, so it only runs
# when you happen to remember. A check that depends on being remembered is not
# a check. This closes the loop the cheap way: no model call, no cron, no cloud
# agent. It just reads the newest daily-logs/<date>-lint.md and, if it is older
# than the lint cadence, prints one line into session context.
#
# Deliberately quiet when the lint is current. A nudge that fires every session
# is noise, and noise gets muted.

# The headless daily-log worker sets this. It must not receive the nudge.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0

# Skip after a compaction, matching load-recent-logs.sh. Compaction fires under
# context pressure, and a housekeeping nudge is the last thing worth spending
# the reclaimed window on. It will fire again on the next real session start.
if command -v jq >/dev/null 2>&1; then
  src="$(cat | jq -r '.source // empty' 2>/dev/null)"
  [ "$src" = "compact" ] && exit 0
fi

VAULT="$CLAUDE_PROJECT_DIR"
[ -n "$VAULT" ] || exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib-folders.sh"
logdir="$(pos_dir "$VAULT" daily-logs)"
[ -d "$logdir" ] || exit 0

LINT_CADENCE_DAYS=7

# Portable YYYY-MM-DD -> epoch seconds (BSD/macOS first, then GNU).
to_epoch() {
  date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null
}

# Newest lint report, by the date in its filename rather than by mtime: mtime is
# unreliable (a clone, a copy, or a sync resets it).
newest="$(ls "$logdir"/*-lint.md 2>/dev/null | sed 's#.*/##' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-lint\.md$' | sort | tail -1)"

if [ -z "$newest" ]; then
  printf '## Vault lint\n\nNo lint report has ever been written. Run `/personal-os:lint` to establish a baseline for vault health.\n'
  exit 0
fi

last_date="${newest%-lint.md}"
last_epoch="$(to_epoch "$last_date")"
now_epoch="$(date +%s)"
[ -n "$last_epoch" ] || exit 0

days=$(( (now_epoch - last_epoch) / 86400 ))

if [ "$days" -gt "$LINT_CADENCE_DAYS" ]; then
  printf '## Vault lint\n\nThe last vault lint was %s (%s days ago), past its %s-day cadence. Vault health findings (contradictions, stale claims, projects overdue against their own cadence) are unverified as of now. Suggest running `/personal-os:lint`.\n' \
    "$last_date" "$days" "$LINT_CADENCE_DAYS"
fi

exit 0
