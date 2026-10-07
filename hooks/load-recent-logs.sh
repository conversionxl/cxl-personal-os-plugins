#!/usr/bin/env bash
# SessionStart hook: inject the 2 most recent daily logs so each session starts
# with continuity. Stdout is added to the session context.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib-valid-log.sh"

# After a compaction the logs are already in the summary; restore-state.sh
# handles that case instead.
input="$(cat)"
[ "$(json_field "$input" source)" = "compact" ] && exit 0

. "$(dirname "${BASH_SOURCE[0]}")/lib-folders.sh"
DIR="$(pos_dir "$CLAUDE_PROJECT_DIR" daily-logs)"
[ -d "$DIR" ] || exit 0
# Dated logs only. lint-exceptions.md and the *-lint.md reports would otherwise
# sort into the "two most recent" slots and push a real log out.
files="$(ls "$DIR"/[0-9]*.md 2>/dev/null | grep -v -- '-lint\.md$' | sort | tail -2)"
[ -z "$files" ] && exit 0

echo "## Recent daily logs (auto-loaded at session start)"
echo
while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "### $(basename "$f")"
  cat "$f"
  echo
done <<< "$files"
