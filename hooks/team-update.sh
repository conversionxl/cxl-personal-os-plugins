#!/usr/bin/env bash
# SessionStart hook: if last week has daily logs but no team update yet, write
# one in the background to team-updates/week-of-<monday>.md. Prints nothing and
# never blocks startup. /personal-os:team-update is the manual, reviewed version.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib-valid-log.sh"
. "$SCRIPT_DIR/lib-folders.sh"
cat >/dev/null
[ -n "$CLAUDE_PROJECT_DIR" ] && [ -d "$(pos_dir "$CLAUDE_PROJECT_DIR" daily-logs)" ] || exit 0
detach bash "$SCRIPT_DIR/team-update-run.sh" "$CLAUDE_PROJECT_DIR"
exit 0
