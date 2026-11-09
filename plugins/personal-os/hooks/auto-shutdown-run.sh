#!/usr/bin/env bash
# Detached worker: generates the daily log from the session transcript via
# headless Claude and writes it to daily-logs/<date>-convo.md (overwriting).

transcript="$1"
out="$2"
prompt_file="$3"
today="$4"

[ -f "$transcript" ] || exit 0
[ -f "$prompt_file" ] || exit 0
mkdir -p "$(dirname "$out")"

# shellcheck source=lib-valid-log.sh
. "$(dirname "$0")/lib-valid-log.sh"
# Fallback if an older copy of the lib is in play: an unset cap makes the jq
# call below fail, which would silently skip the log rather than write a big one.
: "${LOG_STR_CAP:=1200}"

CLAUDE_BIN="$(claude_bin)"
[ -n "$CLAUDE_BIN" ] || exit 0

# A session left open across midnight (or across a weekend) holds more than one
# day of work. Feed the model only the lines timestamped today: the earlier days
# are past dates with no log, so the catch-up hook backfills them one log per
# day on the next session start. Without this filter, days of earlier work get
# folded into today's log and their own days stay blank.
slice="$(mktemp)"
trap 'rm -f "$slice"' EXIT
if command -v jq >/dev/null 2>&1; then
  # Long strings are truncated for the same reason the catch-up hook truncates:
  # a heavy day can overflow the model's context, and a failed run writes no log.
  # Timestamps are UTC; $today is the local day, so compare local to local.
  jq -c --arg d "$today" --argjson cap "$LOG_STR_CAP" '
    def localday: (.timestamp // "") as $t | if $t == "" then "" else (try ($t | sub("\\.[0-9]+"; "") | fromdateiso8601 | strflocaltime("%Y-%m-%d")) catch $t[0:10]) end;
    select(localday == $d)
    | walk(if type == "string" and (length > $cap) then .[0:$cap] + "…[truncated]" else . end)
  ' "$transcript" > "$slice" 2>/dev/null
  # Nothing today means every message belongs to an earlier day (a session
  # closed just after midnight). Leave today unwritten so catch-up handles it.
  [ -s "$slice" ] || exit 0
else
  cp "$transcript" "$slice" 2>/dev/null || exit 0
fi

# A session that carried no prompt has nothing to report, and this hook cannot
# see the sessions that did: it only ever gets its own transcript. Writing from
# an empty slice produces a well-formed log saying no work was captured, which
# then blocks catch-up from ever backfilling the day. See has_user_turns.
has_user_turns "$slice" || exit 0

# A manual /personal-os:shutdown already writes a richer, interactive log for this session.
# When one ran and the day already has content, generating a second block here
# produces two near-duplicate logs for the same session, which makes the day hard to read. Both conditions are required: /personal-os:shutdown invoked but abandoned
# before writing leaves no log, and that day should still get an auto log.
# The pattern is deliberately loose: the transcript is JSON, so the slash may
# arrive as /personal-os:shutdown or as an escaped \/personal-os:shutdown depending on the encoder.
if grep -q 'command-name>[^<]*shutdown' "$slice" 2>/dev/null \
   && has_content "$out"; then
  exit 0
fi

tmp="$(mktemp)"
{
  cat "$prompt_file"
  printf "\n\nToday's date: %s\n\n=== SESSION TRANSCRIPT (JSONL, one message per line) ===\n" "$today"
  cat "$slice"
} | CC_AUTO_SHUTDOWN=1 "$CLAUDE_BIN" -p --no-session-persistence --model sonnet > "$tmp" 2>/dev/null

# Only keep the output if it is actually a log. A non-empty check is not enough:
# an API error string is non-empty, and writing it here would poison the day
# permanently (catch-up skips days that already have a file). Leaving the day
# unwritten is recoverable; a bad log is not.
if ! is_valid_log "$tmp"; then
  rm -f "$tmp"
  exit 0
fi

# The em dash ban is stated in auto-shutdown-prompt.md and the model still
# emits them. A prompt instruction is a
# request; this is enforcement. Colon where the dash introduces or labels,
# comma where it brackets an aside, which is the split the ban asks for.
# Bracketing pairs first, then the single introducing dash.
strip_em_dashes "$tmp"
# No email addresses in a tracked file. See redact_emails.
redact_emails "$tmp"

# Append rather than clobber when the day already has a log. A bare `mv` here
# meant the second session of any day silently destroyed the first session's
# log: this hook only ever sees its own transcript, so it cannot regenerate the
# earlier session's content. Two sessions in a day is normal, so that was
# routine data loss. Each session gets its own section instead.
#
# The gate is has_content, not is_valid_log. Gating on is_valid_log meant a
# hand-authored log (a manual note, a partial /personal-os:shutdown)
# failed the check and fell through to the `mv` below, which destroyed it.
# Anything with real content gets appended to, never replaced.
if has_content "$out"; then
  {
    printf '\n\n---\n\n# Session Log: %s (later session, closed %s)\n' "$today" "$(date +%H:%M)"
    # Drop the generated H1, the heading above replaces it.
    sed '1{/^# Session Log:/d;}' "$tmp"
  } >> "$out"
  rm -f "$tmp"
else
  mv "$tmp" "$out"
fi
