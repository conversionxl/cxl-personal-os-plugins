#!/usr/bin/env bash
# Builds dist/personal-os.zip, the file to upload in Settings -> Plugins.
# The ZIP has .claude-plugin/plugin.json at its root, which is what the upload
# check expects. GitHub's own "Download ZIP" wraps everything in a
# cxl-personal-os-plugins-main/ folder, so the manifest is one level down and
# the upload fails with "The archive must contain a .claude-plugin/plugin.json".
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dist="$root/dist"
rm -rf "$dist"
mkdir -p "$dist"

[ -f "$root/.claude-plugin/plugin.json" ] || { echo "missing .claude-plugin/plugin.json" >&2; exit 1; }
len=$(jq -r '.description | length' "$root/.claude-plugin/plugin.json")
[ "$len" -le 500 ] || { echo "plugin.json description is $len characters; the upload allows 500" >&2; exit 1; }

cd "$root"
zip -qr "$dist/personal-os.zip" . \
  -x '.git/*' '.github/*' 'dist/*' 'scripts/build-zip.sh' '.DS_Store' '*/.DS_Store'
echo "built dist/personal-os.zip"
