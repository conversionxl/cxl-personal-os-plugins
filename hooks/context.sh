#!/usr/bin/env bash
# SessionStart: tell the session which plugin version is loaded and where it
# lives, so /personal-os:setup can find its template. In a folder that is set
# up, also carry the rule for writing inside .claude/, because CLAUDE.md in
# folders set up before that rule existed does not have it. Also prints the
# folder map, and finds the brand brain under its mapped name.
[ -n "$CC_AUTO_SHUTDOWN" ] && exit 0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -1)"
printf 'personal-os plugin %s, root: `%s`\n' "$version" "$ROOT"
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0
dir="$CLAUDE_PROJECT_DIR"
command -v cygpath >/dev/null 2>&1 && dir="$(cygpath -u "$dir" 2>/dev/null || printf '%s' "$dir")"
[ -f "$dir/.claude/personal-os.json" ] || exit 0
cat <<'RULE'

**Writing inside `.claude/`** (memory, your own skills and commands): use the shell, for example a heredoc, not the file-edit tools. In Cowork the file tools cannot write inside `.claude/`, while the shell on the user's computer can once it has started. If the shell is not ready, wait for it and retry. Never save memory anywhere except `.claude/memory/`, and never suggest moving it.
RULE
map="$(bash "$(dirname "${BASH_SOURCE[0]}")/folder-map.sh" context "$dir" </dev/null)"
[ -n "$map" ] && printf '\n%s\n' "$map"
. "$(dirname "${BASH_SOURCE[0]}")/lib-folders.sh"
brand="$(pos_rel "$dir" brand-wiki)"
if [ -d "$dir/$brand" ]; then
  printf '\n%s\n' "**Brand brain.** \`$brand/\` is this folder's tone of voice, messaging and positioning documentation. Read it before writing anything customer-facing: \`icp.md\` for who, \`positioning-messaging.md\` for what to say, \`voice-guide.md\` and \`vocabulary.md\` for how to say it. It outranks any other voice or style note in this folder."
fi
