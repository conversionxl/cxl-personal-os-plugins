#!/usr/bin/env bash
# Run once per machine, after cloning the repo.
#
# Claude Code keeps memory at ~/.claude/projects/<slugified-project-path>/memory,
# which is outside the repo, so memory does not travel between machines by default.
# This points that path at the tracked copy in the repo instead, so every machine
# reads and writes the same memory files.
#
# Works on macOS/Linux (symlink) and Windows Git Bash (directory junction: Git
# Bash's `ln -s` silently makes a copy instead of a link, so memory would drift).
#
# Idempotent: safe to re-run.

set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$REPO/.claude/memory"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) WINDOWS=1 ;;
  *) WINDOWS=0 ;;
esac

# Claude Code slugifies the project path by replacing every "/", "\" and ":" with "-".
if [ "$WINDOWS" = 1 ]; then
  WINPATH="$(cygpath -w "$REPO")"          # C:\Users\...\cxl-personal-os
  SLUG="$(printf '%s' "$WINPATH" | sed 's#[\\/:]#-#g')"
  # VS Code reports the drive letter in lowercase; the filesystem ignores case.
  SLUG="$(printf '%s' "${SLUG:0:1}" | tr 'A-Z' 'a-z')${SLUG:1}"
else
  SLUG="$(printf '%s' "$REPO" | sed 's|/|-|g')"
fi
TARGET="$HOME/.claude/projects/$SLUG/memory"

mkdir -p "$CANONICAL" "$(dirname "$TARGET")"

is_link() {
  if [ "$WINDOWS" = 1 ]; then
    [ -d "$TARGET" ] && [ -n "$(powershell.exe -NoProfile -Command "(Get-Item -LiteralPath '$(cygpath -w "$TARGET")' -Force).LinkType" 2>/dev/null | tr -d '
')" ]
  else
    [ -L "$TARGET" ]
  fi
}

if is_link; then
  echo "Memory already linked: $TARGET -> $CANONICAL"
  exit 0
fi

# A real directory here means this machine has unsynced memory. Never discard it:
# fold anything new into the repo copy, back it up, then link.
if [ -d "$TARGET" ]; then
  backup="$HOME/.claude/memory-backup-$(date +%Y%m%d-%H%M%S)"
  cp -R "$TARGET" "$backup"
  echo "Existing local memory backed up to: $backup"
  cp -Rn "$TARGET"/. "$CANONICAL"/ 2>/dev/null || true
  echo "Merged any machine-local memory files into $CANONICAL (existing repo files kept). Add them to MEMORY.md if they are not listed."
  rm -rf "$TARGET"
fi

if [ "$WINDOWS" = 1 ]; then
  powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '$(cygpath -w "$TARGET")' -Target '$(cygpath -w "$CANONICAL")' | Out-Null"
else
  ln -s "$CANONICAL" "$TARGET"
fi
echo "Linked: $TARGET -> $CANONICAL"
echo "Memory now travels with the repo."
