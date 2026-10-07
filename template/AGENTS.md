# AGENTS.md

This folder is a personal OS. **Read `CLAUDE.md` first and follow it.** It holds the owner's profile, the folder rules, and how they like to work. This file exists so tools other than Claude Code (Codex, GitHub Copilot, Cursor, Gemini CLI, Grok and others) find the same rules. Where the two disagree, `CLAUDE.md` wins.

## Folder names

If `.claude/folders.json` exists, it maps standard folders to the names this folder already uses (for example `{"projects": "PROJECTS"}`). Wherever `CLAUDE.md`, a routine or a skill names a standard folder (`projects/`, `raw/`, `wiki/`, `daily-logs/` and so on), use the mapped folder instead, subfolders included. A folder that is not listed keeps its standard name.

## If your tool does not run the hooks

In Claude Code, hooks load the two newest daily logs at the start of a session and write a new log when it ends. Most other tools do not run them, so do it by hand:

- **At the start of a session,** read the two newest dated files in `daily-logs/` and `.claude/memory/MEMORY.md` before starting work.
- **Before the session ends,** offer to run the shutdown routine. It writes today's log to `daily-logs/YYYY-MM-DD-convo.md`, using the local date.

## Commands

The routines come from the Claude plugin, so their files are not in this folder: `start`, `brief`, `ingest`, `shutdown`, `lint` and `team-update`. When the user names one ("run shutdown", "brief me on the Q4 launch"), fetch it from

`https://raw.githubusercontent.com/conversionxl/cxl-personal-os-plugins/main/commands/<name>.md`

and follow it step by step. Treat `$ARGUMENTS` as whatever the user added after the name, and skip anything that only applies inside Claude (the `/personal-os:` prefix, the plugin root). If you cannot fetch it, say so and ask the user to paste the file.

## Skills and memory

- Skills are in `.claude/skills/<name>/SKILL.md`. When a task matches a skill's description, read it and follow it.
- Standing facts are in `.claude/memory/`, indexed by `MEMORY.md`. Add a file there when the owner tells you something that stays true, and add one line to the index.

## Brand brain

**Brand brain.** If `wiki/brand/` exists, it is this folder's tone of voice, messaging and positioning documentation. Read it before writing anything customer-facing: `icp.md` for who, `positioning-messaging.md` for what to say, `voice-guide.md` and `vocabulary.md` for how to say it. It outranks any other voice or style note in this folder.
