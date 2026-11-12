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

# The upload applies the same 500-character limit to every command, skill and
# agent description, so check every Markdown file's frontmatter too.
python3 - "$root" <<'PY'
import os, re, sys
root, bad = sys.argv[1], []
for d, dirs, files in os.walk(root):
    dirs[:] = [x for x in dirs if x not in (".git", "node_modules", "dist")]
    for name in files:
        if not name.endswith(".md"):
            continue
        p = os.path.join(d, name)
        s = open(p, encoding="utf-8", errors="replace").read()
        m = re.match(r"---\n(.*?)\n---", s, re.S)
        if not m:
            continue
        v = re.search(r"^description:[ \t]*(.*?)(?=^[\w-]+:|\Z)", m.group(1), re.S | re.M)
        if not v:
            continue
        v = v.group(1).strip()
        if v[:1] in "\"'":
            v = v[1:-1]
        elif v[:1] in ">|":
            v = " ".join(v[1:].split())
        if len(v) > 500:
            bad.append(f"{os.path.relpath(p, root)}: {len(v)} characters")
if bad:
    print("Descriptions over the 500-character upload limit:", *bad, sep="\n  ", file=sys.stderr)
    sys.exit(1)
PY

cd "$root"
zip -qr "$dist/personal-os.zip" . \
  -x '.git/*' '.github/*' 'dist/*' 'scripts/build-zip.sh' '.DS_Store' '*/.DS_Store'
echo "built dist/personal-os.zip"
