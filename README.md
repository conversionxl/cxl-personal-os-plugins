# Personal OS plugin

The plug-and-play route to the personal OS from the CXL AI Native Marketer cohort. It builds the same system as the [starter repo](https://github.com/conversionxl/cxl-personal-os): project folders, daily logs written automatically, memory that travels with your folder, and the personal OS commands. You don't need VS Code, and you don't need to clone a repo.

Already set up the starter repo? Keep it. Both routes are the same system.

## Install

Install it **one way only**. Installed twice, every hook runs twice.

**From Claude's settings** (recommended: no typing)

Works in claude.ai and the Claude desktop app ([claude.ai/download](https://claude.ai/download)). One exception: Code on claude.ai only runs cloud sessions on a GitHub repository, and cloud sessions don't load plugins. For the Code tab, use the desktop app.

1. Open **Customize** in the left sidebar. In Cowork, open the Cowork tab first.
2. Click **Browse plugins**, then **Personal**, then **+**, then **Add marketplace from GitHub**.
3. Enter `https://github.com/conversionxl/cxl-personal-os-plugins`, then add **personal-os**.
4. Make an empty folder, such as `Documents/personal-os`. Open it in either:
   - the desktop app's **Code** tab, with **Environment** set to **Local** and the folder picked as **Project folder** (set to Cloud, it only offers repositories), or
   - **Cowork**. Commands work there, but daily logs are not automatic (see below).

   Then type `/personal-os:setup`.

The plugin is saved to your claude.ai account, not your computer, so it follows you to chat, Cowork and Claude Code.

**From Claude Code in a terminal or VS Code**

In a terminal or VS Code session, in an empty folder:

```
/plugin marketplace add conversionxl/cxl-personal-os-plugins
/plugin install personal-os@cxl-personal-os-plugins
/personal-os:setup
```

**Installed both ways by accident?** Run `/plugin` in Claude Code. If you see both `personal-os@synced` and `personal-os@cxl-personal-os-plugins`, uninstall the second.

## Updating

New versions don't install themselves on a personal marketplace. To update: **Plugins → Add → Manage marketplaces → ⋮** next to the marketplace → **Check for updates**. Your folder, logs and projects are untouched. (Automatic sync needs the Claude GitHub App to have access to the repo; that is not set up.)

## Where it works

| Where | What loads |
|---|---|
| Desktop app: Code tab (Environment: Local), terminal, VS Code | Everything |
| Cowork | Commands, skills and agents. **No automatic daily logs:** Cowork runs hooks in its own workspace, where your folder isn't, so run `/personal-os:shutdown` at the end of each day. Memory is written through the shell, because Cowork's file tools can't write inside `.claude/` |
| claude.ai chat | Skills only |
| claude.ai/code in a browser, or the Code tab with Environment: Cloud | Nothing. Cloud sessions do not load plugins |

**Windows:** the hooks are bash scripts. Install Git for Windows and jq once: `winget install Git.Git jqlang.jq`, then fully quit and reopen the Claude app. `/personal-os:start` checks both.

**Daily logs begin in your second session.** Setup switches them on, so close the setup session and start a new one in the folder.

## Commands

| Command | What it does |
|---|---|
| `/personal-os:setup` | Builds the personal OS in the current folder and makes it a git repo. Never overwrites a file |
| `/personal-os:start` | Checks setup, explains the system, fills in "About me", creates your first projects |
| `/personal-os:brief` | Everything the folder knows about a person, project or topic |
| `/personal-os:ingest` | Files what you dropped into `raw/` |
| `/personal-os:shutdown` | End of day: reconciles, routes commitments, writes the daily log |
| `/personal-os:lint` | Weekly health check, including loose and temp files and a folder cleanup plan |
| `/personal-os:team-update` | A standup-style update from your daily logs |

## Already have your own folders?

Keep them. Run `/personal-os:setup` in the folder you already use. If it holds folders of your own, setup asks whether to reroute the personal OS to them (say `PROJECTS/` for projects and `Resources/` for the wiki) before it copies anything, and saves your answer in `.claude/folders.json`. Every hook, command, skill and agent then uses your folder names, the workshop plugins (`/marketing-brain:setup`, `/campaign-engine:setup`) put their folders inside yours, and local-only folders stay out of git under their new names. Nothing moves unless you say so. `CLAUDE.md`, `AGENTS.md` and `.claude/` stay where they are. `/personal-os:lint` checks the map each week.

## How the hooks stay out of your other folders

The plugin is installed once for your whole account, so its hooks would otherwise run in every folder you open. They run only where `/personal-os:setup` has written `.claude/personal-os.json`. Delete that file to switch them off in a folder.

## Workshop plugins

Each workshop has its own plugin in its own marketplace. Add the marketplace once, install the plugin, then run its setup in your personal OS folder:

| Plugin | Add this marketplace | Setup | Adds |
|---|---|---|---|
| **marketing-brain** | `https://github.com/conversionxl/cxl-marketing-brain` | `/marketing-brain:setup` | The brand brain: ICP, positioning and messaging, brand voice. [Details](https://github.com/conversionxl/cxl-marketing-brain#plugin-route) |

## Other AI tools

Setup also writes an `AGENTS.md`. Codex, GitHub Copilot, Cursor and Grok read it, and it points them at `CLAUDE.md` and tells them where the routines are. In Gemini CLI, add `"context": {"fileName": ["AGENTS.md", "GEMINI.md"]}` to `.gemini/settings.json`. Those tools don't run the hooks, so daily logs are by hand there: ask for the shutdown routine at the end of the day. Already set up? Run `/personal-os:setup` again. It adds new files and never overwrites yours.

## Changing how it works

Your folder is yours: `CLAUDE.md`, projects, memory and your own `.claude/skills/` are plain files. The plugin's commands and hooks update with the plugin. To change one, copy it into your folder's `.claude/commands/` and edit the copy. That is the first step toward the full VS Code route.
