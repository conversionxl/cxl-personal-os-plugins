#!/usr/bin/env bash
# Folder map. A user can keep their own folder names (PROJECTS/ instead of
# projects/, Resources/ instead of wiki/) by listing them in
# .claude/folders.json. Every hook and setup script asks for a folder through
# these functions; a missing file or key means the standard folder. Shared by
# every CXL AI Native cohort repo and plugin: keep the copies identical.
# Written for bash 3.2 (macOS default): no associative arrays.

# key:standard-path. Nested keys come first, so the longest prefix wins in
# pos_map_path. A nested key that is not mapped follows its parent: with
# raw mapped to Inbox, voc defaults to Inbox/voc.
POS_KEYS="brand-wiki:wiki/brand voc:raw/voc brand-inputs:raw/brand strategy:raw/strategy performance:raw/performance campaign-inputs:raw/campaigns campaigns:projects/campaigns projects:projects raw:raw wiki:wiki drafts:drafts frameworks:frameworks daily-logs:daily-logs team-updates:team-updates"

# pos_std <key>: the standard path for a key, or nothing for an unknown key.
pos_std() {
  local pair
  for pair in $POS_KEYS; do
    [ "${pair%%:*}" = "$1" ] && { printf '%s' "${pair#*:}"; return; }
  done
}

# pos_get <root> <key>: the mapped value as written, or nothing. Values must be
# relative paths inside the folder; anything else is ignored.
pos_get() {
  local map="$1/.claude/folders.json" v=""
  [ -f "$map" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    v="$(jq -r --arg k "$2" '.[$k] // empty | strings' "$map" 2>/dev/null | tr -d '\r')"
  else
    v="$(sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$map" | head -1 | tr -d '\r')"
  fi
  v="${v#./}"; v="${v%/}"
  case "$v" in /*|*..*|*\\*|[A-Za-z]:*) v="" ;; esac
  printf '%s' "$v"
}

# pos_rel <root> <key>: the folder's path relative to <root>.
pos_rel() {
  local v std
  v="$(pos_get "$1" "$2")"
  if [ -z "$v" ]; then
    std="$(pos_std "$2")"
    [ -n "$std" ] || std="$2"
    case "$std" in
      */*) v="$(pos_rel "$1" "${std%%/*}")/${std#*/}" ;;
      *) v="$std" ;;
    esac
  fi
  printf '%s' "$v"
}

# pos_dir <root> <key>: the folder's absolute path.
pos_dir() { printf '%s/%s' "$1" "$(pos_rel "$1" "$2")"; }

# pos_map_path <root> <standard relative path>: the same path under the map,
# for example projects/_template.md -> PROJECTS/_template.md.
pos_map_path() {
  local pair std
  for pair in $POS_KEYS; do
    std="${pair#*:}"
    case "$2" in
      "$std"|"$std"/*) printf '%s%s' "$(pos_rel "$1" "${pair%%:*}")" "${2#"$std"}"; return ;;
    esac
  done
  printf '%s' "$2"
}
