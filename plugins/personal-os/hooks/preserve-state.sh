#!/usr/bin/env bash
# PreCompact hook: snapshot the state that compaction blurs, so restore-state.sh
# can re-inject it once the compacted session resumes.
#
# Runs synchronously and blocks compaction, so it stays pure jq: no LLM call.
# Deterministic signals only (verbatim prompts, files touched, git status).
#
# Assumes the transcript JSONL is append-only across a compaction. If a future
# compaction ever truncates it, this snapshot loses the pre-compact history.

[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"
session="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
trigger="$(printf '%s' "$input" | jq -r '.trigger // "auto"' 2>/dev/null)"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
[ -n "$session" ] || exit 0

VAULT="$CLAUDE_PROJECT_DIR"
STATE_DIR="$VAULT/.claude/state"
mkdir -p "$STATE_DIR"

# Drop snapshots older than 7 days so the directory doesn't accumulate.
find "$STATE_DIR" -name 'compact-*.md' -type f -mtime +7 -delete 2>/dev/null

out="$STATE_DIR/compact-$session.md"
tmp="$(mktemp)"

{
  echo "## Pre-compact state (restored)"
  echo
  echo "Snapshot taken at $(date '+%Y-%m-%d %H:%M') before a ${trigger} compaction."
  echo "This is the detail compaction summarizes away. Treat it as current session state."
  echo

  # --- Working file set: what was actually being changed, oldest first. ---
  files="$(jq -r 'select(.type=="assistant")
      | .message.content[]?
      | select(.type=="tool_use")
      | select(.name=="Edit" or .name=="Write" or .name=="NotebookEdit")
      | .input.file_path // empty' "$transcript" 2>/dev/null \
    | awk '!seen[$0]++' | tail -20)"

  if [ -n "$files" ]; then
    echo "### Files modified this session"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      echo "- ${p#$VAULT/}"
    done <<< "$files"
    echo
  fi

  # --- Verbatim user prompts: where decisions and corrections actually live. ---
  prompts="$(jq -r 'select(.type=="last-prompt") | .lastPrompt // empty' "$transcript" 2>/dev/null \
    | grep -v '^[[:space:]]*$' | awk '!seen[$0]++' | tail -12)"

  if [ -n "$prompts" ]; then
    echo "### User prompts this session, verbatim and in order"
    echo "Decisions, corrections, and constraints the user stated. These outrank any summary of them."
    echo
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      # Collapse newlines and cap length so one long paste can't dominate the snapshot.
      line="$(printf '%s' "$p" | tr '\n' ' ' | cut -c1-400)"
      echo "- $line"
    done <<< "$prompts"
    echo
  fi

  # --- Git state: cheap, and pins exactly which work is still uncommitted. ---
  if git -C "$VAULT" rev-parse --git-dir >/dev/null 2>&1; then
    branch="$(git -C "$VAULT" branch --show-current 2>/dev/null)"
    status="$(git -C "$VAULT" status --short 2>/dev/null | head -25)"
    echo "### Git state at compaction"
    echo "Branch: ${branch:-unknown}"
    if [ -n "$status" ]; then
      echo
      echo '```'
      printf '%s\n' "$status"
      echo '```'
    else
      echo "Working tree clean."
    fi
    echo
  fi
} > "$tmp"

if [ -s "$tmp" ]; then
  mv "$tmp" "$out"
else
  rm -f "$tmp"
fi
exit 0
