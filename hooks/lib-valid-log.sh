#!/usr/bin/env bash
# Shared validity predicate for generated daily logs.
#
# The headless worker that writes daily logs can fail in ways that still produce
# output: an API error string, a truncated response, a refusal. A plain
# non-empty check accepts all of those, and once a bad file lands the catch-up
# hook treats the day as handled and never revisits it. So the day is lost.
# Both log hooks route their output through is_valid_log before it reaches disk.
#
# Source this file, then call: is_valid_log <file>

# A log is valid only if it has the section heading the generator prompt
# mandates and enough body to be worth keeping.
LOG_MIN_LINES=10

# Max characters kept per string when a transcript is fed to the generator.
# Both log hooks truncate to this. A heavy day (large file reads, big tool
# results) can otherwise overflow the model's context, and the failed run leaves
# no log, which is indistinguishable on disk from a day with no work in it.
LOG_STR_CAP=1200

is_valid_log() {
  f="$1"
  [ -s "$f" ] || return 1
  grep -q '^## Session Summary' "$f" 2>/dev/null || return 1
  [ "$(wc -l < "$f" 2>/dev/null || echo 0)" -ge "$LOG_MIN_LINES" ] || return 1
  return 0
}

# Does a transcript slice contain any turn the user actually typed?
#
# The SessionEnd hook only ever sees its own transcript. A session that opened
# and closed without a prompt (an editor window reopened, a connector check, a
# crashed session relaunched) therefore generated a log saying no work was
# captured, and that log is well formed, so is_valid_log accepts it and catch-up
# treats the day as handled and never revisits it. If the sessions that did the
# work were killed rather than closed, a whole day reads as "nothing happened".
#
# So: a session with no user turns must not write the day's log. Leaving the day
# blank is recoverable, because catch-up merges every transcript for a date.
#
# Hook-injected and tool-result messages carry .type == "user" too, so counting
# user messages alone would accept exactly the empty sessions this rejects. Only
# plain text content authored in the prompt counts. Without jq, return true: the
# old behavior is wrong but it is not this function's job to suppress logs on a
# machine where the question cannot be asked.
has_user_turns() {  # $1 = transcript slice (JSONL)
  # Locals: the other predicates here assign a bare `f`, which silently clobbers
  # a caller's loop variable. Not worth changing those now, worth not adding to.
  local _f="$1" _n
  [ -s "$_f" ] || return 1
  command -v jq >/dev/null 2>&1 || return 0
  _n="$(jq -r '
    select(.type == "user")
    | select((.isMeta // false) | not)
    | .message.content
    | if type == "string" then .
      elif type == "array" then (map(select(.type? == "text") | .text) | join(""))
      else "" end
    | select(test("[^[:space:]]"))
    | select(test("^<(system-reminder|command-message|command-name|local-command)") | not)
  ' "$_f" 2>/dev/null | grep -c . )"
  [ "${_n:-0}" -ge 1 ]
}

# Minimum lines for a file to read as human-authored content rather than a
# failed generator call. Deliberately low: an API error string or a refusal is
# a line or two of prose with no markdown heading, and the heading check below
# is the load-bearing part of this predicate.
CONTENT_MIN_LINES=3

# Is there anything here worth keeping? This is a DIFFERENT question from
# is_valid_log, and conflating the two was routine data loss.
#
# is_valid_log asks whether the generator produced well-formed output, and is
# correct for that job. But hand-authored logs are also written to these files:
# a note you typed into today's log by hand, or an interrupted /personal-os:shutdown,
# leaves content without that heading. Those legitimately have no
# "## Session Summary" heading, so is_valid_log rejects them, and both log
# hooks then treated "not a well-formed generated log" as "safe to destroy".
# Nothing errors when that happens, so the loss goes unnoticed.
#
# Callers that are about to overwrite or quarantine an EXISTING file must use
# this predicate. Only the generator's own fresh output should be judged by
# is_valid_log.
has_content() {
  f="$1"
  [ -s "$f" ] || return 1
  grep -q '^#' "$f" 2>/dev/null || return 1
  [ "$(wc -l < "$f" 2>/dev/null || echo 0)" -ge "$CONTENT_MIN_LINES" ] || return 1
  return 0
}

# Move a bad log out of the way instead of deleting it, per the repo rule
# against silently destroying notes. Quarantined files sit in a dot-folder so
# Obsidian hides them, and the day reads as missing so catch-up regenerates it.
quarantine_log() {
  f="$1"
  [ -e "$f" ] || return 0
  qdir="$(dirname "$f")/.quarantine"
  mkdir -p "$qdir" || return 1
  mv "$f" "$qdir/$(basename "$f").$(date +%Y%m%d%H%M%S).bad" 2>/dev/null
}

# Extract a top-level string field from hook JSON input. jq when available,
# otherwise a sed fallback, so the cheap hooks still work on machines without jq.
json_field() {  # $1 = json, $2 = key
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r --arg k "$2" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
  fi
}

# Replace em dashes in a file. The generator prompt bans them and models still
# emit them, so this is enforcement rather than a request. `sed -i.bak` is the
# one in-place form that works on both GNU (Linux, Git Bash) and BSD (macOS)
# sed; the old `sed -i ''` failed silently on Windows and left every dash in.
strip_em_dashes() {  # $1 = file
  LC_ALL=en_US.UTF-8 sed -i.bak \
    -e 's/ — \([^—]*\) — /, \1, /g' \
    -e 's/ — /: /g' \
    -e 's/—/, /g' "$1" 2>/dev/null && rm -f "$1.bak"
  return 0
}

# Redact every email address. The generator prompt already bans them, and
# models still write them into logs sometimes. A prompt rule is a request, this
# is enforcement. Daily logs are committed to git, and once an address lands in
# history it stays there, so a log never keeps one.
redact_emails() {  # $1 = file
  LC_ALL=en_US.UTF-8 sed -i.bak -E \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[redacted email]/g' "$1" 2>/dev/null && rm -f "$1.bak"
  return 0
}

# Portable detach: setsid (Linux/WSL), nohup (macOS/Git Bash), bare subshell.
detach() {
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >/dev/null 2>&1 </dev/null &
  elif command -v nohup >/dev/null 2>&1; then
    nohup "$@" >/dev/null 2>&1 </dev/null &
  else
    ( "$@" >/dev/null 2>&1 </dev/null & )
  fi
  disown 2>/dev/null || true
}

claude_bin() {
  command -v claude 2>/dev/null && return
  # Native installer location; on Windows the binary is claude.exe.
  for c in "$HOME/.local/bin/claude" "$HOME/.local/bin/claude.exe"; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  return 1
}
