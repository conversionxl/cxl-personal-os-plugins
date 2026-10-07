# Personal OS

> A personal operating system for working with Claude Code, from the CXL AI Native Marketer cohort. Claude reads this file at the start of every session. It explains how the repo runs and how to work with its owner.
>
> **New here? Run `/personal-os:start`.** It walks you through setup and fills in the "About me" section below.

**Writing rule: no em dashes (—), anywhere.** They are a hallmark of AI-generated text. This applies to every file in the repo, daily logs included. Rewrite with whichever punctuation reads best: a full stop for a clean break, a colon for a lead-in, a comma for a brief aside.

---

## About me

<!-- /personal-os:start fills this in. Edit it any time: this is what Claude knows about you before every session. -->

- **Name:**
- **Role and company:**
- **What I'm responsible for:**
- **How I like to work with Claude:**

---

## How this repo runs

Claude has no memory between sessions by default. This repo fixes that with plain Markdown files, so everything Claude knows about your work is readable, editable, and versioned in git.

**Folders and their jobs:**

| Folder | What goes in it |
|---|---|
| `projects/` | One folder per active project, each with a canonical project file. The primary structure for all work. Start from `projects/_template.md`. |
| `raw/` | Unstructured dumps: meeting notes, voice memo transcripts, pasted emails, half-formed ideas. `/personal-os:ingest` processes and files them. |
| `daily-logs/` | One file per day, `YYYY-MM-DD-convo.md`, written automatically when a session ends. Claude's working memory across sessions. |
| `frameworks/` | Reusable methods, models, and checklists: how you do things, not what you are doing. |
| `wiki/` | Durable reference: people, tools, concepts, glossary. Facts that stay true for months. |
| `drafts/` | Content in progress. Anything Claude writes for you lands here first. |
| `team-updates/` | Weekly standup-style updates built from your daily logs. |
| `AGENTS.md` | Points other AI tools (Codex, Copilot, Cursor, Gemini CLI, Grok) at this file, and tells them how to run the routines without hooks. |
| `.claude/commands/` | Your own slash commands. The personal OS commands come from the plugin, as `/personal-os:<name>`. |
| `.claude/skills/` | Skills: know-how Claude loads automatically when a task matches. |
| `.claude/agents/` | Agents: specialists Claude hands a whole job to. |
| `.claude/personal-os.json` | Marks this folder as a personal OS. The plugin's hooks run only in folders that have it. |
| `.claude/memory/` | Standing facts Claude should always know, indexed by `MEMORY.md`. |

**Conventions:**
- **Projects are the starting point.** Before building a command, skill, or agent, ask which project it serves.
- **Project frontmatter:** every project file carries `type`, `status`, `priority`, `cadence`, `next_action`, and `tags`. `/personal-os:lint` uses `cadence` to decide whether a project has gone quiet.
- **Wikilinks** (`[[project-name]]`) for stable entities only: projects, frameworks, people, recurring concepts. Not generic words. Never link to a note that does not exist.
- **Propose before restructuring.** Anything that moves, merges, overwrites, or deletes notes gets a plan first and waits for confirmation. Append or ask; never silently overwrite.
- **Your own folder names.** If `.claude/folders.json` exists, it maps the standard folders in this file to names you already use (for example `projects` to `PROJECTS`, `wiki` to `Resources`). Every command, skill and agent uses the mapped folder wherever it names a standard one, subfolders included. `/personal-os:setup` sets it up and `/personal-os:lint` checks it. `CLAUDE.md`, `AGENTS.md` and `.claude/` never move.
- **Cite what you ingested.** When a note is built from transcripts, exports, or connector results, say where each claim came from.
- **Never invent** statistics, quotes, sources, or case studies. Say when something is unverified.
- **Brand brain.** If `wiki/brand/` exists, it is this folder's tone of voice, messaging and positioning documentation. Read it before writing anything customer-facing: `icp.md` for who, `positioning-messaging.md` for what to say, `voice-guide.md` and `vocabulary.md` for how to say it. It outranks any other voice or style note in this folder.
- **Write inside `.claude/` with the shell.** Memory, skills and commands live there. In Cowork the file-edit tools cannot write inside `.claude/`, but the shell can once it has started, so use a heredoc. If the shell is not ready, wait and retry. Never save memory anywhere except `.claude/memory/`.
- **Secrets stay out of git.** API keys and tokens live only in `.claude/settings.local.json` or `.env`, both gitignored. No personal email addresses in tracked files either: git history is permanent.

---

## Commands

| Command | When to run it | What it does |
|---|---|---|
| `/personal-os:start` | Once, after `/personal-os:setup`. Again any time you want the tour. | Checks setup, links memory, explains the system, fills in "About me", creates your first projects. |
| `/personal-os:brief [person\|project\|topic]` | Before a meeting or a context switch. | Pulls together everything the repo (plus email and calendar, if connected) knows about the subject. |
| `/personal-os:ingest` | When `raw/` has things in it. | Reads every raw dump, proposes where each piece belongs, and files it after you confirm. |
| `/personal-os:shutdown` | End of the working day. | Reconciles what got done, routes new commitments into project files, writes a rich daily log, offers to push to GitHub. |
| `/personal-os:lint` | Weekly. A reminder appears at session start when it is overdue. | Health check: contradictions, stale claims, orphan notes, missing concepts, neglected projects, unsourced claims, folder-map drift, loose and temp files, and a folder cleanup plan. Reports first, fixes on confirmation. |
| `/personal-os:team-update [this-week\|last-week\|today]` | When you owe someone a status update. | Turns your daily logs into a short standup update in `team-updates/`. |

---

## Hooks (what runs automatically)

They come from the personal-os plugin and run only in this folder (it has `.claude/personal-os.json`). They need `jq` and the `claude` CLI on your PATH, and they fail silently if either is missing.

| When | Hook | What it does |
|---|---|---|
| Session start | `health.sh` | Checks that `jq` and the `claude` CLI exist and leaves a heartbeat in `.claude/state/`. If something is missing, it tells you at session start instead of the logs quietly stopping. Needs only bash. |
| Session start | `load-recent-logs.sh` | Loads your two most recent daily logs into context, so every session starts where the last one ended. |
| Session start | `catch-up-logs.sh` | Backfills a daily log for any past day that has a session transcript but no log (the editor was closed, the laptop slept). Runs in the background. |
| Session start | `lint-due.sh` | Prints a one-line reminder if `/personal-os:lint` has not run in 7 days. Silent otherwise. |
| Session start | `team-update.sh` | If last week has daily logs but no team update, writes one to `team-updates/` in the background. |
| Session start | `restore-state.sh` | After a context compaction, re-injects the snapshot taken just before it. |
| Before compaction | `preserve-state.sh` | Snapshots files changed, your verbatim prompts, and git state, so compaction does not blur them. |
| Session end | `auto-shutdown.sh` | Writes today's daily log from the session transcript, using headless Claude (Sonnet). Appends if the day already has a log; never overwrites. |

**Manual fallback (when hooks are not running).** If the session context shows a "hooks degraded" notice, or shows no "Recent daily logs" block while `daily-logs/` has dated logs, the hooks are not running on this machine (most often Windows without Git Bash or `jq`). Then:
- Tell the user once, and point them to `/personal-os:start` to fix it.
- Read the two newest dated files in `daily-logs/` yourself before starting work.
- Before the session ends, remind the user to run `/personal-os:shutdown`. It writes the daily log itself and does not depend on hooks.

**Daily logs vs Claude's built-in memory.** Built-in memory (`.claude/memory/`) holds a small set of standing facts: preferences, key people, where things live. Daily logs hold what happened: work done, decisions, commitments, roll-forward. Memory answers "what is always true", logs answer "where did we leave off". Both are plain files in this repo, so you own them, can read them, and can fix them.

---

## Where you run it

| Tool | Commands | Hooks and automatic daily logs |
|---|---|---|
| Claude Code (VS Code extension or terminal) | Type `/personal-os:start`, `/personal-os:shutdown`, and so on | Yes |
| Desktop app: Code tab (Environment: Local) | Type `/personal-os:start`, `/personal-os:shutdown`, and so on | Yes |
| Cowork | Type `/personal-os:shutdown` and so on | No. Cowork runs hooks in its own workspace, where this folder isn't. Read the newest daily logs at the start of a session, and run `/personal-os:shutdown` at the end of each day |
| claude.ai/code in a browser, or Environment: Cloud | Plugins do not load there | No. Open your GitHub repo and ask for what you need in plain words |

## GitHub is optional

Without GitHub (a ZIP download, or a folder you never push), everything in this repo still works on one machine. What you give up: version history (no undoing a bad edit to a project file or memory), sync across machines, and the more complex setups later in the cohort that build on git, such as shared team repos and pull-request reviews. You can add GitHub later: `git init`, create a private repo, and push.

## Memory

Memory lives in the repo at `.claude/memory/`, indexed by `MEMORY.md`. Claude Code looks for memory at `~/.claude/projects/<slugified-repo-path>/memory/`, outside the repo. `bash .claude/link-memory.sh` points that path at the repo copy, so memory travels with the repo across machines. **Run it once on every machine you use this folder on.** Without it, memory silently stays machine-local.

Index lines in `MEMORY.md` use a colon as the separator: `- [Title](file.md): hook`. Memory records what was true when written; verify a remembered file or tool still exists before acting on it.

---

## How to work with me

- **Be decisive.** Give a recommendation, not a survey of options.
- **Verify before asserting.** Check that a file, command, or connector exists before recommending it.
- **Keep output skimmable.** Short sections, tables over walls of text, no filler.
- **Say plainly what is done and what is not.** Finished and verified: say so. Skipped or unverified: say that too.
