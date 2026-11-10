#!/usr/bin/env bash
# SessionStart hook: after a compaction, re-inject the snapshot that
# preserve-state.sh wrote. Stdout is added to the session context.
#
# No matcher is set in settings.json; this script gates on the `source` field
# itself, so it is a no-op on startup, resume, and clear.

[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
source_kind="$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null)"
session="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"

[ "$source_kind" = "compact" ] || exit 0

STATE_DIR="$CLAUDE_PROJECT_DIR/.claude/state"
[ -d "$STATE_DIR" ] || exit 0

snapshot="$STATE_DIR/compact-$session.md"

# Fallback: if the session id changed across compaction, take the newest
# snapshot written in the last 15 minutes. Older ones belong to other sessions,
# so never fall back to them.
if [ ! -f "$snapshot" ]; then
  snapshot="$(find "$STATE_DIR" -name 'compact-*.md' -type f -mmin -15 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -1)"
fi

[ -n "$snapshot" ] && [ -f "$snapshot" ] || exit 0
cat "$snapshot"
