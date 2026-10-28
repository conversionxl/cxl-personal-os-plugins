---
description: Build your personal OS in the current folder (folders, CLAUDE.md, memory), switch on the automatic daily logs, check your setup, tour the system, personalize it, and show your workshop path through the other modules. Run it again any time to re-check your setup and see your next step; add `tour` for the explanation only.
argument-hint: [tour]
---

# /personal-os:setup

The personal OS's home base. The first run builds the personal OS in the folder this session is working in, checks the tools, explains the system, personalizes it, and shows the workshop path. Later runs re-check the setup and show the workshop path. Keep each message short and skimmable; this is an onboarding, not a lecture. Pause where a step says to wait.

**Which run is this?**
- **`$ARGUMENTS` is `tour`:** give only the explanation in steps 6 and 7, then step 10. Change nothing.
- **Later run:** the folder already holds `.claude/personal-os.json`. Do steps 4 and 5, then step 10. If the "About me" section of `CLAUDE.md` is still empty, offer step 8 first.
- **First run:** every step, in order.

The plugin root is `${CLAUDE_PLUGIN_ROOT}`. The session context also has a line starting `personal-os plugin` with the version and the same path.

## 1. Check the folder

List what is in it. If it already holds `.claude/personal-os.json`, it is a later run (see above). If it holds `.claude/hooks/auto-shutdown.sh`, it is a personal OS cloned from a starter repo that runs its own hooks: say so, say nothing needs setting up (the plugin's hooks stay off there, so there is one daily log a day), and go to step 10. If it holds other files, say that nothing will be overwritten (existing files are kept) and ask whether to continue. An empty folder needs no question.

## 2. Your own folders

Skip this step if the user already answered it in this session, if `.claude/folders.json` exists (unless they asked to change it), or if the folder holds nothing beyond the personal OS itself.

Many people arrive with a system of their own: folders for projects, reference notes, an about-me file. They keep it. The personal OS reroutes to their folders instead of asking them to restructure.

1. **Look.** List the top-level folders and one level down. Anything that is not a standard personal OS folder is theirs.
2. **Match by purpose** and show one table: slot | standard folder | their folder | why. The slots: `projects` (one folder per piece of work), `raw` (inbox, dumps, unsorted), `wiki` (reference, resources, people, glossary), `drafts` (work in progress), `frameworks` (methods, playbooks, checklists, SOPs), `team-updates`. Module slots, only where the module is installed: `brand-wiki` (`wiki/brand/`), `voc` (`raw/voc/`), `brand-inputs` (`raw/brand/`), `strategy` (`raw/strategy/`), `performance` (`raw/performance/`), `campaign-inputs` (`raw/campaigns/`), `campaigns` (`projects/campaigns/`). A module slot that is not mapped follows its parent: with `raw` mapped to `Inbox`, `voc` is `Inbox/voc/`. Recommend keeping `daily-logs` as it is. A folder that fits no slot stays where it is; say so.
3. **Ask** in one line: reroute to your folders, or use the standard layout? Wait for the answer. Standard layout: skip the rest of this step.
4. **Write the map** to `.claude/folders.json` with the shell (a heredoc), only the slots that differ, keeping any keys already there. Values are paths relative to this folder:
   ```
   mkdir -p .claude && cat > .claude/folders.json <<'JSON'
   { "projects": "PROJECTS", "wiki": "RESOURCES" }
   JSON
   ```
5. **Wire it up** and show the output: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/folder-map.sh" gitignore` (local-only folders such as `raw/voc/` stay out of git under their new names), `bash "${CLAUDE_PLUGIN_ROOT}/hooks/folder-map.sh" claude-md` (adds the folder-map rule to an older `CLAUDE.md`), then `bash "${CLAUDE_PLUGIN_ROOT}/hooks/folder-map.sh" show`.
6. **Tidy the leftovers, on confirmation only.** A standard folder the map replaced that holds only what setup put there (its `README.md`, `projects/_template.md`) can go: propose moving `_template.md` into their projects folder and removing the rest. An about-me file in a subfolder (for example `ABOUT ME/CLAUDE.md`) loads only when Claude works in that folder, but it applies everywhere: offer to merge it into the About me section of the root `CLAUDE.md`. A subfolder `CLAUDE.md` with rules for that folder only stays where it is. `CLAUDE.md`, `AGENTS.md` and `.claude/` never move.

From here on, use the mapped folder names in every step and explanation.

## 3. Build it

Run the setup script and show its output:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" "<this folder's absolute path>"`
The script copies into the folders named in `.claude/folders.json` when there is one, mirrors the `.gitignore` rules onto them, and adds the folder-map rule to an existing `CLAUDE.md`.
If bash is not available (Windows without Git Bash), say so, point to `winget install Git.Git`, and stop. On Windows, pass paths in the form bash accepts, such as `C:/Users/<name>/Documents/personal-os`.

Then tell the user, in bold, that daily logs switch on from the **next** session in this folder: "When we finish, close this session and start a new one here. That is when the automatic daily logs begin." **In Cowork** (the shell reports Linux and `CLAUDE_PROJECT_DIR` is empty), say instead that daily logs are not automatic there, because Cowork runs hooks in its own workspace, where this folder isn't: run `/personal-os:shutdown` at the end of each day, or use the Code tab (Environment: Local) for automatic logs.

## 4. Check the setup

Run these checks and show the result as one table (item | status | fix if missing):

| Check | How | Why it matters |
|---|---|---|
| `git` | `git --version` | The repo is versioned and synced through git. |
| `jq` | `command -v jq` | Every hook needs it. Without it the daily logs never get written, and nothing errors. |
| `claude` CLI | `command -v claude` | The daily log and team update hooks call headless Claude. |
| `gh` (optional) | `gh auth status` | Only needed to push the repo to your own GitHub. |
| Memory link | Is `~/.claude/projects/<slug>/memory` a symlink to this repo's `.claude/memory`? The slug is the repo's absolute path with every `/` replaced by `-`. | Without it, memory stays machine-local. |
| Git remote | `git remote -v` | Optional. With no `origin`, the folder works on this machine only; see step 2. No git at all is allowed too. |
| Where Claude runs | The shell reports this folder, and `CLAUDE_PROJECT_DIR` is set (Code tab with Environment: Local, VS Code, or the terminal). | claude.ai in a browser cannot work on a folder, so nothing here would run. Cowork works, without automatic daily logs (see setup). |
| Hooks running | Read `.claude/state/hooks-heartbeat`. It should exist, with `last_run` = today and `missing=` empty. | The heartbeat is written by `health.sh`, which needs only bash. No file means hooks never ran this session. A `missing=` value names what to install. |

**Detect the OS first** (`uname -s`, or `$env:OS` / `ver` if bash is not available). On Windows, also check:
- **Git Bash**: `where bash` or `command -v bash`. Claude Code on Windows needs Git for Windows, and every hook is a bash script. Install: `winget install Git.Git`.
- **jq on the PATH that Git Bash sees**: `bash -c "command -v jq"`. Install: `winget install jqlang.jq`. winget adds it to PATH only for new processes, so **fully quit and reopen VS Code** afterwards, then re-run `/personal-os:setup`.
- If `winget` itself is missing (older Windows or a locked-down work laptop), give the manual route: download `jq-windows-amd64.exe` from https://jqlang.org/download/, rename it `jq.exe`, and put it in `C:\Program Files\Git\usr\bin`.

Install hints for anything missing: macOS `brew install jq gh`; Windows `winget install jqlang.jq GitHub.cli`; Linux via the package manager.

## 5. Fix what you can

- If memory is not linked, run `bash .claude/link-memory.sh` and show its output.
- If there is no `origin` (or it points at a CXL repo), explain that their daily logs, projects, and memory are private, so any GitHub copy should be **their own private repo**. Offer the commands, and run them only on a yes:
  ```
  gh repo create <name> --private --source . --remote origin --push
  ```
  (After `git remote remove origin`, if one exists. If they don't use `gh`, give the manual steps: create an empty private repo on GitHub, then `git remote set-url origin <url>` and `git push -u origin main`.)
- If they do not want GitHub, that is fine: everything works on one machine. Say in two lines what they give up (version history, sync across machines, and the git-based setups later in the cohort) and that they can add it later. Do not push them.
- Anything you cannot fix (a missing install), list it once with the command to run, and continue.

**If the hooks are not running and cannot be fixed now** (no admin rights, a locked-down laptop), switch the user to the manual fallback and say so plainly:
- Daily logs will not write themselves. Run `/personal-os:shutdown` at the end of every session; it writes the log without hooks.
- At the start of a session, Claude reads the newest logs itself (CLAUDE.md tells it to).
- The weekly team update will not write itself either. Run `/personal-os:team-update last-week` on Mondays.
Nothing else in the repo depends on hooks.

## 6. Explain how it works

Explain in this order, briefly, using a table or short bullets for each part. Read `CLAUDE.md` first so the explanation matches this repo exactly.

1. **The problem.** Claude starts every session with no memory of the last one. This repo gives it memory using plain Markdown files the user owns.
2. **Two kinds of memory.**
   - *Built-in memory* (`.claude/memory/`): a small set of standing facts, like preferences, key people, and where things live. Updated when Claude learns something durable.
   - *Daily logs* (`daily-logs/`): what happened each day, like work done, decisions, commitments, and what to pick up next. Written automatically.
   Memory answers "what is always true". Logs answer "where did we leave off".
3. **The folders.** Walk the folder table from `CLAUDE.md`: `projects/`, `raw/`, `daily-logs/`, `frameworks/`, `wiki/`, `drafts/`, `team-updates/`, and the `.claude/` folders (commands, skills, agents, hooks, memory). For each, give one line on what goes there and one example from marketing work (for example: "a pasted call transcript goes in `raw/`", "your campaign QA checklist goes in `frameworks/`").
4. **Projects come first.** Every command, skill, or agent they build later should serve a project. That is why the next step creates projects.

## 7. Explain the hooks and commands

**Hooks** run by themselves. Show the hooks table from `CLAUDE.md` and add the two things users usually miss:
- The daily log is written when the session **ends** (typing `/exit`, or closing the session cleanly). If the editor is killed instead, `catch-up-logs.sh` backfills that day the next time a session starts, so nothing is lost.
- `/personal-os:shutdown` is the richer, interactive version of the automatic log. When they run it, the automatic hook sees that and does not write a duplicate.

**Commands** are triggered by name. In Claude Code, type `/` and the name. The personal OS commands come from the plugin, so they start with `personal-os:`, in the Code tab and in Cowork alike. Commands they build themselves go in `.claude/commands/` and have no prefix. Show the commands table from `CLAUDE.md`, then suggest a rhythm:

| When | Run |
|---|---|
| Before a meeting | `/personal-os:brief <person or project>` |
| Whenever `raw/` fills up | `/personal-os:ingest` |
| End of day | `/personal-os:shutdown` |
| Once a week | `/personal-os:lint` and `/personal-os:team-update last-week` |

Finish this step with one line on the difference between the three kinds of building blocks they will create in the cohort:
- **Command**: a prompt you trigger by name, for a task you repeat.
- **Skill**: know-how Claude loads automatically when a task matches it.
- **Agent**: a specialist Claude hands a whole job to, with its own instructions and tools.

Point to the examples in `.claude/skills/` and `.claude/agents/`.

**If this is a `tour` run, go to step 10 now, then stop.**

## 8. Personalize

Ask these four questions in one message, and wait for the answers:

1. What's your name, role, and company?
2. What are you responsible for? What are you measured on?
3. What are the 2 to 5 projects taking most of your time right now?
4. How do you like to work with Claude? (For example: "be blunt", "always ask before writing", "keep it short".)

Then:
- Fill in the **About me** section of `CLAUDE.md` from answers 1, 2, and 4. Edit only that section.
- For each project in answer 3, propose a folder name and a one-line scope, as a numbered list. **Wait for confirmation.** Then create `projects/<name>/<name>.md` for each, from `projects/_template.md`, with the frontmatter filled in (`status: active`, a `cadence` they choose, a real `next_action`). Leave sections blank rather than inventing content.
- If Gmail, Google Calendar, or a project management connector is available in this session, offer to fill in the project files from what those tools show. Base every line on what the tools return, and say where it came from. If no connector is available, say so and skip.
- Save one memory file for anything durable they said about how they work, and add it to `.claude/memory/MEMORY.md`. Write both with the shell (a heredoc), not the file-edit tools: in Cowork the file tools cannot write inside `.claude/`. If the shell is not ready yet, wait and retry. Never save memory anywhere else.

## 9. Wrap up

End with:
- What was set up (a short checklist: ✅ done, ⚠️ needs their action).
- Their first three moves: drop something into `raw/` and run `/personal-os:ingest`; run `/personal-os:brief` on one of their projects; run `/personal-os:shutdown` at the end of today.
- One line: "Run `/personal-os:setup tour` any time to see this explanation again."
Then go to step 10.

## 10. Your workshop path

The cohort's workshop modules are plugins of their own. Each one has a setup command that coaches the user through it and picks up where they left off. They all go in **this folder**: one folder for every module, so the Campaign Engine reads the Marketing Brain's files and the Reporting agent's reviews land next to the daily logs.

1. **Check what is installed.** For each module, check whether its setup command is available in this session (it is listed among your commands or skills), and read its progress from this folder (at mapped names when `.claude/folders.json` exists):

   | Order | Module | Setup command | Progress in this folder |
   |---|---|---|---|
   | 1 | Marketing Brain | `/marketing-brain:setup` | `wiki/brand/icp.md`, `positioning-messaging.md`, `voice-guide.md`: `status` other than `template` means done. Example runs: `drafts/example-brain/` |
   | 2 | Campaign Engine | `/campaign-engine:setup` | `projects/campaigns/*/brief.md`: `status: approved` or later means a brief is done |
   | 3 | Reporting agent | `/reporting-agent:setup` | `projects/reporting-agent/reporting-agent.md`: its Progress list |

   Show one table: module · installed · progress (not started, in progress, done for the workshop) · next step.
2. **A module that is not installed:** give its repository URL and how to add it, in four short lines:
   - Marketing Brain: `https://github.com/conversionxl/cxl-marketing-brain`. Campaign Engine: `https://github.com/conversionxl/cxl-campaign-engine`. Reporting agent: `https://github.com/conversionxl/cxl-reporting-agent`.
   - In the Claude app or on claude.ai: **Customize › Plugins › + Add › Add from a repository**, paste the URL, click **Sync**, then click **Add**. Easy to miss: after Sync, the plugin is not active until you click Add.
   - A plugin added in the Claude app reaches VS Code through your Claude account, which can take a few minutes. Still missing? Fully quit and reopen VS Code, then start a new chat in this folder.
   - Never download or clone the repositories: a downloaded copy is not the plugin, and its commands don't show up from it.
3. **Recommend the next step:** the first module in order that is installed and not done. If this was the first run, say: "Close this session, start a new one in this folder (that also switches on your daily logs), and type `<setup command>`." Otherwise offer to start it now, on a yes, by following that command. A module is never required before the next one: the Campaign Engine works without a brand brain, it just asks more questions.
4. One line: "Type `/personal-os:setup` any time to see this table again."
