#!/usr/bin/env bash
# Builds a personal OS in the target folder (default: the current folder).
# Copies the template without overwriting anything that already exists, writes
# the marker that switches the hooks on, and makes the folder a git repo.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$PWD}"
cd "$TARGET"

# A folder map (.claude/folders.json, written by the "Your own folders" step
# before this script runs) sends each template file to the user's own folder.
. "$ROOT/hooks/lib-folders.sh"

created=0; kept=0
while IFS= read -r -d '' src; do
  rel="$(pos_map_path "$PWD" "${src#"$ROOT/template/"}")"
  if [ -e "$rel" ]; then kept=$((kept+1)); continue; fi
  mkdir -p "$(dirname "$rel")"
  cp "$src" "$rel"
  created=$((created+1))
done < <(find "$ROOT/template" -type f -print0)
chmod +x .claude/link-memory.sh 2>/dev/null || true

version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -1)"
if [ ! -f .claude/personal-os.json ]; then
  printf '{\n  "plugin": "personal-os",\n  "version": "%s",\n  "created": "%s"\n}\n' "$version" "$(date +%Y-%m-%d)" > .claude/personal-os.json
  created=$((created+1))
fi

if [ -f .claude/folders.json ]; then
  map_gi="$(bash "$ROOT/hooks/folder-map.sh" gitignore "$PWD")"
  map_cm="$(bash "$ROOT/hooks/folder-map.sh" claude-md "$PWD")"
fi

git_state="git not installed"
if command -v git >/dev/null 2>&1; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_state="already a git repo"
  else
    git init -q -b main 2>/dev/null || git init -q
    git add -A
    if git commit -q -m "Personal OS from the personal-os plugin" 2>/dev/null; then
      git_state="new git repo, first commit made"
    else
      git_state="new git repo, not committed (set git user.name and user.email first)"
    fi
  fi
fi

echo "Folder: $TARGET"
echo "Files created: $created. Existing files kept: $kept."
echo "Git: $git_state"
[ -n "${map_gi:-}" ] && echo "$map_gi"
[ -n "${map_cm:-}" ] && echo "$map_cm"
