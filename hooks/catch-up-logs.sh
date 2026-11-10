#!/usr/bin/env bash
# SessionStart hook: backfill daily logs for past days that have transcripts but
# no log. SessionEnd never fires when the process is killed (editor closed,
# crash, sleep), so those days would otherwise stay blank. Runs detached and
# prints nothing: SessionStart stdout is injected into the model's context.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib-valid-log.sh"
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0

input="$(cat)"
transcript="$(json_field "$input" transcript_path)"
if [ -n "$transcript" ]; then
  txdir="$(dirname "$transcript")"
else
  txdir="$HOME/.claude/projects/$(printf '%s' "$CLAUDE_PROJECT_DIR" | sed 's#[/\:]#-#g')"
fi
[ -d "$txdir" ] || exit 0

detach bash "$SCRIPT_DIR/catch-up-logs-run.sh" "$txdir" "$CLAUDE_PROJECT_DIR"
exit 0
