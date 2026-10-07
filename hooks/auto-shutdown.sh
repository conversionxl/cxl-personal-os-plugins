#!/usr/bin/env bash
# SessionEnd hook: write today's daily log from the session transcript in a
# detached process, so closing the session is never blocked by the model call.

# The headless `claude -p` child sets CC_AUTO_SHUTDOWN=1; without this guard its
# own SessionEnd would re-trigger the hook forever.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib-valid-log.sh"
. "$SCRIPT_DIR/lib-folders.sh"

input="$(cat)"
transcript="$(json_field "$input" transcript_path)"
[ -n "$transcript" ] || transcript="$(json_field "$input" transcript)"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0

today="$(date +%F)"
detach bash "$SCRIPT_DIR/auto-shutdown-run.sh" "$transcript" \
  "$(pos_dir "$CLAUDE_PROJECT_DIR" daily-logs)/$today-convo.md" "$SCRIPT_DIR/auto-shutdown-prompt.md" "$today"
exit 0
