#!/usr/bin/env bash
# SessionStart hook: the failsafe for every other hook. It needs nothing but
# bash, so it still runs on a machine where jq or the claude CLI is missing,
# which is exactly when the other hooks fail silently (most often on Windows).
#
# 1. Writes .claude/state/hooks-heartbeat, so /personal-os:setup can prove hooks run at all.
#    No heartbeat after a session start means bash itself never ran the hooks.
# 2. If a dependency is missing, says so in the session context, so Claude
#    tells the user instead of the daily logs quietly never appearing.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
cat >/dev/null
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0

missing=""
command -v jq >/dev/null 2>&1 || missing="$missing jq"
command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ] || [ -x "$HOME/.local/bin/claude.exe" ] || missing="$missing claude-cli"

mkdir -p "$CLAUDE_PROJECT_DIR/.claude/state" 2>/dev/null
printf 'last_run=%s\nos=%s\nmissing=%s\n' "$(date +%F)" "$(uname -s 2>/dev/null)" "${missing# }" \
  > "$CLAUDE_PROJECT_DIR/.claude/state/hooks-heartbeat" 2>/dev/null

if [ -n "$missing" ]; then
  printf '## Personal OS: hooks degraded\n\nMissing on this machine:%s. Until it is installed, daily logs are NOT written automatically and recent logs are NOT loaded. Tell the user once, point them to `/personal-os:setup` to fix it, and follow the manual fallback in CLAUDE.md (read the newest daily logs yourself; remind them to run `/personal-os:shutdown` before ending the session).\n' "$missing"
fi
exit 0
