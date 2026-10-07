#!/usr/bin/env bash
# Detached worker: scans session transcripts and, for each PAST date that has
# transcripts but no daily-logs/<date>-convo.md, generates that log via headless
# Claude using the same prompt as the auto-shutdown hook. It never touches
# today's log (the live session writes that on a clean exit) and never
# overwrites an existing log. Dates are read per line, not per file, so a
# session left open across several days yields one log per day; multiple
# transcripts on the same date are merged in chronological order. Written for
# bash 3.2 (macOS default): no associative arrays.

txdir="$1"
VAULT="$2"
prompt="$(dirname "$0")/auto-shutdown-prompt.md"
. "$(dirname "$0")/lib-folders.sh"
logdir="$(pos_dir "$VAULT" daily-logs)"

[ -d "$txdir" ] || exit 0
[ -f "$prompt" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
mkdir -p "$logdir"

# shellcheck source=lib-valid-log.sh
. "$(dirname "$0")/lib-valid-log.sh"
# Fallback if an older copy of the lib is in play: an unset cap makes the jq
# call below fail, which would silently skip the log rather than write a big one.
: "${LOG_STR_CAP:=1200}"

CLAUDE_BIN="$(claude_bin)"
[ -n "$CLAUDE_BIN" ] || exit 0

today="$(date +%F)"
TAB="$(printf '\t')"

# Serialize concurrent runs (two sessions opening at once) with a lock dir. Kept
# outside the transcripts directory so it is never mistaken for session data. A
# lock older than 2 hours is presumed stale (the machine died mid-run) and is
# reclaimed, otherwise one crashed run would block backfill forever.
lock="$HOME/.claude/.catch-up-logs-$(printf '%s' "$VAULT" | tr '/' '-').lock"
if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +120 2>/dev/null)" ]; then
  rmdir "$lock" 2>/dev/null
fi
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT

# Index every transcript by every date it actually contains, as
# "<date>\t<first-timestamp-on-that-date>\t<file>", sorted so same-day sessions
# merge in chronological order.
#
# Bucketing by the file's first line alone was silent data loss: a session left
# open across midnight, a weekend, or several days holds all of that work in one
# transcript, and filing it under the day the session opened meant every later
# day looked like it had no transcript at all, so it was never a candidate for
# backfill and never got a log.
index="$(
  for f in "$txdir"/*.jsonl; do
    [ -f "$f" ] || continue
    # Transcript timestamps are UTC. Days are local days, the same clock as
    # today, or a late-evening session is filed under tomorrow. Where jq cannot
    # parse dates (some Windows builds), localday falls back to the UTC day.
    # No apostrophes in this comment: macOS bash 3.2 misparses them in here.
    jq -r 'def localday: (.timestamp // "") as $t | if $t == "" then "" else (try ($t | sub("\\.[0-9]+"; "") | fromdateiso8601 | strflocaltime("%Y-%m-%d")) catch $t[0:10]) end; select(.timestamp) | "\(localday)\t\(.timestamp)"' "$f" 2>/dev/null \
      | tr -d '\r' \
      | sort -t "$TAB" -k2,2 \
      | awk -F"$TAB" -v tab="$TAB" -v file="$f" '
          $1 != "" && $1 != prev { print $1 tab $2 tab file; prev = $1 }
        '
  done | sort -t "$TAB" -k2,2
)"
[ -n "$index" ] || exit 0

# Unique past dates (strictly before today) that have transcripts.
dates="$(printf '%s\n' "$index" | awk -F"$TAB" -v today="$today" '$1 < today {print $1}' | sort -u)"

# A log that exists but is not a log (an API error string, a truncated
# response) is worse than a missing one: it makes the day look handled forever.
# Quarantine those first so the backfill below treats them as missing. Today's
# log is swept too, even though it is never regenerated here, because the live
# session's SessionEnd will append to whatever survives this sweep.
#
# The gate is has_content, not is_valid_log. Sweeping on is_valid_log meant
# every hand-authored log was quarantined on the next SessionStart purely for
# lacking a "## Session Summary" heading, which destroyed hand-written notes. Only files that look like generator failures
# (no markdown heading at all) are quarantined now.
for f in "$logdir"/*-convo.md; do
  [ -f "$f" ] || continue
  has_content "$f" || quarantine_log "$f"
done

while IFS= read -r d; do
  [ -n "$d" ] || continue
  out="$logdir/$d-convo.md"
  # A day that already carries a generated summary is finished. A day holding
  # only hand-authored content (a manual note from a session that
  # never closed cleanly) still needs its work summarized, so it falls through
  # and the generated log is APPENDED below rather than replacing anything.
  [ -e "$out" ] && is_valid_log "$out" && continue

  tmp="$(mktemp)"
  {
    cat "$prompt"
    printf "\n\nToday's date: %s\n\n=== SESSION TRANSCRIPT (JSONL, one message per line) ===\n" "$d"
    # Feed only the lines belonging to this date. A multi-day transcript would
    # otherwise put the same four days of work into four identical logs.
    # Long strings (file dumps, tool results, pasted data) are truncated: a busy
    # day can exceed the model's context, and an over-long prompt returns no log
    # at all, which reads on disk exactly like a day where nothing happened.
    printf '%s\n' "$index" | awk -F"$TAB" -v dd="$d" '$1==dd {print $3}' | while IFS= read -r f; do
      jq -c --arg dd "$d" --argjson cap "$LOG_STR_CAP" '
        def localday: (.timestamp // "") as $t | if $t == "" then "" else (try ($t | sub("\\.[0-9]+"; "") | fromdateiso8601 | strflocaltime("%Y-%m-%d")) catch $t[0:10]) end;
        select(localday == $dd)
        | walk(if type == "string" and (length > $cap) then .[0:$cap] + "…[truncated]" else . end)
      ' "$f" 2>/dev/null
    done
  } | CC_AUTO_SHUTDOWN=1 "$CLAUDE_BIN" -p --model sonnet > "$tmp" 2>/dev/null

  # Write only if we got back a valid log. Where the day already holds
  # hand-authored content, append under its own heading so the existing
  # snapshot survives; otherwise take the file, provided nothing raced us to it.
  if ! is_valid_log "$tmp"; then
    rm -f "$tmp"
    continue
  fi
  strip_em_dashes "$tmp"
# No email addresses in a tracked file. See redact_emails.
redact_emails "$tmp"
  if has_content "$out"; then
    {
      printf '\n\n---\n\n# Session Log: %s (backfilled)\n' "$d"
      sed '1{/^# Session Log:/d;}' "$tmp"
    } >> "$out"
    rm -f "$tmp"
  elif [ ! -e "$out" ]; then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"
  fi
done <<< "$dates"
