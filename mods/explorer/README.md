# Explorer

A file tree beside the chat, like the Explorer in VS Code. It shows the folder you're working in so you can watch what Claude and each CXL plugin create, file by file.

## What it shows

- **Your folders and files.** Click a folder to open or close it. Click a file to open it in the Files pane. HTML files also get **↗ browser** to open them in the Browser pane.
- **Git status letters**, as VS Code marks them: **U** new, **A** added, **M** modified, **R** renamed, **↑** committed but not pushed. A folder holding unsaved changes is coloured and carries a dot.
- **Live highlight.** The file Claude is writing right now is highlighted, and "Just changed by Claude" lists what it wrote this session.
- **The plugin map.** A thin coloured line on each row shows which CXL plugin set up that folder (personal-os, marketing-brain, campaign-engine, reporting-agent, visual-brain, product-visual) or created that file. The key under the header lists the plugins on screen; open `raw/`, `wiki/` or `projects/` to see the module folders. What plugins created is kept in `.claude/plugin-map.json`.

It reads your own folder names from `.claude/folders.json`, so a rerouted personal OS maps correctly.

## Commands

- `/explorer` opens the pane. `/explorer plain` opens a simpler text view.
- `/plugin-map` switches the plugin colours on or off.

## Install

In the desktop app's **Code** tab or a terminal session:

```
/plugin marketplace add conversionxl/cxl-personal-os-plugins
/plugin install explorer@cxl-personal-os-plugins
```

If you already added the marketplace for personal-os, only the second line is needed. The pane draws in the desktop app and the terminal. It does not run in Cowork or chat.
