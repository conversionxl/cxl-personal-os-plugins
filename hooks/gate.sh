#!/usr/bin/env bash
# Runs a personal OS hook only in a folder that /personal-os:setup has set up.
# The plugin is installed once per user, so without this gate every hook would
# fire in every folder you open, writing daily logs into unrelated projects.
# The marker is .claude/personal-os.json, written by scripts/setup.sh.
# A folder cloned from a starter repo runs its own copies of these hooks from
# .claude/hooks/. The plugin stands down there, even with the marker, so the
# day never gets two daily logs.
# On Windows CLAUDE_PROJECT_DIR is a C:\ path; test it in Git Bash form, but
# leave the variable itself alone, because catch-up-logs.sh derives the
# transcript folder name from the Windows form.
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0
dir="$CLAUDE_PROJECT_DIR"
command -v cygpath >/dev/null 2>&1 && dir="$(cygpath -u "$dir" 2>/dev/null || printf '%s' "$dir")"
[ -f "$dir/.claude/personal-os.json" ] || exit 0
[ -f "$dir/.claude/hooks/auto-shutdown.sh" ] && exit 0
exec bash "$(dirname "${BASH_SOURCE[0]}")/$1"
