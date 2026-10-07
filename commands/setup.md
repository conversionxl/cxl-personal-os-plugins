---
description: Build your personal OS in the current folder (folders, CLAUDE.md, memory), switch on the automatic daily logs, then start the guided tour.
---

# /personal-os:setup

Set up a personal OS in the folder this session is working in.

1. **Check the folder.** List what is in it. If it already holds `.claude/personal-os.json`, say it is already set up and go straight to step 4. If it holds other files, say that nothing will be overwritten (existing files are kept) and ask whether to continue. An empty folder needs no question.
   **Their own folders first.** If the folder holds folders of their own, run step 2b of `<plugin root>/commands/start.md` ("Your own folders") now, before the script, so the personal OS files land in their folders instead of new standard ones.
2. **The plugin root** is `${CLAUDE_PLUGIN_ROOT}`. The session context also has a line starting `personal-os plugin` with the version and the same path.
3. **Run the setup script** and show its output:
   `bash "<plugin root>/scripts/setup.sh" "<this folder's absolute path>"`
   The script copies into the folders named in `.claude/folders.json` when there is one, mirrors the `.gitignore` rules onto them, and adds the folder-map rule to an existing `CLAUDE.md`.
   If bash is not available (Windows without Git Bash), say so, point to `winget install Git.Git`, and stop. On Windows, pass paths in the form bash accepts, such as `C:/Users/<name>/Documents/personal-os`.
4. **Hand over to the tour.** Tell the user, in bold, that daily logs switch on from the **next** session in this folder: "When we finish, close this session and start a new one here. That is when the automatic daily logs begin." **In Cowork** (the shell reports Linux and `CLAUDE_PROJECT_DIR` is empty), say instead that daily logs are not automatic there, because Cowork runs hooks in its own workspace, where this folder isn't: run `/personal-os:shutdown` at the end of each day, or use the Code tab (Environment: Local) for automatic logs. Then follow the instructions in `<plugin root>/commands/start.md` from step 1.
