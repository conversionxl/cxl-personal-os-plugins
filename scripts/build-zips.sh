#!/usr/bin/env bash
# Builds one uploadable ZIP per plugin in this marketplace, into dist/.
# Each ZIP holds a single plugin with .claude-plugin/plugin.json at its root,
# which is what Settings -> Plugins -> Upload expects. The repository's own
# "Download ZIP" holds every plugin at once and fails that check.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dist="$root/dist"
rm -rf "$dist"
mkdir -p "$dist"

build() {
  local name="$1" dir="$2"
  [ -f "$root/$dir/.claude-plugin/plugin.json" ] || { echo "missing $dir/.claude-plugin/plugin.json" >&2; exit 1; }
  (cd "$root/$dir" && zip -qr "$dist/$name.zip" . -x 'tests/*' 'node_modules/*' '.DS_Store')
  echo "built dist/$name.zip"
}

build personal-os plugins/personal-os
build explorer mods/explorer
