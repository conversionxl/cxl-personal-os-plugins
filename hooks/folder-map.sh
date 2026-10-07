#!/usr/bin/env bash
# The folder map from the shell. Shared by every CXL AI Native cohort repo and
# plugin: keep the copies identical.
#   folder-map.sh context [root]    SessionStart: tell Claude which folders are renamed. Silent without a map.
#   folder-map.sh show [root]       Every slot, its folder here, whether it exists, and git status of local-only ones.
#   folder-map.sh gitignore [root]  Mirror .gitignore rules for standard folders onto their mapped folders.
#   folder-map.sh claude-md [root]  Add the folder-map rule to CLAUDE.md if it is missing.
# [root] defaults to $CLAUDE_PROJECT_DIR, then the current folder.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-folders.sh"
cmd="${1:-show}"
root="${2:-${CLAUDE_PROJECT_DIR:-$PWD}}"
command -v cygpath >/dev/null 2>&1 && root="$(cygpath -u "$root" 2>/dev/null || printf '%s' "$root")"
[ -d "$root" ] || exit 0
[ "$cmd" = context ] && [ ! -t 0 ] && cat >/dev/null

case "$cmd" in
context)
  [ -f "$root/.claude/folders.json" ] || exit 0
  rows=""
  for pair in $POS_KEYS; do
    # Only the slots the user mapped; nested folders follow their parent.
    [ -n "$(pos_get "$root" "${pair%%:*}")" ] || continue
    std="${pair#*:}"; rel="$(pos_rel "$root" "${pair%%:*}")"
    [ "$rel" = "$std" ] || rows="$rows| \`$std/\` | \`$rel/\` |
"
  done
  [ -n "$rows" ] || exit 0
  printf '## Folder map\n\nThis folder keeps some of its own folder names (`.claude/folders.json`). Wherever CLAUDE.md, a command, a skill or an agent names a standard folder, use the folder on the right instead, subfolders included. Folders not listed keep their standard names. `CLAUDE.md`, `AGENTS.md` and `.claude/` never move.\n\n| Standard | In this folder |\n|---|---|\n%s' "$rows"
  ;;
show)
  printf '| Slot | Standard | Here | Exists | Git |\n|---|---|---|---|---|\n'
  for pair in $POS_KEYS; do
    key="${pair%%:*}"; std="${pair#*:}"; rel="$(pos_rel "$root" "$key")"
    ex=no; [ -d "$root/$rel" ] && ex=yes
    g="-"
    if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git -C "$root" check-ignore -q "$rel/pos-probe" 2>/dev/null; then g=local-only; else g=committed; fi
    fi
    printf '| %s | `%s/` | `%s/` | %s | %s |\n' "$key" "$std" "$rel" "$ex" "$g"
  done
  ;;
gitignore)
  gi="$root/.gitignore"
  [ -f "$gi" ] || exit 0
  [ -f "$root/.claude/folders.json" ] || { echo "Folder map: none, .gitignore unchanged."; exit 0; }
  add=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in ""|"#"*) continue ;; esac
    neg=""; p="$line"
    case "$p" in "!"*) neg="!"; p="${p#!}" ;; esac
    p="${p#/}"
    case "$p" in */*) ;; *) continue ;; esac
    mapped="$(pos_map_path "$root" "$p")"
    [ "$mapped" = "$p" ] && continue
    new="$neg$mapped"
    grep -qxF -- "$new" "$gi" && continue
    case "
$add" in *"
$new
"*) continue ;; esac
    add="$add$new
"
  done < "$gi"
  if [ -n "$add" ]; then
    printf '\n# Folder map: the rules above, for the folders this repo renamed in .claude/folders.json.\n%s' "$add" >> "$gi"
    printf 'Folder map: .gitignore rules added for renamed folders:\n%s' "$add"
  else
    echo "Folder map: .gitignore already covers the renamed folders."
  fi
  ;;
claude-md)
  f="$root/CLAUDE.md"
  [ -f "$f" ] || exit 0
  grep -q 'folders\.json' "$f" && { echo "CLAUDE.md: folder-map rule already there."; exit 0; }
  printf '\n## Folder map\n\nIf `.claude/folders.json` exists, it maps the standard folders (projects, raw, wiki, drafts, frameworks, daily-logs, team-updates, and module folders such as wiki/brand or raw/voc) to the names this folder already uses. Every command, skill and agent uses the mapped folder wherever it names a standard one, subfolders included. `CLAUDE.md`, `AGENTS.md` and `.claude/` never move.\n' >> "$f"
  echo "CLAUDE.md: folder-map rule added."
  ;;
*) echo "usage: folder-map.sh context|show|gitignore|claude-md [root]" >&2; exit 2 ;;
esac
exit 0
