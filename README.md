# Personal OS plugin

The plug-and-play route to the personal OS from the CXL AI Native Marketer cohort. It builds the same system as the [starter repo](https://github.com/conversionxl/cxl-personal-os): project folders, daily logs written automatically, memory that travels with your folder, and the personal OS commands. You don't need VS Code, and you don't need to clone a repo.

Already set up the starter repo? Keep it, and don't add the plugin to that folder. Both routes are the same system: one folder uses one of them.

## This repository is the plugin, not your folder

**Don't download, clone or open this repository as your working folder.** It holds the plugin's source code (`commands/`, `hooks/`, `template/`). Opened as a folder, nothing works: the commands don't appear, the hooks don't run, and no daily logs get written.

You install the plugin into Claude, and Claude keeps its own copy. Your working folder is a separate, empty folder of your own, where `/personal-os:setup` builds your personal OS.

| | The plugin (this repository) | Your folder |
|---|---|---|
| What it is | The commands, hooks and skills | Your projects, logs, memory and `CLAUDE.md` |
| Where it lives | In Claude, installed from **Settings → Plugins** | Anywhere on your computer, such as `Documents/personal-os` |
| How you get it | Install it (below). Never download it | Make an empty folder and run `/personal-os:setup` in it |

Want the repository route instead, with your own git copy to open in VS Code? That's the [starter repo](https://github.com/conversionxl/cxl-personal-os), not this one.

## Install

Install it **one way only**: from **Settings → Plugins** in Claude. Installed twice, every hook runs twice.

1. Open Claude: claude.ai or the desktop app ([claude.ai/download](https://claude.ai/download)).
2. Open **Settings → Plugins**, click **Add → Add marketplace**, and choose the GitHub repo option.
3. Enter `conversionxl/cxl-personal-os-plugins`, then add **Personal os**. It then shows under **From marketplaces you added**.
4. Make an empty folder, such as `Documents/personal-os`. Open it in either:
   - the desktop app's **Code** tab, with **Environment** set to **Local** and the folder picked as **Project folder** (set to Cloud, it only offers repositories), or
   - **Cowork**. Commands work there, but daily logs are not automatic (see below).

   Then type `/personal-os:setup`.

The plugin is saved to your claude.ai account, not your computer. Claude syncs it to chat, Cowork, the desktop app, VS Code and the terminal, so you install it once. Code on claude.ai is the one exception: it only runs cloud sessions on a GitHub repository, and cloud sessions don't load plugins. For the Code tab, use the desktop app.

**Only if you can't use Settings → Plugins:** in a terminal or VS Code session, in an empty folder:

```
/plugin marketplace add conversionxl/cxl-personal-os-plugins
/plugin install personal-os@cxl-personal-os-plugins
/personal-os:setup
```

This makes a second, local copy that lives on this computer only. Never use it as well as the Settings → Plugins route.

## Troubleshooting: a local copy and a synced copy

A plugin reaches Claude Code in one of two ways:

| Copy | How it got there | Listed in `/plugin` as |
|---|---|---|
| **Synced** (the one to keep) | Added in **Settings → Plugins** on claude.ai or the desktop app | `personal-os@synced` |
| **Local** | Typed `/plugin marketplace add` and `/plugin install` in a terminal or VS Code | `personal-os@cxl-personal-os-plugins` |

**Signs you have both:** two daily logs for the same session, the session-start context printed twice, or every command listed twice.

**Fix:** keep the synced copy and remove the local one. Ask Claude:

```
Remove the local copy of the personal-os plugin and its cxl-personal-os-plugins marketplace. Keep the synced one.
```

Then fully quit and reopen Claude. (By hand: `/plugin uninstall personal-os@cxl-personal-os-plugins`, then `/plugin marketplace remove cxl-personal-os-plugins`.)

**Plugin missing in VS Code or the terminal after you added it in Settings → Plugins?** The sync can take a few minutes. Fully quit and reopen. Don't fix it by adding the local copy: that's how you end up with two.

**Opened this repository as your folder by mistake?** Close it, make an empty folder of your own, install the plugin as above, and run `/personal-os:setup` there. The downloaded copy can be deleted.

## Updating

New versions don't install themselves on a personal marketplace. To update: **Settings → Plugins → Add → Manage marketplaces → ⋮** next to the marketplace → **Check for updates**. Your folder, logs and projects are untouched. (Automatic sync needs the Claude GitHub App to have access to the repo; that is not set up.)

## Where it works

| Where | What loads |
|---|---|
| Desktop app: Code tab (Environment: Local), terminal, VS Code | Everything |
| Cowork | Commands, skills and agents. **No automatic daily logs:** Cowork runs hooks in its own workspace, where your folder isn't, so run `/personal-os:shutdown` at the end of each day. Memory is written through the shell, because Cowork's file tools can't write inside `.claude/` |
| claude.ai chat | Skills only |
| claude.ai/code in a browser, or the Code tab with Environment: Cloud | Nothing. Cloud sessions do not load plugins |

**Windows:** the hooks are bash scripts. Install Git for Windows and jq once: `winget install Git.Git jqlang.jq`, then fully quit and reopen the Claude app. `/personal-os:setup` checks both.

**Daily logs begin in your second session.** Setup switches them on, so close the setup session and start a new one in the folder.

## Commands

| Command | What it does |
|---|---|
| `/personal-os:setup` | Builds the personal OS in the current folder and makes it a git repo (never overwrites a file), checks your setup, explains the system, fills in "About me", creates your first projects, then shows your workshop path: which modules (Marketing Brain, Campaign Engine, Reporting agent) are installed in this folder, how far you are, and the setup to run next. Run it again any time to re-check your setup and see your next step; `/personal-os:setup tour` repeats the explanation. (`/personal-os:start` still works and runs setup.) |
| `/personal-os:brief` | Everything the folder knows about a person, project or topic |
| `/personal-os:ingest` | Files what you dropped into `raw/` |
| `/personal-os:shutdown` | End of day: reconciles, routes commitments, writes the daily log |
| `/personal-os:lint` | Weekly health check, including loose and temp files and a folder cleanup plan |
| `/personal-os:team-update` | A standup-style update from your daily logs |

## AI visibility builds

Guided setup for the AI visibility workshop. Each one coaches you one step at a time, from an empty folder to a report and a re-run command of your own.

| Command | What it builds |
|---|---|
| `/personal-os:aeo-qualitybuild-instructions` | Build 1, quality: does AI get your company right? A fact sheet, a brand accuracy report, and `/answer-quality` |
| `/personal-os:aeo-goingdeep-instructions` | Build 2, going deep: a weekly n8n tracker of how often AI names you, and `/going-deep` |
| `/personal-os:aeo-goingwide-instructions` | Build 3, going wide: up to 1,000 questions from Search Console, who AI names instead, and `/going-wide` |
| `/personal-os:aeo-baseline-instructions` | Build 4, baseline: what AI traffic is worth, from GA4 and Search Console, and `/baseline` |
| `/personal-os:aeo-canonical-instructions` | Fix the sources: one canonical description of your company, an audit of your site, a swap sheet, a profile checklist for social and third-party listings, and `/canonical-check`. Run it after the quality build |

## Already have your own folders?

Keep them. Run `/personal-os:setup` in the folder you already use. If it holds folders of your own, setup asks whether to reroute the personal OS to them (say `PROJECTS/` for projects and `Resources/` for the wiki) before it copies anything, and saves your answer in `.claude/folders.json`. Every hook, command, skill and agent then uses your folder names, the workshop plugins (`/marketing-brain:setup`, `/campaign-engine:setup`) put their folders inside yours, and local-only folders stay out of git under their new names. Nothing moves unless you say so. `CLAUDE.md`, `AGENTS.md` and `.claude/` stay where they are. `/personal-os:lint` checks the map each week.

## How the hooks stay out of your other folders

The plugin is installed once for your whole account, so its hooks would otherwise run in every folder you open. They run only where `/personal-os:setup` has written `.claude/personal-os.json`. Delete that file to switch them off in a folder. In a folder cloned from a starter repo, which runs its own copies from `.claude/hooks/`, they stay off even with the marker, so you never get two daily logs.

## Workshop plugins

Each workshop has its own plugin in its own marketplace. Add each one from **Settings → Plugins** the same way as personal-os, then run its setup in your personal OS folder. The same rules apply: install from Settings → Plugins, don't download the repository, and keep one copy.

| Plugin | Add this marketplace | Setup | Adds |
|---|---|---|---|
| **marketing-brain** | `https://github.com/conversionxl/cxl-marketing-brain` | `/marketing-brain:setup` | The brand brain: ICP, positioning and messaging, brand voice. [Details](https://github.com/conversionxl/cxl-marketing-brain#plugin-route) |
| **campaign-engine** | `https://github.com/conversionxl/cxl-campaign-engine` | `/campaign-engine:setup` | Briefs, channel workflows, drafts and a quality gate. [Details](https://github.com/conversionxl/cxl-campaign-engine#plugin-route) |

## Other AI tools

Setup also writes an `AGENTS.md`. Codex, GitHub Copilot, Cursor and Grok read it, and it points them at `CLAUDE.md` and tells them where the routines are. In Gemini CLI, add `"context": {"fileName": ["AGENTS.md", "GEMINI.md"]}` to `.gemini/settings.json`. Those tools don't run the hooks, so daily logs are by hand there: ask for the shutdown routine at the end of the day. Already set up? Run `/personal-os:setup` again. It adds new files and never overwrites yours.

## Changing how it works

Your folder is yours: `CLAUDE.md`, projects, memory and your own `.claude/skills/` are plain files. The plugin's commands and hooks update with the plugin. To change one, copy it into your folder's `.claude/commands/` and edit the copy. That is the first step toward the full VS Code route.
